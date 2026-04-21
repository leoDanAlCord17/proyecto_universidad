class Rol {
  const Rol({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.esSistema,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final bool   esSistema;

  factory Rol.desdeJson(Map<String, dynamic> json) => Rol(
    id:          json['id']          as String,
    nombre:      json['nombre']      as String,
    descripcion: json['descripcion'] as String? ?? '',
    esSistema:   json['es_sistema']  as bool?   ?? false,
  );
}
