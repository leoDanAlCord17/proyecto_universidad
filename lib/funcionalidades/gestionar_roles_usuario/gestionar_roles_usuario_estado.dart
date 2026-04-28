import 'package:equatable/equatable.dart';

import 'rol_item.dart';

sealed class GestionarRolesUsuarioEstado extends Equatable {
  const GestionarRolesUsuarioEstado();
}

final class GestionarRolesUsuarioInicial extends GestionarRolesUsuarioEstado {
  const GestionarRolesUsuarioInicial();
  @override
  List<Object?> get props => [];
}

final class GestionarRolesUsuarioCargando extends GestionarRolesUsuarioEstado {
  const GestionarRolesUsuarioCargando();
  @override
  List<Object?> get props => [];
}

final class GestionarRolesUsuarioCargado extends GestionarRolesUsuarioEstado {
  const GestionarRolesUsuarioCargado({
    required this.nombreUsuario,
    required this.correoUsuario,
    required this.rolesActivos,
    required this.rolesDisponibles,
  });

  final String       nombreUsuario;
  final String       correoUsuario;
  final List<RolItem> rolesActivos;
  final List<RolItem> rolesDisponibles;

  @override
  List<Object?> get props => [nombreUsuario, correoUsuario, rolesActivos, rolesDisponibles];
}

final class GestionarRolesUsuarioError extends GestionarRolesUsuarioEstado {
  const GestionarRolesUsuarioError({required this.mensaje});
  final String mensaje;
  @override
  List<Object?> get props => [mensaje];
}

final class GestionarRolesUsuarioOperacionFallida extends GestionarRolesUsuarioEstado {
  const GestionarRolesUsuarioOperacionFallida({
    required this.anterior,
    required this.mensaje,
  });
  final GestionarRolesUsuarioCargado anterior;
  final String                       mensaje;
  @override
  List<Object?> get props => [anterior, mensaje];
}
