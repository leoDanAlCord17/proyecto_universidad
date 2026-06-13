import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'compartido/cache_local.dart';
import 'compartido/historial_navegador.dart';
import 'compartido/logger.dart';
import 'compartido/notificaciones_push_servicio.dart';
import 'compartido/widgets/avisos/aviso_app.dart';
import 'configuracion/colores_app.dart';
import 'configuracion/dependencias.dart';
import 'configuracion/entorno.dart';
import 'configuracion/tema_app.dart';
import 'configuracion/router_app.dart';
import 'funcionalidades/autenticacion/auth_cubit.dart';
import 'funcionalidades/autenticacion/auth_estado.dart';
import 'funcionalidades/notificaciones/notificaciones_cubit.dart';

// Valores inyectados en compile-time con --dart-define-from-file=.env
// En producción / CI: flutter build apk --dart-define-from-file=.env
const _dartUrl = String.fromEnvironment('SUPABASE_URL');
const _dartAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Historial del navegador sin acumular entradas (solo web). Debe ir antes
      // de construir el router para que el gesto "atrás" de la PWA en Android no
      // tenga ninguna pantalla anterior que asomar.
      configurarHistorialSinAcumular();

      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyD7NInOIx0MmiWCkxHw1wrAICvm_zf_kT4',
          authDomain: 'activity-14938.firebaseapp.com',
          projectId: 'activity-14938',
          storageBucket: 'activity-14938.firebasestorage.app',
          messagingSenderId: '734695397025',
          appId: '1:734695397025:web:b31fc635597404703ac2e0',
        ),
      );
      log.i('Firebase inicializado');

      // Evita que el caché de imágenes en memoria crezca indefinidamente
      // en sesiones largas (ej. operadores que dejan la app abierta todo el día).
      PaintingBinding.instance.imageCache
        ..maximumSize = 150 // máximo 150 imágenes descodificadas
        ..maximumSizeBytes = 50 << 20; // máximo 50 MB en memoria

      await CacheLocal.init();

      _configurarErrorHandlers();

      await _inicializarSentry();

      final String url;
      final String anonKey;

      if (_dartUrl.isNotEmpty && _dartAnonKey.isNotEmpty) {
        url = _dartUrl;
        anonKey = _dartAnonKey;
      } else {
        await dotenv.load(fileName: '.env');
        url = dotenv.env['SUPABASE_URL'] ??
            (throw StateError(
                'SUPABASE_URL no encontrado — configura .env o usa --dart-define-from-file'));
        anonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
            (throw StateError(
                'SUPABASE_ANON_KEY no encontrado — configura .env o usa --dart-define-from-file'));
      }

      await Supabase.initialize(url: url, anonKey: anonKey);
      log.i('Supabase inicializado');

      configurarDependencias();

      final authCubit = obtenerIt<AuthCubit>();
      final notifCubit = obtenerIt<NotificacionesCubit>();
      final configuracionRouter = RouterApp(authCubit);

      authCubit.stream.listen((estado) {
        if (estado is! Autenticado) return;
        final usuarioId = estado.usuario.id;
        if (usuarioId == null) return;
        notifCubit.iniciarStream(usuarioId);
        unawaited(NotificacionesPushServicio.inicializar(usuarioId));
      });

      unawaited(authCubit.verificarSesion());

      runApp(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: authCubit),
            BlocProvider.value(value: notifCubit),
          ],
          child: _App(routerApp: configuracionRouter),
        ),
      );
    },
    (error, stack) =>
        log.e('Error no capturado en zone', error: error, stackTrace: stack),
  );
}

/// Inicializa Sentry si el DSN está configurado. En desarrollo o sin DSN, es no-op.
Future<void> _inicializarSentry() async {
  final dsn = entorno.sentryDsn;
  if (dsn.isEmpty) return;

  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = entorno.nombre;
      options.tracesSampleRate = entorno.esProd ? 0.2 : 0.0;
      options.debug = entorno.esDev;
    },
  );
  log.i('Sentry inicializado (entorno: ${entorno.nombre})');
}

/// Configura los manejadores globales de errores antes de iniciar la app.
void _configurarErrorHandlers() {
  // Errores en el framework de Flutter (widgets, rendering, etc.)
  FlutterError.onError = (details) {
    log.e(
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Errores asincrónicos no capturados fuera del árbol de Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    log.e('Error de plataforma no capturado', error: error, stackTrace: stack);
    return true;
  };

  // Widget de fallback cuando un subtree lanza una excepción en release
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (details.context != null) {
      log.e('Widget error: ${details.exceptionAsString()}',
          error: details.exception);
    }
    return _WidgetDeError(mensaje: details.exceptionAsString());
  };
}

// ─── Widget de error visual ───────────────────────────────────────────────────

class _WidgetDeError extends StatelessWidget {
  const _WidgetDeError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: ColoresApp.superficiePrimaria,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: ColoresApp.rojo),
              SizedBox(height: 16),
              Text(
                'Algo salió mal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Por favor reinicia la aplicación.',
                style:
                    TextStyle(fontSize: 14, color: ColoresApp.textoSecundario),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── App ──────────────────────────────────────────────────────────────────────

class _App extends StatelessWidget {
  const _App({required this.routerApp});

  final RouterApp routerApp;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UniAsist',
      debugShowCheckedModeBanner: false,
      theme: temaApp,
      routerConfig: routerApp.router,
      builder: (context, child) => BlocListener<AuthCubit, AuthEstado>(
        listenWhen: (_, curr) => curr is SesionDesplazada,
        listener: (ctx, _) => AvisoApp.mostrar(
          ctx,
          texto: 'Tu sesión fue iniciada en otro dispositivo.',
          estilo: EstiloAviso.informativa,
        ),
        child: child!,
      ),
    );
  }
}
