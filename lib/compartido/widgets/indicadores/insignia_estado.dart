import 'package:flutter/material.dart';
import 'package:activiti/configuracion/colores_app.dart';

enum TamanioInsignia { normal, pequeno }

class InsigniaEstado extends StatelessWidget {
  const InsigniaEstado({
    super.key,
    required this.estatus,
    this.tamanio = TamanioInsignia.normal,
  });

  final String estatus;
  final TamanioInsignia tamanio;

  // Colores definidos una sola vez para toda la app
  static const _colores = {
    'en_curso': (ColoresApp.verdeClaro, ColoresApp.verde),
    'programado': (ColoresApp.ambarClaro, ColoresApp.ambar),
    'finalizado': (ColoresApp.superficieTerciar, ColoresApp.textoSecundario),
    'cancelado': (ColoresApp.rojoClaro, ColoresApp.rojo),
    'borrador': (ColoresApp.superficieTerciar, ColoresApp.textoTerciario),
    'presente': (ColoresApp.verdeClaro, ColoresApp.verde),
    'completado': (ColoresApp.verdeClaro, ColoresApp.verde),
    'ausente': (ColoresApp.rojoClaro, ColoresApp.rojo),
    'esperado': (ColoresApp.superficieTerciar, ColoresApp.textoSecundario),
    'salio_anticipado': (ColoresApp.ambarClaro, ColoresApp.ambar),
    'anulado': (ColoresApp.rojoClaro, ColoresApp.rojo),
    'no_esperado': (ColoresApp.rojoClaro, ColoresApp.rojo),
  };

  // Textos legibles en español para cada estatus
  static const _textos = {
    'en_curso': 'En curso',
    'programado': 'Programado',
    'finalizado': 'Finalizado',
    'cancelado': 'Cancelado',
    'borrador': 'Borrador',
    'presente': 'Presente',
    'completado': 'Completado',
    'ausente': 'Ausente',
    'esperado': 'Esperado',
    'salio_anticipado': 'Anticipado',
    'anulado': 'Anulado',
    'no_esperado': 'No esperado',
  };

  @override
  Widget build(BuildContext context) {
    final colores = _colores[estatus] ??
        (ColoresApp.superficieTerciar, ColoresApp.textoSecundario);

    final texto = _textos[estatus] ?? estatus;

    final esPequeno = tamanio == TamanioInsignia.pequeno;

    return Semantics(
      label: 'Estado: $texto',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: esPequeno ? 7 : 10,
          vertical: esPequeno ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: colores.$1,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          texto,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colores.$2,
                fontSize: esPequeno ? 9 : 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
        ),
      ),
    );
  }
}
