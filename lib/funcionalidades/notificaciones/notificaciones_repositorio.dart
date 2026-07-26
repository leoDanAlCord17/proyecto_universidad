import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'notificacion.dart';

class NotificacionesRepositorio {
  const NotificacionesRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Stream en tiempo real del número de notificaciones no leídas.
  /// Usado por el badge de la barra superior.
  Stream<int> streamCantidadNoLeidas(String usuarioId) {
    return _supabase
        .from(TablasSupabase.notificaciones)
        .stream(primaryKey: ['id'])
        .eq('usuario_id', usuarioId)
        .map((filas) => filas.where((f) => f['leida'] == false).length);
  }

  /// Lista completa de notificaciones del usuario, más recientes primero.
  Future<List<Notificacion>> obtenerTodas(String usuarioId) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .from(TablasSupabase.notificaciones)
              .select()
              .eq('usuario_id', usuarioId)
              .order('creado_en', ascending: false)
              .limit(50)
              .timeout(kTimeoutSolicitud);
          return filas.map(Notificacion.desdeJson).toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Marca una notificación como leída.
  Future<void> marcarLeida(String notificacionId) async {
    try {
      await _supabase
          .from(TablasSupabase.notificaciones)
          .update({'leida': true}).eq('id', notificacionId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Marca todas las notificaciones del usuario como leídas.
  Future<void> marcarTodasLeidas(String usuarioId) async {
    try {
      await _supabase
          .from(TablasSupabase.notificaciones)
          .update({'leida': true})
          .eq('usuario_id', usuarioId)
          .eq('leida', false);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Registra o actualiza el token FCM del dispositivo actual.
  /// Si el token ya existe, actualiza su estado a activo.
  Future<void> registrarToken({
    required String usuarioId,
    required String token,
    required String plataforma,
  }) async {
    try {
      await _supabase.from(TablasSupabase.tokensDispositivo).upsert(
        {
          'usuario_id': usuarioId,
          'token': token,
          'plataforma': plataforma,
          'activo': true,
          'actualizado_en': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'token',
      );
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// true si el usuario tiene al menos un token de dispositivo registrado.
  /// Usado para decidir si mostrar el banner "Activar notificaciones".
  Future<bool> tieneTokenRegistrado(String usuarioId) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .from(TablasSupabase.tokensDispositivo)
              .select('id')
              .eq('usuario_id', usuarioId)
              .limit(1)
              .timeout(kTimeoutSolicitud);
          return filas.isNotEmpty;
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Desactiva el token al cerrar sesión para no recibir notificaciones.
  Future<void> desactivarToken(String token) async {
    try {
      await _supabase.from(TablasSupabase.tokensDispositivo).update({
        'activo': false,
        'actualizado_en': DateTime.now().toUtc().toIso8601String(),
      }).eq('token', token);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }
}
