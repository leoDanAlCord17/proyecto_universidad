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
    this.contadorTexto,
    this.colorContador,
    this.colorTitulo,
    this.colorLugar,
    this.alPresionar,
  });

  final String titulo;
  final String estatus;

  /// Ej: '08:00 – 12:00'
  final String? horario;

  /// Ej: 'Aula 305'
  final String? lugar;

  /// Ej: '35/33' — texto libre del contador de asistentes
  final String? contadorTexto;

  /// Color del punto y texto del contador. Por defecto verde.
  final Color? colorContador;

  final Color? colorTitulo;
  final Color? colorLugar;

  /// Si se pasa, toda la tarjeta se vuelve presionable
  final VoidCallback? alPresionar;

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
          const SizedBox(height: 8),
          Text(
            titulo,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color:      colorTitulo,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (lugar != null) ...[
            const SizedBox(height: 4),
            _FilaLugar(lugar: lugar!, colorLugar: colorLugar),
          ],
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

class _FilaSuperior extends StatelessWidget {
  const _FilaSuperior({required this.estatus, this.horario});

  final String estatus;
  final String? horario;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InsigniaEstado(estatus: estatus),
        const Spacer(),
        if (horario != null)
          Text(
            horario!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

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
        Text(
          lugar,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorLugar,
          ),
        ),
      ],
    );
  }
}

class _FilaContador extends StatelessWidget {
  const _FilaContador({required this.texto, required this.color});

  final String texto;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Row(
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
