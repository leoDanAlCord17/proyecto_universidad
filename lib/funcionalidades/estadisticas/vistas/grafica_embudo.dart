import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';
import '../estadisticas_modelo.dart';
import 'estilos_estadisticas.dart';

class GraficaEmbudo extends StatelessWidget {
  const GraficaEmbudo({required this.porEstatus});
  final List<DatoGrafica> porEstatus;

  @override
  Widget build(BuildContext context) {
    final m = MetricasEmbudo.desdeEstatus(porEstatus);
    if (!m.hayDatos) return const SinDatos();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilaEmbudo(
          etiqueta: 'Convocados',
          cantidad: m.total,
          pct: 1.0,
          color: ColoresApp.acento,
        ),
        const SizedBox(height: 10),
        _FilaEmbudo(
          etiqueta: 'Llegaron',
          cantidad: m.llegaron,
          pct: m.total == 0 ? 0 : m.llegaron / m.total,
          color: ColoresApp.verde,
        ),
        const SizedBox(height: 10),
        _FilaEmbudo(
          etiqueta: 'Completaron',
          cantidad: m.completaron,
          pct: m.total == 0 ? 0 : m.completaron / m.total,
          color: ColoresApp.teal,
        ),
        const SizedBox(height: 10),
        _FilaEmbudo(
          etiqueta: 'No llegaron',
          cantidad: m.ausentes,
          pct: m.total == 0 ? 0 : m.ausentes / m.total,
          color: ColoresApp.rojo,
        ),
      ],
    );
  }
}

class _FilaEmbudo extends StatelessWidget {
  const _FilaEmbudo({
    required this.etiqueta,
    required this.cantidad,
    required this.pct,
    required this.color,
  });

  final String etiqueta;
  final double cantidad;
  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            etiqueta,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresApp.textoSecundario,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 14,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              backgroundColor: color.withValues(alpha: 0.1),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${(pct * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.end,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 28,
          child: Text(
            '${cantidad.toInt()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresApp.textoTerciario,
                  fontSize: 11,
                ),
          ),
        ),
      ],
    );
  }
}
