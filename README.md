# Activiti

Sistema de gestión de asistencia universitaria construido con Flutter + Supabase.

## Requisitos previos

- [Flutter](https://docs.flutter.dev/get-started/install) `>=3.0.0`
- [Dart](https://dart.dev/get-dart) `>=3.0.0`
- Una cuenta en [Supabase](https://supabase.com) con el proyecto configurado
- Android Studio / Xcode para emuladores (opcional)

---

## Configuración del entorno

### 1. Clonar el repositorio

```bash
git clone <url-del-repo>
cd activiti
```

### 2. Crear el archivo de variables de entorno

```bash
cp .env.example .env
```

Edita `.env` con los valores de tu proyecto Supabase:

```
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_anon_key_aqui

# Sentry es opcional — déjalo vacío para solo loggear en consola
SENTRY_DSN=
```

> Puedes encontrar los valores de Supabase en **Supabase → Settings → API**.

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Ejecutar la app

```bash
# Modo dev — carga credenciales desde assets/.env vía flutter_dotenv
flutter run

# Modo dev con flavor explícito (equivalente al anterior)
flutter run --dart-define=ENTORNO=dev

# Modo producción — credenciales inyectadas en compile-time (más seguro)
# Requiere eliminar ".env" de la sección assets en pubspec.yaml antes del build
flutter run --dart-define-from-file=.env --dart-define=ENTORNO=prod
```

> **Nota de seguridad**: En debug el `.env` se incrusta en el APK/IPA en texto plano.
> Para producción, usa `--dart-define-from-file` y elimina `- .env` de los assets en `pubspec.yaml`.

---

## Estructura del proyecto

```
lib/
├── compartido/          # Utilidades, widgets y errores reutilizables
│   ├── errores.dart     # Excepciones tipadas de la app
│   ├── logger.dart      # Logger global
│   ├── traductor_errores.dart
│   └── widgets/
├── configuracion/       # Router, tema, colores, inyección de dependencias
│   ├── entorno.dart     # Sistema de flavors (dev / staging / prod)
│   └── ...
└── funcionalidades/     # Una carpeta por feature (BLoC + repositorio + modelos)
    ├── autenticacion/
    ├── eventos/
    ├── panel_control_evento/
    ├── notificaciones/
    └── ...

test/
├── helpers.dart         # Mocks y fixtures compartidos
├── unidad/
│   ├── cubits/          # Tests de lógica de negocio (BLoC)
│   ├── modelos/         # Tests de modelos y parsers
│   └── utilidades/      # Tests de utilidades puras
└── widgets/             # Tests de pantallas y componentes UI
```

---

## Comandos frecuentes

```bash
# Ejecutar todos los tests
flutter test

# Tests con reporte de cobertura
flutter test --coverage

# Análisis estático (debe retornar 0 issues)
flutter analyze

# Formatear código
dart format lib/ test/

# Aplicar correcciones automáticas del linter
dart fix --apply

# Build de producción (Android)
flutter build apk --dart-define-from-file=.env --dart-define=ENTORNO=prod --release

# Build de producción (iOS)
flutter build ipa --dart-define-from-file=.env --dart-define=ENTORNO=prod --release
```

---

## Arquitectura

La app sigue la arquitectura **Feature-first** con el patrón **BLoC (Cubit)**:

```
Pantalla → BlocBuilder → Cubit → Repositorio → Supabase
```

- **Cubit**: lógica de negocio y manejo de estados
- **Repositorio**: acceso a datos (Supabase), convierte errores técnicos con `TraductorErrores`
- **Estado**: sealed classes con variantes tipadas (`Inicial`, `Cargando`, `Cargado`, `Error`)
- **GetIt**: inyección de dependencias, configurada en `configuracion/dependencias.dart`

### Sistema de flavors

El entorno se controla con `--dart-define=ENTORNO=<valor>` en tiempo de compilación:

| Valor      | Uso                                      |
|------------|------------------------------------------|
| `dev`      | Desarrollo local (valor por defecto)     |
| `staging`  | QA / pruebas pre-producción              |
| `prod`     | Producción — activa Sentry si hay DSN    |

### Manejo de errores

Todos los errores pasan por excepciones tipadas antes de llegar a la UI:

| Excepción            | Cuándo se usa                          |
|----------------------|----------------------------------------|
| `FallaServidor`      | Errores de Supabase/PostgreSQL         |
| `FallaAutenticacion` | Errores de login/registro              |
| `FallaInesperada`    | Errores de red u otros inesperados     |

### Monitoreo (Sentry)

Los errores de producción se reportan a [Sentry](https://sentry.io) —
captura global (`runZonedGuarded`, `FlutterError.onError`), filtrado de ruido
en `logger.dart` e inyección del DSN vía `--dart-define`/GitHub Secrets. Ver
[`docs/SENTRY.md`](docs/SENTRY.md) para la arquitectura completa y el
procedimiento de prueba manual.

---

## CI/CD

El proyecto incluye un workflow de GitHub Actions (`.github/workflows/ci.yml`) que se ejecuta en cada push y pull request:

1. **Formato** — verifica que el código esté bien formateado
2. **Análisis** — ejecuta `flutter analyze`
3. **Tests** — ejecuta la suite completa con cobertura mínima del 60 %

---

## Variables de entorno

| Variable             | Descripción                             | Dónde obtenerla                |
|----------------------|-----------------------------------------|--------------------------------|
| `SUPABASE_URL`       | URL del proyecto Supabase               | Supabase → Settings → API      |
| `SUPABASE_ANON_KEY`  | Clave pública anónima de Supabase       | Supabase → Settings → API      |
| `SENTRY_DSN`         | DSN para reporte de errores (opcional)  | Sentry → Settings → Client Keys|
| `ENTORNO`            | Flavor de la app: `dev`/`staging`/`prod`| Se pasa con `--dart-define`    |

> **Nunca subas `.env` al repositorio.** Está en `.gitignore`.  
> Para CI/CD, inyecta los valores como secrets del repositorio en GitHub.
