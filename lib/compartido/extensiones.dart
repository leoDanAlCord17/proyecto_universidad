import 'package:flutter/material.dart';
import 'widgets/avisos/aviso_app.dart';

extension ContextExtension on BuildContext {
  void mostrarError(String mensaje) {
    AvisoApp.mostrar(this, texto: mensaje, estilo: EstiloAviso.error);
  }
}
