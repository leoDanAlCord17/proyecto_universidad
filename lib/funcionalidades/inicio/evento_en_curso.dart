import 'package:equatable/equatable.dart';

import '../../compartido/constantes.dart';

class EventoEnCurso extends Equatable {
  factory EventoEnCurso.desdeJson(Map<String, dynamic> json) => EventoEnCurso(
        id: json['id'] as String,
        titulo: json['titulo'] as String,
        lugar: json['lugar'] as String?,
        horaInicio: json['hora_inicio'] as String?,
        horaFin: json['hora_fin'] as String?,
        permiteQrEvento: (json['permite_qr_evento'] as bool?) ?? true,
        permiteQrUsuario: (json['permite_qr_usuario'] as bool?) ?? true,
        permiteForaneos: (json['permite_foraneos'] as bool?) ?? false,
        modoRegistro:
            json['modo_registro'] as String? ?? ModoRegistro.administrador,
        alcance: json['alcance'] as String? ?? AlcanceEvento.general,
        totalPresentes: 0,
        totalRegistrados: 0,
      );
  const EventoEnCurso({
    required this.id,
    required this.titulo,
    this.lugar,
    this.horaInicio,
    this.horaFin,
    required this.permiteQrEvento,
    required this.permiteQrUsuario,
    required this.permiteForaneos,
    required this.modoRegistro,
    required this.alcance,
    required this.totalPresentes,
    required this.totalRegistrados,
    this.esColaborador = false,
  });

  final String id;
  final String titulo;
  final String? lugar;
  final String? horaInicio;
  final String? horaFin;
  final bool permiteQrEvento;
  final bool permiteQrUsuario;
  final bool permiteForaneos;
  final String modoRegistro;
  final String alcance;
  final int totalPresentes;
  final int totalRegistrados;
  final bool esColaborador;

  bool get esGeneral => alcance == AlcanceEvento.general;

  bool get esModoAuto => modoRegistro == ModoRegistro.auto;

  double get progreso => totalRegistrados == 0
      ? 0
      : (totalPresentes / totalRegistrados).clamp(0.0, 1.0);

  String get rangoHorario {
    if (horaInicio == null) return '';
    final inicio = _recortarSegundos(horaInicio!);
    final fin = horaFin != null ? ' – ${_recortarSegundos(horaFin!)}' : '';
    return '$inicio$fin';
  }

  static String _recortarSegundos(String hora) {
    final partes = hora.split(':');
    return partes.length >= 2 ? '${partes[0]}:${partes[1]}' : hora;
  }

  EventoEnCurso copyWith({
    int? totalPresentes,
    int? totalRegistrados,
    bool? esColaborador,
  }) =>
      EventoEnCurso(
        id: id,
        titulo: titulo,
        lugar: lugar,
        horaInicio: horaInicio,
        horaFin: horaFin,
        permiteQrEvento: permiteQrEvento,
        permiteQrUsuario: permiteQrUsuario,
        permiteForaneos: permiteForaneos,
        modoRegistro: modoRegistro,
        alcance: alcance,
        totalPresentes: totalPresentes ?? this.totalPresentes,
        totalRegistrados: totalRegistrados ?? this.totalRegistrados,
        esColaborador: esColaborador ?? this.esColaborador,
      );

  @override
  List<Object?> get props => [
        id,
        titulo,
        lugar,
        horaInicio,
        horaFin,
        permiteQrEvento,
        permiteQrUsuario,
        permiteForaneos,
        modoRegistro,
        alcance,
        totalPresentes,
        totalRegistrados,
        esColaborador,
      ];
}
