import 'package:equatable/equatable.dart';

class PerfilCompletoUsuario extends Equatable {
  const PerfilCompletoUsuario({
    required this.id,
    required this.primerNombre,
    this.segundoNombre,
    required this.primerApellido,
    this.segundoApellido,
    this.numeroIdentificacion,
    required this.correo,
    this.telefono,
    required this.estatus,
    this.creadoEn,
    this.tagPrincipalNombre,
    this.tagsSecundariosNombres = const [],
  });

  final String        id;
  final String        primerNombre;
  final String?       segundoNombre;
  final String        primerApellido;
  final String?       segundoApellido;
  final String?       numeroIdentificacion;
  final String        correo;
  final String?       telefono;
  final bool          estatus;
  final DateTime?     creadoEn;
  final String?       tagPrincipalNombre;
  final List<String>  tagsSecundariosNombres;

  String get nombreCompleto => '$primerNombre $primerApellido';
  String get iniciales {
    final n = primerNombre.isNotEmpty ? primerNombre[0] : '';
    final a = primerApellido.isNotEmpty ? primerApellido[0] : '';
    return '$n$a'.toUpperCase();
  }

  @override
  List<Object?> get props => [
    id, primerNombre, segundoNombre, primerApellido, segundoApellido,
    numeroIdentificacion, correo, telefono, estatus, creadoEn,
    tagPrincipalNombre, tagsSecundariosNombres,
  ];
}
