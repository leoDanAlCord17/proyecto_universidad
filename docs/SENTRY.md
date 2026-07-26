# Monitoreo de errores con Sentry — Activiti

Referencia de cómo la app captura, filtra y reporta errores a Sentry, cómo se
inyecta la configuración en cada entorno, y cómo verificar manualmente que la
integración sigue funcionando en producción.

---

## 1. Arquitectura y captura de errores

Sentry solo se activa si hay un DSN configurado (ver sección 2). Sin DSN, toda
la infraestructura de abajo sigue funcionando igual, pero `Sentry.captureException`
es un no-op — los errores se ven en consola vía `log`, nunca llegan a Sentry.io.

### 1.1 Inicialización — `lib/main.dart`

`_inicializarSentry()` corre dentro de `_iniciarApp()`, envuelta en un
`.timeout(_timeoutInicializacion)` (8s) y un `try/catch` — si Sentry no
inicializa a tiempo (red lenta, DSN inválido), se loggea un warning y el
arranque de la app **continúa sin monitoreo** en vez de bloquearse:

```dart
Future<void> _inicializarSentry() async {
  final dsn = entorno.sentryDsn;
  if (dsn.isEmpty) return; // no-op sin DSN

  await SentryFlutter.init((options) {
    options.dsn = dsn;
    options.environment = entorno.nombre;
    options.tracesSampleRate = entorno.esProd ? 0.2 : 0.0;
    options.debug = entorno.esDev;
  });
}
```

- `tracesSampleRate` solo es > 0 en producción (20% de las transacciones) —
  en dev/staging no se generan traces de performance, solo errores.
- `environment` se etiqueta con el flavor actual (`dev` / `staging` / `prod`),
  así los eventos de Sentry se pueden filtrar por entorno en el dashboard.

### 1.2 Captura global de errores no manejados — `lib/main.dart`

Cuatro puntos de entrada cubren todas las formas en que un error puede escapar
sin ser capturado explícitamente en el código de negocio:

| Handler | Cubre | Acción |
|---|---|---|
| `runZonedGuarded` (envuelve `main()`) | Errores asíncronos fuera de cualquier handler de Flutter | `log.e(...)` + `Sentry.captureException(...)` |
| `FlutterError.onError` | Errores del framework (layout, rendering, `assert` en debug) | `log.e(...)` + `Sentry.captureException(...)` |
| `PlatformDispatcher.instance.onError` | Errores asíncronos no capturados fuera del árbol de widgets | `log.e(...)` + `Sentry.captureException(...)` |
| `ErrorWidget.builder` | Una excepción durante el `build()` de un widget | `log.e(...)` + `Sentry.captureException(...)`, y muestra `_WidgetDeError` en vez de la pantalla roja de error |

Los cuatro se configuran en `_configurarErrorHandlers()`, llamada una sola vez
al arrancar, **antes** de `runApp()`.

### 1.3 Filtro de ruido — `lib/compartido/logger.dart`

El código de negocio (cubits, repositorios) no llama a `Sentry.captureException`
directamente — usa `reportarError()`:

```dart
void reportarError(Object error, {StackTrace? stack}) {
  log.e('Error capturado', error: error, stackTrace: stack);

  if (error is! FallaAutenticacion && error is! FallaRed) {
    Sentry.captureException(error, stackTrace: stack ?? StackTrace.current);
  }
}
```

`FallaAutenticacion` (credenciales inválidas) y `FallaRed` (sin conexión,
timeout) son condiciones **esperadas** del uso normal de la app — reportarlas
a Sentry generaría ruido y ocultaría los errores reales. Solo `FallaServidor`
y `FallaInesperada` (bugs genuinos: respuestas mal formadas, excepciones no
previstas) llegan a Sentry. `reportarError()` se llama en el `catch` de
prácticamente todos los cubits del proyecto.

---

## 2. Inyección del DSN

El DSN **nunca** se hardcodea ni se sube al repositorio. Se inyecta en
tiempo de compilación vía `--dart-define`, leído por `lib/configuracion/entorno.dart`:

