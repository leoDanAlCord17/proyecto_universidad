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
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        log.w('Notificaciones push: permiso denegado por el usuario');
        return;
      }

      final token = await _messaging.getToken(vapidKey: _vapidKey);
      if (token == null) {
        log.w('Notificaciones push: no se pudo obtener el token FCM');
        return;
      }

      await _supabase.from('tokens_dispositivo').upsert(
        {
          'usuario_id': usuarioId,
          'token': token,
          'plataforma': 'web',
          'actualizado_en': DateTime.now().toIso8601String(),
        },
        onConflict: 'usuario_id',
      );

      log.i('Token FCM registrado para usuario $usuarioId');

      // Escucha notificaciones mientras la app está en primer plano
      FirebaseMessaging.onMessage.listen((mensaje) {
        final notif = mensaje.notification;
        if (notif == null) return;
        log.i('Notificación recibida en primer plano: ${notif.title}');
      });
    } catch (e, st) {
      log.e('Error al inicializar notificaciones push',
          error: e, stackTrace: st);
    }
  }
}
