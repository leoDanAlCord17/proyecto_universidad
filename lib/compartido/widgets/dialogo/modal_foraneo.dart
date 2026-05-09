import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';

class ModalForaneo extends StatefulWidget {
  const ModalForaneo({super.key, required this.onRegistrar});

  final Future<void> Function({
    required String primerNombre,
    required String primerApellido,
    required String cedula,
    String? contacto,
  }) onRegistrar;

  static void mostrar(
    BuildContext context, {
    required Future<void> Function({
      required String primerNombre,
      required String primerApellido,
      required String cedula,
      String? contacto,
    }) onRegistrar,
  }) {
    showDialog<void>(
      context:      context,
      barrierColor: ColoresApp.sombraBarrera,
      builder:      (_) => ModalForaneo(onRegistrar: onRegistrar),
    );
  }

  @override
  State<ModalForaneo> createState() => _ModalForaneoState();
}

class _ModalForaneoState extends State<ModalForaneo> {
  final _nombreCtrl   = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _cedulaCtrl   = TextEditingController();
  final _contactoCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _cedulaCtrl.dispose();
    _contactoCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final nombre   = _nombreCtrl.text.trim();
    final apellido = _apellidoCtrl.text.trim();
    final cedula   = _cedulaCtrl.text.trim();
    if (nombre.isEmpty || apellido.isEmpty || cedula.isEmpty) return;
    setState(() => _guardando = true);
    try {
      await widget.onRegistrar(
        primerNombre:   nombre,
        primerApellido: apellido,
        cedula:         cedula,
        contacto:       _contactoCtrl.text.trim().isNotEmpty
                            ? _contactoCtrl.text.trim()
                            : null,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CuerpoModal(
      guardando:    _guardando,
      nombreCtrl:   _nombreCtrl,
      apellidoCtrl: _apellidoCtrl,
      cedulaCtrl:   _cedulaCtrl,
      contactoCtrl: _contactoCtrl,
      onRegistrar:  _registrar,
    );
  }
}

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class _CuerpoModal extends StatelessWidget {
  const _CuerpoModal({
    required this.guardando,
    required this.nombreCtrl,
    required this.apellidoCtrl,
    required this.cedulaCtrl,
    required this.contactoCtrl,
    required this.onRegistrar,
  });

  final bool                  guardando;
  final TextEditingController nombreCtrl;
  final TextEditingController apellidoCtrl;
  final TextEditingController cedulaCtrl;
  final TextEditingController contactoCtrl;
  final VoidCallback          onRegistrar;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:    const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: ColoresApp.sombraGeneral, blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Encabezado(),
            const SizedBox(height: 16),
            _FilaNombreApellido(nombreCtrl: nombreCtrl, apellidoCtrl: apellidoCtrl),
            const SizedBox(height: 12),
            TextFormField(controller: cedulaCtrl, decoration: const InputDecoration(hintText: 'Cédula o pasaporte *')),
            const SizedBox(height: 12),
            TextFormField(
              controller:  contactoCtrl,
              decoration:  const InputDecoration(hintText: 'Contacto (opcional)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _BotonRegistrar(guardando: guardando, onTap: onRegistrar),
          ],
        ),
      ),
    );
  }
}

// ─── Encabezado ───────────────────────────────────────────────────────────────

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REGISTRAR INVITADO FORÁNEO',
          style: texto.labelSmall?.copyWith(
            color: ColoresApp.textoSecundario, fontWeight: FontWeight.w800,
            letterSpacing: 0.8, fontSize: 11,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color:        ColoresApp.superficieTerciar,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline_rounded, size: 22, color: ColoresApp.textoSecundario),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Persona sin cuenta en el\nsistema',
                style: texto.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Fila nombre / apellido ───────────────────────────────────────────────────

class _FilaNombreApellido extends StatelessWidget {
  const _FilaNombreApellido({required this.nombreCtrl, required this.apellidoCtrl});
  final TextEditingController nombreCtrl;
  final TextEditingController apellidoCtrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: TextFormField(
          controller:             nombreCtrl,
          decoration:             const InputDecoration(hintText: 'Primer nombre'),
          textCapitalization:     TextCapitalization.words,
        )),
        const SizedBox(width: 10),
        Expanded(child: TextFormField(
          controller:             apellidoCtrl,
          decoration:             const InputDecoration(hintText: 'Primer apellido'),
          textCapitalization:     TextCapitalization.words,
        )),
      ],
    );
  }
}

// ─── Botón registrar ──────────────────────────────────────────────────────────

class _BotonRegistrar extends StatelessWidget {
  const _BotonRegistrar({required this.guardando, required this.onTap});
  final bool         guardando;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color:        ColoresApp.textoPrimario,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap:        guardando ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor:  Colors.white.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: guardando
                ? const Center(child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Registrar como invitado y\nmarcar entrada',
                          style: texto.titleSmall?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700,
                            fontSize: 14, height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
