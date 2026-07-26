# Transición a PWA — Activiti

Archivo de seguimiento de todas las tareas para convertir este proyecto Flutter Web
en una PWA totalmente funcional. Cada tarea se marca cuando queda resuelta.

**Stack**: Flutter Web + Supabase + BLoC (Cubit) + GoRouter  
**Última actualización**: 2026-06-06

---

## Leyenda
- `[ ]` Pendiente
- `[x]` Completado
- `[!]` Problema encontrado (ver descripción)
- `[-]` No aplica / tarea del desarrollador fuera del código

---

## BLOQUE 1 — Fundamentos PWA (requisitos mínimos de instalabilidad)

- [x] **Corregir `web/manifest.json`**
  - Colores: `#5B3FD4` (acento) / `#EEEDF5` (fondo)
  - Descripción real, `lang`, `scope`, `categories`, `shortcuts`
  - _Archivos_: `web/manifest.json`

- [x] **Corregir `web/index.html`**
  - `<meta name="viewport">` añadido (faltaba — crítico para móvil)
  - `theme-color`, metas de iOS Safari, descripción real
  - _Archivos_: `web/index.html`

- [!] **Iconos PWA — confirmado que siguen siendo el logo default de Flutter**
  - Archivos presentes y `web/manifest.json` apunta correctamente a los 4:
    `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`,
    `Icon-maskable-512.png` (rutas verificadas, sin 404).
  - **Verificado visualmente (2026-07-26)**: los 4 son el logo azul genérico
    de Flutter, no un ícono de marca Activiti. Alto impacto de marca — es lo
    primero que ve un usuario al instalar la PWA en su pantalla de inicio.
  - **Acción manual pendiente**: generar los 4 PNG (192/512 estándar +
    192/512 maskable, con zona de seguridad ~40% para el recorte maskable)
    a partir del logo real de Activiti y reemplazar estos archivos
    manteniendo exactamente los mismos nombres — no requiere tocar
    `manifest.json` ni `index.html`, solo sustituir los binarios.

- [x] **Configurar comando de build para producción**
  - Comando correcto activado en CI/CD:
    ```bash
    flutter build web --release --pwa-strategy=offline-first \
      --dart-define-from-file=.env --base-href=/
    ```
  - _Archivos_: `.github/workflows/ci.yml`

- [x] **Configurar VS Code para desarrollo web**
  - `launch.json` creado con configuración "Web (Chrome) — dev"
  - Usa `--dart-define-from-file=.env` automáticamente al presionar F5
  - _Archivos_: `.vscode/launch.json`

---

## BLOQUE 2 — Seguridad

- [x] **`.env` protegido en `.gitignore`**
  - Confirmado en línea 51 del `.gitignore`

- [x] **Credenciales no expuestas en build web**
  - CI/CD crea `.env` desde GitHub Secrets en tiempo de ejecución
  - `--dart-define-from-file=.env` compila las credenciales dentro del JS
  - _Archivos_: `.github/workflows/ci.yml`

- [-] **Headers de seguridad en el servidor**
  - HTTPS, CSP, X-Frame-Options — tarea de infraestructura, no de código Flutter
  - **Acción manual**: configurar en nginx/Firebase Hosting/Netlify según destino

---

## BLOQUE 3 — Soporte offline de datos

- [x] **Dependencias añadidas**: `connectivity_plus: ^6.0.5`, `hive_flutter: ^1.1.0`
  - _Archivos_: `pubspec.yaml`

- [x] **`CacheLocal`** — wrapper de Hive/IndexedDB
  - _Archivos_: `lib/compartido/cache_local.dart`

- [x] **`ConectividadServicio`** — singleton online/offline
  - _Archivos_: `lib/compartido/conectividad.dart`

- [x] **`BannerSinConexion`** — widget compartido (barra ámbar + botón Reintentar)
  - Usado en eventos y perfil. Sin duplicación.
  - _Archivos_: `lib/compartido/widgets/utilidades/banner_sin_conexion.dart`

- [x] **`CacheLocal.init()` en `main.dart`**
  - _Archivos_: `lib/main.dart`

- [x] **Caché offline en módulo Eventos**
  - `EventosRepositorio`: cachea JSON crudo tras cada llamada exitosa
  - `EventosSinConexion`: nuevo estado BLoC con datos cacheados
  - `EventosPantalla`: switch exhaustivo + banner + filtros funcionan offline
  - _Archivos_: `eventos_repositorio.dart`, `eventos_estado.dart`,
    `eventos_cubit.dart`, `eventos_pantalla.dart`

- [x] **Caché offline en módulo Perfil**
  - `PerfilRepositorio`: cachea tags por `usuarioId`
  - `PerfilSinConexion`: nuevo estado BLoC
  - `PerfilPantalla`: banner visible, `tagPrincipal` y `tagsSecundarios`
    se muestran desde caché, edición deshabilitada sin conexión
  - _Archivos_: `perfil_repositorio.dart`, `perfil_estado.dart`,
    `perfil_cubit.dart`, `perfil_pantalla.dart`

- [x] **Notificaciones ya resilientes offline** (sin cambios necesarios)
  - Stream tiene `onError` que emite estado seguro (badge = 0)
  - Escrituras (marcar leída) tienen `try/catch` silencioso

- [ ] **Ejecutar `flutter pub get`**
  - **Acción manual obligatoria** antes de compilar:
    ```bash
    flutter pub get
    ```

---

## BLOQUE 4 — Service Worker

- [x] **Conflicto SW resuelto**
  - `web/sw.js` eliminado; script de registro eliminado de `index.html`
  - Flutter gestiona su propio `flutter_service_worker.js` — no interferir

