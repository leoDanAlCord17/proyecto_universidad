import 'package:equatable/equatable.dart';

class TagItem extends Equatable {
  factory TagItem.desdeJson(Map<String, dynamic> json) => TagItem(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        tipo: json['tipo'] as String? ?? '',
      );
  const TagItem({
    required this.id,
    required this.nombre,
    required this.tipo,
  });

  final String id;
  final String nombre;
  final String tipo;

  bool get esPrincipal => tipo == 'principal';

  @override
  List<Object?> get props => [id, nombre, tipo];
}
