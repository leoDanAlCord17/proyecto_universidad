import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../compartido/constantes.dart';
import '../../../configuracion/colores_app.dart';
import '../estadisticas_estado.dart';
import '../estadisticas_modelo.dart';
import '../filtros_estadisticas.dart';
import 'estilos_estadisticas.dart';
import 'grafica_embudo.dart';
import 'graficas_distribucion.dart';
import 'graficas_tendencias.dart';
import 'seccion_estado_eventos.dart';
import 'secciones_rankings.dart';

class CuerpoEstadisticas extends StatelessWidget {
  const CuerpoEstadisticas({
    required this.datos,
    required this.onDetalle,
    required this.onQuitarTipo,
    required this.onQuitarCreador,
    required this.onQuitarTag,
  });

  final EstadisticasCargadas datos;
  final void Function(String, DatoGrafica) onDetalle;
  final ValueChanged<OpcionFiltro> onQuitarTipo;
  final ValueChanged<OpcionFiltro> onQuitarCreador;
  final ValueChanged<OpcionFiltro> onQuitarTag;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (datos.filtros.tieneFiltrosActivos) ...[
            _ChipsFiltrosActivos(
              filtros: datos.filtros,
              onQuitarTipo: onQuitarTipo,
              onQuitarCreador: onQuitarCreador,
              onQuitarTag: onQuitarTag,
            ),
            const SizedBox(height: 12),
          ],
          ..._seccionSuperior(context),
          ..._seccionMedia(),
          ..._seccionInferior(),
        ],
      ),
    );
  }

  List<Widget> _seccionSuperior(BuildContext context) => [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => context.push(Rutas.auditoriaEvento),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ColoresApp.tealClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.manage_search_rounded,
                      color: ColoresApp.teal, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Auditoría por evento',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: ColoresApp.teal,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _SeccionKpis(resumen: datos.resumen),
        const SizedBox(height: 12),
        TarjetaGrafica(
          titulo: 'Embudo de asistencia',
          subtitulo: 'Conversión de convocados a completados',
          child: GraficaEmbudo(porEstatus: datos.porEstatus),
        ),
        const SizedBox(height: 16),
        SeccionEstadoEventos(estadoEventos: datos.estadoEventos),
        const SizedBox(height: 16),
        TarjetaGrafica(
          titulo: 'Tendencia mensual',
          subtitulo: 'Volumen de eventos y tasa de asistencia por mes',
          altura: 220,
          child: GraficaTendenciaDual(
            datos: datos.tendenciaDual,
            onTap: (d) => onDetalle('mes', d),
          ),
        ),
        const SizedBox(height: 16),
        if (datos.composicionMensual.isNotEmpty) ...[
          TarjetaGrafica(
            titulo: 'Composición por tipo',
            subtitulo: 'Distribución de tipos de evento por mes',
            altura: 240,
            child: GraficaComposicion(
              datos: datos.composicionMensual,
              onTap: (d) => onDetalle('mes', d),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ];

  List<Widget> _seccionMedia() => [
        TarjetaGrafica(
          titulo: 'Por tipo de evento',
          subtitulo: 'Distribución según categoría',
          altura: 220,
          child: GraficaDonut(
            datos: datos.porTipo,
            onTap: (d) => onDetalle('tipo', d),
          ),
        ),
        const SizedBox(height: 16),
        if (datos.tasaPorTipo.isNotEmpty) ...[
          TarjetaGrafica(
            titulo: 'Calidad por tipo de evento',
            subtitulo: 'Tasa de asistencia según categoría',
            child: GraficaTasaPorTipo(datos: datos.tasaPorTipo),
          ),
          const SizedBox(height: 16),
        ],
        TarjetaGrafica(
          titulo: 'Asistencia por estatus',
          subtitulo: 'Toca una barra para ver los eventos',
          altura: 200,
          child: GraficaBarrasEstatus(
            datos: datos.porEstatus,
            onTap: (d) => onDetalle('estatus_asistencia', d),
          ),
        ),
        const SizedBox(height: 16),
        SeccionPorCreador(
          porCreador: datos.porCreador,
          onTap: (d) => onDetalle('creador', d.toDatoGrafica()),
        ),
        const SizedBox(height: 16),
        if (datos.topAsistentes.isNotEmpty) ...[
          SeccionTopAsistentes(datos: datos.topAsistentes),
          const SizedBox(height: 16),
        ],
      ];

  List<Widget> _seccionInferior() => [
        TarjetaGrafica(
          titulo: 'Actividad por día',
          subtitulo: 'Asistentes presentes según día de semana',
          altura: 180,
          child: GraficaBarrasDia(
            datos: datos.porDiaSemana,
            onTap: (d) => onDetalle('dia_semana', d),
          ),
        ),
        const SizedBox(height: 16),
        if (datos.heatmapHora.isNotEmpty) ...[
          TarjetaGrafica(
            titulo: 'Horario de asistencia',
            subtitulo: 'Entradas registradas por hora y día de semana',
            child: GraficaHeatmap(datos: datos.heatmapHora),
          ),
          const SizedBox(height: 16),
        ],
        TarjetaGrafica(
          titulo: 'Escala de eventos',
          subtitulo: 'Distribución por número de asistentes',
          altura: 180,
          child: GraficaEscala(datos: datos.escalaPorTamano),
        ),
        const SizedBox(height: 16),
        if (datos.topTags.isNotEmpty) ...[
          SeccionTopTags(
            datos: datos.topTags,
            onTap: (d) => onDetalle('tipo', d),
          ),
          const SizedBox(height: 16),
        ],
        SeccionTopEventos(topEventos: datos.topEventos),
      ];
}

// ─── Chips de filtros activos ─────────────────────────────────────────────────

class _ChipsFiltrosActivos extends StatelessWidget {
  const _ChipsFiltrosActivos({
    required this.filtros,
    required this.onQuitarTipo,
    required this.onQuitarCreador,
    required this.onQuitarTag,
  });

  final FiltrosEstadisticas filtros;
  final ValueChanged<OpcionFiltro> onQuitarTipo;
  final ValueChanged<OpcionFiltro> onQuitarCreador;
  final ValueChanged<OpcionFiltro> onQuitarTag;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final o in filtros.tiposSeleccionados)
          _ChipFiltro(
            prefijo: 'Tipo',
            nombre: o.nombre,
            color: ColoresApp.acento,
            fondo: ColoresApp.acentoClaro,
            alQuitar: () => onQuitarTipo(o),
          ),
        for (final o in filtros.creadoresSeleccionados)
          _ChipFiltro(
            prefijo: 'Creador',
            nombre: o.nombre,
            color: ColoresApp.teal,
            fondo: ColoresApp.tealClaro,
            alQuitar: () => onQuitarCreador(o),
          ),
        for (final o in filtros.tagsSeleccionados)
          _ChipFiltro(
            prefijo: 'Tag',
            nombre: o.nombre,
            color: ColoresApp.ambar,
            fondo: ColoresApp.ambarClaro,
            alQuitar: () => onQuitarTag(o),
          ),
      ],
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.prefijo,
    required this.nombre,
    required this.color,
    required this.fondo,
    required this.alQuitar,
  });

  final String prefijo;
  final String nombre;
  final Color color;
  final Color fondo;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$prefijo: ',
            style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500),
          ),
          Text(
            nombre,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: alQuitar,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── KPIs ─────────────────────────────────────────────────────────────────────

class _SeccionKpis extends StatelessWidget {
  const _SeccionKpis({required this.resumen});
  final ResumenEstadisticas resumen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TarjetaKpi(
                icono: Icons.event_outlined,
                valor: '${resumen.totalEventos}',
                label: 'Eventos',
                color: ColoresApp.acento,
                fondo: ColoresApp.acentoClaro,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TarjetaKpi(
                icono: Icons.people_outline_rounded,
                valor: '${resumen.totalAsistencias}',
                label: 'Asistencias',
                color: ColoresApp.verde,
                fondo: ColoresApp.verdeClaro,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TarjetaKpi(
                icono: Icons.percent_rounded,
                valor: '${resumen.tasaAsistencia.toStringAsFixed(1)}%',
                label: 'Tasa asistencia',
                color: ColoresApp.ambar,
                fondo: ColoresApp.ambarClaro,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TarjetaKpi(
                icono: Icons.person_outline_rounded,
                valor: '${resumen.usuariosActivos}',
                label: 'Usuarios activos',
                color: ColoresApp.teal,
                fondo: ColoresApp.tealClaro,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TarjetaKpi extends StatelessWidget {
  const _TarjetaKpi({
    required this.icono,
    required this.valor,
    required this.label,
    required this.color,
    required this.fondo,
  });

  final IconData icono;
  final String valor;
  final String label;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: ColoresApp.sombraTarjeta,
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: fondo, borderRadius: BorderRadius.circular(10)),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ColoresApp.textoPrimario,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColoresApp.textoTerciario,
                ),
          ),
        ],
      ),
    );
  }
}