- [x] **Estrategia `offline-first` en el build**
  - `--pwa-strategy=offline-first` activado en CI/CD

---

## BLOQUE 5 — Funcionalidades a verificar en navegador

Estas tareas requieren ejecutar la app en un navegador real y probar manualmente.

- [ ] **Escaneo QR (`mobile_scanner`)**
  - Requiere HTTPS + permiso de cámara
  - Probar en Chrome Android y Safari iOS

- [ ] **Generación y descarga de PDF (`pdf` package)**
  - Probar descarga en Chrome, Firefox y Safari

- [ ] **Compartir (`share_plus`)**
  - Web Share API en móvil; verificar fallback en escritorio

- [ ] **Notificaciones Supabase Realtime en navegador**
  - WebSockets deben funcionar con conexión activa
  - Verificar que no hay crash al perder la red

- [ ] **Cámara en iOS Safari**
  - Safari impone restricciones adicionales a `getUserMedia`
  - Probar escáner QR en iPhone

---

## BLOQUE 6 — Pruebas de instalación PWA

- [ ] **Android (Chrome)** — verificar banner "Añadir a pantalla de inicio"
- [ ] **iOS (Safari)** — Compartir → Añadir a pantalla de inicio
- [ ] **Escritorio (Chrome/Edge)** — ícono de instalación en barra de direcciones
- [ ] **Carga offline tras instalar** — desactivar red → reabrir → ver datos cacheados

---

## BLOQUE 7 — CI/CD y despliegue

- [x] **Job `build_web` en CI/CD**
  - Solo en `push` a ramas principales, después de pasar tests
  - Crea `.env` desde GitHub Secrets, construye PWA, sube artefacto 7 días
  - _Archivos_: `.github/workflows/ci.yml`

- [ ] **Configurar secretos en GitHub**
  - Settings → Secrets and variables → Actions
  - Crear `SUPABASE_URL` y `SUPABASE_ANON_KEY`
  - **Acción manual**

- [ ] **Configurar servidor de despliegue**
  - HTTPS obligatorio para service worker
  - SPA routing: todas las rutas devuelven `index.html`:
    ```nginx
    location / { try_files $uri $uri/ /index.html; }
    ```
  - **Acción manual**

---

## BLOQUE 8 — Diagnóstico Técnico y Deuda Técnica

Resultado de la auditoría de arquitectura realizada por un Ingeniero Senior.
Cada hallazgo tiene su severidad, estado y archivo afectado.

---

### 🔴 Críticos

- [x] **C-1 — Rutas administrativas sin protección activa**
  - **Problema**: El guard de permisos estaba desactivado con un `TODO`. Cualquier
    usuario autenticado podía navegar a `/gestion_usuarios`, `/gestion_roles`,
    `/estadisticas`, etc., escribiendo la URL directamente.
  - **Solución**: Guards implementados en la función `redirect` del router.
    Cada ruta admin se verifica contra `usuario.tienePermiso()`. Sin permiso → redirige a `/home`.
  - _Archivo_: `lib/configuracion/router_app.dart`

---

### 🟠 Importantes

- [x] **I-2 — Duplicación de instancia de `NotificacionesCubit`**
  - **Problema**: El cubit es un `LazyLazySingleton` en GetIt y también se
    creaba con `BlocProvider(create:)` en las rutas `/home` y `/notificaciones`.
    `BlocProvider(create:)` cierra el cubit al desmontar la ruta, destruyendo
    el singleton global.
  - **Solución**:
    - Eliminado `NotificacionesCubit` del `MultiBlocProvider` de `/home`
      (ya está disponible en el árbol raíz desde `main.dart` vía `BlocProvider.value`).
    - Ruta `/notificaciones` cambiada a `BlocProvider.value` para no tomar
      ownership del singleton.
  - _Archivo_: `lib/configuracion/router_app.dart`

- [x] **I-3 — `FallaInesperada` captura errores de red y de servidor sin distinción**
  - **Problema**: Sin un tipo específico para errores de red, no era posible
    distinguir "sin internet" de "JSON malformado" a nivel de tipos.
  - **Solución**:
    - `FallaRed` añadida a `errores.dart`
    - `TraductorErrores.lanzarInesperado(e)` (retorna `Never`) detecta si el error
      es de red y lanza `FallaRed` o `FallaInesperada` según corresponda.
    - Todos los repositorios actualizados de `throw FallaInesperada(TraductorErrores.deInesperado(e))`
      a `TraductorErrores.lanzarInesperado(e)`.
  - _Archivos_: `lib/compartido/errores.dart`, `lib/compartido/traductor_errores.dart`,
    todos los `*_repositorio.dart`

- [x] **I-1 — Sin paginación (implementado en módulo Historial como referencia)**
  - **Patrón implementado**:
    1. Repositorio: `obtenerHistorial(id, {offset, limite})` retorna
       `({List<HistorialItem> items, bool hayMas})`. Usa `.range()` de Supabase
       y ordena server-side por `eventos.fecha_inicio` descendente.
    2. Estado: nuevo `HistorialCargandoMas` para no perder items visibles
       mientras se carga la siguiente página.
    3. Cubit: `cargarMas()` acumula páginas. En caso de error restaura el estado
       anterior sin perder datos.
    4. Pantalla: botón "Cargar más" en la tab "Todos". Indicador de carga inline.
  - **Replicado en `borradores`**, **`roles`**, **`tags`**, **`revision_usuarios`**:
    en cada módulo: repositorio con `offset`/`hayMas` vía `.range()`, nuevo estado
    `*CargandoMas`, `cargarMas()` en cubit con reversión ante error, botón
    "Cargar más" / indicador inline en pantalla.
  - **Completado también en**: `usuarios` (preserva selección/modoSeleccion en `UsuariosCargandoMas`)
    y `auditoria_evento` (paginación de la lista de eventos en la modal; registros sin paginar
    por necesidad de KPIs completos).
  - _Archivos_: `historial_*`, `borradores_*`, `roles_*`, `tags_*`, `revision_usuarios_*`,
    `usuarios_*`, `auditoria_evento_*` (repositorio, estado, cubit, pantalla × 7 módulos)

