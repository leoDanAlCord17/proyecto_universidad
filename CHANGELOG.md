# Changelog

Todos los cambios notables de este proyecto se documentan aquí.  
El formato sigue [Keep a Changelog](https://keepachangelog.com/es/1.1.0/) y el versionado usa [Semantic Versioning](https://semver.org/lang/es/).

---

## [Unreleased]

### Added
- Logger global (`lib/compartido/logger.dart`) con `PrettyPrinter`; reemplaza todos los `print()` de la app
- Manejadores globales de errores en `main.dart`: `FlutterError.onError`, `PlatformDispatcher.instance.onError`, `runZonedGuarded`
- Widget de fallback `_WidgetDeError` para excepciones en subtrees de widgets (release mode)
- Pipeline CI/CD con GitHub Actions (`.github/workflows/ci.yml`): formato, análisis, tests y cobertura con Codecov
- Archivo `.env.example` con instrucciones de configuración de Supabase
- `analysis_options.yaml` con reglas de linting estrictas (calidad, rendimiento, seguridad, null-safety)
- Suite de tests completa: 197 tests (cubits, modelos, utilidades, widgets)
  - `test/unidad/cubits/auditoria_evento_cubit_test.dart` — 25 tests
  - `test/unidad/cubits/notificaciones_cubit_test.dart` — 18 tests
  - `test/unidad/modelos/auditoria_evento_modelo_test.dart` — 70 tests
- `README.md` completo con estructura del proyecto, comandos frecuentes, arquitectura y tabla de variables de entorno

### Changed
- `main.dart`: inicialización refactorizada con manejo de errores de nivel de plataforma
- `pubspec.yaml`: agregada dependencia `logger: ^2.4.0`
- `analysis_options.yaml`: reglas de analyzer elevadas a `error` para parámetros requeridos faltantes, retorno faltante y asignación inválida

### Fixed
- `auth_cubit_test.dart`: stub faltante de `flujoRecuperacionContrasena` que causaba falla en setUp
- `crear_usuario_cubit_test.dart`: stub faltante de `verificarRevisionCreacionHabilitada` en paths de éxito
- `registro_cubit_test.dart`: validación de contraseña actualizada a mínimo 8 caracteres + dígito requerido
- `traductor_errores_test.dart`: mensaje de error de contraseña corta actualizado
- `usuario_test.dart`: estado de rol corregido a booleano; tests de `tienePermiso` actualizados al formato de punto (`eventos.crear`)

---

## [0.1.0] — 2026-04-01

### Added
- Autenticación con Supabase: login, registro, recuperación de contraseña
- Gestión de eventos: crear, editar, listar eventos con tags
- Panel de control de evento: auditoría de asistencia en tiempo real
- Notificaciones en tiempo real vía Supabase Realtime
- Sistema de permisos por rol con formato de punto (`eventos.crear`, `ajustes.usuarios`)
- Arquitectura Feature-first con patrón BLoC (Cubit)
- Inyección de dependencias con GetIt
- Navegación con GoRouter y redirección basada en estado de autenticación
- Soporte de variables de entorno con `flutter_dotenv` y `--dart-define-from-file`
