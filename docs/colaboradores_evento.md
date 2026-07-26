# Colaboradores de evento — Activiti

## Tabla de contenido

1. [Resumen general](#resumen-general)
2. [Qué es un colaborador](#qué-es-un-colaborador)
3. [Diferencias entre roles](#diferencias-entre-roles)
4. [Modelo de datos](#modelo-de-datos)
5. [Flujo de asignación](#flujo-de-asignación)
6. [Flujo de detección en inicio](#flujo-de-detección-en-inicio)
7. [Experiencia del colaborador](#experiencia-del-colaborador)
8. [Experiencia del administrador](#experiencia-del-administrador)
9. [Arquitectura del módulo](#arquitectura-del-módulo)
10. [Estados del cubit](#estados-del-cubit)
11. [Consideraciones de seguridad](#consideraciones-de-seguridad)

---

## Resumen general

El sistema de colaboradores permite a un administrador asignar usuarios de la app como ayudantes en un evento específico. Un colaborador puede registrar asistencia, marcar entradas, registrar foráneos y escanear QR de usuarios durante ese evento, pero **únicamente en el evento donde fue asignado**. No obtiene acceso a ninguna otra pantalla ni evento del sistema.

La asignación es **por evento** y se gestiona desde el panel de control → menú de configuración → Colaboradores. El colaborador no recibe ningún permiso global en el sistema; su identificación es estructural, a través de la tabla `eventos_usuarios_roles`.

---

## Qué es un colaborador

Un colaborador es cualquier usuario con cuenta en Activiti al que un administrador le ha otorgado acceso operativo a un evento puntual. Su participación tiene tres características principales:

- **Acotada:** solo tiene acceso al evento donde fue asignado, no a otros eventos ni al panel de control completo.
- **Reversible:** el administrador puede quitarle el acceso en cualquier momento desde la misma pantalla de gestión.
- **No intrusiva:** no se altera el perfil global del usuario. La asignación vive exclusivamente en `eventos_usuarios_roles` y puede reactivarse si el mismo usuario es vuelto a asignar en el futuro.

---

## Diferencias entre roles

| Característica | Administrador (`eventos.panel_control`) | Colaborador (asignado en `eventos_usuarios_roles`) |
|---|---|---|
| Ve estadísticas del evento | ✅ | ❌ |
| Ve barra de progreso / presentes en inicio | ✅ | ❌ |
| Accede al panel de control completo | ✅ | ❌ |
| Puede registrar asistencia (buscar, escanear, foráneo) | ✅ | ✅ |
| Ve la tarjeta del evento en la pantalla de inicio | ✅ | ✅ |
| Puede asignar o quitar colaboradores | ✅ | ❌ |
| Puede cerrar el evento | ✅ | ❌ |
| Acceso acotado a un evento específico | ❌ (accede a todos) | ✅ (solo el asignado) |

---

## Modelo de datos

### Tabla: `eventos_usuarios_roles`

Es la tabla central de la funcionalidad. Cada fila representa la asignación de un usuario a un evento bajo un rol de sistema.

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | `uuid` | Clave primaria |
| `evento_id` | `uuid` | Referencia al evento |
| `usuario_id` | `uuid` | Referencia al usuario asignado |
| `rol_id` | `uuid` | Referencia al rol `Colaborador` en la tabla `roles` |
| `asignado_por` | `uuid` | ID del administrador que realizó la asignación |
| `estatus` | `boolean` | `true` = activo, `false` = removido (soft-delete) |

**Restricción única:** `UNIQUE(evento_id, usuario_id, rol_id)` — un usuario no puede estar asignado dos veces al mismo rol en el mismo evento. Esta restricción permite el patrón de reactivación mediante upsert.

### Rol de sistema: `Colaborador`

```sql
INSERT INTO roles (nombre, descripcion, es_sistema, estatus)
VALUES ('Colaborador', '...', true, true);
```

El campo `es_sistema = true` indica que este rol no puede ser eliminado ni modificado por los administradores desde la interfaz. Está protegido por diseño.

### Permiso: `eventos.colaborar`

```sql
INSERT INTO permisos (nombre, descripcion, estatus)
VALUES ('eventos.colaborar', '...', true);
```

El permiso existe en la base de datos y está asociado al rol `Colaborador` en `roles_permisos`. Actualmente la app **no valida este permiso en la UI** — la identificación del colaborador se realiza directamente consultando `eventos_usuarios_roles`. El permiso queda disponible para ser usado en políticas de Row Level Security (RLS) de Supabase.

### Diagrama de relaciones

```
eventos
  │
  └──► eventos_usuarios_roles ◄──── usuarios
              │
              └──► roles (nombre = 'Colaborador')
                      │
                      └──► roles_permisos
                                │
                                └──► permisos (nombre = 'eventos.colaborar')
```

---

## Flujo de asignación

### Asignar un colaborador

```
Administrador abre panel de control
        │
        ▼
Presiona botón de configuración (⚙) en el encabezado
        │
        ▼
Selecciona "Colaboradores" en el menú de opciones
        │
        ▼
Abre ColaboradoresEventoPantalla (eventoId)
        │
        ▼
ColaboradoresEventoCubit.iniciar(eventoId, adminId)
        │
        ├─► ColaboradoresEventoRepositorio.obtenerColaboradores(eventoId)
        │         1. Busca el rol_id de 'Colaborador' en tabla roles
        │         2. Consulta eventos_usuarios_roles filtrando por
        │            evento_id + rol_id + estatus = true
        │         3. Obtiene datos del usuario desde tabla usuarios
        │         4. Combina asignacion_id + datos del usuario
        │         └─► Retorna List<ColaboradorItem>
        │
        ▼
Administrador escribe nombre en la barra de búsqueda (≥ 2 caracteres)
        │
        ▼
ColaboradoresEventoCubit.buscar(query)
        │
        ├─► ColaboradoresEventoRepositorio.buscarUsuarios(query)
        │         └─► Consulta tabla usuarios con ilike en nombre/apellido
        │
        ├─► Filtra en cliente los usuarios ya asignados (por usuarioId)
        └─► Emite estado con resultadosBusqueda actualizados
        │
        ▼
Administrador presiona "Agregar" en un resultado
        │
        ▼
ColaboradoresEventoCubit.asignar(UsuarioParaAsignar)
        │
        ├─► ColaboradoresEventoRepositorio.asignarColaborador(eventoId, usuarioId, asignadoPorId)
        │         1. Obtiene rol_id de 'Colaborador'
        │         2. UPSERT en eventos_usuarios_roles con onConflict
        │            (si existía un registro inactivo, lo reactiva)
        │
        ├─► Recarga la lista de colaboradores desde Supabase
        └─► Filtra el usuario recién asignado de los resultados de búsqueda
```

### Quitar un colaborador

```
Administrador presiona "Quitar" en un colaborador existente
        │
        ▼
ColaboradoresEventoCubit.quitar(ColaboradorItem)
        │
        ├─► ColaboradoresEventoRepositorio.quitarColaborador(asignacionId)
        │         └─► UPDATE eventos_usuarios_roles SET estatus = false WHERE id = asignacionId
        │             (soft-delete — el registro permanece para auditoría)
        │
        └─► Recarga la lista de colaboradores desde Supabase
```

> **Reactivación:** si el mismo usuario es vuelto a asignar después de haber sido quitado, el UPSERT con `onConflict: 'evento_id,usuario_id,rol_id'` actualiza `estatus = true` en el registro existente en lugar de crear uno duplicado.

---

## Flujo de detección en inicio

Cuando la app carga la pantalla de inicio, el cubit de eventos en curso necesita saber cuáles eventos corresponden al usuario como colaborador para mostrarlos correctamente.

```
EventosEnCursoCubit.cargar(usuarioId)
        │
        ▼
EventosEnCursoRepositorio.obtenerEventosEnCurso(usuarioId)
        │
        ├─► Paso 1: Consulta todos los eventos con estatus = 'en_curso'
        │
        ├─► Paso 2: Consulta eventos_usuarios_roles filtrando por
        │           usuario_id = usuarioId AND estatus = true
        │           AND evento_id IN (ids del paso 1)
        │
        ├─► Paso 3: Construye Set<String> con los IDs donde el usuario
        │           es colaborador activo
        │
        └─► Paso 4: Por cada evento, aplica copyWith(esColaborador: true)
                    si su id está en el set
```

El flag `esColaborador` viaja en el modelo `EventoEnCurso` y es consumido por `TarjetaEventoEnCurso` para decidir qué mostrar. **Ningún widget consulta Supabase directamente** — toda la detección sucede en el repositorio.

---

## Experiencia del colaborador

### Pantalla de inicio

Un colaborador ve la tarjeta del evento en curso con los botones de acción operativos, pero **sin** los elementos exclusivos del panel de control:

| Elemento | ¿Visible para colaborador? |
|---|---|
| Chip "En curso" | ✅ |
| Rango horario | ✅ |
| Botón "Escanear QR" (si `permite_qr_usuario`) | ✅ |
| Botón "QR Evento" (si `permite_qr_evento`) | ✅ |
| Botón "Usuario foráneo" (si `permite_foraneos`) | ✅ |
| Botón "Buscar usuario" | ✅ |
| Botón "Detalles" (panel de control) | ❌ |
| Contador X/Y presentes | ❌ |
| Barra de progreso | ❌ |

Si el usuario **no tiene** `eventos.panel_control` **ni** es colaborador del evento, la tarjeta muestra únicamente etiquetas de modo de registro (chips de solo lectura: "Manual", "Auto-Registro", "Qr-Registro") sin ningún botón de acción.

### Lógica en `TarjetaEventoEnCurso`

```
tienePanel  = usuario tiene permiso eventos.panel_control
esColaborador = evento.esColaborador (flag del repositorio)

Si !tienePanel && !esColaborador → mostrar chips de modo (solo lectura)
Si tienePanel || esColaborador  → mostrar botones de acción
Si tienePanel                   → mostrar además botón "Detalles"
Si tienePanel                   → mostrar contador de presentes y barra de progreso
```

---

## Experiencia del administrador

### Pantalla de colaboradores

Accesible desde: Panel de control → ⚙ Configuración → Colaboradores.

La pantalla tiene dos secciones:

**Colaboradores actuales**
- Lista todos los colaboradores activos del evento.
- Cada ítem muestra avatar, nombre y número de identificación.
- Botón "Quitar" con indicador de carga por ítem (no bloquea la lista completa).
- Si no hay colaboradores, muestra mensaje informativo.

**Agregar colaborador** (visible cuando la búsqueda tiene ≥ 2 caracteres)
- Resultados filtrados: excluye usuarios que ya son colaboradores del evento.
- Botón "Agregar" con indicador de carga por ítem.
- Búsqueda por nombre o apellido con debounce de 350 ms para no saturar Supabase.
- Si no hay resultados, muestra mensaje informativo.

Ambas secciones son visibles simultáneamente — el administrador puede comparar la lista actual con los resultados mientras busca.

---

## Arquitectura del módulo

El módulo vive en `lib/funcionalidades/colaboradores_evento/` y sigue la arquitectura estándar del proyecto.

### Archivos

| Archivo | Clase principal | Responsabilidad |
|---|---|---|
| `colaborador_item.dart` | `ColaboradorItem`, `UsuarioParaAsignar` | Modelos de datos del módulo |
| `colaboradores_evento_estado.dart` | `ColaboradoresEventoEstado` (sealed) | Definición de todos los estados posibles |
| `colaboradores_evento_cubit.dart` | `ColaboradoresEventoCubit` | Lógica de negocio y orquestación |
| `colaboradores_evento_repositorio.dart` | `ColaboradoresEventoRepositorio` | Único punto de contacto con Supabase |
| `colaboradores_evento_pantalla.dart` | `ColaboradoresEventoPantalla` | UI exclusivamente |

### Modelos

**`ColaboradorItem`** — representa un colaborador ya asignado:

| Campo | Tipo | Descripción |
|---|---|---|
| `asignacionId` | `String` | ID de la fila en `eventos_usuarios_roles` (para quitar) |
| `usuarioId` | `String` | ID del usuario en el sistema |
| `nombre` | `String` | Nombre completo calculado |
| `iniciales` | `String` | Dos letras para el avatar |
| `urlFoto` | `String?` | URL del avatar si existe |
| `numeroIdentificacion` | `String?` | Cédula del usuario |

**`UsuarioParaAsignar`** — representa un usuario encontrado en la búsqueda, aún no asignado:

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | `String` | ID del usuario (para asignar) |
| `nombre` | `String` | Nombre completo calculado |
| `iniciales` | `String` | Dos letras para el avatar |
| `urlFoto` | `String?` | URL del avatar si existe |
| `numeroIdentificacion` | `String?` | Cédula del usuario |

La distinción entre ambos modelos es intencional: `ColaboradorItem` tiene `asignacionId` (necesario para el soft-delete), mientras que `UsuarioParaAsignar` tiene solo `id` del usuario (necesario para el upsert). Mezclarlos en un solo modelo requeriría campos opcionales que degradarían la claridad del código.

### Métodos del cubit

| Método | Descripción |
|---|---|
| `iniciar(eventoId, adminId)` | Carga la lista inicial de colaboradores y establece el contexto |
| `buscar(query)` | Busca usuarios con debounce; filtra los ya asignados en cliente |
| `asignar(usuario)` | Llama al repositorio, recarga la lista y actualiza los resultados de búsqueda |
| `quitar(colaborador)` | Soft-delete por `asignacionId` y recarga la lista |

### Métodos del repositorio

| Método | Supabase involucrado |
|---|---|
| `obtenerColaboradores(eventoId)` | `roles` + `eventos_usuarios_roles` + `usuarios` (3 queries) |
| `buscarUsuarios(query)` | `usuarios` con `ilike` en nombre y apellido |
| `asignarColaborador(...)` | `roles` + upsert en `eventos_usuarios_roles` (2 queries) |
| `quitarColaborador(asignacionId)` | update en `eventos_usuarios_roles` (1 query) |

> **Nota:** todas las operaciones que necesitan el `rol_id` del Colaborador realizan una query previa a la tabla `roles`. No se asume ningún UUID en el código — siempre se busca por `nombre = 'Colaborador'` usando la constante `RolesSistema.colaborador`.

---

## Estados del cubit

```
ColaboradoresEventoInicial
        │
        │ iniciar()
        ▼
ColaboradoresEventoCargando
        │
        ├─ éxito ──► ColaboradoresEventoCargado
        │                    │
        │                    ├─ buscar() ────► ColaboradoresEventoCargado (actualizado)
        │                    │
        │                    ├─ asignar() ───► ColaboradoresEventoCargado (idOperando = usuario.id)
        │                    │                         │
        │                    │                         ├─ éxito ──► ColaboradoresEventoCargado (recargado)
        │                    │                         └─ error ──► ColaboradoresEventoOperacionFallida
        │                    │
        │                    └─ quitar() ────► ColaboradoresEventoCargado (idOperando = asignacionId)
        │                                              │
        │                                              ├─ éxito ──► ColaboradoresEventoCargado (recargado)
        │                                              └─ error ──► ColaboradoresEventoOperacionFallida
        │
        └─ error ──► ColaboradoresEventoError
```

### `ColaboradoresEventoCargado`

| Campo | Tipo | Descripción |
|---|---|---|
| `colaboradores` | `List<ColaboradorItem>` | Lista actual de colaboradores activos |
| `resultadosBusqueda` | `List<UsuarioParaAsignar>` | Resultados filtrados de la búsqueda activa |
| `busqueda` | `String` | Texto actual de la barra de búsqueda |
| `idOperando` | `String?` | ID con operación en curso (bloquea su botón); `null` si ninguno |

### `ColaboradoresEventoOperacionFallida`

Mantiene el estado `anterior` (`ColaboradoresEventoCargado`) para que la pantalla no pierda el contenido visible. El mensaje de error se muestra en un `SnackBar` y el usuario puede volver a intentar la operación.

---

## Consideraciones de seguridad

### Por qué no se usa el permiso `eventos.colaborar` en la UI

La identificación del colaborador se basa en la consulta directa a `eventos_usuarios_roles` y no en la verificación del permiso `eventos.colaborar` en el modelo de usuario. Esto es intencional por dos razones:

1. **El acceso es por evento, no global.** Un permiso del sistema aplica a toda la app; la asignación en `eventos_usuarios_roles` aplica solo al evento indicado. Verificar el permiso en la UI no daría información sobre en qué evento(s) está asignado el usuario.

2. **El permiso está pensado para RLS.** `eventos.colaborar` existe para ser usado en las políticas de Row Level Security de Supabase, donde sí puede inspeccionarse el contexto del evento en la query que se ejecuta.

### Soft-delete y auditoría

Las asignaciones nunca se eliminan físicamente. Al quitar un colaborador se establece `estatus = false`, preservando quién fue asignado, cuándo, y por quién (`asignado_por`). Si el mismo usuario es reasignado, el upsert actualiza el registro existente manteniendo el historial en una sola fila.

### Filtro en cliente vs. en base de datos

La exclusión de usuarios ya asignados de los resultados de búsqueda se realiza en el cliente (cubit), no con un `NOT IN` en Supabase. Esto es correcto dado que:
- La lista de colaboradores activos ya fue cargada en memoria.
- El límite de resultados de búsqueda es 30 registros, por lo que el filtro es O(n) trivial.
- Evita una query adicional o una subquery compleja en Supabase.

### Validación de longitud de búsqueda

La búsqueda requiere mínimo 2 caracteres antes de consultar Supabase, y se trunca a 100 caracteres en el repositorio antes de interpolar en el filtro `ilike`. Esto previene consultas abusivas o inyección de patrones excesivamente largos.
