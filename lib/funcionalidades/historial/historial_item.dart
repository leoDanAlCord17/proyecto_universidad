import 'package:equatable/equatable.dart';

import '../../compartido/constantes.dart';

class HistorialItem extends Equatable {
  factory HistorialItem.desdeJson(Map<String, dynamic> json) {
    final e = json['eventos'] as Map<String, dynamic>? ?? {};
    return HistorialItem(
      id: json['id'] as String,
      eventoId: json['evento_id'] as String,
      eventoTitulo: e['titulo'] as String? ?? 'Evento sin título',
      eventoLugar: e['lugar'] as String?,
      eventoFechaInicio: e['fecha_inicio'] != null
          ? DateTime.tryParse(e['fecha_inicio'] as String)
          : null,
      estatus: json['estatus'] as String? ?? EstatusAsistencia.ausente,
      horaEntrada: _parsearHora(json['hora_entrada'] as String?),
      horaSalida: _parsearHora(json['hora_salida'] as String?),
    );
  }
  const HistorialItem({
    required this.id,
    required this.eventoId,
    required this.eventoTitulo,
    required this.estatus,
    this.eventoLugar,
    this.eventoFechaInicio,
    this.horaEntrada,
    this.horaSalida,
  });

  final String id;
  final String eventoId;
  final String eventoTitulo;
  final String? eventoLugar;
  final DateTime? eventoFechaInicio;
  final String estatus;
  final String? horaEntrada;
  final String? horaSalida;

  bool get esAsistido =>
      estatus == EstatusAsistencia.presente ||
      estatus == EstatusAsistencia.completado;

  bool get esSalidaAnticipada => estatus == EstatusAsistencia.salioAnticipado;
  bool get esAusente => estatus == EstatusAsistencia.ausente;

  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  String get etiquetaFecha {
    if (eventoFechaInicio == null) return '';
    final d = eventoFechaInicio!;
    return '${d.day} ${_meses[d.month - 1]} ${d.year}';
  }

  static String? _parsearHora(String? isoString) {
    if (isoString == null) return null;
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return null;
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h12:$min $ampm';
  }

  @override
  List<Object?> get props => [id, eventoId, estatus];
}
