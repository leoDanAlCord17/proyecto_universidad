import 'package:flutter/material.dart';

import '../../../compartido/widgets/botones/boton_regresar.dart';
import '../../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../../configuracion/colores_app.dart';
import '../filtros_estadisticas.dart';

class BarraTitulo extends StatelessWidget {
  const BarraTitulo({
    required this.filtros,
    required this.alFiltrar,
    required this.alLimpiar,
  });

  final FiltrosEstadisticas filtros;
  final VoidCallback alFiltrar;
  final VoidCallback alLimpiar;

  @override
  Widget build(BuildContext context) {
    final totalActivos = filtros.totalFiltrosActivos;
    return BarraSuperiorApp(
      izquierda: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BotonRegresar(),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Estadísticas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                filtros.etiquetaRango,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColoresApp.acento,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
      derecha: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (totalActivos > 0) ...[
            Material(
              color: ColoresApp.rojoClaro,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: alLimpiar,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(Icons.filter_alt_off_rounded,
                      color: ColoresApp.rojo, size: 15),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: alFiltrar,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: totalActivos > 0
                      ? ColoresApp.acento
                      : ColoresApp.acentoClaro,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: totalActivos > 0
                          ? ColoresApp.blanco
                          : ColoresApp.acento,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      totalActivos > 0 ? 'Filtros ($totalActivos)' : 'Filtros',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: totalActivos > 0
                                ? ColoresApp.blanco
                                : ColoresApp.acento,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
