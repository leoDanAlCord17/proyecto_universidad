import 'package:equatable/equatable.dart';

import 'permiso_opcion.dart';

sealed class CrearRolEstado extends Equatable {
  const CrearRolEstado();
}

final class CrearRolInicial extends CrearRolEstado {
  const CrearRolInicial();
  @override
  List<Object?> get props => [];
}

final class CrearRolCargando extends CrearRolEstado {
  const CrearRolCargando();
  @override
  List<Object?> get props => [];
}

final class CrearRolCargado extends CrearRolEstado {
  const CrearRolCargado({
    required this.permisos,
    required this.permisosVisibles,
    this.rolId,
    this.nombreInicial            = '',
    this.descripcionInicial       = '',
    this.permisosSeleccionadosIds = const [],
    this.permisosIniciales        = const [],
    this.estaGuardando            = false,
  });

  final List<PermisoOpcion> permisos;
  final List<PermisoOpcion> permisosVisibles;
  final String?             rolId;
  final String              nombreInicial;
  final String              descripcionInicial;
  final List<String>        permisosSeleccionadosIds;
  final List<String>        permisosIniciales;
  final bool                estaGuardando;

  CrearRolCargado copiarCon({
    List<PermisoOpcion>? permisosVisibles,
    List<String>?        permisosSeleccionadosIds,
    bool?                estaGuardando,
  }) => CrearRolCargado(
    permisos:                 permisos,
    permisosVisibles:         permisosVisibles         ?? this.permisosVisibles,
    rolId:                    rolId,
    nombreInicial:            nombreInicial,
    descripcionInicial:       descripcionInicial,
    permisosSeleccionadosIds: permisosSeleccionadosIds ?? this.permisosSeleccionadosIds,
    permisosIniciales:        permisosIniciales,
    estaGuardando:            estaGuardando            ?? this.estaGuardando,
  );

  @override
  List<Object?> get props => [
    permisos, permisosVisibles, rolId,
    nombreInicial, descripcionInicial,
    permisosSeleccionadosIds, permisosIniciales, estaGuardando,
  ];
}

final class CrearRolGuardado extends CrearRolEstado {
  const CrearRolGuardado();
  @override
  List<Object?> get props => [];
}

final class CrearRolError extends CrearRolEstado {
  const CrearRolError({required this.mensaje});
  final String mensaje;
  @override
  List<Object?> get props => [mensaje];
}
