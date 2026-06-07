import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';

/// Barra ámbar que se muestra en la parte superior de una pantalla cuando
/// el estado proviene de caché local (sin conexión a internet).
///
/// Uso:
///   BannerSinConexion(onReintentar: _cargar)
class BannerSinConexion extends StatelessWidget {
  const BannerSinConexion({super.key, required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Sin conexión — mostrando datos guardados',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: ColoresApp.ambarClaro,
        child: Row(
          children: [
            const ExcludeSemantics(
              child: Icon(Icons.wifi_off_rounded,
                  size: 14, color: ColoresApp.ambar),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  'Sin conexión — mostrando datos guardados',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresApp.ambar,
                      ),
                ),
              ),
            ),
            TextButton(
              onPressed: onReintentar,
              style: TextButton.styleFrom(
                foregroundColor: ColoresApp.ambar,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
