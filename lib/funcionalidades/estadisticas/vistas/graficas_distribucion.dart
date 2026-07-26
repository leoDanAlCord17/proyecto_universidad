import 'dart:math' show max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';
import '../estadisticas_modelo.dart';
import 'estilos_estadisticas.dart';

class GraficaDonut extends StatefulWidget {
  const GraficaDonut({required this.datos, required this.onTap});
  final List<DatoGrafica> datos;
  final ValueChanged<DatoGrafica> onTap;

  @override
  State<GraficaDonut> createState() => _GraficaDonutState();
}

class _GraficaDonutState extends State<GraficaDonut> {
  int? _seleccionado;

  @override
  Widget build(BuildContext context) {
    if (widget.datos.isEmpty) return const SinDatos();
    final total = widget.datos.fold<double>(0, (s, d) => s + d.valor);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions) {
                    setState(() => _seleccionado = null);
                    return;
                  }
                  final i = response?.touchedSection?.touchedSectionIndex ?? -1;
                  setState(() => _seleccionado = i >= 0 ? i : null);
                  if (event is FlTapUpEvent &&
                      i >= 0 &&
                      i < widget.datos.length) {
                    widget.onTap(widget.datos[i]);
                  }
                },
              ),
              sections: List.generate(widget.datos.length, (i) {
                final d = widget.datos[i];
                final color = paleta[i % paleta.length];
                final activo = _seleccionado == i;
                final pct = total == 0 ? 0.0 : d.valor / total;
                return PieChartSectionData(
                  value: d.valor,
                  color: color,
                  radius: activo ? 58 : 50,
                  title: '${(pct * 100).toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ColoresApp.blanco,
                  ),
                );
              }),
              centerSpaceRadius: 44,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
            child: _LeyendaDonut(
                datos: widget.datos, seleccionado: _seleccionado)),
      ],
    );
  }
}

