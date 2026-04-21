/// Nombres exactos de las tablas en Supabase.
/// Nunca escribir el nombre de una tabla como string directo en el código.
class TablasSupabase {
  static const String usuarios    = 'usuarios';
  static const String eventos     = 'eventos';
  static const String asistencia  = 'asistencia';
  static const String roles       = 'roles';
  static const String tags        = 'tags';
  static const String usuariosTags = 'usuarios_tags';
  static const String tiposEvento  = 'tipos_evento';
  static const String eventosTags  = 'eventos_tags';
}

/// Rutas de navegación de la app.
/// Usar estas constantes en GoRouter y en context.go() / context.push().
class Rutas {
  static const String splash          = '/';
  static const String login           = '/login';
  static const String registro        = '/registro';
  static const String completarPerfil = '/completar_perfil';
  static const String home            = '/home';
  static const String admin           = '/admin';
  static const String eventos         = '/eventos';
  static const String crearEvento     = '/crear_evento';
  static const String borradores      = '/borradores';
  static const String editarEvento    = '/crear_evento/:eventoId';
  static String       editarEventoUrl(String id) => '/crear_evento/$id';
  static const String escanear        = '/escanear';
  static const String asistencia      = '/asistencia';
  static const String perfil          = '/perfil';

  /// Solo para desarrollo — muestra todos los widgets de la app visualmente.
  /// Eliminar esta ruta antes de subir a producción.
  static const String vistaWidgets    = '/dev/widgets';

  /// Solo para desarrollo — muestra el sistema tipográfico con variantes de peso.
  /// Eliminar esta ruta antes de subir a producción.
  static const String vistaFuentes    = '/dev/fuentes';
}

/// Valores válidos para eventos.estatus (CHECK constraint en la DB).
class EstatusEvento {
  static const String borrador   = 'borrador';
  static const String programado = 'programado';
  static const String enCurso    = 'en_curso';
  static const String finalizado = 'finalizado';
  static const String cancelado  = 'cancelado';
}

/// Mensajes de error genéricos para mostrar al usuario.
class MensajesError {
  static const String conexion  = 'Error de conexión. Verifica tu internet.';
  static const String sesion    = 'Tu sesión expiró. Inicia sesión de nuevo.';
  static const String permiso   = 'No tienes permiso para esta acción.';
  static const String inesperado = 'Ocurrió un error inesperado. Intenta de nuevo.';
}
