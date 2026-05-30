import 'package:flutter/material.dart';
import 'package:uniasist/configuracion/colores_app.dart';

class CampoMultiselectApp<T> extends StatelessWidget {
  const CampoMultiselectApp({
    super.key,
    required this.etiqueta,
    required this.hintText,
    required this.opciones,
    required this.mostrarTexto,
    required this.obtenerId,
    required this.idsSeleccionados,
    required this.alSeleccionar,
  });

  final String                    etiqueta;
  final String                    hintText;
  final List<T>                   opciones;
  final String Function(T)        mostrarTexto;
  final String Function(T)        obtenerId;
  final List<String>              idsSeleccionados;
  final void Function(List<String>) alSeleccionar;

  Future<void> _abrirHoja(BuildContext context) async {
    final resultado = await showModalBottomSheet<List<String>>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    ColoresApp.superficiePrimaria,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HojaMultiselect<T>(
        opciones:         opciones,
        mostrarTexto:     mostrarTexto,
        obtenerId:        obtenerId,
        idsSeleccionados: idsSeleccionados,
      ),
    );
    if (resultado != null) alSeleccionar(resultado);
  }

  @override
  Widget build(BuildContext context) {
    final haySeleccion        = idsSeleccionados.isNotEmpty;
    final opcionesSeleccionadas = opciones
        .where((o) => idsSeleccionados.contains(obtenerId(o)))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap:          () => _abrirHoja(context),
            borderRadius:   BorderRadius.circular(12),
            highlightColor: ColoresApp.superficieTerciar,
            splashColor:    ColoresApp.bordeMedio,
            child: Ink(
              decoration: BoxDecoration(
                color:        ColoresApp.superficieSecund,
                border:       Border.all(color: ColoresApp.bordeMedio),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: haySeleccion
                        ? Wrap(
                            spacing:    6,
                            runSpacing: 4,
                            children: opcionesSeleccionadas
                                .map((o) => _ChipSeleccion(texto: mostrarTexto(o)))
                                .toList(),
                          )
                        : Text(
                            hintText,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:      ColoresApp.textoTerciario,
                              fontWeight: FontWeight.w600,
                              fontSize:   14,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: ColoresApp.textoTerciario,
                    size:  20,
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

class _ChipSeleccion extends StatelessWidget {
  const _ChipSeleccion({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        ColoresApp.acentoClaro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color:      ColoresApp.acento,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HojaMultiselect<T> extends StatefulWidget {
  const _HojaMultiselect({
    required this.opciones,
    required this.mostrarTexto,
    required this.obtenerId,
    required this.idsSeleccionados,
  });

  final List<T>            opciones;
  final String Function(T) mostrarTexto;
  final String Function(T) obtenerId;
  final List<String>       idsSeleccionados;

  @override
  State<_HojaMultiselect<T>> createState() => _HojaMultiselectState<T>();
}

class _HojaMultiselectState<T> extends State<_HojaMultiselect<T>> {
  late List<String> _seleccionados;

  @override
  void initState() {
    super.initState();
    _seleccionados = List.from(widget.idsSeleccionados);
  }

  void _alternar(String id) {
    setState(() {
      if (_seleccionados.contains(id)) {
        _seleccionados.remove(id);
      } else {
        _seleccionados.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width:  40,
            height: 4,
            decoration: BoxDecoration(
              color:        ColoresApp.bordeMedio,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount:  widget.opciones.length,
              itemBuilder: (context, i) {
                final opcion           = widget.opciones[i];
                final id               = widget.obtenerId(opcion);
                final estaSeleccionado = _seleccionados.contains(id);
                return CheckboxListTile(
                  value:      estaSeleccionado,
                  onChanged:  (_) => _alternar(id),
                  activeColor: ColoresApp.acento,
                  checkColor:  ColoresApp.blanco,
                  title: Text(
                    widget.mostrarTexto(opcion),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _seleccionados),
                child: const Text('Confirmar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
