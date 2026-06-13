import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Navega a una pestaña principal SIN agregar una entrada al historial del
/// navegador.
///
/// `context.go()` por defecto reporta la navegación como "push" → el navegador
/// hace `history.pushState`, acumulando una entrada por cada cambio de pestaña.
/// En una PWA instalada en Android eso permite que el gesto de retroceso del
/// sistema (deslizar desde el borde) muestre la pestaña anterior.
///
/// `Router.neglect` ejecuta la navegación reportándola como "neglect" → el
/// navegador hace `history.replaceState`, reemplazando la entrada actual en
/// lugar de apilar una nueva. Resultado: toda la navegación entre pestañas vive
/// en una única entrada de historial y el gesto de retroceso no tiene ninguna
/// pantalla anterior que pueda asomarse.
void irAPestana(BuildContext context, String ruta) {
  Router.neglect(context, () => context.go(ruta));
}