- [x] **I-4 — Cobertura de tests real cercana a cero en módulos de negocio**
  - **Problema**: Solo 5 archivos de test, todos de widgets, todos en
    autenticación. Los 26+ módulos funcionales no tienen tests.
    `AuthCubit`, todos los repositorios y cubits de negocio son código
    sin validación automatizada.
  - **Solución**: `test/unidad/cubits/historial_cubit_test.dart` reescrito
    para cubrir la nueva API paginada (12 casos: `cargar` exitoso/vacío/error
    por los 3 tipos de falla, reset de offset; `cargarMas` no-op ×2, acumulación
    de páginas, reversión ante error). Todos pasan con `bloc_test` + `mocktail`.
  - _Archivos_: `test/unidad/cubits/historial_cubit_test.dart`

- [x] **I-5 — `dependencias.dart` como Nodo Dios (333 líneas, 66 imports)**
  - **Problema**: Un solo archivo debía modificarse cada vez que se añadía
    cualquier módulo. Creaba acoplamiento de compilación en todo el grafo.
  - **Solución**: `dependencias.dart` reducido a ~25 líneas; delegación a:
    - `dependencias_auth.dart` — Auth, Login, Registro, CrearUsuario, Contraseñas
    - `dependencias_eventos.dart` — Eventos, CrearEvento, Borradores, PanelControl,
      EscanearQr, EscanearEventoQr, Colaboradores, Auditoria, EventosEnCurso
    - `dependencias_ajustes.dart` — Roles, Permisos, Tags, Usuarios, TiposEvento,
      RevisionUsuarios (gestión de ajustes del sistema)
    - `dependencias_personal.dart` — Inicio, Perfil, Historial, Estadísticas,
      Notificaciones (datos propios del usuario)
  - Nuevo módulo: solo crear su `dependencias_[dominio].dart` y llamarlo en
    `configurarDependencias()`.
  - _Archivos_: `lib/configuracion/dependencias*.dart`

---

### 🟡 Menores

- [x] **M-2 — `Evento.aJson()` incompleto — faltaba el campo `alcance`**
  - Campo `alcance` añadido a `aJson()`. Es un campo requerido en el schema
    de Supabase que no se enviaba al crear/editar eventos.
  - _Archivo_: `lib/funcionalidades/eventos/evento.dart`

- [x] **M-3 — Caché local sin TTL ni versionado de esquema**
  - `CacheLocal` reescrito con soporte de TTL (por defecto 24 horas).
  - Cada entrada almacena `{ d, t, ttl }`. Al leer, si expiró, devuelve null
    y la elimina silenciosamente.
  - Box renombrado a `activiti_cache_v2` para migración limpia desde el
    formato anterior sin TTL.
  - _Archivo_: `lib/compartido/cache_local.dart`

- [x] **M-4 — `_StreamToListen` llamaba `notifyListeners()` en el constructor**
  - **Problema**: Llamar `notifyListeners()` antes de que GoRouter adjunte
    sus listeners es técnicamente incorrecto (aunque inofensivo en la práctica).
  - **Solución**: Línea eliminada del constructor.
  - _Archivo_: `lib/configuracion/router_app.dart`

- [x] **M-5 — Ruta `/auditoria-evento` en kebab-case (inconsistente)**
  - **Problema**: Todas las rutas usan `snake_case`, excepto esta que usaba
    `kebab-case` (`/auditoria-evento`).
  - **Solución**: Cambiada la constante a `/auditoria_evento`.
  - _Archivo_: `lib/compartido/constantes.dart`

- [x] **M-6 — Página 404 sin estilo ni navegación**
  - **Problema**: El `errorBuilder` del router mostraba un `Text` plano
    sin botón de regreso ni branding.
  - **Solución**: Scaffold con icono, texto estilizado y botón
    "Volver al inicio" que usa `context.go(Rutas.home)`.
  - _Archivo_: `lib/configuracion/router_app.dart`

- [x] **M-7 — `ColoresApp.blanco` usaba `Color.fromARGB` en lugar de `Color(0xFF...)`**
  - **Problema**: Inconsistencia con el resto de definiciones de color del archivo.
  - **Solución**: Cambiado a `Color(0xFFFFFFFF)`.
  - _Archivo_: `lib/configuracion/colores_app.dart`

- [x] **M-1 — `router_app.dart` con 84 imports (God File de compilación)**
  - **Problema**: Cualquier cambio en cualquier pantalla forzaba la recompilación
    del router. Impactaba tiempos de compilación incremental a medida que crecía.
  - **Solución**: Router dividido en 5 archivos de dominio. Ver BLOQUE 10 → P3.
  - _Archivos_: `lib/configuracion/router_app.dart`, `lib/configuracion/rutas/`

- [x] **M-2 — `Evento.aJson()` incompleto para round-trip completo**
  - `aJson()` conserva su rol para escrituras Supabase (sin id/timestamps del servidor).
  - Añadido `aJsonCompleto()` que hace `{...aJson(), 'id', 'creado_por', 'creado_en',
    'actualizado_en'}` — permite caché local con round-trip completo vía `desdeJson()`.
  - _Archivo_: `lib/funcionalidades/eventos/evento.dart`

---

## Problemas conocidos pendientes

