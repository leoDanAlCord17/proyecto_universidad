import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'errores.dart';

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
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  // En release solo mostramos warnings y errores
  level: kDebugMode ? Level.debug : Level.warning,
);

/// Registra un error en el logger y lo envía a Sentry cuando corresponde.
///
/// No reporta [FallaAutenticacion] ni [FallaRed]: son condiciones esperadas
/// (credenciales malas, internet caído) que generarían ruido en Sentry.
/// Sí reporta [FallaServidor] y [FallaInesperada]: indican bugs reales.
void reportarError(Object error, {StackTrace? stack}) {
  log.e('Error capturado', error: error, stackTrace: stack);

  if (error is! FallaAutenticacion && error is! FallaRed) {
    Sentry.captureException(error, stackTrace: stack ?? StackTrace.current);
  }
}
