import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'configuracion/dependencias.dart';
import 'configuracion/tema_app.dart';
import 'configuracion/router_app.dart';
import 'funcionalidades/autenticacion/auth_cubit.dart';
import 'funcionalidades/autenticacion/auth_estado.dart';
import 'funcionalidades/notificaciones/notificaciones_cubit.dart';
import 'funcionalidades/notificaciones/notificaciones_repositorio.dart';

// Valores inyectados en compile-time con --dart-define-from-file=.env
// En producción / CI: flutter build apk --dart-define-from-file=.env
const _dartUrl     = String.fromEnvironment('SUPABASE_URL');
const _dartAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

// Handler de mensajes FCM en background (debe ser función de nivel superior)
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Firebase ─────────────────────────────────────────────────────────────
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

  // ─── Supabase ─────────────────────────────────────────────────────────────
  final String url;
  final String anonKey;

  if (_dartUrl.isNotEmpty && _dartAnonKey.isNotEmpty) {
    url     = _dartUrl;
    anonKey = _dartAnonKey;
  } else {
    await dotenv.load(fileName: '.env');
    url     = dotenv.env['SUPABASE_URL']
        ?? (throw StateError('SUPABASE_URL no encontrado'));
    anonKey = dotenv.env['SUPABASE_ANON_KEY']
        ?? (throw StateError('SUPABASE_ANON_KEY no encontrado'));
  }

  await Supabase.initialize(url: url, anonKey: anonKey);

  configurarDependencias();

  final authCubit          = obtenerIt<AuthCubit>();
  final notifCubit         = obtenerIt<NotificacionesCubit>();
  final notifRepositorio   = obtenerIt<NotificacionesRepositorio>();
  final configuracionRouter = RouterApp(authCubit);

  // Registrar token FCM cuando el usuario se autentica
  authCubit.stream.listen((estado) async {
    if (estado is! Autenticado) return;
    final usuarioId = estado.usuario.id;
    if (usuarioId == null) return;

    // Iniciar stream de badge
    notifCubit.iniciarStream(usuarioId);

    // Solicitar permisos (iOS)
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Registrar token FCM
    final token = await messaging.getToken();
    if (token != null) {
      final plataforma = Platform.isIOS ? 'ios' : 'android';
      await notifRepositorio.registrarToken(
        usuarioId:  usuarioId,
        token:      token,
        plataforma: plataforma,
      );
    }

    // Actualizar token si cambia (reinstalación, etc.)
    messaging.onTokenRefresh.listen((nuevoToken) async {
      final plataforma = Platform.isIOS ? 'ios' : 'android';
      await notifRepositorio.registrarToken(
        usuarioId:  usuarioId,
        token:      nuevoToken,
        plataforma: plataforma,
      );
    });
  });

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit..verificarSesion()),
        BlocProvider.value(value: notifCubit),
      ],
      child: _App(routerApp: configuracionRouter),
    ),
  );
}

class _App extends StatelessWidget {
  final RouterApp routerApp;

  const _App({required this.routerApp});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title:                    'UniAsist',
      debugShowCheckedModeBanner: false,
      theme:                    temaApp,
      routerConfig:             routerApp.router,
      builder: (context, child) => BlocListener<AuthCubit, AuthEstado>(
        listenWhen: (_, curr) => curr is SesionDesplazada,
        listener: (ctx, _) => ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Tu sesión fue iniciada en otro dispositivo.'),
          ),
        ),
        child: child!,
      ),
    );
  }
}
