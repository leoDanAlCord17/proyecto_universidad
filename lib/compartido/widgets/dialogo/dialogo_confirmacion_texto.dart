import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';
import '../botones/boton_app.dart';
import '../formularios/campo_texto_app.dart';

/// Diálogo de confirmación que exige escribir un valor exacto (p. ej. el
/// nombre completo de un usuario o el título de un evento) antes de habilitar
/// la acción destructiva.
///
/// Antes duplicado casi al 100% entre `_DialogoSuspenderUsuario`
/// (`usuarios_pantalla.dart`) y `_DialogoCerrarEvento`
/// (`panel_control_pantalla.dart`).
class DialogoConfirmacionTexto extends StatefulWidget {
  const DialogoConfirmacionTexto({
    super.key,
    required this.titulo,
    required this.valorEsperado,
    required this.textoBotonConfirmar,
    required this.alConfirmar,
    this.descripcionPrefijo = '',
    this.descripcionSufijo = '',
    this.etiquetaCampo = 'Confirmación',
    this.pistaCampo,
    this.icono,
    this.distingueMayusculas = false,
  });

  final String titulo;
  final IconData? icono;

  /// Texto antes del valor resaltado, ej. "Para confirmar, escribe el
  /// nombre completo de ".
  final String descripcionPrefijo;

  /// El valor exacto que el usuario debe escribir para habilitar el botón.
  final String valorEsperado;

  /// Texto después del valor resaltado, ej. " para confirmar el cierre.".
  final String descripcionSufijo;

  final String etiquetaCampo;

  /// Placeholder del campo de texto. Si es null, usa [valorEsperado].
  final String? pistaCampo;

  final String textoBotonConfirmar;
  final VoidCallback alConfirmar;

  /// Si es false (default), la comparación ignora mayúsculas/minúsculas.
  final bool distingueMayusculas;

  /// Muestra el diálogo. Ver parámetros del constructor.
  static Future<void> mostrar(
    BuildContext context, {
    required String titulo,
    required String valorEsperado,
    required String textoBotonConfirmar,
    required VoidCallback alConfirmar,
    String descripcionPrefijo = '',
    String descripcionSufijo = '',
    String etiquetaCampo = 'Confirmación',
    String? pistaCampo,
    IconData? icono,
    bool distingueMayusculas = false,
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => DialogoConfirmacionTexto(
        titulo: titulo,
        valorEsperado: valorEsperado,
        textoBotonConfirmar: textoBotonConfirmar,
        alConfirmar: alConfirmar,
        descripcionPrefijo: descripcionPrefijo,
        descripcionSufijo: descripcionSufijo,
        etiquetaCampo: etiquetaCampo,
        pistaCampo: pistaCampo,
        icono: icono,
        distingueMayusculas: distingueMayusculas,
      ),
    );
  }

  @override
  State<DialogoConfirmacionTexto> createState() =>
      _DialogoConfirmacionTextoState();
}

class _DialogoConfirmacionTextoState extends State<DialogoConfirmacionTexto> {
  final _controlador = TextEditingController();
  bool _coincide = false;

  @override
  void initState() {
    super.initState();
    _controlador.addListener(_actualizarCoincidencia);
  }

  void _actualizarCoincidencia() {
    final escrito = _controlador.text.trim();
    final esperado = widget.valorEsperado.trim();
    final coincide = widget.distingueMayusculas
        ? escrito == esperado
        : escrito.toLowerCase() == esperado.toLowerCase();
    if (coincide != _coincide) setState(() => _coincide = coincide);
  }

  @override
  void dispose() {
    _controlador.removeListener(_actualizarCoincidencia);
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: ColoresApp.superficiePrimaria,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: ColoresApp.sombraGeneral,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.icono != null) ...[
                  Icon(widget.icono, color: ColoresApp.rojo, size: 22),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    widget.titulo,
                    style: const TextStyle(
                      color: ColoresApp.textoPrimario,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 14,
                  height: 1.5,
                ),
                children: [
                  if (widget.descripcionPrefijo.isNotEmpty)
                    TextSpan(text: widget.descripcionPrefijo),
                  TextSpan(
                    text: widget.valorEsperado,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ColoresApp.textoPrimario,
                    ),
                  ),
                  if (widget.descripcionSufijo.isNotEmpty)
                    TextSpan(text: widget.descripcionSufijo),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CampoTextoApp(
              etiqueta: widget.etiquetaCampo,
              hintText: widget.pistaCampo ?? widget.valorEsperado,
              controller: _controlador,
            ),
            const SizedBox(height: 20),
            BotonApp(
              variante: VarianteBoton.rojo,
              texto: widget.textoBotonConfirmar,
              alPresionar: _coincide
                  ? () {
                      Navigator.of(context).pop();
                      widget.alConfirmar();
                    }
                  : null,
            ),
            const SizedBox(height: 10),
            BotonApp(
              variante: VarianteBoton.ghost,
              texto: 'Cancelar',
              alPresionar: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
