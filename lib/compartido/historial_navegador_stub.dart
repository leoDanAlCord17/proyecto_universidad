import 'package:flutter/foundation.dart';

// No-op en plataformas no-web (Android / iOS / desktop): ahí el historial del
// navegador no existe, así que no hay nada que configurar.
void configurarHistorialSinAcumular() {}

/// No-op en plataformas no-web — ver la variante web para la explicación.
VoidCallback? activarCentinelaAtras(VoidCallback alConsumir) => null;
