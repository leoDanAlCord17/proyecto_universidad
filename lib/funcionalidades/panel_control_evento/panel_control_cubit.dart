import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import 'asistente_item.dart';
import 'panel_control_estado.dart';
import 'panel_control_repositorio.dart';

class PanelControlCubit extends Cubit<PanelControlEstado> {
  PanelControlCubit(this._repositorio) : super(const PanelControlInicial());

  final PanelControlRepositorio _repositorio;
  String? _eventoId;
  String? _adminId;
  List<AsistenteItem> _audiencia      = [];
  bool                _estaRecargando = false;
  StreamSubscription<List<Map<String, dynamic>>>? _suscripcionAsistencia;

  Future<void> cargar(String eventoId, {String? adminId}) async {
    _eventoId = eventoId;
    _adminId  = adminId;
    emit(const PanelControlCargando());
    try {
      final evento     = await _repositorio.obtenerEvento(eventoId);
      final asistentes = await _repositorio.obtenerAsistentes(eventoId);

      _audiencia = evento.alcance == AlcanceEvento.dirigido
          ? await _repositorio.obtenerMiembrosGrupo(eventoId)
          : <AsistenteItem>[];

      final asistentesConFlag = _marcarEsperados(asistentes, _audiencia);
      emit(PanelControlCargado(
        evento:         evento,
        asistentes:     asistentesConFlag,
        listaEsperados: _mergarConAsistencia(_audiencia, asistentesConFlag),
      ));
      _suscribirStreamAsistencia(eventoId);
    } on FallaServidor catch (e) {
      emit(PanelControlError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(PanelControlError(mensaje: e.mensaje));
    }
  }

  Future<void> registrarForaneo({
    required String primerNombre,
    required String primerApellido,
    String? cedula,
    String? contacto,
  }) async {
    final cargado = _extraerCargado(state);
    if (cargado == null || _eventoId == null) return;

    emit(cargado.copiarCon(estaRegistrando: true));
    try {
      await _repositorio.registrarForaneo(
        eventoId:        _eventoId!,
        primerNombre:    primerNombre,
        primerApellido:  primerApellido,
        cedula:          cedula,
        contacto:        contacto,
        registradoPorId: _adminId,
      );
      await _actualizarListaAsistentes(cargado, estaRegistrando: false);
    } on FallaServidor catch (e) {
      _emitirFalloPanel(cargado, e.mensaje);
    } on FallaInesperada catch (e) {
      _emitirFalloPanel(cargado, e.mensaje);
    }
  }

  Future<void> recargarSilencioso() => _recargarAsistentes();

  void cambiarFiltro(FiltroAsistentes filtro) {
    final cargado = _extraerCargado(state);
    if (cargado == null) return;
    emit(cargado.copiarCon(filtroActivo: filtro));
  }

  Future<void> cerrarEvento() async {
    final cargado = _extraerCargado(state);
    if (cargado == null || _eventoId == null) return;

    emit(cargado.copiarCon(estaCerrando: true));
    try {
      await _repositorio.cerrarEvento(_eventoId!);
      if (cargado.evento.marcarAusentesAuto) {
        await _repositorio.marcarAusentesAuto(_eventoId!);
      }
      emit(const PanelControlEventoCerrado());
    } on FallaServidor catch (e) {
      emit(PanelControlOperacionFallida(
        anterior: cargado.copiarCon(estaCerrando: false),
        mensaje:  e.mensaje,
      ));
    } on FallaInesperada catch (e) {
      emit(PanelControlOperacionFallida(
        anterior: cargado.copiarCon(estaCerrando: false),
        mensaje:  e.mensaje,
      ));
    }
  }

  @override
  Future<void> close() {
    _suscripcionAsistencia?.cancel();
    return super.close();
  }

  // ─── Recarga silenciosa disparada por el stream de Realtime ─────────────────

  Future<void> _recargarAsistentes() async {
    if (_estaRecargando) return;
    final cargado = _extraerCargado(state);
    if (cargado == null || _eventoId == null) return;
    _estaRecargando = true;
    try {
      await _actualizarListaAsistentes(cargado);
    } on FallaServidor catch (_) {
      // Silencioso: el panel funciona con datos ligeramente desactualizados
    } on FallaInesperada catch (_) {
      // Silencioso: el panel funciona con datos ligeramente desactualizados
    } finally {
      _estaRecargando = false;
    }
  }

  // ─── Helpers privados ────────────────────────────────────────────────────────

  void _suscribirStreamAsistencia(String eventoId) {
    _suscripcionAsistencia?.cancel();
    _suscripcionAsistencia = _repositorio
        .streamCambiosAsistencia(eventoId)
        .skip(1)
        .listen((_) => _recargarAsistentes());
  }

  Future<void> _actualizarListaAsistentes(
    PanelControlCargado base, {
    bool estaRegistrando = false,
  }) async {
    final asistentes        = await _repositorio.obtenerAsistentes(_eventoId!);
    final asistentesConFlag = _marcarEsperados(asistentes, _audiencia);
    final actual            = _extraerCargado(state) ?? base;
    emit(actual.copiarCon(
      asistentes:      asistentesConFlag,
      listaEsperados:  _mergarConAsistencia(_audiencia, asistentesConFlag),
      estaRegistrando: estaRegistrando,
    ));
  }

  void _emitirFalloPanel(PanelControlCargado base, String mensaje) {
    final actual = _extraerCargado(state) ?? base;
    emit(PanelControlOperacionFallida(
      anterior: actual.copiarCon(estaRegistrando: false),
      mensaje:  mensaje,
    ));
  }

  List<AsistenteItem> _marcarEsperados(
    List<AsistenteItem> asistentes,
    List<AsistenteItem> audiencia,
  ) {
    final idsEsperados = audiencia
        .map((a) => a.usuarioId)
        .whereType<String>()
        .toSet();
    return asistentes.map((a) {
      if (a.usuarioId != null && idsEsperados.contains(a.usuarioId)) {
        return a.copiarCon(eraEsperado: true);
      }
      return a;
    }).toList();
  }

  List<AsistenteItem> _mergarConAsistencia(
    List<AsistenteItem> audiencia,
    List<AsistenteItem> asistentes,
  ) {
    final mapaAsistencia = <String, AsistenteItem>{
      for (final a in asistentes)
        if (a.usuarioId != null) a.usuarioId!: a,
    };
    return audiencia.map((item) {
      if (item.usuarioId == null) return item;
      return mapaAsistencia[item.usuarioId] ?? item;
    }).toList();
  }

  PanelControlCargado? _extraerCargado(PanelControlEstado estado) =>
      switch (estado) {
        PanelControlCargado()          => estado,
        PanelControlOperacionFallida() => estado.anterior,
        _                              => null,
      };
}
