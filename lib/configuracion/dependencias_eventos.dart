import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../funcionalidades/auditoria_evento/auditoria_evento_cubit.dart';
import '../funcionalidades/auditoria_evento/auditoria_evento_repositorio.dart';
import '../funcionalidades/borradores/borradores_cubit.dart';
import '../funcionalidades/borradores/borradores_repositorio.dart';
import '../funcionalidades/buscar_asistente/buscar_asistente_cubit.dart';
import '../funcionalidades/buscar_asistente/buscar_asistente_repositorio.dart';
import '../funcionalidades/colaboradores_evento/colaboradores_evento_cubit.dart';
import '../funcionalidades/colaboradores_evento/colaboradores_evento_repositorio.dart';
import '../funcionalidades/crear_evento/crear_evento_cubit.dart';
import '../funcionalidades/crear_evento/crear_evento_repositorio.dart';
import '../funcionalidades/escanear_evento_qr/escanear_evento_qr_cubit.dart';
import '../funcionalidades/escanear_evento_qr/escanear_evento_qr_repositorio.dart';
import '../funcionalidades/escanear_qr/escanear_qr_cubit.dart';
import '../funcionalidades/escanear_qr/escanear_qr_repositorio.dart';
import '../funcionalidades/eventos/eventos_cubit.dart';
import '../funcionalidades/eventos/eventos_repositorio.dart';
import '../funcionalidades/inicio/eventos_en_curso_cubit.dart';
import '../funcionalidades/inicio/eventos_en_curso_repositorio.dart';
import '../funcionalidades/panel_control_evento/panel_control_cubit.dart';
import '../funcionalidades/panel_control_evento/panel_control_repositorio.dart';

void configurarDependenciasEventos(GetIt it) {
  it.registerLazySingleton<EventosRepositorio>(
    () => EventosRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<EventosCubit>(
    () => EventosCubit(it<EventosRepositorio>()),
  );

  it.registerLazySingleton<CrearEventoRepositorio>(
    () => CrearEventoRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<CrearEventoCubit>(
    () => CrearEventoCubit(it<CrearEventoRepositorio>()),
  );

  it.registerLazySingleton<BorradoresRepositorio>(
    () => BorradoresRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<BorradoresCubit>(
    () => BorradoresCubit(it<BorradoresRepositorio>()),
  );

  it.registerLazySingleton<EventosEnCursoRepositorio>(
    () => EventosEnCursoRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<EventosEnCursoCubit>(
    () => EventosEnCursoCubit(it<EventosEnCursoRepositorio>()),
  );

  it.registerLazySingleton<PanelControlRepositorio>(
    () => PanelControlRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<PanelControlCubit>(
    () => PanelControlCubit(it<PanelControlRepositorio>()),
  );

  it.registerLazySingleton<BuscarAsistenteRepositorio>(
    () => BuscarAsistenteRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<BuscarAsistenteCubit>(
    () => BuscarAsistenteCubit(it<BuscarAsistenteRepositorio>()),
  );

  it.registerLazySingleton<EscanearQrRepositorio>(
    () => EscanearQrRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<EscanearQrCubit>(
    () => EscanearQrCubit(it<EscanearQrRepositorio>()),
  );

  it.registerLazySingleton<EscanearEventoQrRepositorio>(
    () => EscanearEventoQrRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<EscanearEventoQrCubit>(
    () => EscanearEventoQrCubit(it<EscanearEventoQrRepositorio>()),
  );

  it.registerLazySingleton<ColaboradoresEventoRepositorio>(
    () => ColaboradoresEventoRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<ColaboradoresEventoCubit>(
    () => ColaboradoresEventoCubit(it<ColaboradoresEventoRepositorio>()),
  );

  it.registerLazySingleton<AuditoriaEventoRepositorio>(
    () => AuditoriaEventoRepositorio(it<SupabaseClient>()),
  );
  it.registerFactory<AuditoriaEventoCubit>(
    () => AuditoriaEventoCubit(it<AuditoriaEventoRepositorio>()),
  );
}
