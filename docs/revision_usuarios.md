# Revisión de usuarios — Activiti

## Tabla de contenido

1. [Resumen general](#resumen-general)
2. [Actores del proceso](#actores-del-proceso)
3. [Configuración del sistema](#configuración-del-sistema)
4. [Estados de aprobación](#estados-de-aprobación)
5. [Diagrama de flujo completo](#diagrama-de-flujo-completo)
6. [Flujo del usuario nuevo](#flujo-del-usuario-nuevo)
7. [Flujo del administrador](#flujo-del-administrador)
8. [Arquitectura técnica](#arquitectura-técnica)
9. [Estructura de archivos](#estructura-de-archivos)
10. [Base de datos](#base-de-datos)
11. [Navegación y rutas](#navegación-y-rutas)
12. [Seguridad y RLS](#seguridad-y-rls)
13. [Manejo de errores](#manejo-de-errores)

---

## Resumen general

El módulo de **revisión de usuarios** es un mecanismo opcional de control de acceso que permite a los administradores aprobar o rechazar manualmente cada solicitud de registro antes de que el usuario pueda ingresar a la aplicación.

Este comportamiento se activa o desactiva a través de un flag de configuración en la base de datos. Cuando está **desactivado**, el registro funciona como siempre: el usuario completa su perfil y accede inmediatamente. Cuando está **activado**, el usuario queda en espera hasta que un administrador tome una decisión.

| Modo | Comportamiento |
|------|----------------|
| Flag desactivado (`false`) | El usuario accede a la app inmediatamente tras completar su perfil |
| Flag activado (`true`) | El usuario queda pendiente hasta ser aprobado por un administrador |

---

## Actores del proceso

| Actor | Descripción |
|-------|-------------|
| **Usuario nuevo** | Persona que se registra en la app por primera vez |
| **Administrador** | Usuario con acceso al panel de configuración, donde gestiona las solicitudes pendientes |

El sistema no tiene un rol "administrador" fijo: cualquier usuario que tenga acceso al panel de ajustes (determinado por los permisos del sistema) puede revisar solicitudes.

---

## Configuración del sistema

El comportamiento se controla mediante un registro en la tabla `configuracion_boolean` de Supabase:

| Campo | Valor |
|-------|-------|
| `clave` | `revision_usuario_creacion` |
| `valor` | `true` (activado) / `false` (desactivado) |
| `modulo` | `usuarios` |

### Cómo cambia el comportamiento

```
valor = false  →  Registro instantáneo (comportamiento por defecto)
valor = true   →  Registro con revisión manual del administrador
```

Este flag se consulta en **dos momentos distintos**:

1. **Al crear el perfil** (`crear_usuario_cubit.dart`): determina con qué `estatus_aprobacion` se guarda el usuario.
2. **Al cargar la pantalla de inicio** (`inicio_cubit.dart`): determina si el botón "Revisión de usuarios" aparece en el panel de ajustes del administrador.

Ambas consultas fallan silenciosamente hacia `false` si hay un error de red o de permisos, garantizando que el sistema nunca quede bloqueado por un problema de configuración.

> **Importante:** La tabla `configuracion_boolean` requiere una política RLS que permita lectura a usuarios autenticados. Sin ella, la consulta falla silenciosamente y el flag siempre se comporta como `false`. Ver sección [Seguridad y RLS](#seguridad-y-rls).

---

## Estados de aprobación

El campo `estatus_aprobacion` en la tabla `usuarios` puede tener tres valores, definidos en la clase `EstatusAprobacion` de `constantes.dart`:

| Constante | Valor en BD | Significado |
|-----------|-------------|-------------|
| `EstatusAprobacion.aprobado` | `'aprobado'` | El usuario puede acceder a la app |
| `EstatusAprobacion.pendiente` | `'pendiente'` | El usuario espera revisión del administrador |
| `EstatusAprobacion.rechazado` | `'rechazado'` | El administrador rechazó la solicitud |

El valor por defecto del campo es `'aprobado'`, lo que garantiza retrocompatibilidad: los usuarios creados antes de que existiera este sistema siguen funcionando sin modificación.

---

## Diagrama de flujo completo

```
┌─────────────────────────────────────────────────────────────────┐
│                         REGISTRO NUEVO                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                  ┌──────────────────┐
                  │ ¿Flag activado?  │
                  └────────┬─────────┘
                           │
              ┌────────────┴────────────┐
              │ NO                      │ SÍ
              ▼                         ▼
  ┌─────────────────────┐   ┌───────────────────────┐
  │ estatus = 'aprobado'│   │ estatus = 'pendiente' │
  │ → Acceso inmediato  │   │ → Pantalla de espera  │
  └─────────────────────┘   └──────────┬────────────┘
                                        │
                             ┌──────────┴──────────┐
                             │   ADMINISTRADOR      │
                             │   revisa solicitud   │
                             └──────────┬──────────┘
                                        │
                           ┌────────────┴────────────┐
                           │ APROBAR                  │ RECHAZAR
                           ▼                          ▼
               ┌─────────────────────┐   ┌──────────────────────┐
               │ estatus = 'aprobado'│   │ estatus = 'rechazado'│
               │ → Acceso a la app   │   │ → Pantalla de rechazo│
               └─────────────────────┘   └──────────┬───────────┘
                                                     │
                                                     ▼
                                         ┌─────────────────────┐
                                         │ Usuario puede        │
                                         │ "Intentar de nuevo"  │
                                         │ → Vuelve al formulario│
                                         │   de perfil (upsert) │
                                         └─────────────────────┘
```

---

## Flujo del usuario nuevo

### Paso 1 — Registro en Supabase Auth

El usuario ingresa su correo y contraseña en la pantalla de registro. Supabase crea la cuenta en `auth.users` y emite una sesión activa. En este punto el usuario aún no tiene fila en la tabla `usuarios`.

El `AuthCubit` detecta que hay sesión pero sin perfil y emite el estado `PerfilIncompleto`, que lleva al formulario de datos personales.

### Paso 2 — Completar perfil

El usuario llena su nombre, apellidos, identificación y teléfono. Al presionar "Finalizar Registro", el `CrearUsuarioCubit` ejecuta:

```
1. Consulta flag en configuracion_boolean
2. Construye objeto Usuario con:
   - estatus_aprobacion = 'pendiente'  (si flag = true)
   - estatus_aprobacion = 'aprobado'   (si flag = false)
3. Upsert en tabla usuarios (conflicto en auth_id)
4. Llama a AuthCubit.verificarSesion()
```

El **upsert** (en lugar de insert) es intencional: permite que un usuario previamente rechazado vuelva a enviar su perfil sin violar la restricción única de `auth_id`.

### Paso 3a — Sin revisión requerida

`verificarSesion()` lee el perfil, encuentra `estatus_aprobacion = 'aprobado'` y emite `Autenticado`. El router redirige a la pantalla de inicio.

### Paso 3b — Con revisión requerida

`verificarSesion()` lee el perfil, encuentra `estatus_aprobacion = 'pendiente'` y emite `PendienteAprobacion`. El router redirige a `PendienteAprobacionPantalla`.

Esta pantalla muestra un mensaje informativo y dos acciones:

| Botón | Acción |
|-------|--------|
| **Verificar estado** | Llama a `verificarSesion()` nuevamente para comprobar si el admin ya actuó |
| **Cerrar sesión** | Cierra la sesión y va a login |

No hay actualización en tiempo real: el usuario debe presionar "Verificar estado" manualmente.

### Paso 4 — Usuario rechazado

Si el administrador rechazó la solicitud, `verificarSesion()` encuentra `estatus_aprobacion = 'rechazado'` y emite `UsuarioRechazado`. El router redirige a `UsuarioRechazadoPantalla`.

Esta pantalla ofrece dos opciones:

| Botón | Acción |
|-------|--------|
| **Intentar de nuevo** | `AuthCubit.reiniciarParaReintento()` emite `PerfilIncompleto`, llevando al formulario de perfil. El upsert en el paso 2 actualiza el registro existente con el nuevo `estatus_aprobacion = 'pendiente'`. |
| **Cerrar sesión** | Cierra la sesión y va a login |

---

## Flujo del administrador

### Visibilidad del módulo

El botón "Revisión de usuarios" en el panel de ajustes **solo aparece cuando el flag está activado**. Esto evita mostrar una pantalla vacía cuando la funcionalidad no está en uso.

La pantalla de inicio carga el flag en paralelo con los tags del usuario:

```dart
final tagsF     = _repositorio.obtenerTags(usuarioId);
final revisionF = _repositorio.obtenerRevisionHabilitada();
final tags      = await tagsF;
final revision  = await revisionF;
```

Ambas peticiones corren de forma concurrente para no añadir latencia.

### Pantalla de revisión

`RevisionUsuariosPantalla` muestra la lista de usuarios con `estatus_aprobacion = 'pendiente'`, ordenados por fecha de creación (más antiguos primero).

Cada tarjeta muestra:
- Nombre completo
- Correo electrónico
- Número de identificación (si aplica)
- Teléfono (si aplica)

Y ofrece cuatro acciones:

| Acción | Descripción |
|--------|-------------|
| **Agregar roles** | Navega a `GestionarRolesUsuarioPantalla` con el `usuario_id`. La asignación de roles es independiente del proceso de aprobación. |
| **Agregar tags** | Navega a `GestionarTagsUsuarioPantalla` con el `usuario_id`. Los tags también se gestionan de forma independiente. |
| **Rechazar** | Muestra un diálogo de confirmación. Si confirma, actualiza `estatus_aprobacion = 'rechazado'` y recarga la lista. |
| **Aceptar** | Actualiza `estatus_aprobacion = 'aprobado'` directamente y recarga la lista. |

> El botón "Aceptar" **solo cambia el estatus de aprobación**. Los roles y tags se asignan desde sus pantallas dedicadas, antes o después de aprobar, sin restricción de orden.

### Comportamiento durante operaciones

Mientras se procesa una aprobación o rechazo, la pantalla muestra una capa semitransparente sobre la lista completa y un `CircularProgressIndicator` centrado. El campo `usuarioIdProcessando` en el estado identifica cuál usuario está siendo procesado, previniendo interacciones simultáneas.

Si la operación falla (error de servidor), se muestra un snackbar de error y la lista vuelve a su estado anterior, permitiendo reintentar.

---

## Arquitectura técnica

El módulo sigue el patrón estándar del proyecto: **Pantalla → Cubit → Repositorio → Supabase**.

### `RevisionUsuariosCubit`

Gestiona tres operaciones:

```
cargar()   → obtenerPendientes()         → emite RevisionUsuariosCargados
aprobar()  → aprobar(usuarioId)          → llama a cargar() al terminar
rechazar() → rechazar(usuarioId)         → llama a cargar() al terminar
```

Mientras una operación está en curso, el estado `RevisionUsuariosCargados` lleva el campo `usuarioIdProcessando` con el id del usuario en proceso. La lista de usuarios permanece visible durante la operación.

Si la operación falla, el cubit emite el mismo estado `RevisionUsuariosCargados` (conservando la lista) con `errorOperacion` poblado. El `BlocConsumer` en la pantalla detecta esto y muestra el snackbar.

### Estados de `RevisionUsuariosEstado`

```
RevisionUsuariosInicial    → Estado inicial, antes de la primera carga
RevisionUsuariosCargando   → Cargando la lista de pendientes
RevisionUsuariosCargados   → Lista disponible (puede tener usuarioIdProcessando y/o errorOperacion)
RevisionUsuariosError      → Error al cargar la lista (no al operar sobre un usuario)
```

### `AuthCubit` — Estados globales nuevos

Estos estados se añadieron al cubit global de autenticación:

```
PendienteAprobacion  → El usuario tiene estatus 'pendiente'
UsuarioRechazado     → El usuario tiene estatus 'rechazado'
```

`verificarSesion()` es el único punto que evalúa el `estatus_aprobacion` y emite el estado correspondiente. El router reacciona a estos estados mediante su lógica de `redirect`.

---

## Estructura de archivos

```
lib/
├── compartido/
│   └── constantes.dart                    → EstatusAprobacion, TablasSupabase.configuracionBoolean
│
├── configuracion/
│   ├── router_app.dart                    → Redirects para PendienteAprobacion y UsuarioRechazado
│   └── dependencias.dart                  → Registro de RevisionUsuariosRepositorio y RevisionUsuariosCubit
│
└── funcionalidades/
    ├── autenticacion/
    │   ├── usuario.dart                   → Campo estatusAprobacion, default EstatusAprobacion.aprobado
    │   ├── auth_estado.dart               → PendienteAprobacion, UsuarioRechazado
    │   ├── auth_cubit.dart                → verificarSesion() evalúa estatus; reiniciarParaReintento()
    │   ├── autenticacion_repositorio.dart → crearPerfilUsuario() con upsert; verificarRevisionCreacionHabilitada()
    │   ├── pendiente_aprobacion_pantalla.dart
    │   └── usuario_rechazado_pantalla.dart
    │
    ├── crear_usuario/
    │   └── crear_usuario_cubit.dart       → guardarPerfil() consulta el flag y asigna estatus
    │
    ├── inicio/
    │   ├── inicio_repositorio.dart        → obtenerRevisionHabilitada()
    │   ├── inicio_estado.dart             → InicioTagsCargados.revisionHabilitada
    │   ├── inicio_cubit.dart              → carga flag en paralelo con los tags
    │   └── inicio_pantalla.dart           → muestra botón "Revisión de usuarios" condicionalmente
    │
    └── revision_usuarios/
        ├── revision_usuario_item.dart     → Modelo de datos del usuario pendiente
        ├── revision_usuarios_estado.dart  → Estados del cubit de revisión
        ├── revision_usuarios_repositorio.dart
        ├── revision_usuarios_cubit.dart
        └── revision_usuarios_pantalla.dart
```

---

## Base de datos

### Tabla `usuarios`

El campo relevante es `estatus_aprobacion`:

```sql
estatus_aprobacion VARCHAR NOT NULL DEFAULT 'aprobado'
```

El valor por defecto `'aprobado'` garantiza retrocompatibilidad: los registros existentes antes de implementar este módulo no requieren migración.

### Tabla `configuracion_boolean`

Almacena flags de configuración del sistema:

```sql
CREATE TABLE public.configuracion_boolean (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  clave       VARCHAR      NOT NULL UNIQUE,
  valor       BOOLEAN      NOT NULL DEFAULT false,
  descripcion TEXT         NOT NULL,
  modulo      VARCHAR      NOT NULL,
  creado_en   TIMESTAMP    DEFAULT now(),
  actualizado_en TIMESTAMP DEFAULT now()
);
```

El registro que controla este módulo:

```sql
INSERT INTO configuracion_boolean (clave, valor, descripcion, modulo)
VALUES (
  'revision_usuario_creacion',
  true,
  'Requiere aprobación manual del administrador al crear nuevos usuarios',
  'usuarios'
);
```

---

## Navegación y rutas

Las rutas se definen en `Rutas` (dentro de `constantes.dart`):

| Constante | Path | Pantalla |
|-----------|------|----------|
| `Rutas.pendienteAprobacion` | `/pendiente_aprobacion` | `PendienteAprobacionPantalla` |
| `Rutas.usuarioRechazado` | `/usuario_rechazado` | `UsuarioRechazadoPantalla` |
| `Rutas.revisionUsuarios` | `/revision_usuarios` | `RevisionUsuariosPantalla` |

### Lógica de redirect en el router

El router evalúa el estado de `AuthCubit` en cada navegación. El orden de evaluación es crítico:

```
1. ¿Es AuthInicial?            → /splash
2. ¿Es NoAutenticado?          → /login
3. ¿Es PerfilIncompleto?       → /crear_usuario
4. ¿Es RecuperandoContrasena?  → /recuperar_contrasena
5. ¿Es PendienteAprobacion?    → /pendiente_aprobacion   ← NUEVO
6. ¿Es UsuarioRechazado?       → /usuario_rechazado      ← NUEVO
7. ¿Es SesionDesplazada?       → /sesion_desplazada
8. ¿NO es Autenticado?         → /login  (fallback)
9. ¿Está en ruta de auth?      → /inicio  (redirige al inicio)
```

Los nuevos estados (5 y 6) deben evaluarse **antes** del fallback `is! Autenticado` (paso 8), ya que `PendienteAprobacion` y `UsuarioRechazado` no son instancias de `Autenticado` y caerían incorrectamente a `/login`.

Las rutas `/pendiente_aprobacion` y `/usuario_rechazado` también están incluidas en la lista de "rutas de auth" del paso 9, evitando que un usuario ya autenticado las visite accidentalmente.

---

## Seguridad y RLS

### Política requerida en `configuracion_boolean`

Sin esta política, la consulta del flag falla silenciosamente y el sistema siempre se comporta como si el flag fuera `false`:

```sql
CREATE POLICY "Lectura pública para usuarios autenticados"
  ON configuracion_boolean
  FOR SELECT
  TO authenticated
  USING (true);
```

### Protección de la pantalla de revisión

La pantalla `RevisionUsuariosPantalla` solo es accesible desde el panel de ajustes del inicio, que a su vez solo es visible para usuarios autenticados. Sin embargo, se recomienda complementar con una política RLS en la tabla `usuarios` que restrinja quién puede actualizar el campo `estatus_aprobacion`, limitándolo a usuarios con el rol de administrador.

### Comportamiento ante errores de permisos

Todas las consultas al flag de configuración usan el patrón **fail-safe**: ante cualquier error (red, RLS, timeout), retornan `false` en lugar de lanzar una excepción. Esto garantiza que:

- El registro de nuevos usuarios nunca queda bloqueado
- La pantalla de inicio no lanza un error si el flag no es accesible
- El comportamiento por defecto es el modo sin revisión

---

## Manejo de errores

### Durante el registro

| Situación | Comportamiento |
|-----------|----------------|
| Sin sesión activa al guardar perfil | Emite `CrearUsuarioError` con mensaje al usuario |
| Error de red al consultar el flag | El flag se trata como `false`; el usuario se crea como `'aprobado'` |
| Error de BD al crear perfil | Emite `CrearUsuarioError` con mensaje al usuario |

### Durante la revisión (administrador)

| Situación | Comportamiento |
|-----------|----------------|
| Error al cargar la lista | Emite `RevisionUsuariosError`; pantalla muestra botón "Reintentar" |
| Error al aprobar o rechazar | Mantiene la lista visible; muestra snackbar de error; permite reintentar |
| Operación en curso | Bloquea la interfaz completa con overlay semitransparente |

### Verificación de estado (usuario pendiente)

Si `verificarSesion()` falla por error de red, el `AuthCubit` emite `NoAutenticado` y el usuario es redirigido al login. Esto es intencional: es preferible pedir nuevas credenciales a quedar atascado en la pantalla de espera.
