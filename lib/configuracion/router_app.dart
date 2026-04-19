import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../compartido/constantes.dart';
import '../configuracion/colores_app.dart';
import '../configuracion/dependencias.dart';
import '../funcionalidades/autenticacion/auth_cubit.dart';
import '../funcionalidades/autenticacion/auth_estado.dart';

import '../dev/vista_fuentes_pantalla.dart';
import '../dev/vista_widgets_pantalla.dart';
import '../funcionalidades/autenticacion/login_cubit.dart';
import '../funcionalidades/autenticacion/login_pantalla.dart';
import '../funcionalidades/autenticacion/registro_cubit.dart';
import '../funcionalidades/autenticacion/registro_pantalla.dart';
import '../funcionalidades/crear_usuario/crear_usuario_cubit.dart';
import '../funcionalidades/crear_usuario/crear_usuario_pantalla.dart';
import '../funcionalidades/inicio/inicio_cubit.dart';
import '../funcionalidades/inicio/inicio_pantalla.dart';
import '../funcionalidades/perfil/perfil_cubit.dart';
import '../funcionalidades/perfil/perfil_pantalla.dart';

class RouterApp {
  final AuthCubit authCubit;

  RouterApp(this.authCubit);

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

      // Sin autenticación: solo puede estar en /login, /registro o /dev/widgets (solo debug)
      if (estadoAuth is! Autenticado) {
        final esRutaPublica = ubicacion == Rutas.login
            || ubicacion == Rutas.registro
            || (kDebugMode && ubicacion == Rutas.vistaWidgets)
            || (kDebugMode && ubicacion == Rutas.vistaFuentes);
        return esRutaPublica ? null : Rutas.login;
      }

      // Autenticado: redirigir fuera de rutas públicas y splash
      if (ubicacion == Rutas.splash ||
          ubicacion == Rutas.login ||
          ubicacion == Rutas.registro ||
          ubicacion == Rutas.completarPerfil) {
        return Rutas.home;
      }

      // Protección de zona administrativa por rol
      if (ubicacion.startsWith(Rutas.admin) && !estadoAuth.usuario.tieneRol('admin')) {
        return Rutas.home;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: Rutas.splash,
        builder: (context, state) => const Scaffold(
          backgroundColor: ColoresApp.fondo,
          body: Center(
            child: CircularProgressIndicator(color: ColoresApp.acento),
          ),
        ),
      ),

      GoRoute(
        path: Rutas.login,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<LoginCubit>(),
          child: const LoginPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.registro,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<RegistroCubit>(),
          child: const RegistroPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.completarPerfil,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<CrearUsuarioCubit>(),
          child: const CrearUsuarioPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.home,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<InicioCubit>(),
          child: const InicioPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.admin,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Panel de Administración')),
        ),
      ),

      GoRoute(
        path: Rutas.perfil,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<PerfilCubit>(),
          child: const PerfilPantalla(),
        ),
      ),

      // Solo desarrollo — no registradas en release builds
      if (kDebugMode)
        GoRoute(
          path: Rutas.vistaWidgets,
          builder: (context, state) => const VistaWidgetsPantalla(),
        ),
      if (kDebugMode)
        GoRoute(
          path: Rutas.vistaFuentes,
          builder: (context, state) => const VistaFuentesPantalla(),
        ),
    ],

    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Página no encontrada.')),
    ),
  );
}

/// Clase auxiliar para que GoRouter pueda escuchar el Stream del Cubit.
class _StreamToListen extends ChangeNotifier {
  late final StreamSubscription _suscripcion;

  _StreamToListen(Stream stream) {
    notifyListeners();
    _suscripcion = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }
}
