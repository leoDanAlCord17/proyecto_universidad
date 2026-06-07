import 'package:equatable/equatable.dart';

class Tag extends Equatable {
  factory Tag.desdeJson(Map<String, dynamic> json) {
    final activo = json['estatus'] as bool;
    final conteo =
        (json['usuarios_tags'] as List?)?.cast<Map<String, dynamic>>();
    return Tag(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String,
      estatus: activo,
      descripcion: json['descripcion'] as String? ?? '',
      totalUsuarios: activo && conteo?.isNotEmpty == true
          ? (conteo![0]['count'] as int? ?? 0)
          : 0,
    );
  }
  const Tag({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.estatus,
    required this.descripcion,
    required this.totalUsuarios,
  });

  final String id;
  final String nombre;
  final String tipo;
  final bool estatus;
  final String descripcion;
  final int totalUsuarios;

  bool get esPrincipal => tipo == 'principal';

  Map<String, dynamic> aJson() => {
        'id': id,
        'nombre': nombre,
        'tipo': tipo,
        'estatus': estatus,
        'descripcion': descripcion,
      };

  @override
  List<Object?> get props =>
      [id, nombre, tipo, estatus, descripcion, totalUsuarios];
}
