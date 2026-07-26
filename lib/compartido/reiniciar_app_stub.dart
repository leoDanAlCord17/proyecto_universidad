import 'package:flutter/foundation.dart';

/// No-op en plataformas no-web: no existe un equivalente universal a
/// recargar la página. Se usa [alFallback] para reintentar la
/// inicialización en memoria en su lugar.
void reiniciarApp({required VoidCallback alFallback}) {
  alFallback();
}
