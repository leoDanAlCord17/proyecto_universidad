import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';

class TarjetaBorradorEvento extends StatelessWidget {
  const TarjetaBorradorEvento({
    super.key,
    required this.titulo,
    required this.horario,
    required this.descripcion,
    required this.estaPublicando,
    required this.alVerDetalles,
    required this.alPublicar,
    required this.alOlvidar,
  });

  final String titulo;
  final String horario;
  final String descripcion;
  final bool estaPublicando;
  final VoidCallback alVerDetalles;
  final VoidCallback alPublicar;
  final VoidCallback alOlvidar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
              color: ColoresApp.sombraTarjeta,
              blurRadius: 4,
              offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoPrimario,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 14, color: ColoresApp.textoTerciario),
              const SizedBox(width: 4),
              Text(
                horario,
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (descripcion.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _BotonOlvidar(alPresionar: alOlvidar),
              const SizedBox(width: 10),
              Expanded(child: _BotonDetalles(alPresionar: alVerDetalles)),
              const SizedBox(width: 10),
              Expanded(
                child: _BotonPublicar(
                  estaPublicando: estaPublicando,
                  alPresionar: alPublicar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Botón Olvidar ────────────────────────────────────────────────────────────

class _BotonOlvidar extends StatelessWidget {
  const _BotonOlvidar({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Olvidar borrador',
      child: SizedBox(
        width: 42,
        height: 42,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: alPresionar,
            borderRadius: BorderRadius.circular(12),
            highlightColor: ColoresApp.rojoClaro,
            splashColor: ColoresApp.bordeError,
            child: Ink(
              decoration: BoxDecoration(
                border: Border.all(color: ColoresApp.bordeError),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: ColoresApp.rojo,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Botón Detalles ───────────────────────────────────────────────────────────

class _BotonDetalles extends StatelessWidget {
  const _BotonDetalles({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: alPresionar,
          borderRadius: BorderRadius.circular(12),
          highlightColor: ColoresApp.superficieTerciar,
          splashColor: ColoresApp.bordeMedio,
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(color: ColoresApp.bordeMedio),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Ver detalles',
                style: TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Botón Publicar ───────────────────────────────────────────────────────────

class _BotonPublicar extends StatelessWidget {
  const _BotonPublicar({
    required this.estaPublicando,
    required this.alPresionar,
  });

  final bool estaPublicando;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: estaPublicando ? null : alPresionar,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              gradient: ColoresApp.degradadoPrincipal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: estaPublicando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: ColoresApp.blanco,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Publicar',
                      style: TextStyle(
                        color: ColoresApp.blanco,
                        fontSize: 13,
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
