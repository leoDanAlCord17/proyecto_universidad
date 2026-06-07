import 'errores.dart';

/// Reintenta [operacion] cuando lanza [FallaRed] (error de red transitorio).
///
/// Aplica backoff lineal: espera [esperaBase] × intento entre cada reintento.
/// Cualquier otro error ([FallaServidor], [FallaAutenticacion], etc.) se
/// relanza inmediatamente sin reintentar.
///
/// Uso:
/// ```dart
/// return await conReintentos(() async {
///   final datos = await _supabase.from('tabla').select();
///   return datos.map(Modelo.desdeJson).toList();
/// });
/// ```
Future<T> conReintentos<T>(
  Future<T> Function() operacion, {
  int      maxIntentos = 2,
  Duration esperaBase  = const Duration(milliseconds: 800),
}) async {
  var intentos = 0;
  while (true) {
    try {
      return await operacion();
    } on FallaRed {
      intentos++;
      if (intentos >= maxIntentos) rethrow;
      await Future.delayed(esperaBase * intentos);
    }
  }
}
