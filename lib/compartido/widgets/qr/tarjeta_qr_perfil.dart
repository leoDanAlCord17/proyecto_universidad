import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';
import 'qr_usuario.dart';

class TarjetaQrPerfil extends StatelessWidget {
  const TarjetaQrPerfil({
    super.key,
    required this.usuarioId,
    this.roles           = const [],
    this.tagPrincipal,
    this.tagsSecundarios = const [],
  });

  final String       usuarioId;
  final List<String> roles;
  final String?      tagPrincipal;
  final List<String> tagsSecundarios;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient:     ColoresApp.degradadoPrincipal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MI CÓDIGO QR PERSONAL',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:          ColoresApp.acentoBorde,
              fontWeight:    FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ContenedorQr(usuarioId: usuarioId),
              const SizedBox(width: 16),
              Expanded(
                child: _ColumnaInfo(
                  roles:        roles,
                  tagPrincipal: tagPrincipal,
                ),
              ),
            ],
          ),
          if (tagsSecundarios.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _EtiquetaSeccion('Tags secundarios'),
            const SizedBox(height: 6),
            _FilaScrollChips(chips: tagsSecundarios),
          ],
        ],
      ),
    );
  }
}

// ─── QR ──────────────────────────────────────────────────────────────────────

class _ContenedorQr extends StatelessWidget {
  const _ContenedorQr({required this.usuarioId});

  final String usuarioId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: QrUsuario(usuarioId: usuarioId, tamanio: 110),
    );
  }
}

// ─── Columna derecha ──────────────────────────────────────────────────────────

class _ColumnaInfo extends StatelessWidget {
  const _ColumnaInfo({
    required this.roles,
    required this.tagPrincipal,
  });

  final List<String> roles;
  final String?      tagPrincipal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (roles.isNotEmpty) ...[
          const _EtiquetaSeccion('Roles'),
          const SizedBox(height: 6),
          _FilaScrollChips(chips: roles),
          const SizedBox(height: 12),
        ],
        if (tagPrincipal != null) ...[
          const _EtiquetaSeccion('Tag Principal'),
          const SizedBox(height: 6),
          _FilaScrollChips(chips: [tagPrincipal!]),
        ],
      ],
    );
  }
}

// ─── Etiqueta de sección ──────────────────────────────────────────────────────

class _EtiquetaSeccion extends StatelessWidget {
  const _EtiquetaSeccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color:      Colors.white.withValues(alpha: 0.75),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─── Fila con scroll horizontal ───────────────────────────────────────────────

class _FilaScrollChips extends StatelessWidget {
  const _FilaScrollChips({required this.chips});

  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            _ChipPerfil(texto: chips[i]),
            if (i < chips.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

// ─── Chip individual ──────────────────────────────────────────────────────────

class _ChipPerfil extends StatelessWidget {
  const _ChipPerfil({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
        border:       Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color:      Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
