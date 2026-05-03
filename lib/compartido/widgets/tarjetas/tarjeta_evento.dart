import 'package:flutter/material.dart';
import 'package:uniasist/compartido/widgets/indicadores/insignia_estado.dart';
import 'package:uniasist/compartido/widgets/tarjetas/tarjeta_app.dart';
import 'package:uniasist/configuracion/colores_app.dart';

class TarjetaEvento extends StatelessWidget {
  const TarjetaEvento({
    super.key,
    required this.titulo,
    required this.estatus,
    this.horario,
    this.lugar,
    this.descripcion,
    this.contadorTexto,
    this.colorContador,
    this.colorTitulo,
    this.colorLugar,
    this.alPresionar,
    this.alAbrirPanel,
  });

  final String titulo;
  final String estatus;

  /// Ej: '08:00 – 12:00'
  final String? horario;

  /// Ej: 'Aula 305'
  final String? lugar;

  /// Se muestra en dos líneas máximo bajo el título.
  final String? descripcion;

  /// Ej: '35/33' — texto libre del contador de asistentes
  final String? contadorTexto;

  /// Color del punto y texto del contador. Por defecto verde.
  final Color? colorContador;

  final Color? colorTitulo;
  final Color? colorLugar;

  /// Si se pasa, toda la tarjeta se vuelve presionable.
  final VoidCallback? alPresionar;

  /// Si se pasa, muestra el botón de panel de control al pie de la tarjeta.
  final VoidCallback? alAbrirPanel;

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      variante:    VarianteTarjeta.normal,
      alPresionar: alPresionar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilaSuperior(estatus: estatus, horario: horario),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color:      colorTitulo,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (descripcion != null && descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        descripcion!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:  ColoresApp.textoSecundario,
                          height: 1.45,
                        ),
                        maxLines:  2,
                        overflow:  TextOverflow.ellipsis,
                      ),
                    ],
                    if (lugar != null) ...[
                      const SizedBox(height: 6),
                      _FilaLugar(lugar: lugar!, colorLugar: colorLugar),
                    ],
                  ],
                ),
              ),
              if (alAbrirPanel != null) ...[
                const SizedBox(width: 12),
                _BotonPanel(alPresionar: alAbrirPanel!),
              ],
            ],
          ),
          if (contadorTexto != null) ...[
            const SizedBox(height: 8),
            _FilaContador(
              texto: contadorTexto!,
              color: colorContador ?? ColoresApp.verde,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Fila superior: insignia + horario ───────────────────────────────────────

class _FilaSuperior extends StatelessWidget {
  const _FilaSuperior({required this.estatus, this.horario});

  final String  estatus;
  final String? horario;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InsigniaEstado(estatus: estatus),
        const Spacer(),
        if (horario != null)
          Text(
            horario!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:      ColoresApp.textoSecundario,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

// ─── Botón panel (icono con degradado) ───────────────────────────────────────

class _BotonPanel extends StatelessWidget {
  const _BotonPanel({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap:          alPresionar,
        borderRadius:   BorderRadius.circular(10),
        splashColor:    Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Ink(
          decoration: BoxDecoration(
            gradient:     ColoresApp.degradadoPrincipal,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(
            Icons.tune_rounded,
            color: Colors.white,
            size:  16,
          ),
        ),
      ),
    );
  }
}

// ─── Fila lugar ───────────────────────────────────────────────────────────────

class _FilaLugar extends StatelessWidget {
  const _FilaLugar({required this.lugar, this.colorLugar});

  final String lugar;
  final Color? colorLugar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size:  14,
          color: colorLugar ?? ColoresApp.textoSecundario,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            lugar,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorLugar ?? ColoresApp.textoSecundario,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Fila contador ────────────────────────────────────────────────────────────

class _FilaContador extends StatelessWidget {
  const _FilaContador({required this.texto, required this.color});

  final String texto;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width:  8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color:      color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
