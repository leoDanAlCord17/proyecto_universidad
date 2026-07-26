import 'package:flutter/material.dart';
import 'package:activiti/configuracion/colores_app.dart';

enum VarianteTarjeta { normal, pequena, acento, degradado, punteada }

class TarjetaApp extends StatelessWidget {
  const TarjetaApp({
    super.key,
    required this.child,
    this.variante = VarianteTarjeta.normal,
    this.alPresionar,
    this.relleno,
  });

  final Widget child;
  final VarianteTarjeta variante;
  final VoidCallback? alPresionar;
  final EdgeInsets? relleno;

  static const _acento = ColoresApp.acento;
  static const _acentoClaro = ColoresApp.acentoClaro;
  static const _acentoBorde = ColoresApp.acentoBorde;
  static const _borde = ColoresApp.bordesuave;
  static const _sombra = ColoresApp.sombraTarjeta;

  @override
  Widget build(BuildContext context) {
    final tarjeta = _construirTarjeta();

    if (alPresionar != null) {
      return InkWell(
        onTap: alPresionar,
        borderRadius: _obtenerRadio(),
        child: tarjeta,
      );
    }
    return tarjeta;
  }

  Widget _construirTarjeta() {
    return switch (variante) {
      VarianteTarjeta.normal => _tarjetaNormal(),
      VarianteTarjeta.pequena => _tarjetaPequena(),
      VarianteTarjeta.acento => _tarjetaAcento(),
      VarianteTarjeta.degradado => _ContenedorDegradado(
          relleno: relleno ?? const EdgeInsets.all(16), child: child),
      VarianteTarjeta.punteada => _tarjetaPunteada(),
    };
  }

  Widget _tarjetaNormal() => _contenedor(
        relleno: relleno ?? const EdgeInsets.all(14),
        radio: 18,
        fondo: ColoresApp.superficiePrimaria,
        borde: Border.all(color: _borde),
        sombra: _sombra,
      );

  Widget _tarjetaPequena() => _contenedor(
        relleno:
            relleno ?? const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        radio: 12,
        fondo: ColoresApp.superficiePrimaria,
        borde: Border.all(color: _borde),
        sombra: _sombra,
      );

  Widget _tarjetaAcento() => _contenedor(
        relleno: relleno ?? const EdgeInsets.all(14),
        radio: 18,
        fondo: _acentoClaro,
        borde: const Border(
          top: BorderSide(color: _acentoBorde),
          right: BorderSide(color: _acentoBorde),
          bottom: BorderSide(color: _acentoBorde),
          left: BorderSide(color: _acento, width: 3),
        ),
        sombra: Colors.transparent,
      );

  Widget _tarjetaPunteada() => _contenedor(
        relleno: relleno ?? const EdgeInsets.all(14),
        radio: 18,
        fondo: Colors.transparent,
        borde: Border.all(
            color: _acentoBorde,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside),
        sombra: Colors.transparent,
        esPunteada: true,
      );

  Widget _contenedor({
    required EdgeInsets relleno,
    required double radio,
    required Color fondo,
    required BoxBorder borde,
    required Color sombra,
    bool esPunteada = false,
  }) {
    return Container(
      padding: relleno,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(radio),
        border: esPunteada ? null : borde,
        boxShadow: sombra == Colors.transparent
            ? null
            : [
                BoxShadow(
                    color: sombra, blurRadius: 4, offset: const Offset(0, 1)),
              ],
      ),
      child: esPunteada
          ? CustomPaint(
              painter: _PintadorBordePunteado(
                  radio: radio, color: _acentoBorde, grosor: 1.5),
              child: child,
            )
          : child,
    );
  }

  BorderRadius _obtenerRadio() {
    return switch (variante) {
      VarianteTarjeta.pequena => BorderRadius.circular(12),
      _ => BorderRadius.circular(18),
    };
  }
}

// ─── Contenedor con degradado (QR personal, hero cards) ──────────
class _ContenedorDegradado extends StatelessWidget {
  const _ContenedorDegradado({
    required this.child,
    required this.relleno,
  });

  final Widget child;
  final EdgeInsets relleno;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: relleno,
      decoration: BoxDecoration(
        gradient: ColoresApp.degradadoPrincipal,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

// ─── Pintor del borde punteado ───────────────────────────────────
class _PintadorBordePunteado extends CustomPainter {
  _PintadorBordePunteado({
    required this.radio,
    required this.color,
    required this.grosor,
  });

  final double radio;
  final Color color;
  final double grosor;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..strokeWidth = grosor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radio));
    final ruta = Path()..addRRect(rrect);
    final metrica = ruta.computeMetrics().first;
    final longitud = metrica.length;

    const largo = 6.0;
    const espacio = 5.0;
    var distancia = 0.0;

    while (distancia < longitud) {
      final fin = (distancia + largo).clamp(0.0, longitud);
      canvas.drawPath(metrica.extractPath(distancia, fin), pincel);
      distancia += largo + espacio;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
