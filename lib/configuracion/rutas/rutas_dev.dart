import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../configuracion/entorno.dart';
import '../../dev/vista_fuentes_pantalla.dart';
import '../../dev/vista_widgets_pantalla.dart';

/// Rutas exclusivas del entorno de desarrollo.
/// Se incluyen en el router solo cuando [kDebugMode] es true y el entorno es dev.
List<GoRoute> get rutasDev => [
      if (kDebugMode && entorno.esDev)
        GoRoute(
          path: Rutas.vistaWidgets,
          builder: (context, state) => const VistaWidgetsPantalla(),
        ),
      if (kDebugMode && entorno.esDev)
        GoRoute(
          path: Rutas.vistaFuentes,
          builder: (context, state) => const VistaFuentesPantalla(),
        ),
    ];