```dart
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');
const entorno = _Entorno._(_nombreEntorno, _sentryDsn);
```

### En desarrollo local

El `.env` local puede dejar `SENTRY_DSN` vacío — Sentry simplemente no se
activa (ver `README.md` → Configuración del entorno). No hace falta un DSN
para desarrollar ni para correr los tests.

### En CI/CD — `.github/workflows/ci.yml`

El job `build_web` pasa el DSN como `--dart-define` al compilar, leyéndolo
desde un secret del repositorio:

```yaml
- name: Build web (PWA offline-first)
  run: |
    flutter build web \
      --release \
      --pwa-strategy=offline-first \
      --dart-define-from-file=.env \
      --dart-define=ENTORNO=prod \
      --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }} \
      --base-href=/
```

**Configuración requerida en GitHub** (una sola vez, por quien administre el
repositorio): `Settings → Secrets and variables → Actions → New repository secret`,
nombre `SENTRY_DSN`, valor el DSN del proyecto en **Sentry → Settings → Client Keys (DSN)**.

Si el secret no está configurado, el build sigue funcionando con normalidad
(`entorno.sentryDsn` queda vacío → `_inicializarSentry()` es no-op) — pero
ningún error de producción llegará a Sentry, así que conviene confirmarlo con
el procedimiento de prueba manual de la sección 3 después de configurarlo.

### Builds locales de producción

```bash
flutter build web --release --dart-define-from-file=.env \
  --dart-define=ENTORNO=prod --dart-define=SENTRY_DSN=<tu-dsn>
```

---

## 3. Procedimiento para ejecutar la prueba manual

Sirve para confirmar, sin ambigüedad, que un evento real generado desde la
app instalada/desplegada llega a Sentry — útil después de rotar el DSN,
cambiar de proyecto en Sentry, o como chequeo periódico de que el pipeline
completo (app → Sentry SDK → Sentry.io) sigue intacto.

El botón de prueba vive en `lib/funcionalidades/perfil/perfil_pantalla.dart`,
oculto por defecto detrás de la constante `_mostrarBotonPruebaSentry`.

1. **Activar el botón.** En `perfil_pantalla.dart`, cambiar:
   ```dart
   const bool _mostrarBotonPruebaSentry = false;
   ```
   a `true`.

2. **Compilar/desplegar con el DSN configurado.** Por ejemplo:
   ```bash
   flutter build web --release --dart-define-from-file=.env \
     --dart-define=ENTORNO=prod --dart-define=SENTRY_DSN=<tu-dsn>
   ```
   O simplemente hacer push a una rama que dispare el workflow de CI/CD (ya
   inyecta `SENTRY_DSN` desde el secret — ver sección 2).

3. **Disparar la prueba desde la app.** Entrar con una cuenta que tenga el
   permiso `ajustes` (o correr en modo debug — `kDebugMode`), ir a **Perfil**
   y presionar **"Probar integración con Sentry"**. Debe aparecer el aviso
   *"Excepción de prueba enviada a Sentry"*. Internamente llama a
   `probarSentry()` (`lib/compartido/logger.dart`), que lanza y captura una
   excepción de prueba (`🧪 [Prueba Sentry] Excepción de verificación manual
   de Sentry`) directamente con `Sentry.captureException`.

4. **Confirmar la llegada en Sentry.io.** Entrar al proyecto correspondiente
   → pestaña **Issues** → buscar el mensaje con el emoji 🧪. Debería aparecer
   en segundos a un par de minutos, con el `environment` correspondiente al
   build usado (`prod` si se siguió el paso 2 con `ENTORNO=prod`).

5. **Revertir el flag.** Volver a dejar `_mostrarBotonPruebaSentry = false;`
   y recompilar/redesplegar. El botón nunca debe quedar visible para usuarios
   reales fuera de esta verificación puntual.

### Notas de seguridad

- El botón, incluso activado, solo es visible en `kDebugMode` o para usuarios
  con permiso `ajustes` — nunca para un usuario final típico.
- La excepción de prueba no representa ningún fallo real de la app; es
  esperable y seguro que aparezca en Issues etiquetada como tal.
