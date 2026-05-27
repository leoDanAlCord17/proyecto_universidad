import 'package:equatable/equatable.dart';

class TagOpcion extends Equatable { // 'principal' | 'secundario'

  factory TagOpcion.desdeJson(Map<String, dynamic> json) => TagOpcion(
    id:     json['id']     as String,
    nombre: json['nombre'] as String,
    tipo:   json['tipo']   as String,
  );
  const TagOpcion({
    required this.id,
    required this.nombre,
    required this.tipo,
  });

  final String id;
  final String nombre;
  final String tipo;

  @override
  List<Object?> get props => [id, nombre, tipo];
}
