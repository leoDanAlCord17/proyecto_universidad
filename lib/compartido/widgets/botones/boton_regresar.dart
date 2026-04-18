import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniasist/configuracion/colores_app.dart';

/// Botón de regreso estándar de la app con el ícono <.
///
/// Comportamiento por prioridad:
/// 1. Si se provee [alPresionar], ejecuta esa acción.
/// 2. Si se provee [ruta], navega a esa ruta con context.go().
/// 3. Si no se provee ninguno, retrocede con context.pop().
class BotonRegresar extends StatelessWidget {
  const BotonRegresar({
    super.key,
    this.ruta,
    this.alPresionar,
    this.tooltip = 'Regresar',
  });

  final String?      ruta;
  final VoidCallback? alPresionar;
  /// Texto para lectores de pantalla. Por defecto 'Regresar'.
  final String       tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: alPresionar ?? () {
          if (ruta != null) {
            context.go(ruta!);
          } else {
            context.pop();
          }
        },
        child: Container(
          padding:    const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        ColoresApp.superficieSecund,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size:  18,
            color: ColoresApp.textoPrimario,
          ),
        ),
      ),
    );
  }
}
