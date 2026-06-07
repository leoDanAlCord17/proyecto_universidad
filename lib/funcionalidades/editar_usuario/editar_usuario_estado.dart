import 'package:equatable/equatable.dart';

sealed class EditarUsuarioEstado extends Equatable {
  const EditarUsuarioEstado();
}

final class EditarUsuarioInicial extends EditarUsuarioEstado {
  const EditarUsuarioInicial();
  @override
  List<Object?> get props => [];
}

final class EditarUsuarioCargando extends EditarUsuarioEstado {
  const EditarUsuarioCargando();
  @override
  List<Object?> get props => [];
}

final class EditarUsuarioCargado extends EditarUsuarioEstado {
  const EditarUsuarioCargado({
    required this.usuarioId,
    required this.primerNombreInicial,
    required this.primerApellidoInicial,
    this.segundoNombreInicial,
    this.segundoApellidoInicial,
    this.numeroIdentificacionInicial,
    required this.correoInicial,
    this.telefonoInicial,
    this.estaGuardando = false,
    this.errorValidacion = '',
  });

  final String usuarioId;
  final String primerNombreInicial;
  final String primerApellidoInicial;
  final String? segundoNombreInicial;
  final String? segundoApellidoInicial;
  final String? numeroIdentificacionInicial;
  final String correoInicial;
  final String? telefonoInicial;
  final bool estaGuardando;
  final String errorValidacion;

  EditarUsuarioCargado copiarCon({
    bool? estaGuardando,
    String? errorValidacion,
  }) =>
      EditarUsuarioCargado(
        usuarioId: usuarioId,
        primerNombreInicial: primerNombreInicial,
        primerApellidoInicial: primerApellidoInicial,
        segundoNombreInicial: segundoNombreInicial,
        segundoApellidoInicial: segundoApellidoInicial,
        numeroIdentificacionInicial: numeroIdentificacionInicial,
        correoInicial: correoInicial,
        telefonoInicial: telefonoInicial,
        estaGuardando: estaGuardando ?? this.estaGuardando,
        errorValidacion: errorValidacion ?? this.errorValidacion,
      );

  @override
  List<Object?> get props => [
        usuarioId,
        primerNombreInicial,
        primerApellidoInicial,
        segundoNombreInicial,
        segundoApellidoInicial,
        numeroIdentificacionInicial,
        correoInicial,
        telefonoInicial,
        estaGuardando,
        errorValidacion,
      ];
}

final class EditarUsuarioGuardado extends EditarUsuarioEstado {
  const EditarUsuarioGuardado();
  @override
  List<Object?> get props => [];
}

final class EditarUsuarioError extends EditarUsuarioEstado {
  const EditarUsuarioError({required this.mensaje});

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