class _LeyendaDonut extends StatelessWidget {
  const _LeyendaDonut({required this.datos, required this.seleccionado});
  final List<DatoGrafica> datos;
  final int? seleccionado;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(datos.length, (i) {
        final color = paleta[i % paleta.length];
        final activo = seleccionado == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: activo ? 12 : 10,
                height: activo ? 12 : 10,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  datos[i].etiqueta,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: activo
                            ? ColoresApp.textoPrimario
                            : ColoresApp.textoSecundario,
                        fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                ),
              ),
              Text(
                '${datos[i].valor.toInt()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: activo ? color : ColoresApp.textoPrimario,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Tasa de asistencia por tipo ──────────────────────────────────────────────

class GraficaTasaPorTipo extends StatelessWidget {
  const GraficaTasaPorTipo({required this.datos});
  final List<DatoTasaTipo> datos;

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const SinDatos();
    return Column(
      children: datos
          .map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          d.tipoNombre,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${d.tasa.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colorTasa(d.tasa),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: d.tasa / 100,
                      minHeight: 10,
                      backgroundColor: ColoresApp.superficieTerciar,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorTasa(d.tasa)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.presentes} presentes · ${d.totalRegistros} registros · ${d.totalEventos} eventos',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresApp.textoTerciario,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Barras por estatus ───────────────────────────────────────────────────────

class GraficaBarrasEstatus extends StatelessWidget {
  const GraficaBarrasEstatus({required this.datos, required this.onTap});
  final List<DatoGrafica> datos;
  final ValueChanged<DatoGrafica> onTap;

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const SinDatos();
    final maxY = datos.map((d) => d.valor).reduce(max);

    return BarChart(
      BarChartData(
        maxY: (maxY * 1.35).ceilToDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: ColoresApp.bordesuave, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions) return;
            if (event is! FlTapUpEvent) return;
            final i = response?.spot?.touchedBarGroupIndex ?? -1;
            if (i >= 0 && i < datos.length) onTap(datos[i]);
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => ColoresApp.textoPrimario,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${rod.toY.toInt()}',
              const TextStyle(
                  color: ColoresApp.blanco,
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (valor, meta) {
                final i = valor.toInt();
                if (i < 0 || i >= datos.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    datos[i].etiqueta,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: ColoresApp.textoTerciario,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(
          datos.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: datos[i].valor,
                color: colorEstatus(datos[i].etiqueta),
                width: 28,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Barras por día de semana ─────────────────────────────────────────────────

class GraficaBarrasDia extends StatelessWidget {
  const GraficaBarrasDia({required this.datos, required this.onTap});
  final List<DatoGrafica> datos;
  final ValueChanged<DatoGrafica> onTap;

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const SinDatos();
    final maxY = datos.map((d) => d.valor).reduce(max);

    return BarChart(
      BarChartData(
        maxY: (maxY * 1.35).ceilToDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: ColoresApp.bordesuave, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions) return;
            if (event is! FlTapUpEvent) return;
            final i = response?.spot?.touchedBarGroupIndex ?? -1;
            if (i >= 0 && i < datos.length) onTap(datos[i]);
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => ColoresApp.textoPrimario,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${rod.toY.toInt()} asistentes',
              const TextStyle(
                  color: ColoresApp.blanco,
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (valor, meta) {
                final i = valor.toInt();
                if (i < 0 || i >= datos.length) return const SizedBox.shrink();
                final activo = datos[i].valor == maxY;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    datos[i].etiqueta,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                      color:
                          activo ? ColoresApp.teal : ColoresApp.textoTerciario,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(datos.length, (i) {
          final activo = datos[i].valor == maxY;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: datos[i].valor,
                color: activo
                    ? ColoresApp.teal
                    : ColoresApp.teal.withValues(alpha: 0.45),
                width: 22,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Mapa de calor de hora de entrada ────────────────────────────────────────

class GraficaHeatmap extends StatelessWidget {
  const GraficaHeatmap({required this.datos});
  final List<DatoHeatmap> datos;

  static const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const SinDatos();

    final maxCant = datos.map((d) => d.cantidad).reduce(max).toDouble();
    final horas = datos.map((d) => d.hora).toSet().toList()..sort();
    final mapa = {for (final d in datos) '${d.dia}_${d.hora}': d.cantidad};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 44),
              ..._dias.map(
                (d) => SizedBox(
                  width: 38,
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: ColoresApp.textoTerciario,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...horas.map(
            (hora) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${hora.toString().padLeft(2, '0')}h',
                      style: const TextStyle(
                          fontSize: 10, color: ColoresApp.textoTerciario),
                    ),
                  ),
                  ..._dias.map((dia) {
                    final cant = mapa['${dia}_$hora'] ?? 0;
                    final intensity = maxCant == 0 ? 0.0 : cant / maxCant;
                    return Container(
                      width: 34,
                      height: 24,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: intensity == 0
                            ? ColoresApp.superficieTerciar
                            : ColoresApp.acento
                                .withValues(alpha: 0.15 + intensity * 0.85),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: cant > 0
                          ? Center(
                              child: Text(
                                '$cant',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: intensity > 0.55
                                      ? ColoresApp.blanco
                                      : ColoresApp.acento,
                                ),
                              ),
                            )
                          : null,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Escala de eventos (histograma) ──────────────────────────────────────────

class GraficaEscala extends StatelessWidget {
  const GraficaEscala({required this.datos});
  final List<DatoGrafica> datos;

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const SinDatos();
    final maxY = datos.map((d) => d.valor).reduce(max);

    return BarChart(
      BarChartData(
        maxY: (maxY * 1.35).ceilToDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: ColoresApp.bordesuave, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => ColoresApp.textoPrimario,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${rod.toY.toInt()} eventos',
              const TextStyle(
                  color: ColoresApp.blanco,
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (valor, meta) {
                final i = valor.toInt();
                if (i < 0 || i >= datos.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    datos[i].etiqueta,
                    style: const TextStyle(
                      fontSize: 10,
                      color: ColoresApp.textoTerciario,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(datos.length, (i) {
          final pct = maxY == 0 ? 0.0 : datos[i].valor / maxY;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: datos[i].valor,
                color: ColoresApp.acento.withValues(alpha: 0.3 + pct * 0.7),
                width: 32,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }
}
