import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Escucha el evento nativo `visibilitychange` del navegador y llama a
/// [alReanudar] cuando la pestaña/ventana vuelve a estar visible. Retorna
/// una función para cancelar la suscripción.
VoidCallback? escucharReanudacion(VoidCallback alReanudar) {
  void manejador(web.Event _) {
    if (web.document.visibilityState == 'visible') alReanudar();
  }

  final listener = manejador.toJS;
  web.document.addEventListener('visibilitychange', listener);
  return () => web.document.removeEventListener('visibilitychange', listener);
}
