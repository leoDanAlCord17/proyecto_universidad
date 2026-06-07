import 'package:equatable/equatable.dart';

class RolItem extends Equatable {
  factory RolItem.desdeJson(Map<String, dynamic> json) => RolItem(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        descripcion: json['descripcion'] as String? ?? '',
      );
  const RolItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  final String id;
  final String nombre;
  final String descripcion;

  @override
  List<Object?> get props => [id, nombre, descripcion];
}
