import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uniasist/configuracion/colores_app.dart';

class QrUsuario extends StatelessWidget {
  const QrUsuario({
    super.key,
    required this.usuarioId,
    this.tamanio = 200,
  });

  final String usuarioId;
  final double tamanio;

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data:            usuarioId,
      version:         QrVersions.auto,
      size:            tamanio,
      eyeStyle:        const QrEyeStyle(
        eyeShape:  QrEyeShape.square,
        color:     ColoresApp.acento,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color:           ColoresApp.textoPrimario,
      ),
      backgroundColor: ColoresApp.superficiePrimaria,
    );
  }
}