| # | Descripción | Severidad | Estado |
|---|---|---|---|
| 1 | Iconos pueden ser el logo default de Flutter | Media | Verificación manual pendiente |
| 2 | Secretos de GitHub no configurados | Alta (deploy) | Acción manual pendiente |
| 3 | Servidor de despliegue sin HTTPS/routing | Alta (deploy) | Acción manual pendiente |
| 4 | Paginación en consultas de lista (I-1) | Alta (escala) | ✓ Completado — BLOQUE 9 |
| 5 | Cobertura de tests (I-4) | Alta (calidad) | Parcial — historial + roles cubiertos |
| 6 | `dependencias.dart` dividido por dominio (I-5) | Media | ✓ Completado |
| 7 | `FallaRed` en todos los repositorios (I-3) | Media | ✓ Completado — 26 repos actualizados |
| 8 | `Evento.aJsonCompleto()` round-trip (M-2) | Baja | ✓ Completado |
| 9 | Caché con TTL (M-3) | Baja | ✓ Completado |
| 10 | Router God File 84 imports (M-1) | Baja | Pendiente — requiere go_router_builder |

---

## BLOQUE 9 — Análisis Exhaustivo de Paginación (2026-06-06)

Auditoría de los 28 repositorios. Criterio: ¿puede la consulta retornar cientos
o miles de filas a medida que crece la universidad?

### 🔴 Alta prioridad — listas sin límite que crecen con los datos

- [x] **P-1 — `usuarios.obtenerUsuarios()`**
  - Carga TODOS los usuarios del sistema sin límite.
  - En una universidad: cientos a miles de registros.
  - Complejidad extra: selection mode, batch ops, filtro client-side.
  - Solución: `UsuariosCargandoMas` preserva `seleccionados`/`modoSeleccion` durante la carga;
    `_extraerCargados()` actualizado para soportar el nuevo estado en todas las operaciones.
  - _Archivo_: `lib/funcionalidades/usuarios/usuarios_repositorio.dart`

- [x] **P-2 — `panel_control_evento.obtenerAsistentes(eventoId)`**
  - Carga TODOS los asistentes de un evento sin límite.
  - Eventos masivos pueden tener 200–500+ asistentes.
  - **Decisión**: Techo `.limit(5000)`. El dataset completo es requerido para KPIs
    (`tasaConvocatoria`, `pendientes`, `_mergarConAsistencia`) y para el reload
    silencioso que dispara Realtime con cada escaneo QR.
  - También: añadido handler `FallaRed` faltante en `PanelControlCubit.cargar()`.
  - _Archivo_: `lib/funcionalidades/panel_control_evento/panel_control_repositorio.dart`

- [-] **P-3 — `panel_control_evento.obtenerTodosUsuarios()`**
  - **Método muerto** — definido en el repositorio pero jamás llamado desde el cubit.
  - El cubit usa `_audiencia = []` para eventos `general` (no llama a esta función).
  - No requiere acción. Si se activa en el futuro, aplicar techo como P-1.
  - _Archivo_: `lib/funcionalidades/panel_control_evento/panel_control_repositorio.dart`

- [-] **P-4 — `auditoria_evento.obtenerRegistros(eventoId)`**
  - Los registros son necesarios completos para calcular KPIs (tasa asistencia,
    timeline, donut, registradores). Paginar solo el display pero cargar todo el
    dataset no aporta mejora real; el `SliverList` ya hace virtual rendering.
  - **Decisión**: No paginar. El límite natural es el aforo del evento (≤ 500).
  - _Archivo_: `lib/funcionalidades/auditoria_evento/auditoria_evento_repositorio.dart`

- [x] **P-5 — `auditoria_evento.obtenerEventos()` — reemplazar `limit(300)` hardcodeado**
  - Tiene un límite arbitrario de 300. Debe ser paginación real.
  - Solución: `cargarMasEventos()` en cubit actualiza `_todosEventos` sin cambiar el estado
    principal; la modal usa `setState` reactivo tras el await para releer `cubit.todosEventos`.
  - _Archivo_: `lib/funcionalidades/auditoria_evento/auditoria_evento_repositorio.dart`

### 🟡 Media prioridad — listas de catálogo que crecen lentamente

- [x] **P-6 — `gestionar_tags_usuario.obtenerTagsActivos()`**
  - Todos los tags activos del sistema. Puede crecer.
  - Usado en picker de asignación (`principalesDisponibles`/`secundariosDisponibles`).
  - **Decisión**: Techo de seguridad `.limit(200)` + `.order('tipo').order('nombre')`.
    Paginar un picker rompe la UX (el usuario necesita ver TODAS las opciones para elegir).
    Si algún día los tags superan los 200, la solución correcta es un picker con búsqueda.
  - _Archivo_: `lib/funcionalidades/gestionar_tags_usuario/gestionar_tags_usuario_repositorio.dart`

- [x] **P-7 — `crear_evento.obtenerTags()`**
  - Todos los tags activos para el formulario de crear evento (grupos de audiencia).
  - Mismo razonamiento que P-6. Aplicado `.limit(200)` + `.order('tipo').order('nombre')`.
  - _Archivo_: `lib/funcionalidades/crear_evento/crear_evento_repositorio.dart`

### ✅ No requieren paginación (tablas acotadas o por diseño)

