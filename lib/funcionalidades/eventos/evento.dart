import 'package:equatable/equatable.dart';

import '../../compartido/constantes.dart';

class Evento extends Equatable {
  factory Evento.desdeJson(Map<String, dynamic> json) => Evento(
        id: json['id'] as String,
        titulo: json['titulo'] as String,
        alcance: json['alcance'] as String? ?? AlcanceEvento.general,
        descripcion: json['descripcion'] as String?,
        lugar: json['lugar'] as String?,
        tipoEventoId: json['tipo_evento_id'] as String?,
        fechaInicio: json['fecha_inicio'] != null
            ? DateTime.parse(json['fecha_inicio'] as String)
            : null,
        fechaFin: json['fecha_fin'] != null
            ? DateTime.parse(json['fecha_fin'] as String)
            : null,
        horaInicio: json['hora_inicio'] as String?,
        horaFin: json['hora_fin'] as String?,
        modoRegistro: json['modo_registro'] as String,
        estatus: json['estatus'] as String,
        creadoPor: json['creado_por'] as String?,
        creadoEn: DateTime.parse(json['creado_en'] as String),
        actualizadoEn: DateTime.parse(json['actualizado_en'] as String),
        permiteQrEvento: (json['permite_qr_evento'] as bool?) ?? true,
        permiteQrUsuario: (json['permite_qr_usuario'] as bool?) ?? true,
        permiteManualAdmin: (json['permite_manual_admin'] as bool?) ?? true,
        requiereCicloCompleto:
            (json['requiere_ciclo_completo'] as bool?) ?? false,
        permiteSalidaAnticipada:
            (json['permite_salida_anticipada'] as bool?) ?? false,
        marcarAusentesAuto: (json['marcar_ausentes_auto'] as bool?) ?? false,
        permiteForaneos: (json['permite_foraneos'] as bool?) ?? false,
      );
  const Evento({
    required this.id,
    required this.titulo,
    required this.modoRegistro,
    required this.estatus,
    required this.creadoEn,
    required this.actualizadoEn,
    required this.permiteQrEvento,
    required this.permiteQrUsuario,
    required this.permiteManualAdmin,
    required this.requiereCicloCompleto,
    required this.permiteSalidaAnticipada,
    required this.marcarAusentesAuto,
    required this.permiteForaneos,
    this.alcance = AlcanceEvento.general,
    this.descripcion,
    this.lugar,
    this.tipoEventoId,
    this.fechaInicio,
    this.fechaFin,
    this.horaInicio,
    this.horaFin,
    this.creadoPor,
  });

  final String id;
  final String titulo;
  final String alcance;
  final String? descripcion;
  final String? lugar;
  final String? tipoEventoId;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? horaInicio;
  final String? horaFin;
  final String modoRegistro;
  final String estatus;
  final String? creadoPor;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  final bool permiteQrEvento;
  final bool permiteQrUsuario;
  final bool permiteManualAdmin;
  final bool requiereCicloCompleto;
  final bool permiteSalidaAnticipada;
  final bool marcarAusentesAuto;
  final bool permiteForaneos;

  /// Serialización para enviar a Supabase en operaciones de escritura.
  /// No incluye `id` ni timestamps gestionados por el servidor.
  Map<String, dynamic> aJson() => {
        'titulo': titulo,
        'alcance': alcance,
        'descripcion': descripcion,
        'lugar': lugar,
        'tipo_evento_id': tipoEventoId,
        'fecha_inicio': _formatearFecha(fechaInicio),
        'fecha_fin': _formatearFecha(fechaFin),
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        'modo_registro': modoRegistro,
        'estatus': estatus,
        'permite_qr_evento': permiteQrEvento,
        'permite_qr_usuario': permiteQrUsuario,
        'permite_manual_admin': permiteManualAdmin,
        'requiere_ciclo_completo': requiereCicloCompleto,
        'permite_salida_anticipada': permiteSalidaAnticipada,
        'marcar_ausentes_auto': marcarAusentesAuto,
        'permite_foraneos': permiteForaneos,
      };

