import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../configuracion/colores_app.dart';
import '../compartido/constantes.dart';
import '../funcionalidades/autenticacion/auth_cubit.dart';
import '../funcionalidades/autenticacion/auth_estado.dart';

import 'rutas/rutas_auth.dart';
import 'rutas/rutas_personal.dart';
import 'rutas/rutas_eventos.dart';
import 'rutas/rutas_ajustes.dart';
import 'rutas/rutas_dev.dart';

class RouterApp {

  RouterApp(this.authCubit);
  final AuthCubit authCubit;

  late final router = GoRouter(
    initialLocation: Rutas.splash,

    // Escucha al AuthCubit para reaccionar a cambios de sesión
    refreshListenable: _StreamToListen(authCubit.stream),

    redirect: (context, state) {
      final estadoAuth = authCubit.state;
      final ubicacion = state.matchedLocation;

      // Verificando sesión al arrancar: mostrar splash hasta que AuthCubit resuelva
      if (estadoAuth is AuthInicial) {
        return ubicacion == Rutas.splash ? null : Rutas.splash;
      }

      // Perfil incompleto: tiene cuenta en Auth pero no terminó el registro.
      if (estadoAuth is PerfilIncompleto) {
        return ubicacion == Rutas.completarPerfil ? null : Rutas.completarPerfil;
      }

      // Cuenta pendiente de aprobación por el administrador.
      if (estadoAuth is PendienteAprobacion) {
        return ubicacion == Rutas.pendienteAprobacion
            ? null
            : Rutas.pendienteAprobacion;
      }

      // Cuenta rechazada por el administrador.
      if (estadoAuth is UsuarioRechazado) {
        return ubicacion == Rutas.usuarioRechazado
            ? null
            : Rutas.usuarioRechazado;
      }

      // Recuperación de contraseña: sesión de recovery activa
      if (estadoAuth is RecuperandoContrasena) {
        return ubicacion == Rutas.nuevaContrasena ? null : Rutas.nuevaContrasena;
      }

      // Sin autenticación: solo puede estar en rutas públicas
      if (estadoAuth is! Autenticado) {
        final esRutaPublica = ubicacion == Rutas.login
            || ubicacion == Rutas.registro
            || ubicacion == Rutas.recuperarContrasena;
        return esRutaPublica ? null : Rutas.login;
      }

      // Autenticado: redirigir fuera de rutas de flujo de auth
      if (ubicacion == Rutas.splash ||
          ubicacion == Rutas.login ||
          ubicacion == Rutas.registro ||
          ubicacion == Rutas.completarPerfil ||
          ubicacion == Rutas.pendienteAprobacion ||
          ubicacion == Rutas.usuarioRechazado ||
          ubicacion == Rutas.recuperarContrasena ||
          ubicacion == Rutas.nuevaContrasena) {
        return Rutas.home;
      }

      // ─── GUARDS DE RUTAS POR PERMISO ────────────────────────────────────
      final u = estadoAuth.usuario;
      final sinPermiso =
          (ubicacion.startsWith('/gestion_usuarios') && !u.tienePermiso(Permisos.ajustesUsuarios)) ||
          ((ubicacion == Rutas.gestionRoles || ubicacion.startsWith('/crear_rol')) && !u.tienePermiso(Permisos.ajustesRoles)) ||
          (ubicacion == Rutas.permisosSistema && !u.tienePermiso(Permisos.ajustesPermisos)) ||
          ((ubicacion == Rutas.gestionTags || ubicacion.startsWith('/crear_tag')) && !u.tienePermiso(Permisos.ajustesTags)) ||
          ((ubicacion.startsWith('/gestion_tipos_evento') || ubicacion.startsWith('/crear_tipo_evento')) && !u.tienePermiso(Permisos.ajustesTiposEvento)) ||
          (ubicacion == Rutas.estadisticas && !u.tienePermiso(Permisos.ajustesEstadisticas)) ||
          (ubicacion == Rutas.revisionUsuarios && !u.tienePermiso(Permisos.ajustesRevision)) ||
          (ubicacion == Rutas.auditoriaEvento && !u.tienePermiso(Permisos.ajustesEstadisticas)) ||
          ((ubicacion == Rutas.borradores || ubicacion.startsWith('/crear_evento')) && !u.tienePermiso(Permisos.eventosCrearEventos)) ||
          (ubicacion.contains('/panel') && !u.tienePermiso(Permisos.eventosPanelControl));
      if (sinPermiso) return Rutas.home;

      return null;
    },

    routes: [
      ...rutasAuth,
      ...rutasPersonal,
      ...rutasEventos,
      ...rutasAjustes,
      ...rutasDev,
    ],

    errorBuilder: (context, state) => Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: ColoresApp.textoTerciario),
            const SizedBox(height: 16),
            const Text(
              'Página no encontrada',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: ColoresApp.textoPrimario,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(Rutas.home),
              style: FilledButton.styleFrom(backgroundColor: ColoresApp.acento),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Clase auxiliar para que GoRouter pueda escuchar el Stream del Cubit.
class _StreamToListen extends ChangeNotifier {

  _StreamToListen(Stream stream) {
    _suscripcion = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription _suscripcion;

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }
}
