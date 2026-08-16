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
import 'compartido/reiniciar_app.dart';
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

// Tiempo máximo por paso de arranque. En conexiones lentas o caídas, evita
// que main() se quede colgado indefinidamente antes de invocar runApp() —
// sin esto, el usuario ve una pantalla en blanco sin ningún límite de tiempo
// ni forma de saber que algo salió mal.
const _timeoutInicializacion = Duration(seconds: 8);

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Historial del navegador sin acumular entradas (solo web). Debe ir antes
      // de construir el router para que el gesto "atrás" de la PWA en Android no
      // tenga ninguna pantalla anterior que asomar.
      configurarHistorialSinAcumular();

      await _iniciarApp();
    },
    (error, stack) {
      log.e('Error no capturado en zone', error: error, stackTrace: stack);
      Sentry.captureException(error, stackTrace: stack);
    },
  );
}

/// Orquesta el arranque. Firebase y Sentry son opcionales — si fallan o
/// exceden el timeout, se degrada con gracia y la app sigue arrancando sin
/// push/monitoreo. Supabase es imprescindible: sin él ningún repositorio
/// funciona, así que su fallo lleva a [_AppFalloArranque] en vez de a un
/// árbol de widgets a medio construir.
Future<void> _iniciarApp() async {
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyD7NInOIx0MmiWCkxHw1wrAICvm_zf_kT4',
        authDomain: 'activity-14938.firebaseapp.com',
        projectId: 'activity-14938',
        storageBucket: 'activity-14938.firebasestorage.app',
        messagingSenderId: '734695397025',
        appId: '1:734695397025:web:b31fc635597404703ac2e0',
      ),
    ).timeout(_timeoutInicializacion);
    log.i('Firebase inicializado');
  } catch (e, st) {
    // Firebase solo alimenta las notificaciones push — su ausencia no debe
    // impedir que el resto de la app arranque con normalidad.
    log.w(
      'Firebase no disponible al arrancar (push deshabilitado)',
      error: e,
      stackTrace: st,
    );
  }

  // Evita que el caché de imágenes en memoria crezca indefinidamente
  // en sesiones largas (ej. operadores que dejan la app abierta todo el día).
  PaintingBinding.instance.imageCache
    ..maximumSize = 150 // máximo 150 imágenes descodificadas
    ..maximumSizeBytes = 50 << 20; // máximo 50 MB en memoria

  await CacheLocal.init();

  _configurarErrorHandlers();

  try {
    await _inicializarSentry().timeout(_timeoutInicializacion);
  } catch (e, st) {
    log.w('Sentry no disponible al arrancar', error: e, stackTrace: st);
  }

  String? url;
  String? anonKey;

  if (_dartUrl.isNotEmpty && _dartAnonKey.isNotEmpty) {
    url = _dartUrl;
    anonKey = _dartAnonKey;
  } else {
    try {
      await dotenv.load(fileName: '.env').timeout(_timeoutInicializacion);
      url = dotenv.env['SUPABASE_URL'];
      anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    } catch (e, st) {
      log.e(
        'No se pudo cargar la configuración (.env)',
        error: e,
        stackTrace: st,
      );
    }
  }

  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    log.e('Configuración de Supabase no disponible — no se puede arrancar');
    runApp(const _AppFalloArranque(alReintentar: _reintentarArranque));
    return;
  }

  try {
    await Supabase.initialize(url: url, anonKey: anonKey)
        .timeout(_timeoutInicializacion);
    log.i('Supabase inicializado');
  } catch (e, st) {
    log.e('No se pudo conectar con el servidor', error: e, stackTrace: st);
    runApp(const _AppFalloArranque(alReintentar: _reintentarArranque));
    return;
  }

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
}

void _reintentarArranque() {
  unawaited(_iniciarApp());
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
    Sentry.captureException(details.exception, stackTrace: details.stack);
  };

  // Errores asincrónicos no capturados fuera del árbol de Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    log.e('Error de plataforma no capturado', error: error, stackTrace: stack);
    Sentry.captureException(error, stackTrace: stack);
    return true;
  };

  // Widget de fallback cuando un subtree lanza una excepción en release
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (details.context != null) {
      log.e(
        'Widget error: ${details.exceptionAsString()}',
        error: details.exception,
      );
    }
    // Se reporta siempre, incluso sin context, para no perder ningún error
    // de construcción de widgets en producción.
    Sentry.captureException(details.exception, stackTrace: details.stack);
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

// ─── Pantalla de fallo de arranque ─────────────────────────────────────────────

/// Se muestra en vez del árbol completo de la app cuando una dependencia
/// imprescindible (Supabase) no pudo inicializarse — típicamente por una
/// conexión lenta o caída durante el arranque. Da al usuario una acción
/// explícita en vez de dejarlo ante una pantalla congelada.
class _AppFalloArranque extends StatelessWidget {
  const _AppFalloArranque({required this.alReintentar});

  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activity',
      debugShowCheckedModeBanner: false,
      theme: temaApp,
      home: Scaffold(
        backgroundColor: ColoresApp.fondo,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: ColoresApp.rojo,
                ),
                const SizedBox(height: 20),
                const Text(
                  'No se pudo conectar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColoresApp.textoPrimario,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Revisa tu conexión a internet e inténtalo de nuevo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: ColoresApp.textoSecundario,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => reiniciarApp(alFallback: alReintentar),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ColoresApp.acento,
                  ),
                ),
              ],
            ),
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
      title: 'Activity',
      debugShowCheckedModeBanner: false,
      theme: temaApp,
      routerConfig: routerApp.router,
      builder: (context, child) => BlocListener<AuthCubit, AuthEstado>(
        listenWhen: (_, curr) => curr is SesionDesplazada,
        listener: (_, __) {
          final overlay = routerApp.navigatorKey.currentState?.overlay;
          if (overlay == null) return;
          AvisoApp.mostrarConOverlay(
            overlay,
            texto: 'Tu sesión fue iniciada en otro dispositivo.',
            estilo: EstiloAviso.informativa,
          );
        },
        child: _EscuchaPushEnPrimerPlano(
          navigatorKey: routerApp.navigatorKey,
          child: child!,
        ),
      ),
    );
  }
}

/// Muestra un aviso visual (mismo componente que el resto de la app) cuando
/// llega un push con la app en primer plano — en ese caso el navegador no
/// muestra el banner del sistema por su cuenta, así que sin esto el usuario
/// no tenía ninguna señal de que algo llegó mientras estaba usando la app.
class _EscuchaPushEnPrimerPlano extends StatefulWidget {
  const _EscuchaPushEnPrimerPlano({
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<_EscuchaPushEnPrimerPlano> createState() =>
      _EscuchaPushEnPrimerPlanoState();
}

class _EscuchaPushEnPrimerPlanoState extends State<_EscuchaPushEnPrimerPlano> {
  StreamSubscription<MensajePushRecibido>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = NotificacionesPushServicio.alRecibirPush.listen((mensaje) {
      final overlay = widget.navigatorKey.currentState?.overlay;
      if (overlay == null) return;
      AvisoApp.mostrarConOverlay(
        overlay,
        texto: mensaje.cuerpo.isNotEmpty ? mensaje.cuerpo : mensaje.titulo,
        estilo: EstiloAviso.informativa,
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
