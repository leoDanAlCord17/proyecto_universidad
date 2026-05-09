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
import '../funcionalidades/borradores/borradores_cubit.dart';
import '../funcionalidades/borradores/borradores_pantalla.dart';
import '../funcionalidades/permisos/permisos_cubit.dart';
import '../funcionalidades/permisos/permisos_pantalla.dart';
import '../funcionalidades/roles/roles_cubit.dart';
import '../funcionalidades/roles/roles_pantalla.dart';
import '../funcionalidades/tags/tags_cubit.dart';
import '../funcionalidades/tags/tags_pantalla.dart';
import '../funcionalidades/usuarios/usuarios_cubit.dart';
import '../funcionalidades/usuarios/usuarios_pantalla.dart';
import '../funcionalidades/gestionar_tags_usuario/gestionar_tags_usuario_cubit.dart';
import '../funcionalidades/gestionar_tags_usuario/gestionar_tags_usuario_pantalla.dart';
import '../funcionalidades/crear_tag/crear_tag_cubit.dart';
import '../funcionalidades/crear_tag/crear_tag_pantalla.dart';
import '../funcionalidades/crear_rol/crear_rol_cubit.dart';
import '../funcionalidades/crear_rol/crear_rol_pantalla.dart';
import '../funcionalidades/crear_evento/crear_evento_cubit.dart';
import '../funcionalidades/crear_evento/crear_evento_pantalla.dart';
import '../funcionalidades/eventos/eventos_cubit.dart';
import '../funcionalidades/eventos/eventos_pantalla.dart';
import '../funcionalidades/perfil/perfil_cubit.dart';
import '../funcionalidades/perfil/perfil_pantalla.dart';
import '../funcionalidades/recuperar_contrasena/recuperar_contrasena_cubit.dart';
import '../funcionalidades/recuperar_contrasena/recuperar_contrasena_pantalla.dart';
import '../funcionalidades/nueva_contrasena/nueva_contrasena_cubit.dart';
import '../funcionalidades/nueva_contrasena/nueva_contrasena_pantalla.dart';
import '../funcionalidades/gestionar_roles_usuario/gestionar_roles_usuario_cubit.dart';
import '../funcionalidades/gestionar_roles_usuario/gestionar_roles_usuario_pantalla.dart';
import '../funcionalidades/ver_perfil_usuario/ver_perfil_usuario_cubit.dart';
import '../funcionalidades/ver_perfil_usuario/ver_perfil_usuario_pantalla.dart';
import '../funcionalidades/editar_usuario/editar_usuario_cubit.dart';
import '../funcionalidades/editar_usuario/editar_usuario_pantalla.dart';
import '../funcionalidades/panel_control_evento/panel_control_cubit.dart';
import '../funcionalidades/panel_control_evento/panel_control_pantalla.dart';
import '../funcionalidades/buscar_asistente/buscar_asistente_cubit.dart';
import '../funcionalidades/buscar_asistente/buscar_asistente_pantalla.dart';
import '../funcionalidades/escanear_qr/escanear_qr_cubit.dart';
import '../funcionalidades/escanear_qr/escanear_qr_pantalla.dart';
import '../funcionalidades/escanear_evento_qr/escanear_evento_qr_cubit.dart';
import '../funcionalidades/escanear_evento_qr/escanear_evento_qr_pantalla.dart';
import '../funcionalidades/notificaciones/notificaciones_cubit.dart';
import '../funcionalidades/notificaciones/notificaciones_pantalla.dart';
import '../funcionalidades/tipos_evento/crear_tipo_evento_cubit.dart';
import '../funcionalidades/tipos_evento/crear_tipo_evento_pantalla.dart';
import '../funcionalidades/tipos_evento/tipos_evento_cubit.dart';
import '../funcionalidades/tipos_evento/tipos_evento_pantalla.dart';
import '../funcionalidades/autenticacion/pendiente_aprobacion_pantalla.dart';
import '../funcionalidades/autenticacion/usuario_rechazado_pantalla.dart';
import '../funcionalidades/revision_usuarios/revision_usuarios_cubit.dart';
import '../funcionalidades/revision_usuarios/revision_usuarios_pantalla.dart';
import '../funcionalidades/historial/historial_cubit.dart';
import '../funcionalidades/historial/historial_pantalla.dart';
import '../funcionalidades/inicio/eventos_en_curso_cubit.dart';

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

      // Cuenta pendiente de aprobación por el administrador.
      if (estadoAuth is PendienteAprobacion) {
        return ubicacion == Rutas.pendienteAprobacion
            ? null
            : Rutas.pendienteAprobacion;
      }

      // Cuenta rechazada por el administrador.
      if (estadoAuth is UsuarioRechazado) {
        return ubicacion == Rutas.usuarioRechazado
            ? null
            : Rutas.usuarioRechazado;
      }

      // Recuperación de contraseña: sesión de recovery activa
      if (estadoAuth is RecuperandoContrasena) {
        return ubicacion == Rutas.nuevaContrasena ? null : Rutas.nuevaContrasena;
      }

      // Sin autenticación: solo puede estar en rutas públicas
      if (estadoAuth is! Autenticado) {
        final esRutaPublica = ubicacion == Rutas.login
            || ubicacion == Rutas.registro
            || ubicacion == Rutas.recuperarContrasena
            || (kDebugMode && ubicacion == Rutas.vistaWidgets)
            || (kDebugMode && ubicacion == Rutas.vistaFuentes);
        return esRutaPublica ? null : Rutas.login;
      }

      // Autenticado: redirigir fuera de rutas de flujo de auth
      if (ubicacion == Rutas.splash ||
          ubicacion == Rutas.login ||
          ubicacion == Rutas.registro ||
          ubicacion == Rutas.completarPerfil ||
          ubicacion == Rutas.pendienteAprobacion ||
          ubicacion == Rutas.usuarioRechazado ||
          ubicacion == Rutas.recuperarContrasena ||
          ubicacion == Rutas.nuevaContrasena) {
        return Rutas.home;
      }

      // TODO(prod): Reactivar guards de rutas administrativas antes de producción.
      // Ver corrección A01 en el informe de seguridad.

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
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => obtenerIt<InicioCubit>()),
            BlocProvider(create: (_) => obtenerIt<NotificacionesCubit>()),
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
        path: Rutas.permisosSistema,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<PermisosCubit>(),
          child: const PermisosPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.gestionRoles,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<RolesCubit>(),
          child: const RolesPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.crearRol,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<CrearRolCubit>(),
          child: const CrearRolPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.editarRol,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<CrearRolCubit>(),
          child: CrearRolPantalla(
            rolId: state.pathParameters['rolId'],
          ),
        ),
      ),

      GoRoute(
        path: Rutas.gestionUsuarios,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<UsuariosCubit>(),
          child: const UsuariosPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.gestionarTagsUsuario,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<GestionarTagsUsuarioCubit>(),
          child: GestionarTagsUsuarioPantalla(
            usuarioId: state.pathParameters['usuarioId']!,
          ),
        ),
      ),

      GoRoute(
        path: Rutas.gestionarRolesUsuario,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<GestionarRolesUsuarioCubit>(),
          child: GestionarRolesUsuarioPantalla(
            usuarioId: state.pathParameters['usuarioId']!,
          ),
        ),
      ),

      GoRoute(
        path: Rutas.verPerfilUsuario,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<VerPerfilUsuarioCubit>(),
          child: VerPerfilUsuarioPantalla(
            usuarioId: state.pathParameters['usuarioId']!,
          ),
        ),
      ),

      GoRoute(
        path: Rutas.editarUsuario,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<EditarUsuarioCubit>(),
          child: EditarUsuarioPantalla(
            usuarioId: state.pathParameters['usuarioId']!,
          ),
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
        path: Rutas.gestionTags,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<TagsCubit>(),
          child: const TagsPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.crearTag,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<CrearTagCubit>(),
          child: const CrearTagPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.editarTag,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<CrearTagCubit>(),
          child: CrearTagPantalla(
            tagId: state.pathParameters['tagId'],
          ),
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
        path: Rutas.notificaciones,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<NotificacionesCubit>(),
          child: const NotificacionesPantalla(),
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
        path:    Rutas.pendienteAprobacion,
        builder: (context, state) => const PendienteAprobacionPantalla(),
      ),

      GoRoute(
        path:    Rutas.usuarioRechazado,
        builder: (context, state) => const UsuarioRechazadoPantalla(),
      ),

      GoRoute(
        path: Rutas.revisionUsuarios,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<RevisionUsuariosCubit>(),
          child:  const RevisionUsuariosPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.historial,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<HistorialCubit>(),
          child:  const HistorialPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.gestionTiposEvento,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<TiposEventoCubit>(),
          child: const TiposEventoPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.crearTipoEvento,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<CrearTipoEventoCubit>(),
          child: const CrearTipoEventoPantalla(),
        ),
      ),

      GoRoute(
        path: Rutas.editarTipoEvento,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<CrearTipoEventoCubit>(),
          child: CrearTipoEventoPantalla(
            tipoEventoId: state.pathParameters['tipoEventoId'],
          ),
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
