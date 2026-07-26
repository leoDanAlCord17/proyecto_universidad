import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:activiti/funcionalidades/autenticacion/auth_cubit.dart';
import 'package:activiti/funcionalidades/autenticacion/auth_estado.dart';

class ProtectorPorPermiso extends StatelessWidget {
  const ProtectorPorPermiso({
    super.key,
    required this.permisoRequerido,
    required this.hijo,
    this.reemplazo,
  });

  /// El permiso específico que se necesita (ej: 'usuarios.crear', 'eventos.borrar')
  final String permisoRequerido;

  /// El widget que se mostrará si el usuario tiene el permiso
  final Widget hijo;

  /// Lo que se muestra si NO tiene el permiso (opcional)
  final Widget? reemplazo;

  @override
  Widget build(BuildContext context) {
    final estadoAuth = context.watch<AuthCubit>().state;

    if (estadoAuth is Autenticado) {
      final tienePermiso = estadoAuth.usuario.tienePermiso(permisoRequerido);
      if (tienePermiso) return hijo;
    }

    return reemplazo ?? const SizedBox.shrink();
  }
}
