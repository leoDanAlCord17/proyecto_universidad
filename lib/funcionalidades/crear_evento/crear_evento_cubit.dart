import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'crear_evento_estado.dart';
import 'crear_evento_repositorio.dart';
import 'grupo_audiencia.dart';
import 'tag_opcion.dart';
import 'tipo_evento.dart';

class CrearEventoCubit extends Cubit<CrearEventoEstado> {
  CrearEventoCubit(this._repositorio) : super(const CrearEventoInicial());

  final CrearEventoRepositorio _repositorio;

  Future<void> cargarOpciones() async {
    emit(const CrearEventoCargando());
    try {
      final tiposEvento = await _repositorio.obtenerTiposEvento();
      final tags = await _repositorio.obtenerTags();
      final maxTagsSecundarios = await _repositorio.obtenerMaxTagsSecundarios();
      emit(
        CrearEventoCargado(
          tiposEvento: tiposEvento,
          tagsPrincipales: tags.where((t) => t.tipo == 'principal').toList(),
          tagsSecundarios: tags.where((t) => t.tipo == 'secundario').toList(),
          maxTagsSecundarios: maxTagsSecundarios,
        ),
      );
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(CrearEventoError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(CrearEventoError(mensaje: e.mensaje));
    }
  }

  Future<void> cargarEventoParaEditar(String eventoId) async {
    emit(const CrearEventoCargando());
    try {
      final tiposEvento = await _repositorio.obtenerTiposEvento();
      final tags = await _repositorio.obtenerTags();
      final maxTagsSecundarios = await _repositorio.obtenerMaxTagsSecundarios();
      final evento = await _repositorio.obtenerEvento(eventoId);
      final grupos = await _repositorio.obtenerGruposEvento(eventoId);
      emit(_estadoDesdeEvento(
          eventoId, tiposEvento, tags, maxTagsSecundarios, evento, grupos));
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(CrearEventoError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(CrearEventoError(mensaje: e.mensaje));
    }
  }

  CrearEventoCargado _estadoDesdeEvento(
    String eventoId,
    List<TipoEvento> tiposEvento,
    List<TagOpcion> tags,
    int maxTagsSecundarios,
    Map<String, dynamic> e,
    List<GrupoAudiencia> grupos,
  ) {
    final tipo =
        _resolverTipoEvento(e['tipo_evento_id'] as String?, tiposEvento);
    final bools = _boolsDesdeEvento(e);
    return CrearEventoCargado(
      eventoId: eventoId,
      tiposEvento: tiposEvento,
      tagsPrincipales: tags.where((t) => t.tipo == 'principal').toList(),
      tagsSecundarios: tags.where((t) => t.tipo == 'secundario').toList(),
      maxTagsSecundarios: maxTagsSecundarios,
      tipoEventoSeleccionado: tipo,
      alcance: e['alcance'] as String? ?? AlcanceEvento.general,
      grupos: grupos,
      titulo: e['titulo'] as String? ?? '',
      descripcion: e['descripcion'] as String? ?? '',
      lugar: e['lugar'] as String? ?? '',
      fechaInicio: e['fecha_inicio'] != null
          ? DateTime.tryParse(e['fecha_inicio'] as String)
          : null,
      horaInicio: _parseHora(e['hora_inicio'] as String?),
      tieneFechaFin: true,
      fechaFin: e['fecha_fin'] != null
          ? DateTime.tryParse(e['fecha_fin'] as String)
          : null,
      horaFin: _parseHora(e['hora_fin'] as String?),
      permiteManualAdmin: bools.permiteManualAdmin,
      permiteQrEvento: bools.permiteQrEvento,
      permiteQrUsuario: bools.permiteQrUsuario,
      permiteForaneos: bools.permiteForaneos,
      requiereCicloCompleto: bools.requiereCicloCompleto,
      permiteSalidaAnticipada: bools.permiteSalidaAnticipada,
      marcarAusentesAuto: bools.marcarAusentesAuto,
    );
  }

  TipoEvento? _resolverTipoEvento(String? tipoId, List<TipoEvento> tipos) {
    if (tipoId == null) return null;
    return tipos.cast<TipoEvento?>().firstWhere(
          (t) => t?.id == tipoId,
          orElse: () => null,
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
        permiteManualAdmin: e['permite_manual_admin'] as bool? ?? true,
        permiteQrEvento: e['permite_qr_evento'] as bool? ?? true,
        permiteQrUsuario: e['permite_qr_usuario'] as bool? ?? true,
        permiteForaneos: e['permite_foraneos'] as bool? ?? false,
        requiereCicloCompleto: e['requiere_ciclo_completo'] as bool? ?? false,
        permiteSalidaAnticipada:
            e['permite_salida_anticipada'] as bool? ?? false,
        marcarAusentesAuto: e['marcar_ausentes_auto'] as bool? ?? false,
      );

  void actualizarCampo(
    CrearEventoCargado Function(CrearEventoCargado) actualizar,
  ) {
    final estadoActual = state;
    if (estadoActual is! CrearEventoCargado) return;
    emit(actualizar(estadoActual).copiarCon(limpiarErrorValidacion: true));
  }

  /// Avanza o retrocede al paso indicado en el wizard.
  /// Valida el paso actual antes de avanzar.
  void irAPaso(int paso) {
    final estadoActual = state;
    if (estadoActual is! CrearEventoCargado) return;
    // Validación al avanzar desde el paso 0: el título es obligatorio.
    if (paso > estadoActual.pasoActual &&
        estadoActual.pasoActual == 0 &&
        estadoActual.titulo.trim().isEmpty) {
      _emitirErrorValidacion('El título del evento es obligatorio.');
      return;
    }
    emit(
      estadoActual.copiarCon(
        pasoActual: paso,
        limpiarErrorValidacion: true,
      ),
    );
  }

  void agregarGrupo(GrupoAudiencia grupo) {
    actualizarCampo((s) => s.copiarCon(grupos: [...s.grupos, grupo]));
  }

  void eliminarGrupo(int grupoIndex) {
    actualizarCampo(
      (s) => s.copiarCon(
        grupos: s.grupos.where((g) => g.grupoIndex != grupoIndex).toList(),
      ),
    );
  }

  Future<void> publicarEvento() async {
    final estadoActual = state;
    if (estadoActual is! CrearEventoCargado) return;
    if (estadoActual.horaFin == null) {
      _emitirErrorValidacion('La hora de cierre es obligatoria para publicar.');
      return;
    }
    await _guardar(estatus: EstatusEvento.programado);
  }

  /// Emite primero un estado sin error y luego uno con el error dado.
  /// Esto garantiza que el listener de BlocConsumer se dispare siempre,
  /// incluso si el mensaje es idéntico al anterior (Equatable lo ignoraría).
  void _emitirErrorValidacion(String mensaje) {
    final s = state;
    if (s is! CrearEventoCargado) return;
    emit(s.copiarCon(limpiarErrorValidacion: true));
    emit((state as CrearEventoCargado).copiarCon(errorValidacion: mensaje));
  }

  Future<void> guardarBorrador() async =>
      _guardar(estatus: EstatusEvento.borrador);

  Future<void> _guardar({required String estatus}) async {
    final estadoActual = state;
    if (estadoActual is! CrearEventoCargado) return;
    emit(estadoActual.copiarCon(estaGuardando: true));
    try {
      final datos = _construirDatos(estadoActual, estatus);
      final editando = estadoActual.eventoId != null;
      final eventoId = editando
          ? estadoActual.eventoId!
          : await _repositorio.crearEvento(datos: datos);
      if (editando) {
        await _repositorio.actualizarEvento(id: eventoId, datos: datos);
      }
      await _persistirGrupos(
        eventoId: eventoId,
        editando: editando,
        alcance: estadoActual.alcance,
        grupos: estadoActual.grupos,
      );
      // N8 — notifica a la audiencia cuando se publica un evento dirigido
      if (estatus == EstatusEvento.programado &&
          estadoActual.alcance == AlcanceEvento.dirigido) {
        try {
          final userIds =
              await _repositorio.obtenerUsuariosIdsDirigidos(eventoId);
          if (userIds.isNotEmpty) {
            await Supabase.instance.client.functions.invoke(
              'enviar-notificacion',
              body: {
                'usuario_ids': userIds,
                'titulo': 'Nuevo evento: ${estadoActual.titulo}',
                'cuerpo': 'Se publicó un nuevo evento al que puedes asistir.',
                'tipo': 'evento',
                'entidad_id': eventoId,
                'entidad_tipo': 'evento',
              },
            );
          }
        } catch (e) {
          log.w('No se pudo enviar notificación N8', error: e);
        }
      }
      emit(
        CrearEventoGuardado(
          eventoId: eventoId,
          esBorrador: estatus == EstatusEvento.borrador,
        ),
      );
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(CrearEventoError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(CrearEventoError(mensaje: e.mensaje));
    }
  }

  Future<void> _persistirGrupos({
    required String eventoId,
    required bool editando,
    required String alcance,
    required List<GrupoAudiencia> grupos,
  }) async {
    if (editando) {
      await _repositorio.actualizarGruposEvento(
          eventoId: eventoId, grupos: grupos);
    } else if (alcance == AlcanceEvento.dirigido && grupos.isNotEmpty) {
      await _repositorio.guardarGruposEvento(
          eventoId: eventoId, grupos: grupos);
    }
  }

  Map<String, dynamic> _construirDatos(
    CrearEventoCargado estado,
    String estatus,
  ) {
    return {
      'titulo': estado.titulo,
      'descripcion': estado.descripcion,
      'tipo_evento_id': estado.tipoEventoSeleccionado?.id,
      'lugar': estado.lugar,
      'fecha_inicio': _formatearFecha(estado.fechaInicio),
      'hora_inicio': _formatearHora(estado.horaInicio),
      'fecha_fin': _formatearFecha(estado.fechaFin),
      'hora_fin': _formatearHora(estado.horaFin),
      'alcance': estado.alcance,
      'permite_manual_admin': estado.permiteManualAdmin,
      'permite_qr_evento': estado.permiteQrEvento,
      'permite_qr_usuario': estado.permiteQrUsuario,
      'permite_foraneos': estado.permiteForaneos,
      'requiere_ciclo_completo': estado.requiereCicloCompleto,
      'permite_salida_anticipada': estado.permiteSalidaAnticipada,
      'marcar_ausentes_auto': estado.marcarAusentesAuto,
      'estatus': estatus,
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
      hour: int.tryParse(partes[0]) ?? 0,
      minute: int.tryParse(partes[1]) ?? 0,
    );
  }
}
