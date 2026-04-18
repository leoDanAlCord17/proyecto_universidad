import 'package:flutter/material.dart';
import 'package:uniasist/compartido/widgets/tarjetas/tarjeta_app.dart';

class TarjetaEventoCompacta extends StatelessWidget {
  const TarjetaEventoCompacta({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.colorTitulo,
    this.colorSubtitulo,
    this.alPresionar,
  });

  final String titulo;

  /// Texto secundario. Ej: '10:30 · Lab. 2 · 18 esperados'
  final String? subtitulo;

  final Color? colorTitulo;
  final Color? colorSubtitulo;

  /// Si se pasa, toda la tarjeta se vuelve presionable
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      variante:    VarianteTarjeta.pequena,
      alPresionar: alPresionar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color:      colorTitulo,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitulo!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorSubtitulo,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
