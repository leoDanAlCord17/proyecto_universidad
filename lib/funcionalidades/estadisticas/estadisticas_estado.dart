import 'estadisticas_modelo.dart';
import 'filtros_estadisticas.dart';

sealed class EstadisticasEstado {
  const EstadisticasEstado();
}

final class EstadisticasInicial extends EstadisticasEstado {
  const EstadisticasInicial();
}

final class EstadisticasCargando extends EstadisticasEstado {
  const EstadisticasCargando();
}

final class EstadisticasCargadas extends EstadisticasEstado {
  const EstadisticasCargadas({
    required this.filtros,
    required this.resumen,
    required this.porTipo,
    required this.porMes,
    required this.porEstatus,
    required this.topEventos,
    required this.porDiaSemana,
    required this.porCreador,
    required this.opciones,
    // v3
    required this.tasaPorTipo,
    required this.tendenciaDual,
    required this.escalaPorTamano,
    required this.topTags,
    required this.topAsistentes,
    required this.composicionMensual,
    required this.estadoEventos,
    required this.heatmapHora,
  });

  final FiltrosEstadisticas    filtros;
  final ResumenEstadisticas    resumen;
  final List<DatoGrafica>      porTipo;
  final List<DatoGrafica>      porMes;
  final List<DatoGrafica>      porEstatus;
  final List<EventoTopStat>    topEventos;
  final List<DatoGrafica>      porDiaSemana;
  final List<DatoCreador>      porCreador;
  final OpcionesFiltros        opciones;
  // v3
  final List<DatoTasaTipo>      tasaPorTipo;
  final List<DatoTendenciaDual> tendenciaDual;
  final List<DatoGrafica>       escalaPorTamano;
  final List<DatoTag>           topTags;
  final List<AsistenteFrecuente> topAsistentes;
  final List<ComposicionMes>    composicionMensual;
  final List<DatoGrafica>       estadoEventos;
  final List<DatoHeatmap>       heatmapHora;
}

final class EstadisticasError extends EstadisticasEstado {
  const EstadisticasError(this.mensaje);

  final String mensaje;
}
