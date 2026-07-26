import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';

/// Paleta, helpers de color y widgets base compartidos por las vistas de
/// estadísticas (tarjetas de gráfica, estado vacío, estado de error).
/// Extraído de `estadisticas_pantalla.dart` (antes 3209 líneas) al
/// modularizar por sección.

const paleta = [
  ColoresApp.acento,
  ColoresApp.verde,
  ColoresApp.ambar,
  ColoresApp.rojo,
  ColoresApp.teal,
  ColoresApp.acento2,
];

Color colorEstatus(String etiqueta) => switch (etiqueta) {
      'Presente' => ColoresApp.verde,
      'Completado' => ColoresApp.verde,
      'Salió antes' => ColoresApp.ambar,
      'Ausente' => ColoresApp.rojo,
      'Esperado' => ColoresApp.textoTerciario,
      _ => ColoresApp.teal,
    };

Color colorEstatusEvento(String etiqueta) => switch (etiqueta) {
      'Finalizado' => ColoresApp.verde,
      'En curso' => ColoresApp.acento,
      'Programado' => ColoresApp.ambar,
      'Cancelado' => ColoresApp.rojo,
      _ => ColoresApp.textoTerciario,
    };

Color colorTasa(double tasa) => tasa >= 75
    ? ColoresApp.verde
    : tasa >= 50
        ? ColoresApp.ambar
        : ColoresApp.rojo;

class TarjetaGrafica extends StatelessWidget {
  const TarjetaGrafica({
    required this.titulo,
    required this.child,
    this.subtitulo,
    this.altura,
  });

  final String titulo;
  final String? subtitulo;
  final Widget child;
  final double? altura;

  @override
  Widget build(BuildContext context) {
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
          Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitulo!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColoresApp.textoTerciario,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          altura != null ? SizedBox(height: altura!, child: child) : child,
        ],
      ),
    );
  }
}

class SinDatos extends StatelessWidget {
  const SinDatos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_outlined,
                color: ColoresApp.textoTerciario, size: 36),
            const SizedBox(height: 8),
            Text(
              'Sin datos para este período',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: ColoresApp.textoTerciario),
            ),
          ],
        ),
      ),
    );
  }
}

class VistaError extends StatelessWidget {
  const VistaError({required this.mensaje, required this.alReintentar});
  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: ColoresApp.rojo, size: 48),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: ColoresApp.textoSecundario),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
