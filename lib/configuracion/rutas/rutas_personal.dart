import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../configuracion/dependencias.dart';
import '../../funcionalidades/estadisticas/estadisticas_cubit.dart';
import '../../funcionalidades/estadisticas/estadisticas_pantalla.dart';
import '../../funcionalidades/historial/historial_cubit.dart';
import '../../funcionalidades/historial/historial_pantalla.dart';
import '../../funcionalidades/inicio/eventos_en_curso_cubit.dart';
import '../../funcionalidades/inicio/inicio_cubit.dart';
import '../../funcionalidades/inicio/inicio_pantalla.dart';
import '../../funcionalidades/notificaciones/notificaciones_cubit.dart';
import '../../funcionalidades/notificaciones/notificaciones_pantalla.dart';
import '../../funcionalidades/perfil/perfil_cubit.dart';
import '../../funcionalidades/perfil/perfil_pantalla.dart';

List<GoRoute> get rutasPersonal => [
      GoRoute(
        path: Rutas.home,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => obtenerIt<InicioCubit>()),
            BlocProvider(create: (_) => obtenerIt<EventosEnCursoCubit>()),
          ],
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
      GoRoute(
        path: Rutas.historial,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<HistorialCubit>(),
          child: const HistorialPantalla(),
        ),
      ),
      GoRoute(
        path: Rutas.estadisticas,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<EstadisticasCubit>(),
          child: const EstadisticasPantalla(),
        ),
      ),
      GoRoute(
        path: Rutas.notificaciones,
        builder: (context, state) => BlocProvider.value(
          value: obtenerIt<NotificacionesCubit>(),
          child: const NotificacionesPantalla(),
        ),
      ),
    ];
