import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniasist/configuracion/colores_app.dart';

class BotonRegresar extends StatelessWidget {
  const BotonRegresar({
    super.key,
    this.ruta,
    this.alPresionar,
    this.tooltip = 'Regresar',
  });

  final String?       ruta;
  final VoidCallback? alPresionar;
  final String        tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: alPresionar ?? () {
            if (ruta != null) {
              context.go(ruta!);
            } else {
              context.pop();
            }
          },
          borderRadius:   BorderRadius.circular(12),
          highlightColor: ColoresApp.superficieTerciar,
          splashColor:    ColoresApp.bordeMedio,
          child: Ink(
            padding: const EdgeInsets.all(10),
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
      ),
    );
  }
}
