import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../funcionalidades/estadisticas/estadisticas_cubit.dart';
import '../funcionalidades/estadisticas/estadisticas_repositorio.dart';
import '../funcionalidades/historial/historial_cubit.dart';
import '../funcionalidades/historial/historial_repositorio.dart';
import '../funcionalidades/inicio/inicio_cubit.dart';
import '../funcionalidades/inicio/inicio_repositorio.dart';
import '../funcionalidades/notificaciones/notificaciones_cubit.dart';
import '../funcionalidades/notificaciones/notificaciones_repositorio.dart';
import '../funcionalidades/perfil/perfil_cubit.dart';
import '../funcionalidades/perfil/perfil_repositorio.dart';

void configurarDependenciasPersonal(GetIt it) {
  it.registerLazySingleton<InicioRepositorio>(
    () => InicioRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<InicioCubit>(
    () => InicioCubit(it<InicioRepositorio>()),
  );

  it.registerLazySingleton<PerfilRepositorio>(
    () => PerfilRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<PerfilCubit>(
    () => PerfilCubit(it<PerfilRepositorio>()),
  );

  it.registerLazySingleton<HistorialRepositorio>(
    () => HistorialRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<HistorialCubit>(
    () => HistorialCubit(it<HistorialRepositorio>()),
  );

  it.registerLazySingleton<EstadisticasRepositorio>(
    () => EstadisticasRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<EstadisticasCubit>(
    () => EstadisticasCubit(it<EstadisticasRepositorio>()),
  );

  it.registerLazySingleton<NotificacionesRepositorio>(
    () => NotificacionesRepositorio(it<SupabaseClient>()),
  );
  // Singleton: el badge de notificaciones necesita la misma instancia en toda la app
  it.registerLazySingleton<NotificacionesCubit>(
    () => NotificacionesCubit(it<NotificacionesRepositorio>()),
  );
}
