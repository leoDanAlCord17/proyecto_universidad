import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'buscar_asistente_estado.dart';
import 'buscar_asistente_repositorio.dart';
import 'resultado_busqueda.dart';

class BuscarAsistenteCubit extends Cubit<BuscarAsistenteEstado> {
  BuscarAsistenteCubit(this._repositorio) : super(const BuscarAsistenteInicial());

  final BuscarAsistenteRepositorio _repositorio;

  String?      _eventoId;
  String?      _adminId;
  String       _busqueda  = '';
  final _idsCargando = <String>{};

  List<Map<String, dynamic>>        _ultimosUsuarios    = [];
  Map<String, Map<String, dynamic>> _mapaAsist          = {};
  List<Map<String, dynamic>>        _foraneos           = [];
  Map<String, String>               _mapaRegistradores  = {};

  StreamSubscription<List<Map<String, dynamic>>>? _suscripcion;

  Future<void> iniciar(String eventoId, {String? adminId}) async {
    _eventoId = eventoId;
    _adminId  = adminId;
    emit(const BuscarAsistenteCargando());
    try {
      final evento = await _repositorio.obtenerEvento(eventoId);
      _suscripcion = _repositorio
          .streamAsistencia(eventoId)
          .listen(_actualizarAsistencia);
      emit(BuscarAsistenteCargado(
        evento:            evento,
        resultados:        const [],
        busqueda:          '',
        cantidadPresentes: 0,
        cantidadTotal:     0,
      ),);
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(BuscarAsistenteError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(BuscarAsistenteError(mensaje: e.mensaje));
    }
  }

  Future<void> buscar(String query) async {
    final cargado = _extraerCargado(state);
    if (cargado == null || _eventoId == null) return;
    _busqueda = query;
    if (query.trim().length < 2) {
      emit(cargado.copiarCon(resultados: const [], busqueda: query));
      return;
    }
    try {
      _ultimosUsuarios = await _repositorio.buscarUsuarios(query);
      _emitirResultados(cargado);
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(BuscarAsistenteOperacionFallida(anterior: cargado, mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(BuscarAsistenteOperacionFallida(anterior: cargado, mensaje: e.mensaje));
    }
  }

  Future<void> registrarEntrada(ResultadoBusqueda resultado) async {
    final cargado = _extraerCargado(state);
    if (cargado == null || _eventoId == null) return;
    if (_idsCargando.contains(resultado.usuarioId)) return;
    _idsCargando.add(resultado.usuarioId);
    emit(cargado.copiarCon(estaRegistrando: true, usuarioIdRegistrando: resultado.usuarioId));
    try {
      await _repositorio.registrarEntrada(
        eventoId:        _eventoId!,
        usuarioId:       resultado.usuarioId,
        asistenciaId:    resultado.asistenciaId,
        registradoPorId: _adminId,
      );
      final actual = _extraerCargado(state) ?? cargado;
      emit(actual.copiarCon(estaRegistrando: false, usuarioIdRegistrando: null));
    } on FallaServidor catch (e) {
      reportarError(e);
      _emitirFalloRegistro(cargado, e.mensaje);
    } on FallaInesperada catch (e) {
      reportarError(e);
      _emitirFalloRegistro(cargado, e.mensaje);
    } finally {
      _idsCargando.remove(resultado.usuarioId);
    }
  }

  Future<void> marcarSalida({
    required String asistenciaId,
    required bool   esAnticipada,
    String?         motivo,
  }) async {
    final cargado = _extraerCargado(state);
    if (cargado == null) return;
    emit(cargado.copiarCon(estaMarcandoSalida: true));
    try {
      await _repositorio.marcarSalida(
        asistenciaId:    asistenciaId,
        esAnticipada:    esAnticipada,
        motivo:          motivo,
        registradoPorId: _adminId,
      );
      emit(cargado.copiarCon(estaMarcandoSalida: false));
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(BuscarAsistenteOperacionFallida(
        anterior: cargado.copiarCon(estaMarcandoSalida: false), mensaje: e.mensaje,),);
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(BuscarAsistenteOperacionFallida(
        anterior: cargado.copiarCon(estaMarcandoSalida: false), mensaje: e.mensaje,),);
    }
  }

  @override
  Future<void> close() {
    _suscripcion?.cancel();
    return super.close();
  }

  // ─── Helpers privados ────────────────────────────────────────────────────────

  void _emitirFalloRegistro(BuscarAsistenteCargado base, String mensaje) {
    final actual = _extraerCargado(state) ?? base;
    emit(BuscarAsistenteOperacionFallida(
      anterior: actual.copiarCon(estaRegistrando: false, usuarioIdRegistrando: null),
      mensaje:  mensaje,
    ),);
  }

  void _actualizarAsistencia(List<Map<String, dynamic>> filas) {
    _mapaAsist = {};
    _foraneos  = [];
    for (final f in filas) {
      if (f['usuario_id'] != null) {
        _mapaAsist[f['usuario_id'] as String] = f;
      } else {
        _foraneos.add(f);
      }
    }
    _resolverRegistradoresYEmitir();
  }

  Future<void> _resolverRegistradoresYEmitir() async {
    final idsNuevos = {
      ...(_mapaAsist.values
          .map((f) => f['entrada_registrada_por'] as String?)
          .whereType<String>()),
      ...(_foraneos
          .map((f) => f['entrada_registrada_por'] as String?)
          .whereType<String>()),
    }.where((id) => !_mapaRegistradores.containsKey(id)).toList();

    if (idsNuevos.isNotEmpty) {
      try {
        final nuevos = await _repositorio.resolverNombresUsuarios(idsNuevos);
        _mapaRegistradores = {..._mapaRegistradores, ...nuevos};
      } catch (_) {}
    }

    final cargado = _extraerCargado(state);
    if (cargado != null && _busqueda.trim().length >= 2) _emitirResultados(cargado);
  }

  void _emitirResultados(BuscarAsistenteCargado cargado) {
    final esGeneral = cargado.evento.alcance == AlcanceEvento.general;
    final usuarios  = _ultimosUsuarios.map((u) {
      final uid        = u['id'] as String;
      var   asistencia = _mapaAsist[uid];
      if (asistencia == null && esGeneral) {
        asistencia = {'estatus': EstatusAsistencia.esperado};
      }
      final regId   = asistencia?['entrada_registrada_por'] as String?;
      final regNombre = regId != null ? _mapaRegistradores[regId] : null;
      return ResultadoBusqueda.desdeUsuario(
        u,
        asistencia:          asistencia,
        registradoPorNombre: regNombre,
      );
    }).toList();
    final bLow     = _busqueda.toLowerCase();
    final foraneos = _foraneos.where((f) {
      final fn = (f['visitante_primer_nombre']   as String? ?? '').toLowerCase();
      final fa = (f['visitante_primer_apellido'] as String? ?? '').toLowerCase();
      return fn.contains(bLow) || fa.contains(bLow);
    }).map(ResultadoBusqueda.desdeForaneo).toList();
    emit(cargado.copiarCon(
      resultados:        [...usuarios, ...foraneos],
      busqueda:          _busqueda,
      cantidadPresentes: _contarPresentes(),
      cantidadTotal:     _mapaAsist.length + _foraneos.length,
    ),);
  }

  int _contarPresentes() {
    const activos = {
      EstatusAsistencia.presente,
      EstatusAsistencia.completado,
      EstatusAsistencia.salioAnticipado,
    };
    final enMapa = _mapaAsist.values
        .where((f) => activos.contains(f['estatus'] as String?))
        .length;
    final foraneosPres = _foraneos
        .where((f) => activos.contains(f['estatus'] as String?))
        .length;
    return enMapa + foraneosPres;
  }

  BuscarAsistenteCargado? _extraerCargado(BuscarAsistenteEstado estado) =>
      switch (estado) {
        BuscarAsistenteCargado()          => estado,
        BuscarAsistenteOperacionFallida() => estado.anterior,
        _                                 => null,
      };
}
