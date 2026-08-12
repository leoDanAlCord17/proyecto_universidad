// Complementa AppLifecycleState.resumed (WidgetsBindingObserver) con el
// evento nativo `visibilitychange` del navegador — en Flutter Web,
// AppLifecycleState.resumed no siempre se dispara de forma confiable (depende
// del navegador y de cómo la pestaña/ventana pasó a segundo plano), el mismo
// tipo de problema ya resuelto para el gesto de atrás en
// historial_navegador_web.dart / navegacion_principal.dart.
export 'reanudar_app_stub.dart' if (dart.library.html) 'reanudar_app_web.dart';
