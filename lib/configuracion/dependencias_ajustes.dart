import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../funcionalidades/crear_rol/crear_rol_cubit.dart';
import '../funcionalidades/crear_rol/crear_rol_repositorio.dart';
import '../funcionalidades/crear_tag/crear_tag_cubit.dart';
import '../funcionalidades/crear_tag/crear_tag_repositorio.dart';
import '../funcionalidades/editar_usuario/editar_usuario_cubit.dart';
import '../funcionalidades/editar_usuario/editar_usuario_repositorio.dart';
import '../funcionalidades/gestionar_roles_usuario/gestionar_roles_usuario_cubit.dart';
import '../funcionalidades/gestionar_roles_usuario/gestionar_roles_usuario_repositorio.dart';
import '../funcionalidades/gestionar_tags_usuario/gestionar_tags_usuario_cubit.dart';
import '../funcionalidades/gestionar_tags_usuario/gestionar_tags_usuario_repositorio.dart';
import '../funcionalidades/permisos/permisos_cubit.dart';
import '../funcionalidades/permisos/permisos_repositorio.dart';
import '../funcionalidades/revision_usuarios/revision_usuarios_cubit.dart';
import '../funcionalidades/revision_usuarios/revision_usuarios_repositorio.dart';
import '../funcionalidades/roles/roles_cubit.dart';
import '../funcionalidades/roles/roles_repositorio.dart';
import '../funcionalidades/tags/tags_cubit.dart';
import '../funcionalidades/tags/tags_repositorio.dart';
import '../funcionalidades/tipos_evento/crear_tipo_evento_cubit.dart';
import '../funcionalidades/tipos_evento/tipos_evento_cubit.dart';
import '../funcionalidades/tipos_evento/tipos_evento_repositorio.dart';
import '../funcionalidades/usuarios/usuarios_cubit.dart';
import '../funcionalidades/usuarios/usuarios_repositorio.dart';
import '../funcionalidades/ver_perfil_usuario/ver_perfil_usuario_cubit.dart';
import '../funcionalidades/ver_perfil_usuario/ver_perfil_usuario_repositorio.dart';

void configurarDependenciasAjustes(GetIt it) {
  it.registerLazySingleton<PermisosRepositorio>(
    () => PermisosRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<PermisosCubit>(
    () => PermisosCubit(it<PermisosRepositorio>()),
  );

  it.registerLazySingleton<RolesRepositorio>(
    () => RolesRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<RolesCubit>(
    () => RolesCubit(it<RolesRepositorio>()),
  );

  it.registerLazySingleton<CrearRolRepositorio>(
    () => CrearRolRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<CrearRolCubit>(
    () => CrearRolCubit(it<CrearRolRepositorio>()),
  );

  it.registerLazySingleton<UsuariosRepositorio>(
    () => UsuariosRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<UsuariosCubit>(
    () => UsuariosCubit(it<UsuariosRepositorio>()),
  );

  it.registerLazySingleton<GestionarTagsUsuarioRepositorio>(
    () => GestionarTagsUsuarioRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<GestionarTagsUsuarioCubit>(
    () => GestionarTagsUsuarioCubit(it<GestionarTagsUsuarioRepositorio>()),
  );

  it.registerLazySingleton<GestionarRolesUsuarioRepositorio>(
    () => GestionarRolesUsuarioRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<GestionarRolesUsuarioCubit>(
    () => GestionarRolesUsuarioCubit(it<GestionarRolesUsuarioRepositorio>()),
  );

  it.registerLazySingleton<VerPerfilUsuarioRepositorio>(
    () => VerPerfilUsuarioRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<VerPerfilUsuarioCubit>(
    () => VerPerfilUsuarioCubit(it<VerPerfilUsuarioRepositorio>()),
  );

  it.registerLazySingleton<EditarUsuarioRepositorio>(
    () => EditarUsuarioRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<EditarUsuarioCubit>(
    () => EditarUsuarioCubit(it<EditarUsuarioRepositorio>()),
  );

  it.registerLazySingleton<TagsRepositorio>(
    () => TagsRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<TagsCubit>(
    () => TagsCubit(it<TagsRepositorio>()),
  );

  it.registerLazySingleton<CrearTagRepositorio>(
    () => CrearTagRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<CrearTagCubit>(
    () => CrearTagCubit(it<CrearTagRepositorio>()),
  );

  it.registerLazySingleton<TiposEventoRepositorio>(
    () => TiposEventoRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<TiposEventoCubit>(
    () => TiposEventoCubit(it<TiposEventoRepositorio>()),
  );
  it.registerFactory<CrearTipoEventoCubit>(
    () => CrearTipoEventoCubit(it<TiposEventoRepositorio>()),
  );

  it.registerLazySingleton<RevisionUsuariosRepositorio>(
    () => RevisionUsuariosRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<RevisionUsuariosCubit>(
    () => RevisionUsuariosCubit(it<RevisionUsuariosRepositorio>()),
  );
}
