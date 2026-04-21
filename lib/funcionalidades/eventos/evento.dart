import 'package:equatable/equatable.dart';

class Evento extends Equatable {
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
    this.descripcion,
    this.lugar,
    this.tipoEventoId,
    this.fechaInicio,
    this.fechaFin,
    this.horaInicio,
    this.horaFin,
    this.creadoPor,
  });

  final String    id;
  final String    titulo;
  final String?   descripcion;
  final String?   lugar;
  final String?   tipoEventoId;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String?   horaInicio;
  final String?   horaFin;
  final String    modoRegistro;
  final String    estatus;
  final String?   creadoPor;
  final DateTime  creadoEn;
  final DateTime  actualizadoEn;
  final bool      permiteQrEvento;
  final bool      permiteQrUsuario;
  final bool      permiteManualAdmin;
  final bool      requiereCicloCompleto;
  final bool      permiteSalidaAnticipada;
  final bool      marcarAusentesAuto;
  final bool      permiteForaneos;

  factory Evento.desdeJson(Map<String, dynamic> json) => Evento(
        id:                      json['id']                         as String,
        titulo:                  json['titulo']                     as String,
        descripcion:             json['descripcion']                as String?,
        lugar:                   json['lugar']                      as String?,
        tipoEventoId:            json['tipo_evento_id']             as String?,
        fechaInicio:             json['fecha_inicio'] != null
            ? DateTime.parse(json['fecha_inicio'] as String)
            : null,
        fechaFin:                json['fecha_fin'] != null
            ? DateTime.parse(json['fecha_fin'] as String)
            : null,
        horaInicio:              json['hora_inicio']                as String?,
        horaFin:                 json['hora_fin']                   as String?,
        modoRegistro:            json['modo_registro']              as String,
        estatus:                 json['estatus']                    as String,
        creadoPor:               json['creado_por']                 as String?,
        creadoEn:                DateTime.parse(json['creado_en']   as String),
        actualizadoEn:           DateTime.parse(json['actualizado_en'] as String),
        permiteQrEvento:         (json['permite_qr_evento']        as bool?) ?? true,
        permiteQrUsuario:        (json['permite_qr_usuario']       as bool?) ?? true,
        permiteManualAdmin:      (json['permite_manual_admin']     as bool?) ?? true,
        requiereCicloCompleto:   (json['requiere_ciclo_completo']  as bool?) ?? false,
        permiteSalidaAnticipada: (json['permite_salida_anticipada'] as bool?) ?? false,
        marcarAusentesAuto:      (json['marcar_ausentes_auto']     as bool?) ?? false,
        permiteForaneos:         (json['permite_foraneos']         as bool?) ?? false,
      );

  Map<String, dynamic> aJson() => {
        'titulo':                    titulo,
        'descripcion':               descripcion,
        'lugar':                     lugar,
        'tipo_evento_id':            tipoEventoId,
        'fecha_inicio':              _formatearFecha(fechaInicio),
        'fecha_fin':                 _formatearFecha(fechaFin),
        'hora_inicio':               horaInicio,
        'hora_fin':                  horaFin,
        'modo_registro':             modoRegistro,
        'estatus':                   estatus,
        'permite_qr_evento':         permiteQrEvento,
        'permite_qr_usuario':        permiteQrUsuario,
        'permite_manual_admin':      permiteManualAdmin,
        'requiere_ciclo_completo':   requiereCicloCompleto,
        'permite_salida_anticipada': permiteSalidaAnticipada,
        'marcar_ausentes_auto':      marcarAusentesAuto,
        'permite_foraneos':          permiteForaneos,
      };

  static String? _formatearFecha(DateTime? fecha) {
    if (fecha == null) return null;
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$m-$d';
  }

  @override
  List<Object?> get props => [
        id, titulo, descripcion, lugar, tipoEventoId,
        fechaInicio, fechaFin, horaInicio, horaFin,
        modoRegistro, estatus, creadoPor, creadoEn, actualizadoEn,
        permiteQrEvento, permiteQrUsuario, permiteManualAdmin,
        requiereCicloCompleto, permiteSalidaAnticipada,
        marcarAusentesAuto, permiteForaneos,
      ];
}
