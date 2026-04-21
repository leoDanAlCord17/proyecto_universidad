import 'package:flutter/material.dart';
import 'package:uniasist/configuracion/colores_app.dart';

class BotonContornoIcono extends StatelessWidget {
  const BotonContornoIcono({
    super.key,
    required this.icono,
    required this.alPresionar,
    this.tamanio    = 40,
    this.colorIcono = ColoresApp.textoSecundario,
  });

  final IconData      icono;
  final VoidCallback? alPresionar;
  final double        tamanio;
  final Color         colorIcono;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  tamanio,
      height: tamanio,
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap:          alPresionar ?? () {},
          borderRadius:   BorderRadius.circular(10),
          highlightColor: ColoresApp.superficieTerciar,
          splashColor:    ColoresApp.bordeMedio,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border:       Border.all(color: ColoresApp.bordeMedio),
            ),
            child: Icon(
              icono,
              size:  tamanio * 0.55,
              color: colorIcono,
            ),
          ),
        ),
      ),
    );
  }
}