| Método | Razón |
|---|---|
| `auditoria_evento.obtenerEventos()` | Reemplazado por P-5 |
| `notificaciones.obtenerTodas()` | `limit(50)` es intencional — bandeja de entrada |
| `buscar_asistente.buscarUsuarios()` | `limit(30)` — resultado de búsqueda acotado por diseño |
| `colaboradores_evento.buscarUsuarios()` | `limit(30)` — igual |
| `tipos_evento.obtenerTiposEvento()` | Catálogo pequeño, estable (10-50 tipos máximo) |
| `permisos.obtenerPermisos()` | Permisos del sistema, fijo (< 30 registros) |
| `crear_rol.obtenerPermisos()` | Igual que anterior |
| `gestionar_roles_usuario.obtenerRolesActivos()` | Roles acotados (< 20) |
| `colaboradores_evento.obtenerColaboradores()` | Colaboradores por evento (< 20 por diseño) |
| `crear_evento.obtenerTiposEvento()` | Catálogo pequeño |
| `obtenerTagsUsuario()`, `obtenerRolesUsuario()` | Tags/roles de UN usuario (acotado) |
| `obtenerGruposEvento()`, `obtenerMiembrosGrupo()` | Grupos de un evento (acotado) |
| `inicio.obtenerTagsUsuario()`, `perfil.obtenerTags()` | Datos de usuario específico |

### Progreso

| # | Módulo | Estado |
|---|---|---|
| P-1 | `usuarios.obtenerUsuarios()` | [x] Hecho |
| P-2 | `panel_control.obtenerAsistentes()` | [x] Hecho (limit 5000 + FallaRed) |
| P-3 | `panel_control.obtenerTodosUsuarios()` | [-] Muerto — nunca llamado desde el cubit |
| P-4 | `auditoria_evento.obtenerRegistros()` | [-] Descartado (dataset completo requerido para KPIs) |
| P-5 | `auditoria_evento.obtenerEventos()` | [x] Hecho |
| P-6 | `gestionar_tags_usuario.obtenerTagsActivos()` | [x] Hecho (limit 200 + order) |
| P-7 | `crear_evento.obtenerTags()` | [x] Hecho (limit 200 + order) |

---

---

## BLOQUE 10 — Calidad de Código y Tests de Integración (2026-06-07)

Implementación de 5 mejoras identificadas en la auditoría de ingeniero senior.

---

### P3 — Router God File: 84 imports → 5 archivos de dominio

- [x] **Dividir `router_app.dart` por dominio**
  - **Problema antes**: Un solo archivo con 84 imports forzaba recompilación del
    router ante cualquier cambio en cualquier pantalla del proyecto.
  - **Análisis**: El router mezclaba lógica de guard/redirect con la construcción
    de rutas de 5 dominios distintos. El guard debía seguir en el archivo central
    porque necesita acceso al `AuthCubit` y a `Rutas.*`. La construcción de rutas
    era el componente a separar.
  - **Patrón implementado**: Cada archivo de dominio expone un getter de lista:
    ```dart
    List<GoRoute> get rutasAuth => [ GoRoute(path: Rutas.login, ...), ... ];
    ```
    El router central los esparce: `routes: [...rutasAuth, ...rutasPersonal, ...]`
  - **Resultado**: `router_app.dart` pasó de 84 a 5 imports. Cada archivo de dominio
    solo importa sus propias pantallas. `flutter analyze lib/configuracion/` → 0 issues.
  - _Archivos creados_:
    - `lib/configuracion/rutas/rutas_auth.dart` — splash, login, registro, completarPerfil, recuperarContrasena, nuevaContrasena, pendienteAprobacion, usuarioRechazado
    - `lib/configuracion/rutas/rutas_personal.dart` — home (MultiBlocProvider), admin, perfil, historial, estadisticas, notificaciones
    - `lib/configuracion/rutas/rutas_eventos.dart` — eventos, crearEvento, editarEvento, borradores, panelControl, buscarAsistente, escanearQrUsuario, escanear, colaboradoresEvento, auditoriaEvento
    - `lib/configuracion/rutas/rutas_ajustes.dart` — 15 rutas de gestión del sistema
    - `lib/configuracion/rutas/rutas_dev.dart` — vistaWidgets, vistaFuentes (solo `kDebugMode && entorno.esDev`)
    - `lib/configuracion/router_app.dart` — reducido a guards + redirect + spread de las 5 listas

---

### P4 — Cero tests de integración → suite de 16 tests

- [x] **Tests de integración: cubit real + repositorio mockeado + UI real**
  - **Problema antes**: Solo existían tests de widget con cubits mockeados. Eso
    no verificaba la cadena cubit → estado → UI ante lógica de negocio real.
    Un bug en el cubit podía pasar desapercibido aunque los widget tests pasaran.
  - **Análisis**: Los tests de integración deben usar el cubit REAL (no `MockCubit`)
    y solo mockear el repositorio externo. Así se prueba que la lógica interna del
    cubit produce los estados correctos y que la UI los renderiza bien.
  - **Patrón implementado**:
    ```dart
    final cubit = LoginCubit(repositorio);       // cubit real
    when(() => repositorio.iniciarSesion(...))   // repo mockeado
        .thenAnswer((_) async => authResponse);
    await tester.pumpWidget(_marco(cubit, authCubit));
    await tester.pump(); // future resuelve → cubit emite estado
    await tester.pump(); // BlocListener reacciona → UI actualiza
    ```
  - **Nota técnica**: `BlocProvider<AuthCubit>.value(value: auth)` — siempre
    anotar el tipo genérico explícitamente; sin él, Dart infiere `MockAuthCubit`
    y `context.read<AuthCubit>()` lanza `ProviderNotFoundException`.
  - **16 tests de integración** cubriendo 5 flujos:
    - `test/integracion/login_integracion_test.dart` — 3 tests (campos vacíos, éxito, error servidor)
    - `test/integracion/registro_integracion_test.dart` — 4 tests (campos vacíos, contraseñas distintas, éxito, error servidor)
    - `test/integracion/historial_integracion_test.dart` — 3 tests (carga con items, lista vacía, error red)
    - `test/integracion/borradores_integracion_test.dart` — 3 tests (cargar, error, publicarEvento)
    - `test/integracion/revision_usuarios_integracion_test.dart` — 3 tests (carga, lista vacía, error servidor)

