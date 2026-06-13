import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Estrategia de URL que, cuando el navegador iría a APILAR una entrada nueva
/// (`pushState`), en su lugar la REEMPLAZA (`replaceState`). Así el historial
/// del navegador nunca crece más allá de 1 entrada.
///
/// Extiende [HashUrlStrategy] (la estrategia por defecto de Flutter web) para
/// no cambiar el formato de las URLs actuales; solo intercepta el apilado.
class _EstrategiaSinAcumular extends HashUrlStrategy {
  @override
  void pushState(Object? state, String title, String url) {
    // history.pushState (apilar) → history.replaceState (reemplazar).
    replaceState(state, title, url);
  }
}

void configurarHistorialSinAcumular() {
  setUrlStrategy(_EstrategiaSinAcumular());
}
