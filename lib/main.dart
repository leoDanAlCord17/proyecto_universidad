import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'configuracion/dependencias.dart';
import 'configuracion/tema_app.dart';
import 'configuracion/router_app.dart';
import 'funcionalidades/autenticacion/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final url     = dotenv.env['SUPABASE_URL']
      ?? (throw StateError('SUPABASE_URL no encontrado en .env — agrega el archivo .env al proyecto.'));
  final anonKey = dotenv.env['SUPABASE_ANON_KEY']
      ?? (throw StateError('SUPABASE_ANON_KEY no encontrado en .env — agrega el archivo .env al proyecto.'));

  await Supabase.initialize(url: url, anonKey: anonKey);

  // Registrar todas las dependencias una sola vez
  configurarDependencias();

  final authCubit = obtenerIt<AuthCubit>();
  final configuracionRouter = RouterApp(authCubit);

  runApp(
    BlocProvider.value(
      value: authCubit..verificarSesion(),
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
      title: 'UniAsist',
      debugShowCheckedModeBanner: false,
      theme: temaApp,
      routerConfig: routerApp.router,
    );
  }
}
