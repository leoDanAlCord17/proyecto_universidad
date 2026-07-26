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
      final from = state.uri.queryParameters['from'];

      // Verificando sesión al arrancar: mostrar splash hasta que AuthCubit
      // resuelva. Se preserva la ruta + query originales (deep link o F5
      // sobre una URL compartida) en `from` para poder restaurarla una vez
      // se conozca el estado real de autenticación — antes se perdía porque
      // el redirect sobrescribía `ubicacion` con Rutas.splash sin guardar
      // a dónde iba el usuario.
      if (estadoAuth is AuthInicial) {
        if (ubicacion == Rutas.splash) return null;
        return _conFrom(Rutas.splash, _ubicacionCompleta(state));
      }

      // Perfil incompleto: tiene cuenta en Auth pero no terminó el registro.
      if (estadoAuth is PerfilIncompleto) {
        return ubicacion == Rutas.completarPerfil
            ? null
            : Rutas.completarPerfil;
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
        return ubicacion == Rutas.nuevaContrasena
            ? null
            : Rutas.nuevaContrasena;
      }

      // Sin autenticación: solo puede estar en rutas públicas
      if (estadoAuth is! Autenticado) {
        final esRutaPublica = ubicacion == Rutas.login ||
            ubicacion == Rutas.registro ||
            ubicacion == Rutas.recuperarContrasena;
        if (esRutaPublica) return null;
        // Preserva el destino original (o el que ya venía en `from` desde
        // splash) para volver a él después de iniciar sesión.
        return _conFrom(Rutas.login, from ?? _ubicacionCompleta(state));
      }

      // Autenticado: redirigir fuera de rutas de flujo de auth, restaurando
      // el destino original (`from`) si vino de un deep link, un F5 o un
      // enlace compartido. Sin `from` válido, cae al home de siempre.
      if (ubicacion == Rutas.splash ||
          ubicacion == Rutas.login ||
          ubicacion == Rutas.registro ||
          ubicacion == Rutas.completarPerfil ||
          ubicacion == Rutas.pendienteAprobacion ||
          ubicacion == Rutas.usuarioRechazado ||
          ubicacion == Rutas.recuperarContrasena ||
          ubicacion == Rutas.nuevaContrasena) {
        if (from != null && from.isNotEmpty && _esRutaInternaValida(from)) {
          return from;
        }
        return Rutas.home;
      }

      // ─── GUARDS DE RUTAS POR PERMISO ────────────────────────────────────
      final u = estadoAuth.usuario;
      final sinPermiso = (ubicacion.startsWith('/gestion_usuarios') &&
              !u.tienePermiso(Permisos.ajustesUsuarios)) ||
          ((ubicacion == Rutas.gestionRoles ||
                  ubicacion.startsWith('/crear_rol')) &&
              !u.tienePermiso(Permisos.ajustesRoles)) ||
          (ubicacion == Rutas.permisosSistema &&
              !u.tienePermiso(Permisos.ajustesPermisos)) ||
          ((ubicacion == Rutas.gestionTags ||
                  ubicacion.startsWith('/crear_tag')) &&
              !u.tienePermiso(Permisos.ajustesTags)) ||
          ((ubicacion.startsWith('/gestion_tipos_evento') ||
                  ubicacion.startsWith('/crear_tipo_evento')) &&
              !u.tienePermiso(Permisos.ajustesTiposEvento)) ||
          (ubicacion == Rutas.estadisticas &&
              !u.tienePermiso(Permisos.ajustesEstadisticas)) ||
          (ubicacion == Rutas.revisionUsuarios &&
              !u.tienePermiso(Permisos.ajustesRevision)) ||
          (ubicacion == Rutas.auditoriaEvento &&
              !u.tienePermiso(Permisos.ajustesEstadisticas)) ||
          ((ubicacion == Rutas.borradores ||
                  ubicacion.startsWith('/crear_evento')) &&
              !u.tienePermiso(Permisos.eventosCrearEventos)) ||
          (ubicacion.contains('/panel') &&
              !u.tienePermiso(Permisos.eventosPanelControl));
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
            const Icon(Icons.search_off_rounded,
                size: 64, color: ColoresApp.textoTerciario),
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

/// Construye `base?from=<ubicacion>` para preservar el destino original
/// a través de una redirección intermedia (splash, login).
String _conFrom(String base, String ubicacion) {
  if (ubicacion.isEmpty || ubicacion == base) return base;
  return Uri(path: base, queryParameters: {'from': ubicacion}).toString();
}

/// Reconstruye la ruta completa (path + query) que el usuario solicitó
/// originalmente, para poder restaurarla después de splash/login.
String _ubicacionCompleta(GoRouterState state) {
  final uri = state.uri;
  if (uri.query.isEmpty) return uri.path;
  return '${uri.path}?${uri.query}';
}

/// Valida que `from` sea una ruta interna segura antes de redirigir a ella:
/// rechaza URLs protocol-relative (`//host`, posible open-redirect) y
/// cualquier ruta de flujo de auth (evitaría un loop de redirección).
bool _esRutaInternaValida(String ruta) {
  if (!ruta.startsWith('/') || ruta.startsWith('//')) return false;
  const rutasAuthFlow = {
    Rutas.splash,
    Rutas.login,
    Rutas.registro,
    Rutas.completarPerfil,
    Rutas.pendienteAprobacion,
    Rutas.usuarioRechazado,
    Rutas.recuperarContrasena,
    Rutas.nuevaContrasena,
  };
  final path = Uri.parse(ruta).path;
  return !rutasAuthFlow.contains(path);
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
