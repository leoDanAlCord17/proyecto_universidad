import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import '../eventos/evento.dart';
import 'escanear_qr_cubit.dart';
import 'escanear_qr_estado.dart';

class EscanearQrPantalla extends StatefulWidget {
  const EscanearQrPantalla({super.key, required this.eventoId});

  final String eventoId;

  @override
  State<EscanearQrPantalla> createState() => _EscanearQrPantallaState();
}

class _EscanearQrPantallaState extends State<EscanearQrPantalla> {
  late final MobileScannerController _controladorCamara;
  bool    _estaCargado = false;
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
    if (_estaCargado) return;
    _estaCargado = true;
    final auth    = context.read<AuthCubit>().state;
    final adminId = auth is Autenticado ? auth.usuario.id : null;
    context.read<EscanearQrCubit>().iniciar(widget.eventoId, adminId: adminId);
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
    context.read<EscanearQrCubit>().procesarQr(rawValue);
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
            // Cámara fuera del subtree del BlocConsumer — nunca se recrea por cambios de estado.
            MobileScanner(controller: _controladorCamara, onDetect: _onDetect),
            BlocConsumer<EscanearQrCubit, EscanearQrEstado>(
              listener: (ctx, state) {
                if (state is EscanearQrListo)        _ultimoQr = null;
                if (state is EscanearQrConfirmado)   HapticFeedback.mediumImpact();
                if (state is EscanearQrYaRegistrado) HapticFeedback.lightImpact();
              },
              builder: _construirOverlay,
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirOverlay(BuildContext context, EscanearQrEstado state) {
    final evento       = _eventoDeEstado(state);
    final presentes    = _presentesDeEstado(state);
    final estaCargando = state is EscanearQrCargando || state is EscanearQrInicial;
    final errorMsg     = state is EscanearQrErrorCarga ? state.mensaje : null;

    return Column(
      children: [
        Container(height: MediaQuery.paddingOf(context).top, color: ColoresApp.scannerFondo),
        evento != null
            ? _Header(
                evento:      evento,
                presentes:   presentes,
                onBack:      () => context.pop(),
                controlador: _controladorCamara,
              )
            : _HeaderPlaceholder(
                onBack:      () => context.pop(),
                controlador: _controladorCamara,
              ),
        _construirAreaEscaneo(state, estaCargando: estaCargando, errorMsg: errorMsg),
      ],
    );
  }

  Widget _construirAreaEscaneo(
    EscanearQrEstado state, {
    required bool    estaCargando,
    required String? errorMsg,
  }) {
    return Expanded(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _construirMarcoEscaneo(state),
          if (estaCargando)
            const ColoredBox(
              color: ColoresApp.scannerFondo,
              child: Center(child: CircularProgressIndicator(color: ColoresApp.acento)),
            ),
          if (errorMsg != null)
            ColoredBox(
              color: ColoresApp.scannerFondo,
              child: _VistaError(mensaje: errorMsg),
            ),
        ],
      ),
    );
  }

  Widget _construirMarcoEscaneo(EscanearQrEstado state) {
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
              painter: _PintorMarco(ventanaRect: ventana, procesando: state is EscanearQrProcesando),
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

  static bool _tieneResultado(EscanearQrEstado s) =>
      s is EscanearQrConfirmado ||
      s is EscanearQrYaRegistrado ||
      s is EscanearQrNoValido;

  static Evento? _eventoDeEstado(EscanearQrEstado s) => switch (s) {
    EscanearQrListo()        => s.evento,
    EscanearQrProcesando()   => s.evento,
    EscanearQrConfirmado()   => s.evento,
    EscanearQrYaRegistrado() => s.evento,
    EscanearQrNoValido()     => s.evento,
    _                        => null,
  };

  static int _presentesDeEstado(EscanearQrEstado s) => switch (s) {
    EscanearQrListo()        => s.presentes,
    EscanearQrProcesando()   => s.presentes,
    EscanearQrConfirmado()   => s.presentes,
    EscanearQrYaRegistrado() => s.presentes,
    EscanearQrNoValido()     => s.presentes,
    _                        => 0,
  };
}

// ─── Header placeholder ────────────────────────────────────────────────────────

