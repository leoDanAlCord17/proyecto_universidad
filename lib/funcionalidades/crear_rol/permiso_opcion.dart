import 'package:equatable/equatable.dart';

class PermisoOpcion extends Equatable {
  factory PermisoOpcion.desdeJson(Map<String, dynamic> json) => PermisoOpcion(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String? ?? '',
      );
  const PermisoOpcion({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  final String id;
  final String nombre;
  final String descripcion;

  Map<String, dynamic> aJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
      };

  @override
  List<Object?> get props => [id, nombre, descripcion];
}
