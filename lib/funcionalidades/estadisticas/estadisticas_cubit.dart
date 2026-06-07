import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'estadisticas_estado.dart';
import 'estadisticas_modelo.dart';
import 'estadisticas_repositorio.dart';
import 'filtros_estadisticas.dart';

class EstadisticasCubit extends Cubit<EstadisticasEstado> {
  EstadisticasCubit(this._repositorio) : super(const EstadisticasInicial());

  final EstadisticasRepositorio _repositorio;

  /// Carga todas las secciones en paralelo.
  Future<void> cargar(FiltrosEstadisticas filtros) async {
    emit(const EstadisticasCargando());
    try {
      emit(await _resolverTodo(filtros));
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(EstadisticasError(e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(EstadisticasError(e.mensaje));
    }
  }

  /// Lanza los 16 futures en paralelo y construye el estado cargado.
  Future<EstadisticasCargadas> _resolverTodo(
      FiltrosEstadisticas filtros) async {
    // v2
    final resumenFuture = _repositorio.obtenerResumen(filtros);
    final porTipoFuture = _repositorio.obtenerEventosPorTipo(filtros);
    final porMesFuture = _repositorio.obtenerEventosPorMes(filtros);
    final porEstatusFuture = _repositorio.obtenerAsistenciaPorEstatus(filtros);
    final topFuture = _repositorio.obtenerTopEventos(filtros);
    final porDiaFuture = _repositorio.obtenerAsistenciaDiaSemana(filtros);
    final porCreadorFuture = _repositorio.obtenerEventosPorCreador(filtros);
    final opcionesFuture = _repositorio.obtenerOpciones(filtros);
    // v3
    final tasaPorTipoFuture = _repositorio.obtenerTasaPorTipo(filtros);
    final tendenciaFuture = _repositorio.obtenerTendenciaDual(filtros);
    final escalaFuture = _repositorio.obtenerEscalaEventos(filtros);
    final topTagsFuture = _repositorio.obtenerTopTags(filtros);
    final topAsistentesFuture = _repositorio.obtenerTopAsistentes(filtros);
    final composicionFuture = _repositorio.obtenerComposicionMensual(filtros);
    final estadoFuture = _repositorio.obtenerEstadoEventos(filtros);
    final heatmapFuture = _repositorio.obtenerHeatmapHora(filtros);

    await Future.wait([
      resumenFuture,
      porTipoFuture,
      porMesFuture,
      porEstatusFuture,
      topFuture,
      porDiaFuture,
      porCreadorFuture,
      opcionesFuture,
      tasaPorTipoFuture,
      tendenciaFuture,
      escalaFuture,
      topTagsFuture,
      topAsistentesFuture,
      composicionFuture,
      estadoFuture,
      heatmapFuture,
    ]);

    return EstadisticasCargadas(
      filtros: filtros,
      resumen: await resumenFuture,
      porTipo: await porTipoFuture,
      porMes: await porMesFuture,
      porEstatus: await porEstatusFuture,
      topEventos: await topFuture,
      porDiaSemana: await porDiaFuture,
      porCreador: await porCreadorFuture,
      opciones: await opcionesFuture,
      tasaPorTipo: await tasaPorTipoFuture,
      tendenciaDual: await tendenciaFuture,
      escalaPorTamano: await escalaFuture,
      topTags: await topTagsFuture,
      topAsistentes: await topAsistentesFuture,
      composicionMensual: await composicionFuture,
      estadoEventos: await estadoFuture,
      heatmapHora: await heatmapFuture,
    );
  }

  /// Retorna detalle de eventos para drill-down sin cambiar el estado principal.
  Future<List<EventoResumido>> cargarDetalle({
    required FiltrosEstadisticas filtros,
    required String dimension,
    required String valor,
  }) =>
      _repositorio.obtenerDetalleEventos(
        filtros: filtros,
        dimension: dimension,
        valor: valor,
      );
}
