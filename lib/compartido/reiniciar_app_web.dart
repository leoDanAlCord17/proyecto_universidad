import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// Recarga la página completa — estado limpio garantizado tras un fallo de
/// arranque. [alFallback] se ignora en web.
void reiniciarApp({required VoidCallback alFallback}) {
  html.window.location.reload();
}
