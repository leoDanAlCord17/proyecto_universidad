import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';
import '../dialogo/dialogo_confirmacion.dart';

class BarraBusquedaApp extends StatelessWidget {
  const BarraBusquedaApp({
    super.key,
    required this.alCambiar,
    this.hintText             = 'Buscar...',
    this.controlador,
    this.alSeleccionarRango,
    this.alLimpiarRango,
    this.rangoSeleccionado,
  });

  final ValueChanged<String>      alCambiar;
  final String                    hintText;
  final TextEditingController?    controlador;

  /// Cuando no es null, muestra el botón de calendario.
  final ValueChanged<DateTimeRange>? alSeleccionarRango;

  /// Cuando no es null, permite limpiar el rango seleccionado.
  final VoidCallback?                alLimpiarRango;

  /// Rango actualmente seleccionado (para destacar el ícono).
  final DateTimeRange?               rangoSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: ColoresApp.bordeMedio),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search_rounded,
            color: ColoresApp.textoTerciario,
            size:  20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller:   controlador,
              onChanged:    alCambiar,
              style:        const TextStyle(
                color:    ColoresApp.textoPrimario,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText:      hintText,
                hintStyle:     const TextStyle(
                  color:    ColoresApp.textoTerciario,
                  fontSize: 14,
                ),
                border:        InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled:         true,
                fillColor:      Colors.transparent,
                isDense:        true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (alSeleccionarRango != null) ...[
            Container(
              width: 1,
              height: 24,
              color: ColoresApp.bordeMedio,
            ),
            _BotonCalendario(
              rangoSeleccionado:  rangoSeleccionado,
              alSeleccionarRango: alSeleccionarRango!,
              alLimpiarRango:     alLimpiarRango,
            ),
          ] else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}

// ─── Botón calendario ─────────────────────────────────────────────────────────

class _BotonCalendario extends StatelessWidget {
  const _BotonCalendario({
    required this.alSeleccionarRango,
    this.alLimpiarRango,
    this.rangoSeleccionado,
  });

  final ValueChanged<DateTimeRange> alSeleccionarRango;
  final VoidCallback?               alLimpiarRango;
  final DateTimeRange?              rangoSeleccionado;

  Future<void> _alPresionar(BuildContext context) async {
    if (rangoSeleccionado != null && alLimpiarRango != null) {
      await _mostrarOpcionesRango(context);
    } else {
      await _abrirSelector(context);
    }
  }

  Future<void> _mostrarOpcionesRango(BuildContext context) async {
    final confirmo = await DialogoConfirmacion.mostrar(
      context,
      titulo:         'Filtro de fechas',
      descripcion:    '¿Qué deseas hacer con el filtro de fechas activo?',
      textoConfirmar: 'Modificar rango',
      textoCancelar:  'Quitar filtro',
    );

    if (confirmo == false) {
      alLimpiarRango!();
    } else if (confirmo == true && context.mounted) {
      await _abrirSelector(context);
    }
  }

  Future<void> _abrirSelector(BuildContext context) async {
    final ahora = DateTime.now();
    final hoy   = DateTime(ahora.year, ahora.month, ahora.day);

    final rango = await showDateRangePicker(
      context:          context,
      initialDateRange: rangoSeleccionado ?? DateTimeRange(start: hoy, end: hoy),
      firstDate:        DateTime(2020),
      lastDate:         DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary:    ColoresApp.acento,
            onPrimary:  ColoresApp.blanco,
            surface:    ColoresApp.superficiePrimaria,
            onSurface:  ColoresApp.textoPrimario,
          ),
        ),
        child: child!,
      ),
    );

    if (rango != null) alSeleccionarRango(rango);
  }

  @override
  Widget build(BuildContext context) {
    final tieneRango = rangoSeleccionado != null;

    return Material(
      color:        Colors.transparent,
      borderRadius: const BorderRadius.only(
        topRight:    Radius.circular(14),
        bottomRight: Radius.circular(14),
      ),
      child: InkWell(
        onTap:        () => _alPresionar(context),
        borderRadius: const BorderRadius.only(
          topRight:    Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        highlightColor: ColoresApp.acentoClaro,
        splashColor:    ColoresApp.bordeMedio,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.calendar_month_rounded,
            size:  20,
            color: tieneRango ? ColoresApp.acento : ColoresApp.textoTerciario,
          ),
        ),
      ),
    );
  }
}

