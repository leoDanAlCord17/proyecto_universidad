/// Error de base de datos o comunicación con Supabase.
/// Se lanza cuando una consulta a la tabla falla (PostgrestException).
class FallaServidor implements Exception {
  const FallaServidor(this.mensaje);
  final String mensaje;
}

/// Error de autenticación.
/// Se lanza cuando las credenciales son incorrectas, el correo ya existe,
/// la contraseña es inválida, o la sesión expira (AuthException).
class FallaAutenticacion implements Exception {
  const FallaAutenticacion(this.mensaje);
  final String mensaje;
}

/// Error de red o conectividad.
/// Se lanza cuando no hay conexión a internet o el host no responde.
class FallaRed implements Exception {
  const FallaRed(this.mensaje);
  final String mensaje;
}

/// Error no clasificado o inesperado.
/// Se lanza como último recurso cuando el error no es de Supabase ni de red.
class FallaInesperada implements Exception {
  const FallaInesperada(this.mensaje);
  final String mensaje;
}
