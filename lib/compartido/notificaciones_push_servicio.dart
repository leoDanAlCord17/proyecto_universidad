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
}
