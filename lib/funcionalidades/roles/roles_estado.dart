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
    this.conteoUsuarios = const {},
  });

  final List<Rol>        roles;
  final List<Rol>        rolesFiltrados;
  /// Mapa rolId → cantidad de usuarios activos con ese rol asignado.
  final Map<String, int> conteoUsuarios;

  RolesCargados copiarCon({List<Rol>? rolesFiltrados}) => RolesCargados(
    roles:          roles,
    rolesFiltrados: rolesFiltrados ?? this.rolesFiltrados,
    conteoUsuarios: conteoUsuarios,
  );

  @override
  List<Object?> get props => [roles, rolesFiltrados, conteoUsuarios];
}

final class RolesError extends RolesEstado {
  const RolesError({required this.mensaje});

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
