class PermisoOpcion {
  const PermisoOpcion({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  final String id;
  final String nombre;
  final String descripcion;

  factory PermisoOpcion.desdeJson(Map<String, dynamic> json) => PermisoOpcion(
    id:          json['id']          as String,
    nombre:      json['nombre']      as String,
    descripcion: json['descripcion'] as String? ?? '',
  );
}
