import 'package:flutter/foundation.dart';

// No-op en plataformas no-web: ahí AppLifecycleState.resumed ya es
// confiable, no hace falta el respaldo del evento del navegador.
VoidCallback? escucharReanudacion(VoidCallback alReanudar) => null;
