import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../compartido/avatar_repositorio.dart';
import 'dependencias_ajustes.dart';
import 'dependencias_auth.dart';
import 'dependencias_eventos.dart';
import 'dependencias_personal.dart';

/// Instancia global de GetIt. Se usa en toda la app como obtenerIt<Tipo>().
final obtenerIt = GetIt.instance;

/// Registra todas las dependencias de la app.
/// Se llama una sola vez en main.dart, después de inicializar Supabase.
void configurarDependencias() {
  // ─── INFRAESTRUCTURA ─────────────────────────────────────────────────────
  obtenerIt.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );
  obtenerIt.registerLazySingleton<AvatarRepositorio>(
    () => AvatarRepositorio(obtenerIt<SupabaseClient>()),
  );

  // ─── DOMINIOS ────────────────────────────────────────────────────────────
  configurarDependenciasAuth(obtenerIt);
  configurarDependenciasEventos(obtenerIt);
  configurarDependenciasAjustes(obtenerIt);
  configurarDependenciasPersonal(obtenerIt);
}
