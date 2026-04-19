import 'package:flutter/material.dart';
import 'package:uniasist/compartido/widgets/qr/qr_usuario.dart';
import 'package:uniasist/configuracion/colores_app.dart';

class TarjetaQrUsuario extends StatelessWidget {
  const TarjetaQrUsuario({
    super.key,
    required this.usuarioId,
  });

  final String usuarioId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color:      ColoresApp.sombraTarjeta,
            blurRadius: 4,
            offset:     Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MI CÓDIGO QR',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        ColoresApp.superficiePrimaria,
              borderRadius: BorderRadius.circular(16),
              border:       Border.all(color: ColoresApp.acentoBorde, width: 1.5),
            ),
            child: QrUsuario(usuarioId: usuarioId, tamanio: 180),
          ),
          const SizedBox(height: 20),
          Text(
            'Muéstralo al organizador para que\nescanee y registre tu entrada',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
