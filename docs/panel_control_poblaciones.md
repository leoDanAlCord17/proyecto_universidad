# Panel de control de eventos — Poblaciones y segmentación de usuarios

## Tabla de contenido

1. [Resumen general](#resumen-general)
2. [Las tres poblaciones](#las-tres-poblaciones)
3. [Alcance del evento: general vs dirigido](#alcance-del-evento-general-vs-dirigido)
4. [Cómo se construye la audiencia dirigida](#cómo-se-construye-la-audiencia-dirigida)
5. [Flujo de carga de datos](#flujo-de-carga-de-datos)
6. [asistentes vs listaEsperados](#asistentes-vs-listaesperados)
7. [El modelo AsistenteItem](#el-modelo-asistenteitem)
8. [Contadores y tasas](#contadores-y-tasas)
9. [Sistema de filtros](#sistema-de-filtros)
10. [Actualizaciones en tiempo real](#actualizaciones-en-tiempo-real)
11. [Cierre del evento y ausentes automáticos](#cierre-del-evento-y-ausentes-automáticos)

---

## Resumen general

El panel de control de un evento (`PanelControlPantalla`) es la vista central desde donde un administrador monitorea quién ha llegado, quién falta, y cuántas personas hay en el recinto en tiempo real. Toda la lógica vive en `PanelControlCubit` / `PanelControlRepositorio`. La pantalla es completamente reactiva al estado emitido por el cubit y no contiene ninguna lógica de negocio.

---

## Las tres poblaciones

El sistema distingue tres tipos de personas que pueden aparecer en un evento. Esta clasificación es permanente a lo largo de toda la vida del registro.

### Población A — Usuarios esperados (`eraEsperado = true`)

Son usuarios con cuenta en el sistema que formaban parte de la **audiencia definida** del evento antes de que comenzara. Se identifican porque en el momento de cargar el panel su `usuario_id` aparece en la lista de audiencia del evento.

- Solo existen en eventos de alcance **dirigido**.
- Su registro en la tabla `asistencia` puede haber sido pre-creado con `estatus = 'esperado'` o creado en el momento en que llegan.
- Son la base del cálculo de las tasas de convocatoria y ocupación.

### Población B — Usuarios no esperados (`eraEsperado = false`, `esForaneo = false`)

Son usuarios con cuenta en el sistema que llegaron al evento **sin estar en la audiencia definida**. Pueden ocurrir por dos razones:

- El evento es de alcance **general** (cualquier usuario del sistema puede asistir).
- El evento es **dirigido** pero el usuario llegó de todas formas (caso de asistentes adicionales).

No afectan las tasas de convocatoria ni las de ocupación relativa a la audiencia.

### Población C — Foráneos (`esForaneo = true`)

Son personas **sin cuenta en el sistema** registradas manualmente por un administrador. Su registro en la tabla `asistencia` no tiene `usuario_id`; en su lugar se almacenan campos `visitante_*`:

| Campo en BD | Descripción |
|---|---|
| `visitante_primer_nombre` | Nombre |
| `visitante_primer_apellido` | Apellido |
| `visitante_numero_identificacion` | Cédula o pasaporte |
| `visitante_contacto` | Teléfono u otro contacto |

El campo `esForaneo` en `AsistenteItem` se deriva automáticamente al parsear: si `usuario_id == null` entonces `esForaneo = true`.

---

## Alcance del evento: general vs dirigido

El campo `alcance` de la tabla `eventos` controla si el evento tiene una audiencia pre-definida:

| `alcance` | Descripción | Audiencia en panel |
|---|---|---|
| `'general'` | Cualquier usuario puede asistir | `listaEsperados` vacía, `totalAudiencia = 0` |
| `'dirigido'` | Solo usuarios de grupos definidos | `listaEsperados` contiene la audiencia construida a partir de tags |

En un evento **general**, todos los asistentes del sistema son Población B (no esperados), y las tasas de convocatoria y ocupación no se calculan (`tasaConvocatoria = null`).

En un evento **dirigido**, los miembros de la audiencia que llegaron son Población A, los que no llegaron aparecen como pendientes, y quienes llegan sin estar en la lista son Población B.

---

## Cómo se construye la audiencia dirigida

La audiencia de un evento dirigido se define mediante **grupos de tags**. Un grupo es un conjunto de tags (principal + secundarios) que un usuario debe tener simultáneamente para pertenecer a ese grupo. Un usuario pertenece a la audiencia si satisface **al menos un grupo**.

### Tablas involucradas

```
eventos  ──►  evento_grupos_tags  (grupo_index, tag_id)
                    │
                    ▼
             usuarios_tags  (usuario_id, tag_id, estatus)
                    │
                    ▼
              usuarios  (datos personales)
```

### Algoritmo en `obtenerMiembrosGrupo`

```
1. Obtener todos los (grupo_index, tag_id) del evento.

2. Construir mapa de grupos:
   { 0: [tag-A, tag-B], 1: [tag-C], ... }

3. Consultar usuarios_tags donde tag_id IN (todos los tag ids)
   y estatus = true (solo asignaciones activas).

4. Por cada usuario, acumular el set de tags que tiene.

5. Un usuario pertenece a la audiencia si su set de tags
   contiene TODOS los tags de al menos un grupo del mapa.

6. Construir AsistenteItem sintético con estatus = 'esperado'
   para cada miembro de la audiencia.
```

> **Nota importante:** `obtenerMiembrosGrupo` solo consulta `usuarios_tags` con `estatus = true`. Si a un usuario se le revoca un tag después de que el evento fue programado, dejará de aparecer en la audiencia en futuras cargas del panel.

---

## Flujo de carga de datos

```
PanelControlCubit.cargar(eventoId)
        │
        ├─► repositorio.obtenerEvento(eventoId)
        │         └─► Tabla: eventos
        │
        ├─► repositorio.obtenerAsistentes(eventoId)
        │         └─► Tabla: asistencia JOIN usuarios
        │             (registros reales con datos del usuario)
        │
        ├─► [solo si alcance == 'dirigido']
        │   repositorio.obtenerMiembrosGrupo(eventoId)
        │         └─► evento_grupos_tags + usuarios_tags + usuarios
        │             (lista sintética de audiencia)
        │
        ├─► _marcarEsperados(asistentes, audiencia)
        │         Cruza los registros reales contra la audiencia.
        │         Si el usuario_id de un registro está en la audiencia,
        │         se marca eraEsperado = true en su AsistenteItem.
        │
        ├─► _mergarConAsistencia(audiencia, asistentesConFlag)
        │         Toma la lista de audiencia y reemplaza cada ítem
        │         con su registro real si ya existe en asistencia.
        │         Resultado: listaEsperados (audiencia con estado actual).
        │
        └─► emit(PanelControlCargado(...))
                  + iniciar stream en tiempo real
```

---

## `asistentes` vs `listaEsperados`

Estas dos listas conviven en `PanelControlCargado` y tienen propósitos distintos.

### `asistentes`

**Qué es:** Los registros reales de la tabla `asistencia` del evento, con el flag `eraEsperado` aplicado. Incluye las tres poblaciones (A, B y C).

**Cuándo se usa:** Para todos los contadores globales (`totalPresentes`, `presentesNoEsperados`, `presentesForaneos`, `cantidadAnticipados`) y para los filtros `todos`, `noEsperados`, `registrados`, `abandono`, `foraneos`.

**Limitación:** No incluye a los miembros de la audiencia que todavía no han llegado (estatus `'esperado'` sin registro real), porque esos aún no tienen fila en la tabla `asistencia`. Salvo que se hayan pre-registrado al configurar el evento.

### `listaEsperados`

**Qué es:** La audiencia definida del evento, donde cada ítem ha sido reemplazado por su registro real si existe. En eventos generales esta lista está vacía.

**Cuándo se usa:** Para el filtro `esperados`, el contador `pendientes` y `totalAudiencia`.

**Cómo se construye:** `_mergarConAsistencia` recorre la audiencia e intenta encontrar el registro real de cada usuario en `asistentes`. Si lo encuentra, usa el registro real (con su estatus actual). Si no, mantiene el ítem sintético (`estatus = 'esperado'`).

```
audiencia        asistentesConFlag       listaEsperados
─────────        ─────────────────       ──────────────
usuario-A  ──►  [tiene registro]  ──►   registro real de A (estatus: presente)
usuario-B  ──►  [no tiene]        ──►   ítem sintético de B (estatus: esperado)
usuario-C  ──►  [tiene registro]  ──►   registro real de C (estatus: completado)
```

---

## El modelo AsistenteItem

Cada persona en el panel está representada por un `AsistenteItem`. Sus campos clave:

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | String | UUID del registro en `asistencia` (o del usuario en ítems sintéticos) |
| `usuarioId` | String? | UUID del usuario en el sistema. `null` para foráneos |
| `nombre` | String | Nombre completo (calculado desde los campos del usuario o del visitante) |
| `iniciales` | String | Dos letras mayúsculas para el avatar |
| `detalle` | String? | Número de identificación (usuario del sistema) o contacto (foráneo) |
| `urlFoto` | String? | URL del avatar. Siempre `null` para foráneos |
| `estatus` | String | Estado actual en el evento |
| `esForaneo` | bool | `true` si no tiene cuenta en el sistema |
| `eraEsperado` | bool | `true` si estaba en la audiencia definida |
| `horaEntrada` | String? | Hora local formateada `HH:mm` |
| `horaSalida` | String? | Hora local formateada `HH:mm` |

### Estados posibles (`estatus`)

| Valor | Descripción |
|---|---|
| `'esperado'` | Todavía no ha llegado (audiencia pre-definida) |
| `'presente'` | Marcó entrada, sigue en el recinto |
| `'completado'` | Salió normalmente al finalizar el evento |
| `'salio_anticipado'` | Salió antes de que el evento terminara |
| `'ausente'` | No llegó y el evento cerró con `marcarAusentesAuto = true` |
| `'anulado'` | Registro anulado manualmente |

### Propiedades computadas

```dart
esRegistrado  → estatus == 'presente' || estatus == 'completado'
esAbandono    → estatus == 'salio_anticipado'
etiquetaDetalle → texto descriptivo que combina estatus y hora
```

---

## Contadores y tasas

Todos los contadores viven como getters en `PanelControlCargado` y se recalculan automáticamente cada vez que el estado cambia.

### Contadores absolutos

| Getter | Fórmula |
|---|---|
| `presentesEsperados` | asistentes donde `eraEsperado == true` y estatus activo |
| `presentesNoEsperados` | asistentes donde `!esForaneo && !eraEsperado` y estatus activo |
| `presentesForaneos` | asistentes donde `esForaneo == true` y estatus activo |
| `totalPresentes` | todos los asistentes con estatus activo (las tres poblaciones) |
| `pendientes` | listaEsperados donde `estatus == 'esperado'` |
| `ausentes` | asistentes donde `eraEsperado && estatus == 'ausente'` |
| `cantidadAnticipados` | asistentes donde `estatus == 'salio_anticipado'` |
| `totalAudiencia` | `listaEsperados.length` (0 para eventos generales) |

> **Estatus activo** significa `presente`, `completado` o `salio_anticipado` — es decir, la persona llegó en algún momento, independientemente de si ya salió.

### Tasas (solo eventos dirigidos)

| Getter | Fórmula | Significado |
|---|---|---|
| `tasaConvocatoria` | `presentesEsperados / totalAudiencia` | Qué porcentaje de la audiencia definida llegó |
| `tasaOcupacion` | `totalPresentes / totalAudiencia` | Qué porcentaje del aforo definido fue el total real |

Ambas tasas retornan `null` si el evento es de alcance `general` o si `totalAudiencia == 0`.

### Ejemplo numérico

Evento dirigido con audiencia de 100 personas:

```
Audiencia definida:        100
Llegaron (esperados):       72   → presentesEsperados = 72
Llegaron (no esperados):     5   → presentesNoEsperados = 5
Llegaron (foráneos):         3   → presentesForaneos = 3
─────────────────────────────
Total presentes:            80   → totalPresentes = 80
Pendientes:                 28   → pendientes = 28

tasaConvocatoria = 72/100 = 72%
tasaOcupacion    = 80/100 = 80%
```

---

## Sistema de filtros

El panel tiene una barra de filtros en pills (`_FiltrosTabs`). Cada filtro opera sobre listas diferentes:

| Filtro | Lista fuente | Condición adicional |
|---|---|---|
| `todos` | `asistentes` | ninguna |
| `esperados` | `listaEsperados` | ninguna (incluye los que no han llegado) |
| `noEsperados` | `asistentes` | `!esForaneo && !eraEsperado` |
| `registrados` | `asistentes` | `esRegistrado` (presente o completado) |
| `abandono` | `asistentes` | `esAbandono` (salio_anticipado) |
| `foraneos` | `asistentes` | `esForaneo` |

Los filtros `esperados` y `noEsperados` se ocultan automáticamente en eventos de alcance `general`, ya que no aplican cuando no hay audiencia definida.

---

## Actualizaciones en tiempo real

Una vez que el panel carga correctamente, se suscribe a un stream de Supabase Realtime sobre la tabla `asistencia`:

```
_repositorio.streamCambiosAsistencia(eventoId)
    .skip(1)          ← descarta la primera emisión (ya cargada manualmente)
    .listen((_) → _recargarAsistentes())
```

El stream actúa solo como **disparador**. Cuando detecta cualquier cambio en `asistencia`, llama a `_recargarAsistentes()`, que vuelve a consultar la tabla completa con todos los joins. Esto garantiza que los datos mostrados siempre incluyen los campos relacionados del usuario (nombre, foto, etc.), que el stream en sí no provee.

### Comportamiento ante fallos de recarga

Si `_recargarAsistentes()` falla (error de red, Supabase no disponible), el panel **no muestra ningún error**. El fallo se captura silenciosamente con typed catches que incluyen un comentario explicativo, y el panel continúa mostrando los últimos datos válidos. Esto es intencional: una recarga fallida no debe interrumpir la operación del evento.

---

## Cierre del evento y ausentes automáticos

Cuando el administrador ejecuta `cerrarEvento()`:

1. Se actualiza `eventos.estatus` a `'finalizado'` en Supabase.
2. Si `evento.marcarAusentesAuto == true`, se llama a `marcarAusentesAuto(eventoId)`, que hace un `UPDATE` masivo en `asistencia`:
   - `WHERE evento_id = X AND estatus = 'esperado'`
   - `SET estatus = 'ausente'`
3. El cubit emite `PanelControlEventoCerrado` y la pantalla navega hacia atrás.

> Si `marcarAusentesAuto == false`, los registros con `estatus = 'esperado'` quedan intactos al cerrar — útil si se quieren marcar ausencias de forma manual o si el cierre es provisional.

El diálogo de confirmación (`_DialogoCerrarEvento`) requiere que el administrador escriba el nombre exacto del evento para confirmar. El botón de confirmar solo se habilita cuando `_coincidenNombres == true`, previniendo cierres accidentales.
