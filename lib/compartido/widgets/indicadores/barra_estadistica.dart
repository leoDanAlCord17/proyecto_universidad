import 'package:flutter/material.dart';
import 'package:activiti/configuracion/colores_app.dart';

class BarraEstadistica extends StatelessWidget {
  const BarraEstadistica({
    super.key,
    required this.etiqueta,
    required this.porcentaje,
    this.colorBarra,
    this.colorEtiqueta,
    this.colorPorcentaje,
  });

  /// Texto descriptivo a la izquierda. Ej: 'Tasa de asistencia'
  final String etiqueta;

  /// Valor entre 0.0 y 1.0. Ej: 0.75 para 75%
  final double porcentaje;

  final Color? colorBarra;
  final Color? colorEtiqueta;
  final Color? colorPorcentaje;

  @override
  Widget build(BuildContext context) {
    final barra = colorBarra ?? ColoresApp.verde;
    final colorTexto = colorEtiqueta ?? ColoresApp.textoPrimario;
    final colorPct = colorPorcentaje ?? ColoresApp.verde;
    final porcentajeSeguro = porcentaje.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              etiqueta,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorTexto,
                  ),
            ),
            Text(
              '${(porcentajeSeguro * 100).round()}%',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorPct,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: LinearProgressIndicator(
            value: porcentajeSeguro,
            minHeight: 8,
            backgroundColor: ColoresApp.superficieTerciar,
            valueColor: AlwaysStoppedAnimation<Color>(barra),
          ),
        ),
      ],
    );
  }
}
