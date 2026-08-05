import 'package:flutter/material.dart';
import 'package:activiti/configuracion/colores_app.dart';

class BarraSuperiorApp extends StatelessWidget {
  const BarraSuperiorApp({
    super.key,
    this.izquierda,
    this.centro,
    this.derecha,
  });

  final Widget? izquierda;
  final Widget? centro;
  final Widget? derecha;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ColoresApp.superficiePrimaria,
      child: SizedBox(
        height: 90,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          // Row (no Stack+Align) para que `izquierda` reciba un ancho
          // máximo real y acotado por lo que ocupa `derecha` — con Stack
          // cada lado se posicionaba de forma independiente sin negociar
          // espacio, así que en pantallas angostas un `izquierda` largo
          // (ej. el saludo con nombre de usuario en Inicio) se montaba
          // encima de los botones de `derecha` en vez de encogerse.
          child: Row(
            children: [
              if (izquierda != null)
                Expanded(
                  child:
                      Align(alignment: Alignment.centerLeft, child: izquierda!),
                ),
              if (centro != null) centro!,
              if (derecha != null)
                Align(alignment: Alignment.centerRight, child: derecha!),
            ],
          ),
        ),
      ),
    );
  }
}
