import 'package:equatable/equatable.dart';

class TipoEventoItem extends Equatable {
  const TipoEventoItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.estatus,
    this.creadoEn,
    this.creadoPor,
    this.actualizadoPor,
    this.actualizadoEn,
  });

  final String    id;
  final String    nombre;
  final String    descripcion;
  final bool      estatus;
  final DateTime? creadoEn;
  final String?   creadoPor;
  final String?   actualizadoPor;
  final DateTime? actualizadoEn;

  factory TipoEventoItem.desdeJson(Map<String, dynamic> json) => TipoEventoItem(
    id:             json['id']              as String,
    nombre:         json['nombre']          as String,
    descripcion:    (json['descripcion']    as String?) ?? '',
    estatus:        (json['estatus']        as bool?) ?? false,
    creadoEn:       json['creado_en']       != null ? DateTime.tryParse(json['creado_en'] as String)       : null,
    creadoPor:      json['creado_por']      as String?,
    actualizadoPor: json['actualizado_por'] as String?,
    actualizadoEn:  json['actualizado_en']  != null ? DateTime.tryParse(json['actualizado_en'] as String) : null,
  );

  Map<String, dynamic> aJson() => {
    'nombre':      nombre,
    'descripcion': descripcion,
    'estatus':     estatus,
  };

  @override
  List<Object?> get props => [
    id, nombre, descripcion, estatus,
    creadoEn, creadoPor, actualizadoPor, actualizadoEn,
  ];
}
