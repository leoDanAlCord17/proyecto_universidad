import 'package:equatable/equatable.dart';

class RevisionUsuarioItem extends Equatable {
  factory RevisionUsuarioItem.desdeJson(Map<String, dynamic> json) =>
      RevisionUsuarioItem(
        id: json['id'] as String,
        primerNombre: json['primer_nombre'] as String,
        segundoNombre: json['segundo_nombre'] as String?,
        primerApellido: json['primer_apellido'] as String,
        segundoApellido: json['segundo_apellido'] as String?,
        correo: json['correo'] as String,
        numeroIdentificacion: json['numero_identificacion'] as String?,
        telefono: json['telefono'] as String?,
        creadoEn: json['creado_en'] != null
            ? DateTime.tryParse(json['creado_en'] as String)
            : null,
      );
  const RevisionUsuarioItem({
    required this.id,
    required this.primerNombre,
    required this.primerApellido,
    required this.correo,
    this.segundoNombre,
    this.segundoApellido,
    this.numeroIdentificacion,
    this.telefono,
    this.creadoEn,
  });

  final String id;
  final String primerNombre;
  final String? segundoNombre;
  final String primerApellido;
  final String? segundoApellido;
  final String correo;
  final String? numeroIdentificacion;
  final String? telefono;
  final DateTime? creadoEn;

  String get nombreCompleto => [
        primerNombre,
        if (segundoNombre != null && segundoNombre!.isNotEmpty) segundoNombre,
        primerApellido,
        if (segundoApellido != null && segundoApellido!.isNotEmpty)
          segundoApellido,
      ].join(' ');

  @override
  List<Object?> get props => [
        id,
        primerNombre,
        segundoNombre,
        primerApellido,
        segundoApellido,
        correo,
        numeroIdentificacion,
        telefono,
        creadoEn,
      ];
}