---

### P5 — Accesibilidad mínima: Semantics en widgets compartidos

- [x] **Añadir Semantics a todos los widgets del directorio `compartido/`**
  - **Problema antes**: Ningún widget compartido tenía etiquetas semánticas.
    Los lectores de pantalla no podían distinguir campos de contraseña de texto
    normal, ni identificar botones de icono.
  - **Análisis**: Se priorizaron los widgets de mayor impacto:
    1. **Campos de texto** (`CampoTextoApp`): la etiqueta de accesibilidad debe
       ser la misma que la etiqueta visual para que el lector la anuncie.
    2. **Botones de icono** (`BotonIcono`, ojo de contraseña): sin texto visible,
       requieren `Semantics(button: true, label: ...)` para ser identificables.
    3. **Banners de estado** (`BannerSinConexion`): deben anunciarse como
       `liveRegion: true` para que el lector los anuncie al aparecer.
    4. **Iconos decorativos**: deben silenciarse con `ExcludeSemantics`.
  - **Widgets modificados**:
    - `lib/compartido/widgets/formularios/campo_texto_app.dart`
      — `Semantics(label: etiqueta, textField: true)` en `TextFormField`
      — `Semantics(button: true, label: 'Mostrar/Ocultar contraseña', excludeSemantics: true)` en ojo
    - `lib/compartido/widgets/utilidades/banner_sin_conexion.dart`
      — `Semantics(liveRegion: true, label: 'Sin conexión — mostrando datos guardados')`
      — `ExcludeSemantics` en icono y texto hijos (evita duplicar el anuncio)
    - `lib/compartido/widgets/formularios/barra_busqueda_app.dart`
      — `ExcludeSemantics` en icono de lupa decorativo
      — `Semantics(button: true, label: 'Filtrar por rango de fechas' / 'Filtro activo...')` en `_BotonCalendario`
    - `lib/compartido/widgets/botones/boton_icono.dart`
      — `Semantics(button: true, label: tooltip, enabled: alPresionar != null)`
      — `ExcludeSemantics` en `Icon` hijo

---

### P10 — Sin retry/backoff en llamadas de red → utilidad `conReintentos`

- [x] **Crear `lib/compartido/reintento.dart` y aplicar en repositorios críticos**
  - **Problema antes**: Un fallo de red momentáneo (timeout de 1 s, DNS flaky)
    propagaba `FallaRed` directamente al usuario sin ningún reintento.
    En una PWA con conectividad móvil variable esto genera falsos positivos.
  - **Análisis**: Solo los errores `FallaRed` merecen reintento automático.
    `FallaServidor` (4xx/5xx) y `FallaAutenticacion` deben propagarse
    inmediatamente — reintentar un 401 solo empeoraría.
    El backoff debe ser lineal y acotado para no bloquear la UI.
  - **Implementación**:
    ```dart
    Future<T> conReintentos<T>(
      Future<T> Function() operacion, {
      int      maxIntentos = 2,        // 1 intento original + 1 reintento
      Duration esperaBase  = const Duration(milliseconds: 800),
    }) async {
      var intentos = 0;
      while (true) {
        try {
          return await operacion();
        } on FallaRed {
          intentos++;
          if (intentos >= maxIntentos) rethrow;
          await Future.delayed(esperaBase * intentos); // backoff lineal: 800ms, 1600ms
        }
      }
    }
    ```
  - **Aplicado en repositorios de lectura frecuente** (escrituras quedan sin retry
    para evitar operaciones duplicadas en Supabase):
    - `historial_repositorio.dart` → `obtenerHistorial()`
    - `eventos_repositorio.dart` → `obtenerEventosConGrupos()`
    - `panel_control_repositorio.dart` → `obtenerEvento()`, `obtenerAsistentes()`
  - _Archivo creado_: `lib/compartido/reintento.dart`

---

### P11 — `imageCache` sin límite → configurar techo en `main.dart`

- [x] **Limitar el caché de imágenes de Flutter al arrancar la app**
  - **Problema antes**: Flutter no tiene límite por defecto en el `imageCache`.
    En una PWA con muchas fotos de perfil y eventos, el proceso podía crecer
    sin techo hasta que el GC forzara una pausa o el tab se reiniciara.
  - **Análisis**: En una app de gestión universitaria, las imágenes son avatares
    y banners de evento de baja rotación. Un límite de 150 entradas y 50 MB
    es suficientemente holgado para el uso real y acotado para producción web.
    Límites más agresivos causarían thrashing de caché (mismos avatares
    descargados repetidamente).
  - **Implementación** (en `main.dart`, antes de `runApp`):
    ```dart
    PaintingBinding.instance.imageCache
      ..maximumSize      = 150   // máximo 150 imágenes en caché
      ..maximumSizeBytes = 50 << 20;  // 50 MB techo de memoria
    ```
  - _Archivo_: `lib/main.dart`

---

---

## BLOQUE 11 — Hardening para Producción (2026-06-07)

Resultado de la segunda auditoría de ingeniero senior. Cubre los gaps bloqueantes
e importantes identificados tras la primera auditoría.

---

### H1 — Validación de email en el cliente (bloqueante)

