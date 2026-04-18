import 'package:flutter/material.dart';
import 'package:uniasist/configuracion/colores_app.dart';

extension ContextExtension on BuildContext {
  /// Muestra un SnackBar de error con el estilo estándar de la app.
  /// Usar en listeners de BlocConsumer en lugar de duplicar el SnackBar.
  void mostrarError(String mensaje) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content:         Text(mensaje),
        backgroundColor: ColoresApp.rojo,
      ),
    );
  }
}
