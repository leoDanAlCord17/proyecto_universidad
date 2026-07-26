import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'logger.dart';

class NotificacionesPushServicio {
  static final _messaging = FirebaseMessaging.instance;
  static final _supabase = Supabase.instance.client;

  static const _vapidKey =
      'BDUU8PnSRN6VbCAQutygJHIFjF6I5y0gasq_UTlLdRRJEW0xSFEhFsIWmT7lX83rC8FPPAbvcdFXFdaFj17aLlE';

  static Future<void> inicializar(String usuarioId) async {
    try {
      log.i('PUSH: iniciando para usuario $usuarioId');
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      log.i('PUSH: estado de permiso → ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        log.w('Notificaciones push: permiso denegado por el usuario');
        return;
      }

      final token = await _messaging.getToken(vapidKey: _vapidKey);
      log.i('PUSH: token obtenido → ${token?.substring(0, 20)}...');
      if (token == null) {
        log.w('Notificaciones push: no se pudo obtener el token FCM');
        return;
      }

      log.i('PUSH: guardando token en DB para usuario $usuarioId');
      await _supabase.from('tokens_dispositivo').upsert(
        {
          'usuario_id': usuarioId,
          'token': token,
          'plataforma': 'web',
          'actualizado_en': DateTime.now().toIso8601String(),
        },
        onConflict: 'token',
      );

      log.i('PUSH: token guardado correctamente ✓');

      // Escucha notificaciones mientras la app está en primer plano
      FirebaseMessaging.onMessage.listen((mensaje) {
        final notif = mensaje.notification;
        if (notif == null) return;
        log.i('Notificación recibida en primer plano: ${notif.title}');
      });
    } catch (e, st) {
      log.e(
        'Error al inicializar notificaciones push',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Envía una notificación in-app + push a través de la Edge Function
  /// `enviar-notificacion`, que inserta en la tabla `notificaciones` y
  /// despacha FCM a los dispositivos registrados de cada usuario.
  ///
  /// Punto único de armado del payload — antes cada cubit construía el
  /// `body` a mano, lo que produjo variantes inconsistentes (algunas sin
  /// `tipo`, otras sin `entidad_id`/`entidad_tipo`). Ver docs/mapa_notificaciones.md
  /// para el catálogo de notificaciones (N1–N13) y sus tipos correctos.
  ///
  /// Fire-and-forget: nunca lanza. Un fallo de notificación (Edge Function
  /// caída, red intermitente) no debe interrumpir ni revertir la operación
  /// de negocio que la origina — se registra como warning y se continúa.
  static Future<void> enviar({
    required List<String> usuarioIds,
    required String titulo,
    required String cuerpo,
    required String tipo,
    String? entidadId,
    String? entidadTipo,
  }) async {
    if (usuarioIds.isEmpty) return;
    try {
      await _supabase.functions.invoke(
        'enviar-notificacion',
        body: {
          'usuario_ids': usuarioIds,
          'titulo': titulo,
          'cuerpo': cuerpo,
          'tipo': tipo,
          if (entidadId != null) 'entidad_id': entidadId,
          if (entidadTipo != null) 'entidad_tipo': entidadTipo,
        },
      );
    } catch (e) {
      log.w('No se pudo enviar notificación push ("$titulo")', error: e);
    }
  }
}
