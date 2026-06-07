class Permiso {
  factory Permiso.desdeJson(Map<String, dynamic> json) => Permiso(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String? ?? '',
      );
  const Permiso({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  final String id;
  final String nombre;
  final String descripcion;
}