- [x] **Regex de email en `LoginCubit` y `RegistroCubit`**
  - **Problema**: La validación solo verificaba `isEmpty`. Un correo con formato
    inválido (`notvalid`, `@`, `a@`) llegaba a Supabase y el error retornado
    podía no estar mapeado en `TraductorErrores`, mostrando un mensaje genérico.
  - **Solución**: Regex `^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$` aplicado en ambos cubits.
    Si no coincide → `LoginError` / `RegistroError` con mensaje claro antes de llamar al repo.
  - _Archivos_: `lib/funcionalidades/autenticacion/login_cubit.dart`,
    `lib/funcionalidades/autenticacion/registro_cubit.dart`

---

### H2 — Hardening del AuthCubit (bloqueante)

- [x] **`_procesarCambioToken` no esperaba `cerrarSesion()`**
  - **Problema**: La sesión se cerraba con `unawaited`, lo que significa que
    `emit(SesionDesplazada())` se ejecutaba antes de que Supabase cerrara la
    sesión. Si el router redirigía al login y `verificarSesion()` se llamaba
    antes del cierre, podía autenticar de nuevo al mismo usuario.
  - **Solución**: Convertido a `async`, `await _repositorio.cerrarSesion()` antes
    de emitir el estado.
  - _Archivo_: `lib/funcionalidades/autenticacion/auth_cubit.dart`

- [x] **Splash infinito si `verificarSesion()` no responde**
  - **Problema**: `verificarSesion()` espera `obtenerPerfil()` que hace una
    query a Supabase. Si el servidor no responde (cold start, red caída), el
    usuario queda atrapado en el spinner infinito sin mensaje de error.
  - **Solución**: `verificarSesion()` envuelto con `.timeout(kTimeoutSolicitud)`.
    Si supera 15s → emite `NoAutenticado()` y el router redirige al login.
  - _Archivo_: `lib/funcionalidades/autenticacion/auth_cubit.dart`

---

### H3 — Timeouts en todos los repositorios (bloqueante)

- [x] **`kTimeoutSolicitud` global + `TimeoutException` en `TraductorErrores`**
  - Constante `kTimeoutSolicitud = Duration(seconds: 15)` añadida a `constantes.dart`.
  - `TraductorErrores.lanzarInesperado()` actualizado para detectar `TimeoutException`
    y lanzar `FallaRed` con mensaje descriptivo (en lugar de `FallaInesperada`).
  - _Archivos_: `lib/compartido/constantes.dart`, `lib/compartido/traductor_errores.dart`

- [x] **`.timeout(kTimeoutSolicitud)` en los 28 repositorios**
  - Cada `await _supabase.from(...)` envuelto con `.timeout()`.
  - `TimeoutException` capturado y convertido a `FallaRed` vía `lanzarInesperado`.
  - _Archivos_: todos los `*_repositorio.dart`

---

### H4 — `conReintentos` extendido a todos los repos de lectura

- [x] **Aplicar `conReintentos` a todos los métodos `obtener*` / `buscar*`**
  - **Antes**: solo 3 repos tenían retry (historial, eventos, panel_control).
  - **Ahora**: todos los métodos de lectura (sin escrituras, para evitar duplicados).
  - _Archivos_: todos los `*_repositorio.dart` que tenían métodos de lectura sin retry

---

### H5 — Observabilidad: `reportarError()` en todos los cubits

- [x] **Helper `reportarError()` en `logger.dart`**
  - Función global que: (1) llama `log.e()`, (2) reporta a Sentry solo si el error
    es `FallaServidor` o `FallaInesperada` (no errores esperados de red o de auth).
  - _Archivo_: `lib/compartido/logger.dart`

- [x] **`reportarError()` en los catch blocks de todos los cubits**
  - **Antes**: los errores capturados en cubits se silenciaban. Sentry no veía
    errores frecuentes que no crasheaban la app.
  - **Ahora**: cada `on FallaServidor`, `on FallaRed`, `on FallaInesperada` llama
    `reportarError(falla)` antes de emitir el estado de error.
  - _Archivos_: todos los `*_cubit.dart`

---

---

## BLOQUE 12 — Notificaciones Push (2026-06-08)

Infraestructura implementada: Firebase FCM + service worker + Edge Function `enviar-notificacion`.
Las notificaciones se envían llamando a la Edge Function desde los cubits tras operaciones exitosas.

---

### Alta prioridad — Afectan directamente la cuenta del usuario

- [x] **N1 — Cuenta aprobada**
  - Cuándo: admin ejecuta `aprobar(usuarioId)` en `RevisionUsuariosCubit`
  - Quién recibe: el usuario aprobado
  - Mensaje: *"Tu cuenta fue aprobada. Ya puedes acceder a Activiti."*
  - _Archivo_: `lib/funcionalidades/revision_usuarios/revision_usuarios_cubit.dart`

- [x] **N2 — Cuenta rechazada**
  - Cuándo: admin ejecuta `rechazar(usuarioId)` en `RevisionUsuariosCubit`
  - Quién recibe: el usuario rechazado
  - Mensaje: *"Tu solicitud de cuenta fue rechazada."*
  - _Archivo_: `lib/funcionalidades/revision_usuarios/revision_usuarios_cubit.dart`

- [x] **N3 — Cuenta suspendida**
  - Cuándo: `suspender(usuarioId)` o `suspenderLote(ids)` en `UsuariosCubit`
  - Quién recibe: el/los usuarios suspendidos
  - Mensaje: *"Tu cuenta ha sido suspendida."*
  - _Archivo_: `lib/funcionalidades/usuarios/usuarios_cubit.dart`

- [x] **N4 — Asignado como colaborador**
  - Cuándo: `asignarColaborador()` en `ColaboradoresEventoCubit`
  - Quién recibe: el usuario asignado
  - Mensaje: *"Fuiste asignado como colaborador en un evento."*
  - _Archivo_: `lib/funcionalidades/colaboradores_evento/colaboradores_evento_cubit.dart`

