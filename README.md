# UniAsist

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
cd uniasist
```

### 2. Crear el archivo de variables de entorno

```bash
cp .env.example .env
```

Edita `.env` con los valores de tu proyecto Supabase:

```
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_anon_key_aqui
```

> Puedes encontrar estos valores en **Supabase → Settings → API**.

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Ejecutar la app

```bash
# Modo debug (carga variables desde .env)
flutter run

# Modo release (inyecta variables en compile-time, no incluye .env)
flutter run --dart-define-from-file=.env
```

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

# Análisis estático
flutter analyze

# Formatear código
dart format lib/ test/

# Aplicar correcciones automáticas del linter
dart fix --apply lib/

# Build de producción (Android)
flutter build apk --dart-define-from-file=.env --release

# Build de producción (iOS)
flutter build ipa --dart-define-from-file=.env --release
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

### Manejo de errores

Todos los errores pasan por excepciones tipadas antes de llegar a la UI:

| Excepción           | Cuándo se usa                          |
|---------------------|----------------------------------------|
| `FallaServidor`     | Errores de Supabase/PostgreSQL         |
| `FallaAutenticacion`| Errores de login/registro              |
| `FallaInesperada`   | Errores de red u otros inesperados     |

---

## CI/CD

El proyecto incluye un workflow de GitHub Actions (`.github/workflows/ci.yml`) que se ejecuta en cada push y pull request:

1. **Formato** — verifica que el código esté bien formateado
2. **Análisis** — ejecuta `flutter analyze`
3. **Tests** — ejecuta la suite completa de tests con cobertura

---

## Variables de entorno

| Variable          | Descripción                          | Dónde obtenerla              |
|-------------------|--------------------------------------|------------------------------|
| `SUPABASE_URL`    | URL del proyecto Supabase            | Supabase → Settings → API    |
| `SUPABASE_ANON_KEY` | Clave pública anónima de Supabase  | Supabase → Settings → API    |

> **Nunca subas `.env` al repositorio.** Está en `.gitignore`.  
> Para CI/CD, inyecta los valores como secrets del repositorio en GitHub.
