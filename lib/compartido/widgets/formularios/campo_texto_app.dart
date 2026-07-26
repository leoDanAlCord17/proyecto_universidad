import 'package:flutter/material.dart';
import 'package:activiti/configuracion/colores_app.dart';

class CampoTextoApp extends StatefulWidget {
  const CampoTextoApp({
    super.key,
    required this.etiqueta,
    required this.hintText,
    this.controller,
    this.esContrasena = false,
    this.soloLectura = false,
  });
  final String etiqueta;
  final String hintText;
  final TextEditingController? controller;
  final bool esContrasena;
  final bool soloLectura;

  @override
  State<CampoTextoApp> createState() => _CampoTextoAppState();
}

class _CampoTextoAppState extends State<CampoTextoApp> {
  // Estado interno para alternar la visibilidad
  late bool _estaOscurecido;

  @override
  void initState() {
    super.initState();
    // Inicialmente, si es contraseña, empezamos ocultando el texto
    _estaOscurecido = widget.esContrasena;
  }

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.etiqueta,
          style: estilo.titleSmall,
        ),
        const SizedBox(height: 8),
        Semantics(
          label: widget.etiqueta,
          textField: true,
          child: TextFormField(
            controller: widget.controller,
            obscureText: _estaOscurecido,
            readOnly: widget.soloLectura,
            style: estilo.bodyMedium?.copyWith(color: ColoresApp.textoPrimario),
            decoration: InputDecoration(
              hintText: widget.hintText,
              suffixIcon: widget.esContrasena
                  ? Semantics(
                      button: true,
                      label: _estaOscurecido
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      excludeSemantics: true,
                      child: IconButton(
                        icon: Icon(
                          _estaOscurecido
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: ColoresApp.textoTerciario,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _estaOscurecido = !_estaOscurecido;
                          });
                        },
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
