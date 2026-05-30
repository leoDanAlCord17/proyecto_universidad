import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import 'escanear_evento_qr_cubit.dart';
import 'escanear_evento_qr_estado.dart';

class EscanearEventoQrPantalla extends StatefulWidget {
  const EscanearEventoQrPantalla({super.key});

  @override
  State<EscanearEventoQrPantalla> createState() => _EscanearEventoQrPantallaState();
}

class _EscanearEventoQrPantallaState extends State<EscanearEventoQrPantalla> {
  late final MobileScannerController _controladorCamara;
  bool    _estaIniciado = false;
  String? _ultimoQr;

  @override
  void initState() {
    super.initState();
    _controladorCamara = MobileScannerController(
      facing:  CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    final auth = context.read<AuthCubit>().state;
    if (auth is Autenticado && auth.usuario.id != null) {
      context.read<EscanearEventoQrCubit>().iniciar(usuarioId: auth.usuario.id!);
    }
  }

  @override
  void dispose() {
    _controladorCamara.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!mounted) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.isEmpty || rawValue == _ultimoQr) return;
    _ultimoQr = rawValue;
    context.read<EscanearEventoQrCubit>().procesarQr(rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness:     Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: ColoresApp.scannerFondo,
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: _controladorCamara, onDetect: _onDetect),
            BlocConsumer<EscanearEventoQrCubit, EscanearEventoQrEstado>(
              listener: (ctx, state) {
                if (state is EscanearEventoQrListo)        _ultimoQr = null;
                if (state is EscanearEventoQrConfirmado)   HapticFeedback.mediumImpact();
                if (state is EscanearEventoQrYaRegistrado) HapticFeedback.lightImpact();
              },
              builder: _construirOverlay,
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirOverlay(BuildContext context, EscanearEventoQrEstado state) {
    return Column(
      children: [
        Container(height: MediaQuery.paddingOf(context).top, color: ColoresApp.scannerFondo),
        _EncabezadoEscaneo(onBack: () => context.pop(), controlador: _controladorCamara),
        _construirAreaEscaneo(state),
      ],
    );
  }

  Widget _construirAreaEscaneo(EscanearEventoQrEstado state) {
    return Expanded(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _construirMarcoEscaneo(state),
        ],
      ),
    );
  }

  Widget _construirMarcoEscaneo(EscanearEventoQrEstado state) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final size     = constraints.biggest;
        final scanSize = size.width * 0.70;
        final ventana  = Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.42),
          width:  scanSize,
          height: scanSize,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              size:    size,
              painter: _PintorMarco(
                ventanaRect: ventana,
                procesando:  state is EscanearEventoQrProcesando,
              ),
            ),
            if (_tieneResultado(state))
              Positioned(
                left:   16,
                right:  16,
                bottom: 32,
                child:  _TarjetaResultado(state: state),
              ),
          ],
        );
      },
    );
  }

  static bool _tieneResultado(EscanearEventoQrEstado s) =>
      s is EscanearEventoQrConfirmado         ||
      s is EscanearEventoQrYaRegistrado       ||
      s is EscanearEventoQrNoDisponible       ||
      s is EscanearEventoQrDirigidoNoPermitido ||
      s is EscanearEventoQrNoValido;
}

// ─── Encabezado ────────────────────────────────────────────────────────────────

class _EncabezadoEscaneo extends StatelessWidget {
  const _EncabezadoEscaneo({
    required this.onBack,
    required this.controlador,
  });
  final VoidCallback            onBack;
  final MobileScannerController controlador;

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   ColoresApp.scannerFondo,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Row(
        children: [
          _BotonVolver(onTap: onBack),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Escanear evento',
              style: TextStyle(color: ColoresApp.blanco, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          _BotonLinterna(controlador: controlador),
        ],
      ),
    );
  }
}

class _BotonVolver extends StatelessWidget {
  const _BotonVolver({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        ColoresApp.blanco.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor:  ColoresApp.blanco.withValues(alpha: 0.2),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: ColoresApp.blanco, size: 18),
        ),
      ),
    );
  }
}

// ─── Botón linterna ────────────────────────────────────────────────────────────

