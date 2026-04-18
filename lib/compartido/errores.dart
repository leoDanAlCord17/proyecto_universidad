/// Error de base de datos o comunicación con Supabase.
/// Se lanza cuando una consulta a la tabla falla (PostgrestException).
class FallaServidor implements Exception {
  final String mensaje;
  const FallaServidor(this.mensaje);
}

/// Error de autenticación.
/// Se lanza cuando las credenciales son incorrectas, el correo ya existe,
/// la contraseña es inválida, o la sesión expira (AuthException).
class FallaAutenticacion implements Exception {
  final String mensaje;
  const FallaAutenticacion(this.mensaje);
}

/// Error no clasificado o inesperado.
/// Se lanza como último recurso cuando el error no es de Supabase.
class FallaInesperada implements Exception {
  final String mensaje;
  const FallaInesperada(this.mensaje);
}
