import 'package:flutter/material.dart';
import 'package:uniasist/configuracion/colores_app.dart';

class CampoFechaApp extends StatelessWidget {
  const CampoFechaApp({
    super.key,
    required this.etiqueta,
    required this.hintText,
    required this.alSeleccionar,
    this.fechaActual,
    this.fechaMinima,
  });

  final String etiqueta;
  final String hintText;
  final void Function(DateTime) alSeleccionar;
  final DateTime? fechaActual;
  final DateTime? fechaMinima;

  String _formatearFecha(DateTime fecha) {
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }

  Future<void> _abrirSelector(BuildContext context) async {
    final hoy = DateTime.now();
    final resultado = await showDatePicker(
      context: context,
      initialDate: fechaActual ?? hoy,
      firstDate: fechaMinima ?? hoy,
      lastDate: DateTime(2030),
    );
    if (resultado != null) alSeleccionar(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _abrirSelector(context),
            borderRadius: BorderRadius.circular(12),
            highlightColor: ColoresApp.superficieTerciar,
            splashColor: ColoresApp.bordeMedio,
            child: Ink(
              decoration: BoxDecoration(
                color: ColoresApp.superficieSecund,
                border: Border.all(color: ColoresApp.bordeMedio),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fechaActual != null
                          ? _formatearFecha(fechaActual!)
                          : hintText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: fechaActual != null
                                ? ColoresApp.textoPrimario
                                : ColoresApp.textoTerciario,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: ColoresApp.textoTerciario,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
