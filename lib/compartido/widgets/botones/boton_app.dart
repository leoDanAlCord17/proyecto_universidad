import 'package:flutter/material.dart';
import 'package:uniasist/configuracion/colores_app.dart';

// Define los tres tipos de botón que existen en la app.
// Si en el futuro necesitas otro tipo, lo agregas aquí.
enum VarianteBoton { primario, ghost, rojo }

class BotonApp extends StatelessWidget {
  const BotonApp({
    super.key,
    required this.texto,
    required this.alPresionar,
    this.icono,
    this.variante = VarianteBoton.primario,
    this.estaCargando = false,
    this.ancho = double.infinity,
  });

  final String texto;
  final VoidCallback? alPresionar;

  /// Ícono que aparece a la izquierda del texto. Ej: Icons.check para '✓ Registrar entrada'.
  final IconData? icono;

  final VarianteBoton variante;
  final bool estaCargando;
  final double ancho;

  static const _colorAcento  = ColoresApp.acento;
  static const _colorAcento2 = ColoresApp.acento2;
  static const _colorBorde   = ColoresApp.acentoBorde;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: 50,
      child: _construirBoton(),
    );
  }

  Widget _construirBoton() {
    return switch (variante) {
      VarianteBoton.primario => _BotonPrimario(
          texto:       texto,
          icono:       icono,
          alPresionar: estaCargando ? null : alPresionar,
          estaCargando: estaCargando,
        ),
      VarianteBoton.ghost => _BotonGhost(
          texto:       texto,
          icono:       icono,
          alPresionar: estaCargando ? null : alPresionar,
        ),
      VarianteBoton.rojo => _BotonRojo(
          texto:       texto,
          icono:       icono,
          alPresionar: estaCargando ? null : alPresionar,
        ),
    };
  }
}

// ─── Contenido del botón: ícono + texto o solo texto ─────────────
class _ContenidoBoton extends StatelessWidget {
  const _ContenidoBoton({
    required this.texto,
    required this.colorTexto,
    this.icono,
  });

  final String texto;
  final Color colorTexto;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    if (icono == null) {
      return Text(
        texto,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color:      colorTexto,
          fontSize:   15,
        ),
      );
    }
    return Row(
      mainAxisSize:       MainAxisSize.min,
      mainAxisAlignment:  MainAxisAlignment.center,
      children: [
        Icon(icono, size: 17, color: colorTexto),
        const SizedBox(width: 8),
        Text(
          texto,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color:    colorTexto,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

// ─── Variante primaria: fondo con gradiente morado ────────────────
class _BotonPrimario extends StatelessWidget {
  const _BotonPrimario({
    required this.texto,
    required this.estaCargando,
    this.icono,
    this.alPresionar,
  });

  final String texto;
  final IconData? icono;
  final bool estaCargando;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: alPresionar == null
            ? null
            : const LinearGradient(
                colors: [BotonApp._colorAcento, BotonApp._colorAcento2],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              ),
        color:        alPresionar == null ? ColoresApp.superficieTerciar : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: alPresionar,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor:     Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: estaCargando
            ? Semantics(
                label: 'Cargando',
                child: const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    color:       ColoresApp.blanco,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : _ContenidoBoton(
                texto:      texto,
                icono:      icono,
                colorTexto: ColoresApp.blanco,
              ),
      ),
    );
  }
}

// ─── Variante ghost: fondo transparente con borde ─────────────────
class _BotonGhost extends StatelessWidget {
  const _BotonGhost({
    required this.texto,
    this.icono,
    this.alPresionar,
  });

  final String texto;
  final IconData? icono;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: alPresionar,
      style: OutlinedButton.styleFrom(
        foregroundColor: BotonApp._colorAcento,
        side: const BorderSide(color: BotonApp._colorBorde, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _ContenidoBoton(
        texto:      texto,
        icono:      icono,
        colorTexto: BotonApp._colorAcento,
      ),
    );
  }
}

// ─── Variante rojo: para acciones destructivas ────────────────────
class _BotonRojo extends StatelessWidget {
  const _BotonRojo({
    required this.texto,
    this.icono,
    this.alPresionar,
  });

  final String texto;
  final IconData? icono;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: alPresionar,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColoresApp.rojo,
        shadowColor:     Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _ContenidoBoton(
        texto:      texto,
        icono:      icono,
        colorTexto: ColoresApp.blanco,
      ),
    );
  }
}
