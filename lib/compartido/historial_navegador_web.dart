import 'package:flutter/foundation.dart';
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

  /// Empuja una entrada REAL de historial (bypassea el override de arriba
  /// llamando directo a `super.pushState`), con la misma URL visible — no
  /// navega a ningún lado, solo le da al navegador algo que "consumir" en
  /// el próximo back/swipe del sistema. Ver [activarCentinelaAtras].
  void empujarCentinela() => super.pushState(_estadoCentinela, '', getPath());
}

const _estadoCentinela = {'centinela': true};

_EstrategiaSinAcumular? _estrategia;

void configurarHistorialSinAcumular() {
  final estrategia = _EstrategiaSinAcumular();
  _estrategia = estrategia;
  setUrlStrategy(estrategia);
}

/// Activa el truco de la "entrada centinela": empuja una entrada de
/// historial real para que el PRIMER back/swipe del sistema tenga algo que
/// consumir, en vez de cerrar la PWA de inmediato. Sin ninguna entrada
/// previa en el historial (que es lo que [configurarHistorialSinAcumular]
/// deja, a propósito, para evitar el bug de "asomo" de pantalla anterior),
/// Android cierra la app antes de que Flutter tenga oportunidad de
/// reaccionar — confirmado en dispositivo real.
///
/// Cada vez que el usuario consume la entrada, se llama a [alConsumir] y se
/// repone otra automáticamente para el próximo back. [alConsumir] es
/// responsable de filtrar los casos que no le corresponden (p. ej. estar
/// debajo de una pantalla empujada) — ver NavegacionPrincipal.
///
/// Retorna una función para cancelar la suscripción, o `null` si el
/// historial sin acumular todavía no se configuró.
VoidCallback? activarCentinelaAtras(VoidCallback alConsumir) {
  final estrategia = _estrategia;
  if (estrategia == null) return null;
  estrategia.empujarCentinela();
  return estrategia.addPopStateListener((_) {
    estrategia.empujarCentinela();
    alConsumir();
  });
}