class _BotonLinterna extends StatelessWidget {
  const _BotonLinterna({required this.controlador});
  final MobileScannerController controlador;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controlador,
      builder: (_, scannerState, __) {
        final torchState = scannerState.torchState;
        if (torchState == TorchState.unavailable) return const SizedBox.shrink();
        final encendida = torchState == TorchState.on;
        return Material(
          color:        encendida
              ? ColoresApp.ambar.withValues(alpha: 0.25)
              : ColoresApp.blanco.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap:        controlador.toggleTorch,
            borderRadius: BorderRadius.circular(12),
            splashColor:  ColoresApp.blanco.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                encendida
                    ? Icons.flashlight_on_rounded
                    : Icons.flashlight_off_rounded,
                color: encendida ? ColoresApp.ambar : ColoresApp.blanco,
                size:  20,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Pintor del marco de escaneo ──────────────────────────────────────────────

class _PintorMarco extends CustomPainter {
  const _PintorMarco({required this.ventanaRect, this.procesando = false});

  final Rect ventanaRect;
  final bool procesando;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = ColoresApp.scannerOverlay;
    final r = ventanaRect;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, r.top), overlay);
    canvas.drawRect(Rect.fromLTWH(0, r.bottom, size.width, size.height - r.bottom), overlay);
    canvas.drawRect(Rect.fromLTWH(0, r.top, r.left, r.height), overlay);
    canvas.drawRect(Rect.fromLTWH(r.right, r.top, size.width - r.right, r.height), overlay);

    final cornerPaint = Paint()
      ..color       = procesando ? ColoresApp.ambar : ColoresApp.scannerEsquina
      ..strokeWidth = 3.5
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    _esquina(canvas, cornerPaint, r.topLeft,     esArriba: true,  esIzquierda: true);
    _esquina(canvas, cornerPaint, r.topRight,    esArriba: true,  esIzquierda: false);
    _esquina(canvas, cornerPaint, r.bottomLeft,  esArriba: false, esIzquierda: true);
    _esquina(canvas, cornerPaint, r.bottomRight, esArriba: false, esIzquierda: false);
  }

  void _esquina(
    Canvas canvas,
    Paint  p,
    Offset c, {
    required bool esArriba,
    required bool esIzquierda,
  }) {
    const len = 28.0;
    const rad = 10.0;
    final dx = esIzquierda ? 1.0 : -1.0;
    final dy = esArriba    ? 1.0 : -1.0;

    final path = Path()
      ..moveTo(c.dx + dx * len, c.dy)
      ..lineTo(c.dx + dx * rad, c.dy)
      ..arcToPoint(
          Offset(c.dx, c.dy + dy * rad),
          radius:    const Radius.circular(rad),
          clockwise: esIzquierda == esArriba,
        )
      ..lineTo(c.dx, c.dy + dy * len);

    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_PintorMarco old) =>
      old.ventanaRect != ventanaRect || old.procesando != procesando;
}

// ─── Tarjeta de resultado ──────────────────────────────────────────────────────

class _TarjetaResultado extends StatelessWidget {
  const _TarjetaResultado({required this.state});

  final EscanearEventoQrEstado state;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: switch (state) {
        final EscanearEventoQrConfirmado          s => _CardConfirmado(key: const ValueKey('conf'), state: s),
        final EscanearEventoQrYaRegistrado        s => _CardYaRegistrado(key: const ValueKey('ya'), state: s),
        final EscanearEventoQrNoDisponible        s => _CardNoDisponible(key: const ValueKey('nd'), state: s),
        final EscanearEventoQrDirigidoNoPermitido s => _CardDirigidoNoPermitido(key: const ValueKey('dnp'), state: s),
        EscanearEventoQrNoValido()                  => const _CardNoValido(key: ValueKey('inv')),
        _                                           => const SizedBox.shrink(key: ValueKey('none')),
      },
    );
  }
}

// ─── Card: confirmado ──────────────────────────────────────────────────────────

class _CardConfirmado extends StatelessWidget {
  const _CardConfirmado({super.key, required this.state});

  final EscanearEventoQrConfirmado state;