  /// Serialización completa para caché local: incluye todos los campos
  /// necesarios para reconstruir el objeto con `Evento.desdeJson()`.
  Map<String, dynamic> aJsonCompleto() => {
        ...aJson(),
        'id': id,
        'creado_por': creadoPor,
        'creado_en': creadoEn.toUtc().toIso8601String(),
        'actualizado_en': actualizadoEn.toUtc().toIso8601String(),
      };

  static String? _formatearFecha(DateTime? fecha) {
    if (fecha == null) return null;
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$m-$d';
  }

  @override
  List<Object?> get props => [
        id,
        titulo,
        alcance,
        descripcion,
        lugar,
        tipoEventoId,
        fechaInicio,
        fechaFin,
        horaInicio,
        horaFin,
        modoRegistro,
        estatus,
        creadoPor,
        creadoEn,
        actualizadoEn,
        permiteQrEvento,
        permiteQrUsuario,
        permiteManualAdmin,
        requiereCicloCompleto,
        permiteSalidaAnticipada,
        marcarAusentesAuto,
        permiteForaneos,
      ];
}

// ─── Grupo de audiencia (para lógica de visibilidad) ─────────────────────────

class GrupoEvento extends Equatable {
  const GrupoEvento({
    required this.grupoIndex,
    required this.tagPrincipalId,
    this.tagsSecundariosIds = const [],
    this.nombresParaBusqueda = const [],
  });

  final int grupoIndex;
  final String tagPrincipalId;
  final List<String> tagsSecundariosIds;
  final List<String> nombresParaBusqueda;

  @override
  List<Object?> get props => [grupoIndex, tagPrincipalId, tagsSecundariosIds];
}

// ─── Evento con sus grupos de audiencia ──────────────────────────────────────

class EventoConGrupos extends Equatable {
  factory EventoConGrupos.desdeJson(Map<String, dynamic> json) {
    final filas = json['evento_grupos_tags'] as List? ?? [];
    final grupos = _construirGrupos(filas);
    return EventoConGrupos(evento: Evento.desdeJson(json), grupos: grupos);
  }
  const EventoConGrupos({
    required this.evento,
    required this.grupos,
    this.totalPresentes,
  });

  final Evento evento;
  final List<GrupoEvento> grupos;

  /// Cantidad de asistentes actualmente presentes (solo en curso).
  final int? totalPresentes;

  EventoConGrupos copiarConPresentes(int total) => EventoConGrupos(
        evento: evento,
        grupos: grupos,
        totalPresentes: total,
      );

  bool get esGeneral => evento.alcance == AlcanceEvento.general;

  List<String> get nombresParaBusqueda =>
      grupos.expand((g) => g.nombresParaBusqueda).toList();

  static List<GrupoEvento> _construirGrupos(List<dynamic> filas) {
    final Map<int, String> principalesId = {};
    final Map<int, List<String>> secundariosIds = {};
    final Map<int, List<String>> nombresPorGrupo = {};

    for (final fila in filas.cast<Map<String, dynamic>>()) {
      final grupoIndex = fila['grupo_index'] as int;
      final tagId = fila['tag_id'] as String;
      final tagData = fila['tags'] as Map<String, dynamic>?;
      final tipo = tagData?['tipo'] as String?;
      final nombre = tagData?['nombre'] as String?;

      if (tipo == 'principal') {
        principalesId[grupoIndex] = tagId;
      } else {
        secundariosIds.putIfAbsent(grupoIndex, () => []).add(tagId);
      }
      if (nombre != null) {
        nombresPorGrupo.putIfAbsent(grupoIndex, () => []).add(nombre);
      }
    }

    return principalesId.entries
        .map(
          (e) => GrupoEvento(
            grupoIndex: e.key,
            tagPrincipalId: e.value,
            tagsSecundariosIds: secundariosIds[e.key] ?? [],
            nombresParaBusqueda: nombresPorGrupo[e.key] ?? [],
          ),
        )
        .toList();
  }

  @override
  List<Object?> get props => [evento, grupos, totalPresentes];
}
