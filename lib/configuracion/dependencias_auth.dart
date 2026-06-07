import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../funcionalidades/autenticacion/auth_cubit.dart';
import '../funcionalidades/autenticacion/autenticacion_repositorio.dart';
import '../funcionalidades/autenticacion/login_cubit.dart';
import '../funcionalidades/autenticacion/registro_cubit.dart';
import '../funcionalidades/crear_usuario/crear_usuario_cubit.dart';
import '../funcionalidades/nueva_contrasena/nueva_contrasena_cubit.dart';
import '../funcionalidades/recuperar_contrasena/recuperar_contrasena_cubit.dart';

void configurarDependenciasAuth(GetIt it) {
  it.registerLazySingleton<AutenticacionRepositorio>(
    () => AutenticacionRepositorio(it<SupabaseClient>()),
  );

  it.registerLazySingleton<AuthCubit>(
    () => AuthCubit(it<AutenticacionRepositorio>()),
  );

  it.registerFactory<LoginCubit>(
    () => LoginCubit(it<AutenticacionRepositorio>()),
  );

  it.registerFactory<RegistroCubit>(
    () => RegistroCubit(it<AutenticacionRepositorio>()),
  );

  it.registerFactory<CrearUsuarioCubit>(
    () => CrearUsuarioCubit(it<AutenticacionRepositorio>()),
  );

  it.registerFactory<RecuperarContrasenaCubit>(
    () => RecuperarContrasenaCubit(it<AutenticacionRepositorio>()),
  );

  it.registerFactory<NuevaContrasenaCubit>(
    () => NuevaContrasenaCubit(it<AutenticacionRepositorio>()),
  );
}
