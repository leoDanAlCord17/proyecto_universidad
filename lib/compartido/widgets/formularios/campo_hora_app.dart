import 'package:flutter/material.dart';
import 'package:uniasist/configuracion/colores_app.dart';

class CampoHoraApp extends StatelessWidget {
  const CampoHoraApp({
    super.key,
    required this.etiqueta,
    required this.hintText,
    required this.alSeleccionar,
    this.horaActual,
  });

  final String etiqueta;
  final String hintText;
  final void Function(TimeOfDay) alSeleccionar;
  final TimeOfDay? horaActual;

  String _formatearHora(TimeOfDay hora) {
    final h = hora.hourOfPeriod == 0 ? 12 : hora.hourOfPeriod;
    final m = hora.minute.toString().padLeft(2, '0');
    final esPm = hora.period == DayPeriod.pm;
    return '$h:$m ${esPm ? 'PM' : 'AM'}';
  }

  Future<void> _abrirSelector(BuildContext context) async {
    final resultado = await showTimePicker(
      context: context,
      initialTime: horaActual ?? TimeOfDay.now(),
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
                      horaActual != null
                          ? _formatearHora(horaActual!)
                          : hintText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: horaActual != null
                                ? ColoresApp.textoPrimario
                                : ColoresApp.textoTerciario,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                  ),
                  const Icon(
                    Icons.access_time_outlined,
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
