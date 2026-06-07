import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../configuracion/dependencias.dart';
import '../../funcionalidades/auditoria_evento/auditoria_evento_cubit.dart';
import '../../funcionalidades/auditoria_evento/auditoria_evento_pantalla.dart';
import '../../funcionalidades/borradores/borradores_cubit.dart';
import '../../funcionalidades/borradores/borradores_pantalla.dart';
import '../../funcionalidades/buscar_asistente/buscar_asistente_cubit.dart';
import '../../funcionalidades/buscar_asistente/buscar_asistente_pantalla.dart';
import '../../funcionalidades/colaboradores_evento/colaboradores_evento_cubit.dart';
import '../../funcionalidades/colaboradores_evento/colaboradores_evento_pantalla.dart';
import '../../funcionalidades/crear_evento/crear_evento_cubit.dart';
import '../../funcionalidades/crear_evento/crear_evento_pantalla.dart';
import '../../funcionalidades/escanear_evento_qr/escanear_evento_qr_cubit.dart';
import '../../funcionalidades/escanear_evento_qr/escanear_evento_qr_pantalla.dart';
import '../../funcionalidades/escanear_qr/escanear_qr_cubit.dart';
import '../../funcionalidades/escanear_qr/escanear_qr_pantalla.dart';
import '../../funcionalidades/eventos/eventos_cubit.dart';
import '../../funcionalidades/eventos/eventos_pantalla.dart';
import '../../funcionalidades/panel_control_evento/panel_control_cubit.dart';
import '../../funcionalidades/panel_control_evento/panel_control_pantalla.dart';

List<GoRoute> get rutasEventos => [
      GoRoute(
        path: Rutas.eventos,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<EventosCubit>(),
          child: const EventosPantalla(),
        ),
      ),
      GoRoute(
        path: Rutas.crearEvento,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<CrearEventoCubit>(),
          child: const CrearEventoPantalla(),
        ),
      ),
      GoRoute(
        path: Rutas.editarEvento,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<CrearEventoCubit>(),
          child: CrearEventoPantalla(
            eventoId: state.pathParameters['eventoId'],
          ),
        ),
      ),
      GoRoute(
        path: Rutas.borradores,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<BorradoresCubit>(),
          child: const BorradoresPantalla(),
        ),
      ),
      GoRoute(
        path: Rutas.panelControl,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<PanelControlCubit>(),
          child: PanelControlPantalla(
            eventoId: state.pathParameters['eventoId']!,
          ),
        ),
      ),
      GoRoute(
        path: Rutas.buscarAsistente,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<BuscarAsistenteCubit>(),
          child: BuscarAsistentePantalla(
            eventoId: state.pathParameters['eventoId']!,
          ),
        ),
      ),
      GoRoute(
        path: Rutas.escanearQrUsuario,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<EscanearQrCubit>(),
          child: EscanearQrPantalla(
            eventoId: state.pathParameters['eventoId']!,
          ),
        ),
      ),
      GoRoute(
        path: Rutas.escanear,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<EscanearEventoQrCubit>(),
          child: const EscanearEventoQrPantalla(),
        ),
      ),
      GoRoute(
        path: Rutas.colaboradoresEvento,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<ColaboradoresEventoCubit>(),
          child: ColaboradoresEventoPantalla(
            eventoId: state.pathParameters['eventoId']!,
          ),
        ),
      ),
      GoRoute(
        path: Rutas.auditoriaEvento,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<AuditoriaEventoCubit>(),
          child: const AuditoriaEventoPantalla(),
        ),
      ),
    ];
