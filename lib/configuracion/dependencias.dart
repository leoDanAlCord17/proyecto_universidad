import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../funcionalidades/autenticacion/auth_cubit.dart';
import '../funcionalidades/autenticacion/autenticacion_repositorio.dart';
import '../funcionalidades/autenticacion/login_cubit.dart';
import '../funcionalidades/autenticacion/registro_cubit.dart';
import '../funcionalidades/crear_usuario/crear_usuario_cubit.dart';
import '../funcionalidades/borradores/borradores_cubit.dart';
import '../funcionalidades/borradores/borradores_repositorio.dart';
import '../funcionalidades/crear_evento/crear_evento_cubit.dart';
import '../funcionalidades/crear_evento/crear_evento_repositorio.dart';
import '../funcionalidades/inicio/inicio_cubit.dart';
import '../funcionalidades/inicio/inicio_repositorio.dart';
import '../funcionalidades/perfil/perfil_cubit.dart';
import '../funcionalidades/perfil/perfil_repositorio.dart';
import '../funcionalidades/permisos/permisos_cubit.dart';
import '../funcionalidades/permisos/permisos_repositorio.dart';
import '../funcionalidades/roles/roles_cubit.dart';
import '../funcionalidades/roles/roles_repositorio.dart';
import '../funcionalidades/crear_rol/crear_rol_cubit.dart';
import '../funcionalidades/crear_rol/crear_rol_repositorio.dart';
import '../funcionalidades/tags/tags_cubit.dart';
import '../funcionalidades/tags/tags_repositorio.dart';
import '../funcionalidades/usuarios/usuarios_cubit.dart';
import '../funcionalidades/usuarios/usuarios_repositorio.dart';
import '../funcionalidades/gestionar_tags_usuario/gestionar_tags_usuario_cubit.dart';
import '../funcionalidades/gestionar_tags_usuario/gestionar_tags_usuario_repositorio.dart';
import '../funcionalidades/crear_tag/crear_tag_cubit.dart';
import '../funcionalidades/crear_tag/crear_tag_repositorio.dart';
import '../funcionalidades/eventos/eventos_cubit.dart';
import '../funcionalidades/eventos/eventos_repositorio.dart';
import '../funcionalidades/recuperar_contrasena/recuperar_contrasena_cubit.dart';
import '../funcionalidades/nueva_contrasena/nueva_contrasena_cubit.dart';
import '../funcionalidades/gestionar_roles_usuario/gestionar_roles_usuario_cubit.dart';
import '../funcionalidades/gestionar_roles_usuario/gestionar_roles_usuario_repositorio.dart';
import '../funcionalidades/ver_perfil_usuario/ver_perfil_usuario_cubit.dart';
import '../funcionalidades/ver_perfil_usuario/ver_perfil_usuario_repositorio.dart';
import '../funcionalidades/editar_usuario/editar_usuario_cubit.dart';
import '../funcionalidades/editar_usuario/editar_usuario_repositorio.dart';
import '../funcionalidades/panel_control_evento/panel_control_cubit.dart';
import '../funcionalidades/panel_control_evento/panel_control_repositorio.dart';
import '../funcionalidades/buscar_asistente/buscar_asistente_cubit.dart';
import '../funcionalidades/buscar_asistente/buscar_asistente_repositorio.dart';
import '../funcionalidades/escanear_qr/escanear_qr_cubit.dart';
import '../funcionalidades/escanear_qr/escanear_qr_repositorio.dart';
import '../funcionalidades/escanear_evento_qr/escanear_evento_qr_cubit.dart';
import '../funcionalidades/escanear_evento_qr/escanear_evento_qr_repositorio.dart';
import '../funcionalidades/notificaciones/notificaciones_cubit.dart';
import '../funcionalidades/tipos_evento/crear_tipo_evento_cubit.dart';
import '../funcionalidades/tipos_evento/tipos_evento_cubit.dart';
import '../funcionalidades/tipos_evento/tipos_evento_repositorio.dart';

/// Instancia global de GetIt. Se usa en toda la app como obtenerIt<Tipo>().
final obtenerIt = GetIt.instance;

