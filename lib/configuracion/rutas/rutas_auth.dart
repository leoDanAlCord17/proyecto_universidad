import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../configuracion/colores_app.dart';
import '../../configuracion/dependencias.dart';
import '../../funcionalidades/autenticacion/login_cubit.dart';
import '../../funcionalidades/autenticacion/login_pantalla.dart';
import '../../funcionalidades/autenticacion/pendiente_aprobacion_pantalla.dart';
import '../../funcionalidades/autenticacion/registro_cubit.dart';
import '../../funcionalidades/autenticacion/registro_pantalla.dart';
import '../../funcionalidades/autenticacion/usuario_rechazado_pantalla.dart';
import '../../funcionalidades/crear_usuario/crear_usuario_cubit.dart';
import '../../funcionalidades/crear_usuario/crear_usuario_pantalla.dart';
import '../../funcionalidades/nueva_contrasena/nueva_contrasena_cubit.dart';
import '../../funcionalidades/nueva_contrasena/nueva_contrasena_pantalla.dart';
import '../../funcionalidades/recuperar_contrasena/recuperar_contrasena_cubit.dart';
import '../../funcionalidades/recuperar_contrasena/recuperar_contrasena_pantalla.dart';

List<GoRoute> get rutasAuth => [
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
        path: Rutas.recuperarContrasena,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<RecuperarContrasenaCubit>(),
          child: const RecuperarContrasenaPantalla(),
        ),
      ),
      GoRoute(
        path: Rutas.nuevaContrasena,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<NuevaContrasenaCubit>(),
          child: const NuevaContrasenaPantalla(),
        ),
      ),
      GoRoute(
        path: Rutas.pendienteAprobacion,
        builder: (context, state) => const PendienteAprobacionPantalla(),
      ),
      GoRoute(
        path: Rutas.usuarioRechazado,
        builder: (context, state) => const UsuarioRechazadoPantalla(),
      ),
    ];