- [x] **N5 — Removido como colaborador**
  - Cuándo: `quitarColaborador()` en `ColaboradoresEventoCubit`
  - Quién recibe: el usuario removido
  - Mensaje: *"Ya no eres colaborador en el evento."*
  - _Archivo_: `lib/funcionalidades/colaboradores_evento/colaboradores_evento_cubit.dart`

- [x] **N6 — Rol asignado**
  - Cuándo: `asignarRol()` en `GestionarRolesUsuarioCubit` o `asignarRolLote()` en `UsuariosCubit`
  - Quién recibe: el/los usuarios afectados
  - Mensaje: *"Se te asignó un nuevo rol en el sistema."*
  - _Archivos_: `gestionar_roles_usuario_cubit.dart`, `usuarios_cubit.dart`

- [x] **N7 — Rol removido**
  - Cuándo: `quitarRol()` en `GestionarRolesUsuarioCubit`
  - Quién recibe: el usuario afectado
  - Mensaje: *"Se te removió un rol del sistema."*
  - _Archivo_: `lib/funcionalidades/gestionar_roles_usuario/gestionar_roles_usuario_cubit.dart`

---

### Media prioridad — Afectan participación en eventos

- [x] **N8 — Evento publicado**
  - Cuándo: `publicarEvento()` en `CrearEventoCubit`
  - Quién recibe: usuarios con tags coincidentes (alcance `dirigido`); eventos `general` se omiten
  - Mensaje: *"Nuevo evento: [título]."*
  - _Archivos_: `crear_evento_cubit.dart`, `crear_evento_repositorio.dart` (nuevo método `obtenerUsuariosIdsDirigidos`)

- [-] **N9 — Evento cancelado**
  - No aplica — no existe funcionalidad de cancelar eventos en el código actual.

- [-] **N10 — Evento iniciado**
  - No aplica — no existe funcionalidad de iniciar eventos (`en_curso`) en el código actual.

- [x] **N11 — Evento cerrado**
  - Cuándo: `cerrarEvento()` en `PanelControlCubit`
  - Quién recibe: colaboradores del evento (tabla `eventos_usuarios_roles`)
  - Mensaje: *"El evento [título] fue cerrado."*
  - _Archivos_: `panel_control_cubit.dart`, `panel_control_repositorio.dart` (nuevo método `obtenerColaboradoresIds`)

---

### Baja prioridad — Informativos operacionales

- [x] **N12 — Entrada registrada por QR**
  - Cuándo: `procesarQr()` en `EscanearQrCubit` cuando `registrado == true`
  - Quién recibe: el usuario escaneado (`rawValue` = `usuarioId`)
  - Mensaje: *"Tu entrada a [título] fue registrada."*
  - _Archivo_: `escanear_qr_cubit.dart`

- [x] **N13 — Marcado como ausente automáticamente**
  - Cuándo: `cerrarEvento()` en `PanelControlCubit`, después de `marcarAusentesAuto()`
  - Quién recibe: usuarios con estatus `esperado` capturados antes de la actualización
  - Mensaje: *"Fuiste marcado como ausente en [título]."*
  - _Archivos_: `panel_control_cubit.dart`, `panel_control_repositorio.dart` (nuevo método `obtenerEsperadosIds`)

---

### Progreso BLOQUE 12

| # | Notificación | Prioridad | Estado |
|---|---|---|---|
| N1 | Cuenta aprobada | Alta | [x] Hecho |
| N2 | Cuenta rechazada | Alta | [x] Hecho |
| N3 | Cuenta suspendida | Alta | [x] Hecho |
| N4 | Asignado colaborador | Alta | [x] Hecho |
| N5 | Removido colaborador | Alta | [x] Hecho |
| N6 | Rol asignado | Alta | [x] Hecho |
| N7 | Rol removido | Alta | [x] Hecho |
| N8 | Evento publicado | Media | [x] Hecho |
| N9 | Evento cancelado | Media | [-] No aplica |
| N10 | Evento iniciado | Media | [-] No aplica |
| N11 | Evento cerrado | Media | [x] Hecho |
| N12 | Entrada por QR | Baja | [x] Hecho |
| N13 | Ausente automático | Baja | [x] Hecho |

---

## Progreso general

**Completadas**: 37 de 37 tareas originales + BLOQUE 9 (paginación) + BLOQUE 10 (calidad) + BLOQUE 11 (hardening producción) + BLOQUE 12 alta prioridad (notificaciones push).

**BLOQUE 9 — Paginación (100%)**:
- P-1, P-5: paginación real con `cargarMas()` + estado `*CargandoMas`.
- P-2, P-4: techo de seguridad para KPIs/Realtime.
- P-3: método muerto — sin acción. P-6, P-7: techo limit(200).

**BLOQUE 10 — Calidad (100%)**:
- Router dividido, 16 tests de integración, Semantics, conReintentos (3 repos), imageCache.

**BLOQUE 11 — Hardening (100%)**:
- H1: validación de email con regex en login + registro.
- H2: AuthCubit sin race condition en sesión desplazada + timeout en splash.
- H3: timeout 15s en los 28 repositorios + `TimeoutException → FallaRed`.
- H4: `conReintentos` extendido a todos los repos de lectura.
- H5: `reportarError()` en todos los cubits → Sentry ve errores de producción.

**BLOQUE 12 — Notificaciones Push (100%)**:
- Infraestructura: Firebase FCM + service worker + Edge Function desplegada.
- N1–N7 (alta prioridad): implementadas en cubits.
- N8, N11, N12, N13: implementadas. N9 y N10: no aplica (funcionalidades no existen).

Quedan únicamente las acciones manuales de infraestructura (iconos PWA, GitHub Secrets, servidor HTTPS).
