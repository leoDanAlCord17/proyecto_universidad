import 'package:equatable/equatable.dart';

String _calcularIniciales(String nombre, String apellido) {
  final n = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
  final a = apellido.isNotEmpty ? apellido[0].toUpperCase() : '';
  return '$n$a';
}

class ColaboradorItem extends Equatable {
  factory ColaboradorItem.desdeJson(Map<String, dynamic> json) {
    final primerNombre = json['primer_nombre'] as String? ?? '';
    final primerApellido = json['primer_apellido'] as String? ?? '';
    return ColaboradorItem(
      asignacionId: json['asignacion_id'] as String,
      usuarioId: json['usuario_id'] as String,
      nombre: '$primerNombre $primerApellido'.trim(),
      iniciales: _calcularIniciales(primerNombre, primerApellido),
      urlFoto: json['url_avatar'] as String?,
      numeroIdentificacion: json['numero_identificacion'] as String?,
      asignadoPorNombre: json['asignado_por_nombre'] as String?,
    );
  }
  const ColaboradorItem({
    required this.asignacionId,
    required this.usuarioId,
    required this.nombre,
    required this.iniciales,
    this.urlFoto,
    this.numeroIdentificacion,
    this.asignadoPorNombre,
  });

  final String asignacionId;
  final String usuarioId;
  final String nombre;
  final String iniciales;
  final String? urlFoto;
  final String? numeroIdentificacion;
  final String? asignadoPorNombre;

  @override
  List<Object?> get props => [
        asignacionId,
        usuarioId,
        nombre,
        iniciales,
        urlFoto,
        numeroIdentificacion,
        asignadoPorNombre,
      ];
}

class UsuarioParaAsignar extends Equatable {
  factory UsuarioParaAsignar.desdeJson(Map<String, dynamic> json) {
    final primerNombre = json['primer_nombre'] as String? ?? '';
    final primerApellido = json['primer_apellido'] as String? ?? '';
    return UsuarioParaAsignar(
      id: json['id'] as String,
      nombre: '$primerNombre $primerApellido'.trim(),
      iniciales: _calcularIniciales(primerNombre, primerApellido),
      urlFoto: json['url_avatar'] as String?,
      numeroIdentificacion: json['numero_identificacion'] as String?,
    );
  }
  const UsuarioParaAsignar({
    required this.id,
    required this.nombre,
    required this.iniciales,
    this.urlFoto,
    this.numeroIdentificacion,
  });

  final String id;
  final String nombre;
  final String iniciales;
  final String? urlFoto;
  final String? numeroIdentificacion;

  @override
  List<Object?> get props =>
      [id, nombre, iniciales, urlFoto, numeroIdentificacion];
}
