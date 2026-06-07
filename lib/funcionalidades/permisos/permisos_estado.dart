import 'package:equatable/equatable.dart';

import 'permiso.dart';

sealed class PermisosEstado extends Equatable {
  const PermisosEstado();
}

final class PermisosInicial extends PermisosEstado {
  const PermisosInicial();
  @override
  List<Object?> get props => [];
}

final class PermisosCargando extends PermisosEstado {
  const PermisosCargando();
  @override
  List<Object?> get props => [];
}

final class PermisosCargados extends PermisosEstado {
  const PermisosCargados({
    required this.permisos,
    required this.permisosFiltrados,
  });

  final List<Permiso> permisos;
  final List<Permiso> permisosFiltrados;

  PermisosCargados copiarCon({List<Permiso>? permisosFiltrados}) =>
      PermisosCargados(
        permisos: permisos,
        permisosFiltrados: permisosFiltrados ?? this.permisosFiltrados,
      );

  @override
  List<Object?> get props => [permisos, permisosFiltrados];
}

final class PermisosError extends PermisosEstado {
  const PermisosError({required this.mensaje});

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
