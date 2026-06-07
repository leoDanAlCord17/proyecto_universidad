import 'package:flutter/material.dart';
import 'package:uniasist/configuracion/colores_app.dart';

class CampoSelectApp<T> extends StatelessWidget {
  const CampoSelectApp({
    super.key,
    required this.etiqueta,
    required this.hintText,
    required this.opciones,
    required this.mostrarTexto,
    required this.alSeleccionar,
    this.valorActual,
  });

  final String etiqueta;
  final String hintText;
  final List<T> opciones;
  final String Function(T) mostrarTexto;
  final void Function(T) alSeleccionar;
  final T? valorActual;

  Future<void> _abrirHoja(BuildContext context) async {
    final resultado = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: ColoresApp.superficiePrimaria,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HojaSelect<T>(
        opciones: opciones,
        mostrarTexto: mostrarTexto,
        valorActual: valorActual,
      ),
    );
    if (resultado != null) alSeleccionar(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _abrirHoja(context),
            borderRadius: BorderRadius.circular(12),
            highlightColor: ColoresApp.superficieTerciar,
            splashColor: ColoresApp.bordeMedio,
            child: Ink(
              decoration: BoxDecoration(
                color: ColoresApp.superficieSecund,
                border: Border.all(color: ColoresApp.bordeMedio),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      valorActual != null
                          ? mostrarTexto(valorActual as T)
                          : hintText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: valorActual != null
                                ? ColoresApp.textoPrimario
                                : ColoresApp.textoTerciario,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: ColoresApp.textoTerciario,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HojaSelect<T> extends StatelessWidget {
  const _HojaSelect({
    required this.opciones,
    required this.mostrarTexto,
    this.valorActual,
  });

  final List<T> opciones;
  final String Function(T) mostrarTexto;
  final T? valorActual;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ColoresApp.bordeMedio,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: opciones.length,
              itemBuilder: (context, i) {
                final opcion = opciones[i];
                final estaActiva = valorActual == opcion;
                return ListTile(
                  title: Text(
                    mostrarTexto(opcion),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: estaActiva
                              ? ColoresApp.acento
                              : ColoresApp.textoPrimario,
                        ),
                  ),
                  trailing: estaActiva
                      ? const Icon(Icons.check_rounded,
                          color: ColoresApp.acento)
                      : null,
                  onTap: () => Navigator.pop(context, opcion),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
