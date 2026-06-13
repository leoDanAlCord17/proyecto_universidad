import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../configuracion/dependencias.dart';
import '../../funcionalidades/estadisticas/estadisticas_cubit.dart';
import '../../funcionalidades/estadisticas/estadisticas_pantalla.dart';
import '../../funcionalidades/navegacion_principal.dart';
import '../../funcionalidades/notificaciones/notificaciones_cubit.dart';
import '../../funcionalidades/notificaciones/notificaciones_pantalla.dart';

List<GoRoute> get rutasPersonal => [
      // Las pestañas Inicio / Eventos / Asistencia / Perfil viven dentro de este
      // contenedor (IndexedStack), no como rutas separadas. Cambiar de pestaña es
      // estado interno y no toca el historial del navegador.
      GoRoute(
        path: Rutas.home,
        builder: (context, state) => const NavegacionPrincipal(),
      ),
      GoRoute(
        path: Rutas.admin,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Panel de Administración')),
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
