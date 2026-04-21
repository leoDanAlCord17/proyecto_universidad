import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import 'crear_evento_estado.dart';
import 'crear_evento_repositorio.dart';
import 'tag_opcion.dart';
import 'tipo_evento.dart';

class CrearEventoCubit extends Cubit<CrearEventoEstado> {
  CrearEventoCubit(this._repositorio) : super(const CrearEventoInicial());

  final CrearEventoRepositorio _repositorio;

  Future<void> cargarOpciones() async {
    emit(const CrearEventoCargando());
    try {
      final tiposEvento = await _repositorio.obtenerTiposEvento();
      final tags        = await _repositorio.obtenerTags();
      emit(CrearEventoCargado(
        tiposEvento:     tiposEvento,
        tagsPrincipales: tags.where((t) => t.tipo == 'principal').toList(),
        tagsSecundarios: tags.where((t) => t.tipo == 'secundario').toList(),
      ));
    } on FallaServidor catch (e) {
      emit(CrearEventoError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(CrearEventoError(mensaje: e.mensaje));
    }
  }

  Future<void> cargarEventoParaEditar(String eventoId) async {
    emit(const CrearEventoCargando());
    try {
      final tiposEvento = await _repositorio.obtenerTiposEvento();
      final tags        = await _repositorio.obtenerTags();
      final resultado   = await _repositorio.obtenerEvento(eventoId);
      emit(_estadoDesdeEvento(eventoId, tiposEvento, tags, resultado));
    } on FallaServidor catch (e) {
      emit(CrearEventoError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(CrearEventoError(mensaje: e.mensaje));
    }
  }

  CrearEventoCargado _estadoDesdeEvento(
    String eventoId,
    List<TipoEvento> tiposEvento,
    List<TagOpcion> tags,
    ({Map<String, dynamic> evento, List<String> tagsPrincipalesIds, List<String> tagsSecundariosIds}) resultado,
  ) {
    final e     = resultado.evento;
    final tipo  = _resolverTipoEvento(e['tipo_evento_id'] as String?, tiposEvento);
    final bools = _boolsDesdeEvento(e);
    return CrearEventoCargado(
      eventoId:                eventoId,
      tiposEvento:             tiposEvento,
      tagsPrincipales:         tags.where((t) => t.tipo == 'principal').toList(),
      tagsSecundarios:         tags.where((t) => t.tipo == 'secundario').toList(),
      tipoEventoSeleccionado:  tipo,
      tagsPrincipalesIds:      resultado.tagsPrincipalesIds,
      tagsSecundariosIds:      resultado.tagsSecundariosIds,
      titulo:                  e['titulo']      as String? ?? '',
      descripcion:             e['descripcion'] as String? ?? '',
      lugar:                   e['lugar']       as String? ?? '',
      fechaInicio:             e['fecha_inicio'] != null ? DateTime.tryParse(e['fecha_inicio'] as String) : null,
      horaInicio:              _parseHora(e['hora_inicio'] as String?),
      tieneFechaFin:           e['fecha_fin'] != null,
      fechaFin:                e['fecha_fin'] != null ? DateTime.tryParse(e['fecha_fin'] as String) : null,
      horaFin:                 _parseHora(e['hora_fin'] as String?),
      usarTags:                resultado.tagsPrincipalesIds.isNotEmpty || resultado.tagsSecundariosIds.isNotEmpty,
      permiteManualAdmin:      bools.permiteManualAdmin,
      permiteQrEvento:         bools.permiteQrEvento,
      permiteQrUsuario:        bools.permiteQrUsuario,
      permiteForaneos:         bools.permiteForaneos,
      requiereCicloCompleto:   bools.requiereCicloCompleto,
      permiteSalidaAnticipada: bools.permiteSalidaAnticipada,
      marcarAusentesAuto:      bools.marcarAusentesAuto,
    );
  }

  TipoEvento? _resolverTipoEvento(String? tipoId, List<TipoEvento> tipos) {
    if (tipoId == null) return null;
    return tipos.cast<TipoEvento?>().firstWhere(
      (t) => t?.id == tipoId, orElse: () => null,
    );
  }

  ({
    bool permiteManualAdmin,
    bool permiteQrEvento,
    bool permiteQrUsuario,
    bool permiteForaneos,
    bool requiereCicloCompleto,
    bool permiteSalidaAnticipada,
    bool marcarAusentesAuto,
  }) _boolsDesdeEvento(Map<String, dynamic> e) => (
    permiteManualAdmin:      e['permite_manual_admin']      as bool? ?? true,
    permiteQrEvento:         e['permite_qr_evento']         as bool? ?? true,
    permiteQrUsuario:        e['permite_qr_usuario']        as bool? ?? true,
    permiteForaneos:         e['permite_foraneos']          as bool? ?? false,
    requiereCicloCompleto:   e['requiere_ciclo_completo']   as bool? ?? false,
    permiteSalidaAnticipada: e['permite_salida_anticipada'] as bool? ?? false,
    marcarAusentesAuto:      e['marcar_ausentes_auto']      as bool? ?? false,
  );

  void actualizarCampo(
    CrearEventoCargado Function(CrearEventoCargado) actualizar,
  ) {
    final estadoActual = state;
    if (estadoActual is! CrearEventoCargado) return;
    emit(actualizar(estadoActual));
  }

  Future<void> publicarEvento() async =>
      _guardar(estatus: EstatusEvento.programado);

  Future<void> guardarBorrador() async =>
      _guardar(estatus: EstatusEvento.borrador);

  Future<void> _guardar({required String estatus}) async {
    final estadoActual = state;
    if (estadoActual is! CrearEventoCargado) return;
    emit(estadoActual.copiarCon(estaGuardando: true));
    try {
      final datos    = _construirDatos(estadoActual, estatus);
      final editando = estadoActual.eventoId != null;
      final eventoId = editando
          ? estadoActual.eventoId!
          : await _repositorio.crearEvento(datos: datos);
      if (editando) {
        await _repositorio.actualizarEvento(id: eventoId, datos: datos);
      }
      final tagIds = estadoActual.usarTags
          ? [...estadoActual.tagsPrincipalesIds, ...estadoActual.tagsSecundariosIds]
          : <String>[];
      await _persistirTags(eventoId: eventoId, editando: editando, tagIds: tagIds);
      emit(CrearEventoGuardado(eventoId: eventoId));
    } on FallaServidor catch (e) {
      emit(CrearEventoError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(CrearEventoError(mensaje: e.mensaje));
    }
  }

  Future<void> _persistirTags({
    required String       eventoId,
    required bool         editando,
    required List<String> tagIds,
  }) async {
    if (editando) {
      await _repositorio.actualizarTagsEvento(eventoId: eventoId, tagIds: tagIds);
    } else if (tagIds.isNotEmpty) {
      await _repositorio.guardarTagsEvento(eventoId: eventoId, tagIds: tagIds);
    }
  }

  Map<String, dynamic> _construirDatos(
    CrearEventoCargado estado,
    String estatus,
  ) {
    return {
      'titulo':                    estado.titulo,
      'descripcion':               estado.descripcion,
      'tipo_evento_id':            estado.tipoEventoSeleccionado?.id,
      'lugar':                     estado.lugar,
      'fecha_inicio':              _formatearFecha(estado.fechaInicio),
      'hora_inicio':               _formatearHora(estado.horaInicio),
      'fecha_fin':                 estado.tieneFechaFin ? _formatearFecha(estado.fechaFin) : null,
      'hora_fin':                  estado.tieneFechaFin ? _formatearHora(estado.horaFin) : null,
      'permite_manual_admin':      estado.permiteManualAdmin,
      'permite_qr_evento':         estado.permiteQrEvento,
      'permite_qr_usuario':        estado.permiteQrUsuario,
      'permite_foraneos':          estado.permiteForaneos,
      'requiere_ciclo_completo':   estado.requiereCicloCompleto,
      'permite_salida_anticipada': estado.permiteSalidaAnticipada,
      'marcar_ausentes_auto':      estado.marcarAusentesAuto,
      'estatus':                   estatus,
    };
  }

  String? _formatearFecha(DateTime? fecha) {
    if (fecha == null) return null;
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$m-$d';
  }

  String? _formatearHora(TimeOfDay? hora) {
    if (hora == null) return null;
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay? _parseHora(String? hora) {
    if (hora == null) return null;
    final partes = hora.split(':');
    if (partes.length < 2) return null;
    return TimeOfDay(
      hour:   int.tryParse(partes[0]) ?? 0,
      minute: int.tryParse(partes[1]) ?? 0,
    );
  }
}
