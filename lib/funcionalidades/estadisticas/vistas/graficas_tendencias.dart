import 'dart:math' show max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';
import '../estadisticas_modelo.dart';
import 'estilos_estadisticas.dart';

class GraficaTendenciaDual extends StatelessWidget {
  const GraficaTendenciaDual({required this.datos, required this.onTap});

  final List<DatoTendenciaDual> datos;
  final ValueChanged<DatoGrafica> onTap;

  LineTouchData _touchData(double maxCant) => LineTouchData(
        touchCallback: (event, response) {
          if (!event.isInterestedForInteractions) return;
          final spots = response?.lineBarSpots;
          if (spots == null || spots.isEmpty) return;
          final i = spots.first.spotIndex;
          if (i >= 0 && i < datos.length) {
            onTap(DatoGrafica(
                etiqueta: datos[i].mes,
                valor: datos[i].cantidad,
                valorSql: datos[i].mes));
          }
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => ColoresApp.textoPrimario,
          getTooltipItems: (spots) => spots.map((s) {
            final isRate = s.barIndex == 1;
            return LineTooltipItem(
              isRate
                  ? '${s.y.toStringAsFixed(0)}% tasa'
                  : '${(maxCant == 0 ? 0 : s.y / 100 * maxCant).toInt()} eventos',
              TextStyle(
                color: isRate ? ColoresApp.verde : ColoresApp.acento2,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      );

  FlTitlesData _titlesData() => FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (valor, meta) {
              final i = valor.toInt();
              if (i < 0 || i >= datos.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  datos[i].mes,
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
      );

  @override
  Widget build(BuildContext context) {
    if (datos.length < 2) return const SinDatos();
    final maxCant = datos.map((d) => d.cantidad).reduce(max);

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (datos.length - 1).toDouble(),
              minY: 0,
              maxY: 100,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: ColoresApp.bordesuave, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: _touchData(maxCant),
              titlesData: _titlesData(),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    datos.length,
                    (i) => FlSpot(
                      i.toDouble(),
                      maxCant == 0 ? 0 : (datos[i].cantidad / maxCant * 100),
                    ),
                  ),
                  isCurved: true,
                  color: ColoresApp.acento,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: ColoresApp.acento.withValues(alpha: 0.06),
                  ),
                ),
                LineChartBarData(
                  spots: List.generate(
                    datos.length,
                    (i) => FlSpot(i.toDouble(), datos[i].tasa),
                  ),
                  isCurved: true,
                  color: ColoresApp.verde,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: ColoresApp.verde.withValues(alpha: 0.06),
                  ),
                  dashArray: [6, 3],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PuntoLeyenda(
                color: ColoresApp.acento, label: 'Eventos (relativo)'),
            SizedBox(width: 20),
            _PuntoLeyenda(color: ColoresApp.verde, label: 'Tasa asistencia %'),
          ],
        ),
      ],
    );
  }
}

class _PuntoLeyenda extends StatelessWidget {
  const _PuntoLeyenda({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColoresApp.textoSecundario,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}

// ─── Composición mensual (barras apiladas) ────────────────────────────────────

class GraficaComposicion extends StatelessWidget {
  const GraficaComposicion({required this.datos, required this.onTap});

  final List<ComposicionMes> datos;
  final ValueChanged<DatoGrafica> onTap;

  List<BarChartGroupData> _construirBarras(List<String> tipos) =>
      List.generate(datos.length, (i) {
        final mes = datos[i];
        double acum = 0;
        final stackItems = <BarChartRodStackItem>[];
        for (int j = 0; j < tipos.length; j++) {
          final val = mes.porTipo[tipos[j]] ?? 0;
          if (val > 0) {
            stackItems.add(BarChartRodStackItem(
                acum, acum + val, paleta[j % paleta.length]));
            acum += val;
          }
        }
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: acum,
              rodStackItems: stackItems,
              width: 18,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      });

  BarTouchData _touchData() => BarTouchData(
        touchCallback: (event, response) {
          if (!event.isInterestedForInteractions) return;
          if (event is! FlTapUpEvent) return;
          final i = response?.spot?.touchedBarGroupIndex ?? -1;
          if (i >= 0 && i < datos.length) {
            onTap(DatoGrafica(
                etiqueta: datos[i].mes,
                valor: datos[i].total,
                valorSql: datos[i].mes));
          }
        },
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
      );

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const SinDatos();

    final tiposSet = <String>{};
    for (final m in datos) {
      tiposSet.addAll(m.porTipo.keys);
    }
    final tipos = tiposSet.toList()..sort();
    final maxY = datos.map((m) => m.total).fold(0.0, max);

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: (maxY * 1.3).ceilToDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: ColoresApp.bordesuave, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: _touchData(),
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
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (val, meta) {
                      final i = val.toInt();
                      if (i < 0 || i >= datos.length)
                        return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          datos[i].mes,
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
              barGroups: _construirBarras(tipos),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: List.generate(
            tipos.length,
            (j) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: paleta[j % paleta.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  tipos[j],
                  style: const TextStyle(
                    fontSize: 11,
                    color: ColoresApp.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
