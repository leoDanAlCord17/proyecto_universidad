import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../configuracion/colores_app.dart';

class ModalQrEvento extends StatefulWidget {
  const ModalQrEvento({super.key, required this.eventoId, this.horaFin});

  final String  eventoId;
  final String? horaFin;

  static void mostrar(
    BuildContext context, {
    required String  eventoId,
    String?          horaFin,
  }) {
    showDialog<void>(
      context:      context,
      barrierColor: ColoresApp.sombraBarrera,
      builder:      (_) => ModalQrEvento(eventoId: eventoId, horaFin: horaFin),
    );
  }

  @override
  State<ModalQrEvento> createState() => _ModalQrEventoState();
}

class _ModalQrEventoState extends State<ModalQrEvento> {
  Timer?   _timer;
  Duration _restante = Duration.zero;
  bool     _caducado = false;

  @override
  void initState() {
    super.initState();
    _calcularRestante();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(_calcularRestante),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calcularRestante() {
    final objetivo = _objetivo();
    if (objetivo == null) { _restante = Duration.zero; return; }
    final diff = objetivo.difference(DateTime.now());
    if (diff.isNegative) {
      _restante = Duration.zero;
      _caducado = true;
    } else {
      _restante = diff;
      _caducado = false;
    }
  }

  DateTime? _objetivo() {
    final horaFin = widget.horaFin;
    if (horaFin == null) return null;
    final p = horaFin.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    final s = p.length >= 3 ? (int.tryParse(p[2]) ?? 0) : 0;
    final hoy = DateTime.now();
    return DateTime(hoy.year, hoy.month, hoy.day, h, m, s);
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String get _tiempoTexto {
    final h = _restante.inHours;
    final m = _restante.inMinutes.remainder(60);
    final s = _restante.inSeconds.remainder(60);
    return '${_pad(h)}:${_pad(m)}:${_pad(s)}';
  }

  String get _horaCierreTexto {
    final horaFin = widget.horaFin;
    if (horaFin == null) return '--:--';
    final p = horaFin.split(':');
    if (p.length < 2) return horaFin;
    final h       = int.tryParse(p[0]) ?? 0;
    final m       = p[1];
    final periodo = h < 12 ? 'AM' : 'PM';
    final h12     = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $periodo';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:    const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _caducado ? ColoresApp.bordeError : const Color(0x261A9462),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(color: ColoresApp.sombraGeneral, blurRadius: 28, offset: Offset(0, 8)),
          ],
        ),
        child: _caducado
            ? _VistaCaducada(
                horaCierreTexto: _horaCierreTexto,
                eventoId:        widget.eventoId,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SeccionVerde(tiempoTexto: _tiempoTexto, horaCierreTexto: _horaCierreTexto),
                  _SeccionQr(eventoId: widget.eventoId),
                ],
              ),
      ),
    );
  }
}

// ─── Vista caducada ───────────────────────────────────────────────────────────

class _VistaCaducada extends StatelessWidget {
  const _VistaCaducada({required this.horaCierreTexto, required this.eventoId});
  final String horaCierreTexto;
  final String eventoId;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EncabezadoCaducado(texto: texto),
            const SizedBox(height: 14),
            _TarjetaAviso(horaCierreTexto: horaCierreTexto, texto: texto),
            const SizedBox(height: 20),
            _QrBloqueado(eventoId: eventoId),
            const SizedBox(height: 16),
            Text(
              'Contacta al coordinador para correcciones',
              style: texto.bodySmall?.copyWith(
                color:      ColoresApp.acento,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoCaducado extends StatelessWidget {
  const _EncabezadoCaducado({required this.texto});
  final TextTheme texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(color: ColoresApp.rojo, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          'QR Caducado',
          style: texto.labelSmall?.copyWith(
            color: ColoresApp.rojo, fontWeight: FontWeight.w700, fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          'Evento finalizado',
          style: texto.labelSmall?.copyWith(color: ColoresApp.textoTerciario, fontSize: 12),
        ),
      ],
    );
  }
}

class _TarjetaAviso extends StatelessWidget {
  const _TarjetaAviso({required this.horaCierreTexto, required this.texto});
  final String    horaCierreTexto;
  final TextTheme texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        ColoresApp.rojoClaro,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: ColoresApp.bordeError, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.cancel_outlined, color: ColoresApp.rojo, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Este QR ya no es válido',
                  style: texto.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'El evento cerró a las $horaCierreTexto. Código desactivado automáticamente.',
                  style: texto.bodySmall?.copyWith(
                    color:  ColoresApp.textoSecundario,
                    height: 1.45,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrBloqueado extends StatelessWidget {
  const _QrBloqueado({required this.eventoId});
  final String eventoId;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 0.12,
          child: QrImageView(
            data:            eventoId,
            version:         QrVersions.auto,
            size:            180,
            eyeStyle:        const QrEyeStyle(eyeShape: QrEyeShape.square, color: ColoresApp.textoSecundario),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: ColoresApp.textoSecundario),
            backgroundColor: Colors.white,
          ),
        ),
        Container(
          padding:    const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        ColoresApp.superficieSecund,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.lock_rounded, size: 30, color: ColoresApp.textoSecundario),
        ),
      ],
    );
  }
}

// ─── Sección verde ────────────────────────────────────────────────────────────

class _SeccionVerde extends StatelessWidget {
  const _SeccionVerde({required this.tiempoTexto, required this.horaCierreTexto});
  final String tiempoTexto;
  final String horaCierreTexto;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        color:        ColoresApp.verdeClaro,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _LadoIzquierdo(texto: texto, tiempoTexto: tiempoTexto)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Cierre', style: texto.labelSmall?.copyWith(color: ColoresApp.textoSecundario, fontSize: 11)),
              const SizedBox(height: 3),
              Text(horaCierreTexto, style: texto.titleMedium?.copyWith(color: ColoresApp.textoPrimario, fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LadoIzquierdo extends StatelessWidget {
  const _LadoIzquierdo({required this.texto, required this.tiempoTexto});
  final TextTheme texto;
  final String    tiempoTexto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(color: ColoresApp.verde, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text('TIEMPO RESTANTE', style: texto.labelSmall?.copyWith(
              color: ColoresApp.textoPrimario, fontWeight: FontWeight.w800,
              letterSpacing: 0.8, fontSize: 11,
            )),
          ],
        ),
        const SizedBox(height: 5),
        Text(tiempoTexto, style: texto.displaySmall?.copyWith(
          color: ColoresApp.verde, fontWeight: FontWeight.w800,
          fontSize: 38, letterSpacing: 1.5, height: 1.0,
        )),
      ],
    );
  }
}

// ─── Sección QR ───────────────────────────────────────────────────────────────

class _SeccionQr extends StatelessWidget {
  const _SeccionQr({required this.eventoId});
  final String eventoId;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1A1A9462), width: 1),
              boxShadow: const [BoxShadow(color: ColoresApp.sombraTarjeta, blurRadius: 10, offset: Offset(0, 3))],
            ),
            child: QrImageView(
              data:            eventoId,
              version:         QrVersions.auto,
              size:            190,
              eyeStyle:        const QrEyeStyle(eyeShape: QrEyeShape.square, color: ColoresApp.acento),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: ColoresApp.acento),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: texto.bodySmall?.copyWith(color: ColoresApp.textoSecundario, height: 1.5),
              children: const [
                TextSpan(text: 'Los asistentes escanean este '),
                TextSpan(text: 'código', style: TextStyle(color: ColoresApp.acento, fontWeight: FontWeight.w700)),
                TextSpan(text: ' para\nregistrarse'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
