import 'package:flutter/material.dart';
import '../../../configuracion/colores_app.dart';

/// Widget de error centralizado que reemplaza todas las clases _VistaError
/// privadas en las pantallas de la app.
///
/// Muestra un ícono en contenedor rojo, el mensaje de error y opcionalmente
/// un botón "Reintentar" cuando se pasa [alReintentar].
class VistaErrorApp extends StatelessWidget {
  const VistaErrorApp({
    super.key,
    required this.mensaje,
    this.alReintentar,
  });

  final String mensaje;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: ColoresApp.rojoClaro,
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: ColoresApp.rojo,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresApp.textoSecundario,
                  ),
            ),
            if (alReintentar != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: alReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
