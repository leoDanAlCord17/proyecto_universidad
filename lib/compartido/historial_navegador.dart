// Configura el historial del navegador para que las navegaciones internas NO
// acumulen entradas (se mantiene siempre 1 sola entrada), y expone el truco
// de la "entrada centinela" (activarCentinelaAtras) que usa NavegacionPrincipal
// para poder reaccionar al back/swipe del sistema pese a eso.
//
// Por qué: en la PWA instalada en Android, el gesto de borde (deslizar desde
// la izquierda) dispara el "atrás" del historial del navegador. Mientras
// exista una entrada anterior, Android/Chrome dibuja el "asomo" durante el
// arrastre y recarga la pantalla al soltar — aunque el BackButtonListener
// ya impida cambiar de pantalla. Si el historial nunca crece, no hay entrada
// anterior que dibujar ni a dónde retroceder, así que el gesto desaparece por
// completo. Es la misma idea que ya aplican las pestañas con IndexedStack
// (ver navegacion.dart), pero a nivel global del navegador.
//
// La implementación real vive en la variante web; en Android/iOS/desktop el
// historial del navegador no existe y esto es un no-op.
export 'historial_navegador_stub.dart'
    if (dart.library.html) 'historial_navegador_web.dart';
