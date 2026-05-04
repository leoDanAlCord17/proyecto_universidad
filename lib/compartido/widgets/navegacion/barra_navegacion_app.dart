import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniasist/configuracion/colores_app.dart';

import '../../constantes.dart';

class BarraNavegacionApp extends StatelessWidget {
  const BarraNavegacionApp({
    super.key,
    required this.indiceActual,
    required this.alCambiarIndice,
  });

  final int indiceActual;
  final void Function(int) alCambiarIndice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        boxShadow: [
          BoxShadow(
            color:      ColoresApp.sombraTarjeta,
            blurRadius: 16,
            offset:     Offset(0, -4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
            child: Row(
              children: [
                _ItemNavegacion(
                  icono:        Icons.home_rounded,
                  etiqueta:     'Inicio',
                  indice:       0,
                  indiceActual: indiceActual,
                  alPresionar:  alCambiarIndice,
                ),
                _ItemNavegacion(
                  icono:        Icons.calendar_month_rounded,
                  etiqueta:     'Eventos',
                  indice:       1,
                  indiceActual: indiceActual,
                  alPresionar:  alCambiarIndice,
                ),
                _BotonEscanear(
                  estaActivo: indiceActual == 2,
                  alPresionar: () => context.push(Rutas.escanear),
                ),
                _ItemNavegacion(
                  icono:        Icons.how_to_reg_rounded,
                  etiqueta:     'Asistencia',
                  indice:       3,
                  indiceActual: indiceActual,
                  alPresionar:  alCambiarIndice,
                ),
                _ItemNavegacion(
                  icono:        Icons.person_outline_rounded,
                  etiqueta:     'Perfil',
                  indice:       4,
                  indiceActual: indiceActual,
                  alPresionar:  alCambiarIndice,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemNavegacion extends StatelessWidget {
  const _ItemNavegacion({
    required this.icono,
    required this.etiqueta,
    required this.indice,
    required this.indiceActual,
    required this.alPresionar,
  });

  final IconData           icono;
  final String             etiqueta;
  final int                indice;
  final int                indiceActual;
  final void Function(int) alPresionar;

  bool get _estaActivo => indice == indiceActual;

  @override
  Widget build(BuildContext context) {
    final color = _estaActivo ? ColoresApp.acento : ColoresApp.textoTerciario;

    return Expanded(
      child: InkWell(
        onTap:        () => alPresionar(indice),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              etiqueta,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize:   11,
                fontWeight: _estaActivo ? FontWeight.w700 : FontWeight.w700,
                color:      color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonEscanear extends StatelessWidget {
  const _BotonEscanear({
    required this.estaActivo,
    required this.alPresionar,
  });

  final bool         estaActivo;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap:        alPresionar,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width:  48,
              height: 48,
              decoration: BoxDecoration(
                shape:    BoxShape.circle,
                gradient: estaActivo ? ColoresApp.degradadoPrincipal : null,
                color:    estaActivo ? null : ColoresApp.acentoClaro,
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size:  22,
                color: estaActivo ? Colors.white : ColoresApp.acento,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Escanear',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize:   11,
                fontWeight: estaActivo ? FontWeight.w700 : FontWeight.w700,
                color:      estaActivo ? ColoresApp.acento : ColoresApp.textoTerciario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
