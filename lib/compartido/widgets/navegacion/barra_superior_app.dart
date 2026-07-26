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
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (izquierda != null)
                Align(alignment: Alignment.centerLeft, child: izquierda!),
              if (centro != null)
                Align(alignment: Alignment.center, child: centro!),
              if (derecha != null)
                Align(alignment: Alignment.centerRight, child: derecha!),
            ],
          ),
        ),
      ),
    );
  }
}
