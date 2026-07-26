import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';
import '../estadisticas_modelo.dart';
import 'estilos_estadisticas.dart';

class SeccionEstadoEventos extends StatelessWidget {
  const SeccionEstadoEventos({required this.estadoEventos});
  final List<DatoGrafica> estadoEventos;

  @override
  Widget build(BuildContext context) {
    if (estadoEventos.isEmpty) return const SizedBox.shrink();
    final total = estadoEventos.fold(0.0, (s, d) => s + d.valor);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
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
        children: [
          Text('Salud operacional',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            'Estado de los eventos en el período',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: ColoresApp.textoTerciario),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: estadoEventos
                  .map(
                    (d) => Flexible(
                      flex: d.valor.toInt().clamp(1, 9999),
                      child: Container(
                        height: 16,
                        color: colorEstatusEvento(d.etiqueta),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: estadoEventos.map((d) {
              final color = colorEstatusEvento(d.etiqueta);
              final pct = (d.valor / total * 100).toStringAsFixed(0);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      d.etiqueta,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${d.valor.toInt()} ($pct%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
