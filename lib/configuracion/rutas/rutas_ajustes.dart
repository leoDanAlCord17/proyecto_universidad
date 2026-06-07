import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../configuracion/dependencias.dart';
import '../../funcionalidades/crear_rol/crear_rol_cubit.dart';
import '../../funcionalidades/crear_rol/crear_rol_pantalla.dart';
import '../../funcionalidades/crear_tag/crear_tag_cubit.dart';
import '../../funcionalidades/crear_tag/crear_tag_pantalla.dart';
import '../../funcionalidades/editar_usuario/editar_usuario_cubit.dart';
import '../../funcionalidades/editar_usuario/editar_usuario_pantalla.dart';
import '../../funcionalidades/gestionar_roles_usuario/gestionar_roles_usuario_cubit.dart';
import '../../funcionalidades/gestionar_roles_usuario/gestionar_roles_usuario_pantalla.dart';
import '../../funcionalidades/gestionar_tags_usuario/gestionar_tags_usuario_cubit.dart';
import '../../funcionalidades/gestionar_tags_usuario/gestionar_tags_usuario_pantalla.dart';
import '../../funcionalidades/permisos/permisos_cubit.dart';
import '../../funcionalidades/permisos/permisos_pantalla.dart';
import '../../funcionalidades/revision_usuarios/revision_usuarios_cubit.dart';
import '../../funcionalidades/revision_usuarios/revision_usuarios_pantalla.dart';
import '../../funcionalidades/roles/roles_cubit.dart';
import '../../funcionalidades/roles/roles_pantalla.dart';
import '../../funcionalidades/tags/tags_cubit.dart';
import '../../funcionalidades/tags/tags_pantalla.dart';
import '../../funcionalidades/tipos_evento/crear_tipo_evento_cubit.dart';
import '../../funcionalidades/tipos_evento/crear_tipo_evento_pantalla.dart';
import '../../funcionalidades/tipos_evento/tipos_evento_cubit.dart';
import '../../funcionalidades/tipos_evento/tipos_evento_pantalla.dart';
import '../../funcionalidades/usuarios/usuarios_cubit.dart';
import '../../funcionalidades/usuarios/usuarios_pantalla.dart';
import '../../funcionalidades/ver_perfil_usuario/ver_perfil_usuario_cubit.dart';
import '../../funcionalidades/ver_perfil_usuario/ver_perfil_usuario_pantalla.dart';

List<GoRoute> get rutasAjustes => [
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
        path: Rutas.revisionUsuarios,
        builder: (context, state) => BlocProvider(
          create: (_) => obtenerIt<RevisionUsuariosCubit>(),
          child: const RevisionUsuariosPantalla(),
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
    ];
