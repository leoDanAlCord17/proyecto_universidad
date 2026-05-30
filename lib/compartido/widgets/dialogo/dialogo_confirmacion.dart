import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';

class DialogoConfirmacion extends StatelessWidget {
  const DialogoConfirmacion({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.textoConfirmar,
    required this.textoCancelar,
  });

  final String titulo;
  final String descripcion;

  /// Botón morado (acción principal).
  final String textoConfirmar;

  /// Botón rojo (acción destructiva o alternativa).
  final String textoCancelar;

  /// Muestra el diálogo y retorna:
  /// `true`  → el usuario presionó el botón morado (confirmar),
  /// `false` → el usuario presionó el botón rojo (cancelar),
  /// `null`  → cerró sin elegir.
  static Future<bool?> mostrar(
    BuildContext context, {
    required String titulo,
    required String descripcion,
    required String textoConfirmar,
    required String textoCancelar,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (_) => DialogoConfirmacion(
          titulo:          titulo,
          descripcion:     descripcion,
          textoConfirmar:  textoConfirmar,
          textoCancelar:   textoCancelar,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:    const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color:        ColoresApp.superficiePrimaria,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color:      ColoresApp.sombraGeneral,
              blurRadius: 24,
              offset:     Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                color:      ColoresApp.textoPrimario,
                fontSize:   17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              descripcion,
              style: const TextStyle(
                color:    ColoresApp.textoSecundario,
                fontSize: 14,
                height:   1.5,
              ),
            ),
            const SizedBox(height: 24),
            _BotonConfirmar(
              texto:      textoConfirmar,
              alPresionar: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            _BotonCancelar(
              texto:      textoCancelar,
              alPresionar: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón confirmar (morado) ─────────────────────────────────────────────────

class _BotonConfirmar extends StatelessWidget {
  const _BotonConfirmar({required this.texto, required this.alPresionar});

  final String       texto;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  double.infinity,
      height: 48,
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap:        alPresionar,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              gradient:     ColoresApp.degradadoPrincipal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                texto,
                style: const TextStyle(
                  color:      ColoresApp.blanco,
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Botón cancelar (rojo) ────────────────────────────────────────────────────

class _BotonCancelar extends StatelessWidget {
  const _BotonCancelar({required this.texto, required this.alPresionar});

  final String       texto;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  double.infinity,
      height: 48,
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap:          alPresionar,
          borderRadius:   BorderRadius.circular(12),
          highlightColor: ColoresApp.rojoClaro,
          splashColor:    ColoresApp.bordeError,
          child: Ink(
            decoration: BoxDecoration(
              border:       Border.all(color: ColoresApp.bordeError),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                texto,
                style: const TextStyle(
                  color:      ColoresApp.rojo,
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
