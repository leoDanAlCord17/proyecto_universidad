import 'package:equatable/equatable.dart';

String _calcularIniciales(String nombre, String apellido) {
  final n = nombre.isNotEmpty   ? nombre[0].toUpperCase()   : '';
  final a = apellido.isNotEmpty ? apellido[0].toUpperCase() : '';
  return '$n$a';
}

class ColaboradorItem extends Equatable {
  const ColaboradorItem({
    required this.asignacionId,
    required this.usuarioId,
    required this.nombre,
    required this.iniciales,
    this.urlFoto,
    this.numeroIdentificacion,
  });

  final String  asignacionId;
  final String  usuarioId;
  final String  nombre;
  final String  iniciales;
  final String? urlFoto;
  final String? numeroIdentificacion;

  factory ColaboradorItem.desdeJson(Map<String, dynamic> json) {
    final primerNombre   = json['primer_nombre']   as String? ?? '';
    final primerApellido = json['primer_apellido']  as String? ?? '';
    return ColaboradorItem(
      asignacionId:        json['asignacion_id']          as String,
      usuarioId:           json['usuario_id']              as String,
      nombre:              '$primerNombre $primerApellido'.trim(),
      iniciales:           _calcularIniciales(primerNombre, primerApellido),
      urlFoto:             json['url_avatar']              as String?,
      numeroIdentificacion: json['numero_identificacion']  as String?,
    );
  }

  @override
  List<Object?> get props => [
    asignacionId, usuarioId, nombre, iniciales, urlFoto, numeroIdentificacion,
  ];
}

class UsuarioParaAsignar extends Equatable {
  const UsuarioParaAsignar({
    required this.id,
    required this.nombre,
    required this.iniciales,
    this.urlFoto,
    this.numeroIdentificacion,
  });

  final String  id;
  final String  nombre;
  final String  iniciales;
  final String? urlFoto;
  final String? numeroIdentificacion;

  factory UsuarioParaAsignar.desdeJson(Map<String, dynamic> json) {
    final primerNombre   = json['primer_nombre']   as String? ?? '';
    final primerApellido = json['primer_apellido']  as String? ?? '';
    return UsuarioParaAsignar(
      id:                   json['id']                     as String,
      nombre:               '$primerNombre $primerApellido'.trim(),
      iniciales:            _calcularIniciales(primerNombre, primerApellido),
      urlFoto:              json['url_avatar']              as String?,
      numeroIdentificacion: json['numero_identificacion']   as String?,
    );
  }

  @override
  List<Object?> get props => [id, nombre, iniciales, urlFoto, numeroIdentificacion];
}
