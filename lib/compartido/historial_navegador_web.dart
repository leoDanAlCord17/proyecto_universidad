import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Estrategia de URL que, cuando el navegador iría a APILAR una entrada nueva
/// (`pushState`), en su lugar la REEMPLAZA (`replaceState`). Así el historial
/// del navegador nunca crece más allá de 1 entrada.
///
/// Extiende [PathUrlStrategy] (URLs limpias: `/eventos` en vez de
/// `/#/eventos`) en lugar de usar el helper `usePathUrlStrategy()` de
/// Flutter directamente, porque necesitamos conservar el override de
/// `pushState` de abajo. El servidor debe reescribir cualquier ruta a
/// `index.html` para que las URLs limpias sobrevivan un F5 — ya configurado
/// en `vercel.json`.
class _EstrategiaSinAcumular extends PathUrlStrategy {
  @override
  void pushState(Object? state, String title, String url) {
    // history.pushState (apilar) → history.replaceState (reemplazar).
    replaceState(state, title, url);
  }
}

void configurarHistorialSinAcumular() {
  setUrlStrategy(_EstrategiaSinAcumular());
}
