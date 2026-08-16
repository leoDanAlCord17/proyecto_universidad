import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../configuracion/colores_app.dart';
import '../../extensiones.dart';
import '../../logger.dart';
import 'tarjeta_app.dart';

/// Tarjeta delgada que invita a unirse al grupo de Telegram de la app —
/// se muestra arriba del QR personal en Inicio. Usa [TarjetaApp] (variante
/// pequeña) para heredar el mismo fondo/borde/sombra que el resto de
/// tarjetas de la app en vez de definir un estilo propio.
class TarjetaTelegram extends StatelessWidget {
  const TarjetaTelegram({super.key});

  static const _enlaceGrupo = 'https://t.me/+8EOIbdJ9GMk0YzBh';

  Future<void> _abrirGrupo(BuildContext context) async {
    final uri = Uri.parse(_enlaceGrupo);
    try {
      final abierto =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abierto && context.mounted) {
        context.mostrarError('No se pudo abrir Telegram.');
      }
    } catch (e, st) {
      log.w('No se pudo abrir el enlace de Telegram', error: e, stackTrace: st);
      if (context.mounted) context.mostrarError('No se pudo abrir Telegram.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      variante: VarianteTarjeta.pequena,
      alPresionar: () => _abrirGrupo(context),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ColoresApp.telegramAzulClaro,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const FaIcon(
              FontAwesomeIcons.telegram,
              color: ColoresApp.telegramAzul,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Únete a nuestro grupo de Telegram',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Novedades, avisos y soporte',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: ColoresApp.textoTerciario,
            size: 20,
          ),
        ],
      ),
    );
  }
}
