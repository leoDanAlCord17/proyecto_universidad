import 'package:equatable/equatable.dart';

class UsuarioItem extends Equatable {

  factory UsuarioItem.desdeJson(Map<String, dynamic> json) => UsuarioItem(
    id:                   json['id']                    as String,
    primerNombre:         json['primer_nombre']         as String? ?? '',
    primerApellido:       json['primer_apellido']       as String? ?? '',
    correo:               json['correo']                as String? ?? '',
    estatus:              (json['estatus']              as bool?) ?? true,
    numeroIdentificacion: json['numero_identificacion'] as String?,
  );
  const UsuarioItem({
    required this.id,
    required this.primerNombre,
    required this.primerApellido,
    required this.correo,
    required this.estatus,
    this.numeroIdentificacion,
  });

  final String  id;
  final String  primerNombre;
  final String  primerApellido;
  final String  correo;
  final bool    estatus;
  final String? numeroIdentificacion;

  String get nombreCompleto => '$primerNombre $primerApellido';
  String get iniciales {
    final n = primerNombre.isNotEmpty ? primerNombre[0] : '';
    final a = primerApellido.isNotEmpty ? primerApellido[0] : '';
    return '$n$a'.toUpperCase();
  }

  @override
  List<Object?> get props => [
    id, primerNombre, primerApellido, correo, estatus, numeroIdentificacion,
  ];
}
