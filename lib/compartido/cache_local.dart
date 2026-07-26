import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'logger.dart';

/// Caché local con IndexedDB en web, Hive nativo en móvil.
/// Cada entrada almacena el valor junto con un timestamp y un TTL.
/// Si la entrada expiró, [leer] devuelve null y la elimina silenciosamente.
///
/// Si [init] falla (p. ej. IndexedDB bloqueado en modo incógnito estricto de
/// Safari/Firefox, cuota de almacenamiento agotada), el resto de los métodos
/// se vuelven no-op silenciosos en vez de lanzar — la app sigue arrancando y
/// funcionando sin caché local en lugar de quedar en blanco en `runApp()`.
///
/// Uso:
///   await CacheLocal.init();
///   await CacheLocal.guardar('eventos', jsonString);          // TTL por defecto: 24 h
///   await CacheLocal.guardar('x', json, ttl: Duration(hours: 2));
///   final data = CacheLocal.leer('eventos');                  // null si expiró o no existe
class CacheLocal {
  // Nombre versionado: migración limpia desde el formato anterior sin TTL.
  static const _caja = 'activiti_cache_v2';

  static bool _disponible = false;

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox<String>(_caja);
      _disponible = true;
    } catch (e, st) {
      _disponible = false;
      log.w(
        'CacheLocal no disponible — la app continuará sin caché local',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Guarda [valor] bajo [clave]. El [ttl] por defecto es 24 horas.
  /// No-op silencioso si la caché no está disponible.
  static Future<void> guardar(
    String clave,
    String valor, {
    Duration ttl = const Duration(hours: 24),
  }) async {
    if (!_disponible) return;
    final entrada = jsonEncode({
      'd': valor,
      't': DateTime.now().millisecondsSinceEpoch,
      'ttl': ttl.inMilliseconds,
    });
    await Hive.box<String>(_caja).put(clave, entrada);
  }

  /// Lee el valor bajo [clave]. Devuelve null si no existe, está expirado,
  /// el formato no es válido o la caché no está disponible.
  static String? leer(String clave) {
    if (!_disponible) return null;
    final raw = Hive.box<String>(_caja).get(clave);
    if (raw == null) return null;
    try {
      final entrada = jsonDecode(raw) as Map<String, dynamic>;
      final guardadoEn = entrada['t'] as int;
      final ttlMs = entrada['ttl'] as int;
      if (DateTime.now().millisecondsSinceEpoch - guardadoEn > ttlMs) {
        Hive.box<String>(_caja).delete(clave);
        return null;
      }
      return entrada['d'] as String;
    } catch (_) {
      return null;
    }
  }

  /// No-op silencioso si la caché no está disponible.
  static Future<void> eliminar(String clave) async {
    if (!_disponible) return;
    await Hive.box<String>(_caja).delete(clave);
  }

  /// No-op silencioso si la caché no está disponible.
  static Future<void> limpiar() async {
    if (!_disponible) return;
    await Hive.box<String>(_caja).clear();
  }
}
