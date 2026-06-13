import 'package:flutter/foundation.dart';

/// Controla cuál pestaña está activa en la barra de navegación principal.
///
/// Es un singleton global a propósito: tanto la barra inferior como pantallas
/// externas (p.ej. al terminar de crear un evento) cambian de pestaña asignando
/// `pestanaActiva.value = indice`, SIN navegar por el router.
///
/// Por qué importa: si cambiar de pestaña fuera una navegación del router, el
/// navegador haría `pushState` y acumularía una entrada de historial por cada
/// pestaña. En una PWA instalada en Android eso permite que el gesto de
/// retroceso (deslizar desde el borde izquierdo) muestre y entre a la pestaña
/// anterior. Al cambiar de pestaña por estado interno (un `IndexedStack`) el
/// historial del navegador nunca crece, así que el gesto no tiene ninguna
/// pantalla anterior que mostrar.
///
/// Los índices coinciden con [BarraNavegacionApp]:
/// 0 = Inicio, 1 = Eventos, 3 = Asistencia, 4 = Perfil.
/// (El índice 2, Escanear, no es una pestaña: abre una pantalla aparte.)
final ValueNotifier<int> pestanaActiva = ValueNotifier<int>(0);
