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
}
