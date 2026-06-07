// Flavor del entorno inyectado en compile-time:
//   flutter run --dart-define=ENTORNO=dev       (default)
//   flutter run --dart-define=ENTORNO=staging
//   flutter build apk --dart-define=ENTORNO=prod --dart-define-from-file=.env
const _nombreEntorno = String.fromEnvironment('ENTORNO', defaultValue: 'dev');
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

/// Instancia global del entorno actual. Usar en toda la app.
const entorno = _Entorno._(_nombreEntorno, _sentryDsn);

final class _Entorno {
  const _Entorno._(this.nombre, this.sentryDsn);

  final String nombre;
  final String sentryDsn;

  bool get esDev => nombre == 'dev';
  bool get esStaging => nombre == 'staging';
  bool get esProd => nombre == 'prod';
}
