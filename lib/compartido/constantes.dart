/// Nombres exactos de las tablas en Supabase.
/// Nunca escribir el nombre de una tabla como string directo en el código.
class TablasSupabase {
  static const String usuarios    = 'usuarios';
  static const String eventos     = 'eventos';
  static const String asistencia  = 'asistencia';
  static const String roles       = 'roles';
  static const String tags        = 'tags';
  static const String usuariosTags  = 'usuarios_tags';
  static const String usuariosRoles = 'usuarios_roles';
  static const String tiposEvento  = 'tipos_evento';
  static const String eventoGruposTags = 'evento_grupos_tags';
  static const String configuracionInt     = 'configuracion_int';
  static const String configuracionBoolean = 'configuracion_boolean';
  static const String permisos             = 'permisos';
  static const String rolesPermisos        = 'roles_permisos';
  static const String notificaciones       = 'notificaciones';
  static const String tokensDispositivo    = 'tokens_dispositivo';
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
  static const String permisosSistema = '/permisos';
  static const String gestionRoles    = '/gestion_roles';
  static const String crearRol        = '/crear_rol';
  static const String editarRol       = '/crear_rol/:rolId';
  static String       editarRolUrl(String id) => '/crear_rol/$id';
  static const String editarEvento    = '/crear_evento/:eventoId';
  static String       editarEventoUrl(String id) => '/crear_evento/$id';
  static const String escanear        = '/escanear';
  static const String asistencia      = '/asistencia';
  static const String gestionUsuarios        = '/gestion_usuarios';
  static const String gestionarTagsUsuario   = '/gestion_usuarios/:usuarioId/tags';
  static String       gestionarTagsUsuarioUrl(String id) => '/gestion_usuarios/$id/tags';
  static const String gestionarRolesUsuario  = '/gestion_usuarios/:usuarioId/roles';
  static String       gestionarRolesUsuarioUrl(String id) => '/gestion_usuarios/$id/roles';
  static const String verPerfilUsuario       = '/gestion_usuarios/:usuarioId/perfil';
  static String       verPerfilUsuarioUrl(String id) => '/gestion_usuarios/$id/perfil';
  static const String editarUsuario          = '/gestion_usuarios/:usuarioId/editar';
  static String       editarUsuarioUrl(String id) => '/gestion_usuarios/$id/editar';
  static const String gestionTags     = '/gestion_tags';
  static const String crearTag        = '/crear_tag';
  static const String editarTag       = '/crear_tag/:tagId';
  static String       editarTagUrl(String id) => '/crear_tag/$id';
  static const String recuperarContrasena = '/recuperar_contrasena';
  static const String nuevaContrasena     = '/nueva_contrasena';
  static const String perfil              = '/perfil';
  static const String notificaciones      = '/notificaciones';

  static const String historial            = '/historial';
  static const String pendienteAprobacion = '/pendiente_aprobacion';
  static const String usuarioRechazado    = '/usuario_rechazado';
  static const String revisionUsuarios    = '/revision_usuarios';

  static const String gestionTiposEvento  = '/gestion_tipos_evento';
  static const String crearTipoEvento     = '/crear_tipo_evento';
  static const String editarTipoEvento    = '/crear_tipo_evento/:tipoEventoId';
  static String       editarTipoEventoUrl(String id) => '/crear_tipo_evento/$id';

  static const String panelControl    = '/eventos/:eventoId/panel';
  static String       panelControlUrl(String id) => '/eventos/$id/panel';

  static const String buscarAsistente    = '/eventos/:eventoId/panel/buscar';
  static String       buscarAsistenteUrl(String id) => '/eventos/$id/panel/buscar';

  static const String escanearQrUsuario    = '/eventos/:eventoId/panel/qr_usuario';
  static String       escanearQrUsuarioUrl(String id) => '/eventos/$id/panel/qr_usuario';

  /// Solo para desarrollo — muestra todos los widgets de la app visualmente.
  /// Eliminar esta ruta antes de subir a producción.
  static const String vistaWidgets    = '/dev/widgets';

  /// Solo para desarrollo — muestra el sistema tipográfico con variantes de peso.
  /// Eliminar esta ruta antes de subir a producción.
  static const String vistaFuentes    = '/dev/fuentes';
}

/// Valores válidos para usuarios.estatus_aprobacion (CHECK constraint en la DB).
class EstatusAprobacion {
  static const String pendiente = 'pendiente';
  static const String aprobado  = 'aprobado';
  static const String rechazado = 'rechazado';
}

/// Valores válidos para eventos.estatus (CHECK constraint en la DB).
class EstatusEvento {
  static const String borrador   = 'borrador';
  static const String programado = 'programado';
  static const String enCurso    = 'en_curso';
  static const String finalizado = 'finalizado';
  static const String cancelado  = 'cancelado';
}

/// Valores válidos para eventos.modo_registro (CHECK constraint en la DB).
class ModoRegistro {
  static const String auto          = 'auto';
  static const String administrador = 'administrador';
}

/// Valores válidos para eventos.alcance (CHECK constraint en la DB).
class AlcanceEvento {
  static const String general  = 'general';
  static const String dirigido = 'dirigido';
}

/// Valores válidos para asistencia.estatus (CHECK constraint en la DB).
class EstatusAsistencia {
  static const String esperado        = 'esperado';
  static const String presente        = 'presente';
  static const String completado      = 'completado';
  static const String ausente         = 'ausente';
  static const String salioAnticipado = 'salio_anticipado';
  static const String anulado         = 'anulado';
}

/// Mensajes de error genéricos para mostrar al usuario.
class MensajesError {
  static const String conexion  = 'Error de conexión. Verifica tu internet.';
  static const String sesion    = 'Tu sesión expiró. Inicia sesión de nuevo.';
  static const String permiso   = 'No tienes permiso para esta acción.';
  static const String inesperado = 'Ocurrió un error inesperado. Intenta de nuevo.';
}