  Widget _construirEncabezado() {
    return Row(
      children: [
        Container(
          width:      22,
          height:     22,
          decoration: const BoxDecoration(color: ColoresApp.verde, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: ColoresApp.blanco, size: 14),
        ),
        const SizedBox(width: 8),
        const Text(
          'QR detectado',
          style: TextStyle(color: ColoresApp.verde, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    );
  }

  Widget _construirBoton() {
    return Container(
      width:      double.infinity,
      padding:    const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: ColoresApp.verde, borderRadius: BorderRadius.circular(14)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_rounded, color: ColoresApp.blanco, size: 18),
          SizedBox(width: 8),
          Text(
            '✓ Entrada registrada',
            style: TextStyle(color: ColoresApp.blanco, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        ColoresApp.scannerVerdeOscuro,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: ColoresApp.verde.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _construirEncabezado(),
          const SizedBox(height: 12),
          Text(
            state.eventoNombre,
            style: const TextStyle(
              color: ColoresApp.blanco, fontWeight: FontWeight.w800, fontSize: 20, height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _construirBoton(),
        ],
      ),
    );
  }
}

// ─── Card: ya registrado ───────────────────────────────────────────────────────

class _CardYaRegistrado extends StatelessWidget {
  const _CardYaRegistrado({super.key, required this.state});

  final EscanearEventoQrYaRegistrado state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        ColoresApp.scannerAmbarOscuro,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: ColoresApp.ambar.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width:      42,
            height:     42,
            decoration: const BoxDecoration(color: ColoresApp.ambar, shape: BoxShape.circle),
            child: const Icon(Icons.replay_rounded, color: ColoresApp.blanco, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ya registrado',
                  style: TextStyle(
                    color: ColoresApp.ambar, fontWeight: FontWeight.w700, fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.eventoNombre,
                  style: const TextStyle(
                    color: ColoresApp.blanco, fontWeight: FontWeight.w800,
                    fontSize: 15, height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Ya estás registrado en este evento',
                  style: TextStyle(color: ColoresApp.blanco.withValues(alpha: 0.4), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card: evento no disponible ───────────────────────────────────────────────

class _CardNoDisponible extends StatelessWidget {
  const _CardNoDisponible({super.key, required this.state});

  final EscanearEventoQrNoDisponible state;

  Widget _construirEncabezado() {
    return Row(
      children: [
        Container(
          width:      22,
          height:     22,
          decoration: const BoxDecoration(color: ColoresApp.scannerGrisOscuro, shape: BoxShape.circle),
          child: const Icon(Icons.event_busy_rounded, color: ColoresApp.blanco, size: 13),
        ),
        const SizedBox(width: 8),
        const Text(
          'Evento no disponible',
          style: TextStyle(
            color: ColoresApp.scannerGrisClaro, fontWeight: FontWeight.w700, fontSize: 13,),
        ),
      ],
    );
  }

  Widget _construirAviso() {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color:        ColoresApp.scannerGris.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: ColoresApp.scannerGris.withValues(alpha: 0.3)),
      ),
      child: const Text(
        'Este evento ya no acepta registros',
        textAlign: TextAlign.center,
        style: TextStyle(color: ColoresApp.scannerGrisClaro, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        ColoresApp.scannerAzulOscuro,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: ColoresApp.scannerGris.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _construirEncabezado(),
          const SizedBox(height: 12),
          Text(
            state.eventoNombre,
            style: const TextStyle(
              color: ColoresApp.blanco, fontWeight: FontWeight.w800, fontSize: 20, height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _construirAviso(),
        ],
      ),
    );
  }
}

// ─── Card: evento dirigido sin permiso ────────────────────────────────────────

class _CardDirigidoNoPermitido extends StatelessWidget {
  const _CardDirigidoNoPermitido({super.key, required this.state});

  final EscanearEventoQrDirigidoNoPermitido state;

  Widget _construirEncabezado() {
    return Row(
      children: [
        Container(
          width:      22,
          height:     22,
          decoration: const BoxDecoration(color: ColoresApp.rojo, shape: BoxShape.circle),
          child: const Icon(Icons.block_rounded, color: ColoresApp.blanco, size: 13),
        ),
        const SizedBox(width: 8),
        const Text(
          'Sin acceso',
          style: TextStyle(color: ColoresApp.rojo, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    );
  }

  Widget _construirAviso() {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color:        ColoresApp.rojo.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: ColoresApp.rojo.withValues(alpha: 0.3)),
      ),
      child: const Text(
        'Este evento no es para ti · Acércate a un administrador',
        textAlign: TextAlign.center,
        style: TextStyle(color: ColoresApp.rojo, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        ColoresApp.scannerRojoOscuro,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: ColoresApp.rojo.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _construirEncabezado(),
          const SizedBox(height: 12),
          Text(
            state.eventoNombre,
            style: const TextStyle(
              color: ColoresApp.blanco, fontWeight: FontWeight.w800, fontSize: 20, height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _construirAviso(),
        ],
      ),
    );
  }
}

// ─── Card: QR no válido ────────────────────────────────────────────────────────

class _CardNoValido extends StatelessWidget {
  const _CardNoValido({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        ColoresApp.scannerRojoOscuro,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: ColoresApp.rojo.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width:      42,
            height:     42,
            decoration: const BoxDecoration(color: ColoresApp.rojo, shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, color: ColoresApp.blanco, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'QR no válido',
                  style: TextStyle(color: ColoresApp.rojo, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  'Este código no corresponde a ningún evento.',
                  style: TextStyle(color: ColoresApp.blanco.withValues(alpha: 0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
