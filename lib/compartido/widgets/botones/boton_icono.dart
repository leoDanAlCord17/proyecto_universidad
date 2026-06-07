import 'package:flutter/material.dart';
import 'package:uniasist/configuracion/colores_app.dart';

enum VarianteBotonIcono { normal, acento, rojo }

class BotonIcono extends StatelessWidget {
  const BotonIcono({
    super.key,
    required this.icono,
    required this.alPresionar,
    this.tooltip,
    this.variante = VarianteBotonIcono.normal,
    this.tamanio = 18,
  });

  final IconData icono;
  final VoidCallback? alPresionar;

  /// Texto descriptivo para lectores de pantalla y hover. Recomendado siempre.
  final String? tooltip;
  final VarianteBotonIcono variante;
  final double tamanio;

  static const _estilos = {
    VarianteBotonIcono.normal: (
      ColoresApp.superficieSecund,
      ColoresApp.textoPrimario
    ),
    VarianteBotonIcono.acento: (ColoresApp.acentoClaro, ColoresApp.acento),
    VarianteBotonIcono.rojo: (ColoresApp.rojoClaro, ColoresApp.rojo),
  };

  @override
  Widget build(BuildContext context) {
    final (colorFondo, colorIcono) = _estilos[variante]!;

    final boton = Semantics(
      button: true,
      label: tooltip,
      enabled: alPresionar != null,
      child: GestureDetector(
        onTap: alPresionar,
        child: Container(
          padding: EdgeInsets.all(tamanio * 0.55),
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExcludeSemantics(
            child: Icon(icono, size: tamanio, color: colorIcono),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: boton);
    }
    return boton;
  }
}
