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

// Valores inyectados en compile-time con --dart-define-from-file=.env
// En producción / CI: flutter build apk --dart-define-from-file=.env
const _dartUrl     = String.fromEnvironment('SUPABASE_URL');
const _dartAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final String url;
  final String anonKey;

  if (_dartUrl.isNotEmpty && _dartAnonKey.isNotEmpty) {
    url     = _dartUrl;
    anonKey = _dartAnonKey;
  } else {
    await dotenv.load(fileName: '.env');
    url     = dotenv.env['SUPABASE_URL']
        ?? (throw StateError('SUPABASE_URL no encontrado — configura .env o usa --dart-define-from-file'));
    anonKey = dotenv.env['SUPABASE_ANON_KEY']
        ?? (throw StateError('SUPABASE_ANON_KEY no encontrado — configura .env o usa --dart-define-from-file'));
  }

  await Supabase.initialize(url: url, anonKey: anonKey);

  configurarDependencias();

  final authCubit           = obtenerIt<AuthCubit>();
  final notifCubit          = obtenerIt<NotificacionesCubit>();
  final configuracionRouter = RouterApp(authCubit);

  // Inicia el stream de notificaciones en tiempo real al autenticarse
  authCubit.stream.listen((estado) {
    if (estado is! Autenticado) return;
    final usuarioId = estado.usuario.id;
    if (usuarioId == null) return;
    notifCubit.iniciarStream(usuarioId);
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
      title:                      'UniAsist',
      debugShowCheckedModeBanner: false,
      theme:                      temaApp,
      routerConfig:               routerApp.router,
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
