import 'package:equatable/equatable.dart';

class TipoEvento extends Equatable {
  const TipoEvento({required this.id, required this.nombre});

  final String id;
  final String nombre;

  factory TipoEvento.desdeJson(Map<String, dynamic> json) => TipoEvento(
    id:     json['id']     as String,
    nombre: json['nombre'] as String,
  );

  @override
  List<Object?> get props => [id, nombre];
}
