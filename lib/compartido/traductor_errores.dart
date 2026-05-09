import 'package:supabase_flutter/supabase_flutter.dart';
import 'constantes.dart';

/// Convierte errores técnicos de Supabase en mensajes legibles para el usuario.
///
/// Uso en repositorios:
///   on AuthException catch (e)      { throw FallaAutenticacion(TraductorErrores.deAuth(e)); }
///   on PostgrestException catch (e) { throw FallaServidor(TraductorErrores.dePostgres(e)); }
///   catch (e)                       { throw FallaInesperada(TraductorErrores.deInesperado(e)); }
class TraductorErrores {
  TraductorErrores._();

  /// Traduce errores de Supabase Auth (login, registro, sesión).
  static String deAuth(AuthException e) {
    final porCodigo = switch (e.statusCode) {
      '400' => 'Correo o contraseña incorrectos.',
      '422' => 'El formato del correo no es válido.',
      '429' => 'Demasiados intentos. Espera unos minutos e intenta de nuevo.',
      '500' => MensajesError.conexion,
      _     => null,
    };

    return porCodigo ?? _deAuthPorMensaje(e.message);
  }

  /// Traduce errores de base de datos PostgreSQL / PostgREST.
  static String dePostgres(PostgrestException e) {
    return switch (e.code) {
      // Postgres
      '23505'    => 'Ya existe un registro con esos datos.',
      '23503'    => 'La operación no es válida: referencia inexistente.',
      '23502'    => 'Faltan datos obligatorios.',
      '42501'    => MensajesError.permiso,
      // PostgREST
      'PGRST116' => 'No se encontraron resultados.',
      'PGRST201' => MensajesError.inesperado,
      'PGRST301' => MensajesError.sesion,
      'PGRST204' => 'No se encontraron resultados.',
      _          => MensajesError.inesperado,
    };
  }

  /// Último recurso para errores no clasificados.
  /// Detecta errores de red para dar un mensaje más útil.
  static String deInesperado(Object e) {
    final texto = e.toString().toLowerCase();
    if (texto.contains('socketexception') ||
        texto.contains('network')         ||
        texto.contains('connection')) {
      return MensajesError.conexion;
    }
    return MensajesError.inesperado;
  }

  // Fallback por contenido del mensaje cuando el statusCode no alcanza
  static String _deAuthPorMensaje(String mensaje) {
    final m = mensaje.toLowerCase();
    if (m.contains('already registered'))  return 'Este correo ya tiene una cuenta. Inicia sesión.';
    if (m.contains('email not confirmed')) return 'Debes confirmar tu correo antes de ingresar.';
    if (m.contains('password should be'))  return 'La contraseña debe tener al menos 8 caracteres e incluir un número.';
    if (m.contains('signup is disabled'))  return 'El registro no está disponible en este momento.';
    if (m.contains('invalid'))             return 'Correo o contraseña incorrectos.';
    return MensajesError.inesperado;
  }
}
