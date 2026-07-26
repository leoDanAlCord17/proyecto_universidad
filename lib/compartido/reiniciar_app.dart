// Reinicia la app tras un fallo de arranque (p. ej. Supabase no respondió).
//
// Por qué recargar la página entera en vez de solo reintentar la
// inicialización en memoria: si el timeout de `main.dart` se cumplió pero la
// llamada original (`Supabase.initialize`, etc.) sigue viva en segundo plano
// y termina completándose más tarde, invocarla una segunda vez podría chocar
// con esa inicialización tardía. Recargar la página garantiza un estado
// limpio. En plataformas no-web no existe ese riesgo de recarga, así que se
// usa un reintento en memoria como respaldo razonable.
export 'reiniciar_app_stub.dart'
    if (dart.library.html) 'reiniciar_app_web.dart';