class _HeaderPlaceholder extends StatelessWidget {
  const _HeaderPlaceholder({
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
          const Spacer(),
          _BotonLinterna(controlador: controlador),
        ],
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.evento,
    required this.presentes,
    required this.onBack,
    required this.controlador,
  });

  final Evento                  evento;
  final int                     presentes;
  final VoidCallback            onBack;
  final MobileScannerController controlador;

  String _subtitulo() {
    final partes = <String>[];
    if (evento.horaInicio != null && evento.horaFin != null) {
      partes.add('${_formatearHora(evento.horaInicio!)}–${_formatearHora(evento.horaFin!)}');
    }
    if (evento.lugar != null) partes.add(evento.lugar!);
    return partes.join(' · ');
  }

  String _formatearHora(String hora) {
    final p = hora.split(':');
    if (p.length < 2) return hora;
    final h24  = int.tryParse(p[0]) ?? 0;
    final min  = p[1].padLeft(2, '0');
    final h12  = h24 % 12 == 0 ? 12 : h24 % 12;
    final ampm = h24 < 12 ? 'AM' : 'PM';
    return '$h12:$min $ampm';
  }

  Widget _construirInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width:  8,
              height: 8,
              decoration: const BoxDecoration(color: ColoresApp.verde, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                evento.titulo,
                style: const TextStyle(
                  color: ColoresApp.blanco, fontSize: 16, fontWeight: FontWeight.w700, height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (_subtitulo().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            _subtitulo(),
            style: TextStyle(color: ColoresApp.blanco.withValues(alpha: 0.55), fontSize: 12, height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   ColoresApp.scannerFondo,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Row(
        children: [
          _BotonVolver(onTap: onBack),
          const SizedBox(width: 12),
          Expanded(child: _construirInfo()),
          const SizedBox(width: 8),
          _ChipContadorPresentes(presentes: presentes),
          const SizedBox(width: 8),
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

// ─── Chip contador de presentes ───────────────────────────────────────────────

class _ChipContadorPresentes extends StatelessWidget {
  const _ChipContadorPresentes({required this.presentes});
  final int presentes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        ColoresApp.verde.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: ColoresApp.verde.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  6,
            height: 6,
            decoration: const BoxDecoration(
              color: ColoresApp.verde, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Text(
              '$presentes',
              key: ValueKey(presentes),
              style: const TextStyle(
                color:      ColoresApp.verde,
                fontWeight: FontWeight.w800,
                fontSize:   14,
                height:     1.0,
              ),
            ),
          ),
        ],
      ),
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

  final EscanearQrEstado state;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: switch (state) {
        final EscanearQrConfirmado   s => _CardConfirmado(key: const ValueKey('conf'), state: s),
        final EscanearQrYaRegistrado s => _CardYaRegistrado(key: const ValueKey('ya'), state: s),
        EscanearQrNoValido()           => const _CardNoValido(key: ValueKey('inv')),
        _                              => const SizedBox.shrink(key: ValueKey('none')),
      },
    );
  }
}

// ─── Card: confirmado ──────────────────────────────────────────────────────────

class _CardConfirmado extends StatelessWidget {
  const _CardConfirmado({super.key, required this.state});

  final EscanearQrConfirmado state;

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

  Widget _construirBotonConfirmado() {
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
            '✓ Entrada confirmada',
            style: TextStyle(color: ColoresApp.blanco, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subPartes = <String>[
      if (state.cedula != null) state.cedula!,
      if (state.rol    != null) state.rol!,
    ];

    return Container(
      padding:    const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        ColoresApp.scannerVerdeOscuro,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresApp.verde.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _construirEncabezado(),
          const SizedBox(height: 12),
          Text(
            state.nombre,
            style: const TextStyle(
              color: ColoresApp.blanco, fontWeight: FontWeight.w800, fontSize: 20, height: 1.2,
            ),
          ),
          if (subPartes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subPartes.join(' · '),
              style: TextStyle(color: ColoresApp.blanco.withValues(alpha: 0.55), fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          _construirBotonConfirmado(),
        ],
      ),
    );
  }
}

// ─── Card: ya registrado ───────────────────────────────────────────────────────

class _CardYaRegistrado extends StatelessWidget {
  const _CardYaRegistrado({super.key, required this.state});

  final EscanearQrYaRegistrado state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        ColoresApp.scannerAmbarOscuro,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresApp.ambar.withValues(alpha: 0.5), width: 1),
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
                  state.nombre,
                  style: const TextStyle(
                    color: ColoresApp.blanco, fontWeight: FontWeight.w800,
                    fontSize: 15, height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (state.cedula != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    state.cedula!,
                    style: TextStyle(color: ColoresApp.blanco.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  'Esta persona ya marcó su entrada',
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
        border: Border.all(color: ColoresApp.rojo.withValues(alpha: 0.35), width: 1),
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
                  'Este código no pertenece a ningún usuario.',
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

// ─── Vista de error de carga ───────────────────────────────────────────────────

class _VistaError extends StatelessWidget {
  const _VistaError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          mensaje,
          style: const TextStyle(color: ColoresApp.rojo, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
