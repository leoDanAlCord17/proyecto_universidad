import 'package:flutter/material.dart';
import '../../../configuracion/colores_app.dart';

enum EstiloAviso { informativa, exito, error }

class AvisoApp {
  static OverlayEntry? _entradaActual;

  static void mostrar(
    BuildContext context, {
    required String texto,
    required EstiloAviso estilo,
    Duration duracion = const Duration(milliseconds: 2500),
  }) {
    _entradaActual?.remove();

    final entrada = OverlayEntry(
      builder: (_) =>
          _VistaAviso(texto: texto, estilo: estilo, duracion: duracion),
    );
    _entradaActual = entrada;
    Overlay.of(context).insert(entrada);

    Future.delayed(duracion + const Duration(milliseconds: 400), () {
      if (_entradaActual == entrada) {
        _entradaActual?.remove();
        _entradaActual = null;
      }
    });
  }
}

// ─── Vista interna ────────────────────────────────────────────────────────────

class _VistaAviso extends StatefulWidget {
  const _VistaAviso({
    required this.texto,
    required this.estilo,
    required this.duracion,
  });

  final String texto;
  final EstiloAviso estilo;
  final Duration duracion;

  @override
  State<_VistaAviso> createState() => _VistaAvisoState();
}

class _VistaAvisoState extends State<_VistaAviso>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacidad;

  static const _durFadeIn = Duration(milliseconds: 200);
  static const _durFadeOut = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _durFadeIn);
    _opacidad = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.forward();

    Future.delayed(widget.duracion - _durFadeOut, () {
      if (mounted) _ctrl.reverse(from: 1);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colores = _coloresPorEstilo(widget.estilo);

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _opacidad,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: colores.fondo,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colores.borde),
                  boxShadow: const [
                    BoxShadow(
                      color: ColoresApp.sombraGeneral,
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(colores.icono, color: colores.color, size: 22),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.texto,
                        style: TextStyle(
                          color: colores.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Colores por estilo ───────────────────────────────────────────────────────

class _ColoresAviso {
  const _ColoresAviso({
    required this.color,
    required this.fondo,
    required this.borde,
    required this.icono,
  });

  final Color color;
  final Color fondo;
  final Color borde;
  final IconData icono;
}

_ColoresAviso _coloresPorEstilo(EstiloAviso estilo) => switch (estilo) {
      EstiloAviso.informativa => const _ColoresAviso(
          color: ColoresApp.teal,
          fondo: ColoresApp.tealClaro,
          borde: ColoresApp.bordeAviso,
          icono: Icons.info_outline_rounded,
        ),
      EstiloAviso.exito => const _ColoresAviso(
          color: ColoresApp.verde,
          fondo: ColoresApp.verdeClaro,
          borde: ColoresApp.bordeExito,
          icono: Icons.check_circle_outline_rounded,
        ),
      EstiloAviso.error => const _ColoresAviso(
          color: ColoresApp.rojo,
          fondo: ColoresApp.rojoClaro,
          borde: ColoresApp.bordeError,
          icono: Icons.error_outline_rounded,
        ),
    };
