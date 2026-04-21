import 'package:equatable/equatable.dart';

import 'rol.dart';

sealed class RolesEstado extends Equatable {
  const RolesEstado();
}

final class RolesInicial extends RolesEstado {
  const RolesInicial();
  @override
  List<Object?> get props => [];
}

final class RolesCargando extends RolesEstado {
  const RolesCargando();
  @override
  List<Object?> get props => [];
}

final class RolesCargados extends RolesEstado {
  const RolesCargados({
    required this.roles,
    required this.rolesFiltrados,
  });

  final List<Rol> roles;
  final List<Rol> rolesFiltrados;

  RolesCargados copiarCon({List<Rol>? rolesFiltrados}) => RolesCargados(
    roles:          roles,
    rolesFiltrados: rolesFiltrados ?? this.rolesFiltrados,
  );

  @override
  List<Object?> get props => [roles, rolesFiltrados];
}

final class RolesError extends RolesEstado {
  const RolesError({required this.mensaje});

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
