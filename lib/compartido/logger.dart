import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Logger global de la aplicación.
///
/// Uso:
///   import 'package:uniasist/compartido/logger.dart';
///   log.d('mensaje de debug');
///   log.i('información');
///   log.w('advertencia');
///   log.e('error', error: e, stackTrace: st);
final log = Logger(
  printer: PrettyPrinter(
    methodCount:       2,
    errorMethodCount:  8,
    lineLength:        120,
    colors:            true,
    printEmojis:       true,
    dateTimeFormat:    DateTimeFormat.onlyTimeAndSinceStart,
  ),
  // En release solo mostramos warnings y errores
  level: kDebugMode ? Level.debug : Level.warning,
);