/// Registra todas las dependencias de la app.
/// Se llama una sola vez en main.dart, después de inicializar Supabase.
void configurarDependencias() {
  // ─── INFRAESTRUCTURA ─────────────────────────────────
  // El cliente de Supabase: singleton porque es una sola conexión
  obtenerIt.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // ─── REPOSITORIOS ────────────────────────────────────
  // Singleton: no guardan estado mutable, solo ejecutan consultas
  obtenerIt.registerLazySingleton<AutenticacionRepositorio>(
    () => AutenticacionRepositorio(obtenerIt<SupabaseClient>()),
  );

  // ─── CUBITS GLOBALES ─────────────────────────────────
  // AuthCubit: singleton porque toda la app lo necesita activo
  obtenerIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(obtenerIt<AutenticacionRepositorio>()),
  );

  // ─── CUBITS DE PANTALLA ──────────────────────────────
  // Factory: cada pantalla recibe una instancia nueva y limpia
  obtenerIt.registerFactory<LoginCubit>(
    () => LoginCubit(obtenerIt<AutenticacionRepositorio>()),
  );

  obtenerIt.registerFactory<RegistroCubit>(
    () => RegistroCubit(obtenerIt<AutenticacionRepositorio>()),
  );

  obtenerIt.registerFactory<CrearUsuarioCubit>(
    () => CrearUsuarioCubit(obtenerIt<AutenticacionRepositorio>()),
  );

  obtenerIt.registerLazySingleton<InicioRepositorio>(
    () => InicioRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<InicioCubit>(
    () => InicioCubit(obtenerIt<InicioRepositorio>()),
  );

  obtenerIt.registerLazySingleton<PerfilRepositorio>(
    () => PerfilRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<PerfilCubit>(
    () => PerfilCubit(obtenerIt<PerfilRepositorio>()),
  );

  obtenerIt.registerLazySingleton<CrearEventoRepositorio>(
    () => CrearEventoRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<CrearEventoCubit>(
    () => CrearEventoCubit(obtenerIt<CrearEventoRepositorio>()),
  );

  obtenerIt.registerLazySingleton<BorradoresRepositorio>(
    () => BorradoresRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<BorradoresCubit>(
    () => BorradoresCubit(obtenerIt<BorradoresRepositorio>()),
  );

  obtenerIt.registerLazySingleton<PermisosRepositorio>(
    () => PermisosRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<PermisosCubit>(
    () => PermisosCubit(obtenerIt<PermisosRepositorio>()),
  );

  obtenerIt.registerLazySingleton<RolesRepositorio>(
    () => RolesRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<RolesCubit>(
    () => RolesCubit(obtenerIt<RolesRepositorio>()),
  );

  obtenerIt.registerLazySingleton<CrearRolRepositorio>(
    () => CrearRolRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<CrearRolCubit>(
    () => CrearRolCubit(obtenerIt<CrearRolRepositorio>()),
  );

  obtenerIt.registerLazySingleton<UsuariosRepositorio>(
    () => UsuariosRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<UsuariosCubit>(
    () => UsuariosCubit(obtenerIt<UsuariosRepositorio>()),
  );

  obtenerIt.registerLazySingleton<GestionarTagsUsuarioRepositorio>(
    () => GestionarTagsUsuarioRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<GestionarTagsUsuarioCubit>(
    () => GestionarTagsUsuarioCubit(obtenerIt<GestionarTagsUsuarioRepositorio>()),
  );

  obtenerIt.registerLazySingleton<TagsRepositorio>(
    () => TagsRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<TagsCubit>(
    () => TagsCubit(obtenerIt<TagsRepositorio>()),
  );

  obtenerIt.registerLazySingleton<CrearTagRepositorio>(
    () => CrearTagRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<CrearTagCubit>(
    () => CrearTagCubit(obtenerIt<CrearTagRepositorio>()),
  );

  obtenerIt.registerLazySingleton<EventosRepositorio>(
    () => EventosRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<EventosCubit>(
    () => EventosCubit(obtenerIt<EventosRepositorio>()),
  );

  obtenerIt.registerFactory<RecuperarContrasenaCubit>(
    () => RecuperarContrasenaCubit(obtenerIt<AutenticacionRepositorio>()),
  );

  obtenerIt.registerFactory<NuevaContrasenaCubit>(
    () => NuevaContrasenaCubit(obtenerIt<AutenticacionRepositorio>()),
  );

  obtenerIt.registerLazySingleton<GestionarRolesUsuarioRepositorio>(
    () => GestionarRolesUsuarioRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<GestionarRolesUsuarioCubit>(
    () => GestionarRolesUsuarioCubit(obtenerIt<GestionarRolesUsuarioRepositorio>()),
  );

  obtenerIt.registerLazySingleton<VerPerfilUsuarioRepositorio>(
    () => VerPerfilUsuarioRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<VerPerfilUsuarioCubit>(
    () => VerPerfilUsuarioCubit(obtenerIt<VerPerfilUsuarioRepositorio>()),
  );

  obtenerIt.registerLazySingleton<EditarUsuarioRepositorio>(
    () => EditarUsuarioRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<EditarUsuarioCubit>(
    () => EditarUsuarioCubit(obtenerIt<EditarUsuarioRepositorio>()),
  );

  obtenerIt.registerLazySingleton<PanelControlRepositorio>(
    () => PanelControlRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<PanelControlCubit>(
    () => PanelControlCubit(obtenerIt<PanelControlRepositorio>()),
  );

  obtenerIt.registerLazySingleton<BuscarAsistenteRepositorio>(
    () => BuscarAsistenteRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<BuscarAsistenteCubit>(
    () => BuscarAsistenteCubit(obtenerIt<BuscarAsistenteRepositorio>()),
  );

  obtenerIt.registerLazySingleton<EscanearQrRepositorio>(
    () => EscanearQrRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<EscanearQrCubit>(
    () => EscanearQrCubit(obtenerIt<EscanearQrRepositorio>()),
  );

  obtenerIt.registerLazySingleton<EscanearEventoQrRepositorio>(
    () => EscanearEventoQrRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<EscanearEventoQrCubit>(
    () => EscanearEventoQrCubit(obtenerIt<EscanearEventoQrRepositorio>()),
  );

  obtenerIt.registerFactory<NotificacionesCubit>(
    () => NotificacionesCubit(),
  );

  obtenerIt.registerLazySingleton<TiposEventoRepositorio>(
    () => TiposEventoRepositorio(obtenerIt<SupabaseClient>()),
  );

  obtenerIt.registerFactory<TiposEventoCubit>(
    () => TiposEventoCubit(obtenerIt<TiposEventoRepositorio>()),
  );

  obtenerIt.registerFactory<CrearTipoEventoCubit>(
    () => CrearTipoEventoCubit(obtenerIt<TiposEventoRepositorio>()),
  );
}
