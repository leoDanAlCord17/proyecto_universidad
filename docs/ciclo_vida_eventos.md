# Ciclo de vida de eventos — UniAsist

## Tabla de contenido

1. [Resumen general](#resumen-general)
2. [Estados de un evento](#estados-de-un-evento)
3. [Diagrama de transiciones](#diagrama-de-transiciones)
4. [Componente servidor — Supabase](#componente-servidor--supabase)
5. [Componente cliente — Flutter](#componente-cliente--flutter)
6. [Lógica de ausentes automáticos](#lógica-de-ausentes-automáticos)
7. [Zona horaria](#zona-horaria)
8. [Mantenimiento y operaciones](#mantenimiento-y-operaciones)

---

## Resumen general

El sistema de ciclo de vida de eventos en UniAsist gestiona automáticamente el cambio de estatus de los eventos sin intervención manual del administrador. El proceso se divide en dos capas:

| Capa | Tecnología | Responsabilidad |
|------|-----------|-----------------|
| Servidor | PostgreSQL + pg_cron (Supabase) | Transiciones de estatus, marcado de ausentes |
| Cliente | Flutter (Timer + AppLifecycle) | Refresco de pantalla para reflejar cambios |

---

## Estados de un evento

```
borrador  →  programado  →  en_curso  →  finalizado
                  ↘              ↘
                cancelado      cancelado
```

| Estado | Descripción | Quién lo asigna |
|--------|-------------|-----------------|
| `borrador` | Evento creado pero no publicado | Manual (admin al guardar) |
| `programado` | Publicado, esperando su fecha/hora de inicio | Manual (admin al publicar) |
| `en_curso` | El evento está activo en este momento | **Automático** (pg_cron) |
| `finalizado` | El evento terminó | **Automático** (pg_cron) |
| `cancelado` | El evento fue cancelado | Manual (no implementado aún) |

---

## Diagrama de transiciones

```
                     hora_inicio llega
                    ┌─────────────────────────────────┐
                    │                                 ▼
[borrador] ──(publicar)──► [programado] ──────► [en_curso]
                                                     │
                                         hora_fin llega
                                                     │
                                                     ▼
                                            [finalizado]
                                        (+ marcar ausentes
                                          si está activo)
```

**Las transiciones automáticas** ocurren cuando el job de pg_cron ejecuta
`ciclo_eventos()` cada minuto y comprueba si algún evento debe cambiar de estatus.

---

## Componente servidor — Supabase

### Función PostgreSQL: `public.ciclo_eventos()`

Archivo de referencia: ejecutada directamente en Supabase, no existe en el proyecto Flutter.

**¿Qué hace en cada ejecución?**

#### Paso 1 — `programado` → `en_curso`

```
Condición: estatus = 'programado'
           AND (fecha_inicio + hora_inicio) AT TIME ZONE 'America/Caracas' <= NOW()
```

Si la fecha y hora de inicio del evento ya llegaron (en hora Venezuela), el evento
pasa a `en_curso`. Sólo aplica a eventos que tengan ambos campos definidos.

#### Paso 2 — `en_curso` → `finalizado`

```
Condición: estatus = 'en_curso'
           AND (fecha_fin + hora_fin) AT TIME ZONE 'America/Caracas' <= NOW()
```

Si la fecha y hora de fin ya llegaron (en hora Venezuela), el evento pasa a `finalizado`.
Si `marcar_ausentes_auto = true`, se ejecuta adicionalmente el paso 3.

#### Paso 3 — Marcado automático de ausentes *(solo si aplica)*

Se ejecuta inmediatamente después de la transición a `finalizado`, únicamente cuando
`marcar_ausentes_auto = true`. Ver sección [Lógica de ausentes automáticos](#lógica-de-ausentes-automáticos).

---

### Job pg_cron: `ciclo-eventos`

| Campo | Valor |
|-------|-------|
| Nombre | `ciclo-eventos` |
| Frecuencia | Cada minuto (`* * * * *`) |
| Comando | `SELECT public.ciclo_eventos()` |
| Usuario | `postgres` (superusuario de Supabase) |

**El job corre independientemente de si hay usuarios conectados a la app.**
Es el único enfoque confiable para un sistema universitario donde los eventos
deben activarse en horario exacto.

---

## Componente cliente — Flutter

### Archivos involucrados

- `lib/funcionalidades/eventos/eventos_cubit.dart`
- `lib/funcionalidades/eventos/eventos_pantalla.dart`

### Timer de refresco automático (`EventosCubit`)

Al cargar exitosamente los eventos, el cubit inicia un `Timer.periodic` de **60 segundos**
que ejecuta `_refrescarSilencioso()`.

**Comportamiento del refresco silencioso:**
- No muestra el indicador de carga (`CircularProgressIndicator`)
- Actualiza las listas `en_curso` y `proximos` sin interrumpir al usuario
- Respeta los filtros activos (texto de búsqueda y rango de fechas)
- Si falla (sin internet, error de red): **ignora silenciosamente** — no muestra error
- El timer se cancela automáticamente cuando el usuario sale de la pantalla

**Ciclo de vida del timer:**

```
cargar() exitoso
     │
     └── Timer.periodic(60s) ──► _refrescarSilencioso()
                                        │
                          (cada 60 seg mientras la pantalla está abierta)

Pantalla destruida (dispose) ──► timer.cancel()
```

### Observer de ciclo de vida de la app (`EventosPantalla`)

`_EventosPantallaState` implementa `WidgetsBindingObserver` para detectar cuando
el usuario vuelve a la app desde segundo plano.

```
App en segundo plano
     │
     └── Usuario regresa (AppLifecycleState.resumed)
               │
               └── cargar() ──► refresco completo + reinicio del timer
```

Esto garantiza que si el usuario estuvo fuera de la app varios minutos (más de un
ciclo del timer), al regresar verá los estatus actualizados inmediatamente.

---

## Lógica de ausentes automáticos

Sólo se ejecuta cuando el evento tiene `marcar_ausentes_auto = true` y
acaba de transicionar a `finalizado`.

### Para cada usuario que debería haber asistido:

| Caso | Acción |
|------|--------|
| Tiene registro con `estatus = 'esperado'` | Se actualiza a `'ausente'` |
| No tiene ningún registro en `asistencia` | Se inserta un nuevo registro con `estatus = 'ausente'` |
| Tiene `presente`, `completado`, `salio_anticipado` | **No se toca** — ya asistió |
| Es visitante foráneo (sin `usuario_id`) | **No aplica** — solo usuarios registrados |

### ¿A quiénes se les marca?

**Evento `alcance = 'general'`:**
Todos los usuarios con `estatus = true` en la tabla `usuarios`.

**Evento `alcance = 'dirigido'`:**
Solo los usuarios que coinciden con al menos un grupo de audiencia del evento.
La regla de coincidencia es:

```
Para cada grupo (definido por grupo_index en evento_grupos_tags):
  El usuario debe tener:
    ✓ El tag PRINCIPAL del grupo (tipo = 'principal')
    ✓ TODOS los tags SECUNDARIOS del grupo (tipo = 'secundario')

El usuario aparece si coincide con AL MENOS UN grupo (lógica OR entre grupos).
```

**Ejemplo:**

```
Grupo 0: ALUMNOS + GENÉTICA + MATEMÁTICAS III
Grupo 1: PROFESORES

Usuario A (ALUMNOS + GENÉTICA + MATEMÁTICAS III) → coincide con Grupo 0 ✓
Usuario B (ALUMNOS + GENÉTICA)                   → NO coincide (falta MATEMÁTICAS III) ✗
Usuario C (PROFESORES)                           → coincide con Grupo 1 ✓
```

---

## Zona horaria

**Venezuela usa UTC-4 de forma permanente** (sin cambio de horario, zona IANA: `America/Caracas`).

Los campos `hora_inicio` y `hora_fin` en la tabla `eventos` son de tipo
`time without time zone`, lo que significa que no guardan información de zona horaria.
Cuando el administrador ingresa "08:00", la app lo guarda como el string `"08:00"`.

La función `ciclo_eventos()` usa `AT TIME ZONE 'America/Caracas'` para interpretar
correctamente esos valores:

```sql
-- El servidor de Supabase corre en UTC
-- Si un admin ingresa hora_inicio = '08:00' (Venezuela)
-- La función lo trata como 08:00 VET = 12:00 UTC

(fecha_inicio + hora_inicio) AT TIME ZONE 'America/Caracas' <= NOW()
-- Equivale a: '2026-04-26 08:00 VET' <= NOW() UTC ✓
```

**Sin esta corrección**, el evento activaría 4 horas antes de lo esperado.

---

## Mantenimiento y operaciones

### Verificar que el job está activo

```sql
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'ciclo-eventos';
```

### Ver el historial de ejecuciones del job

```sql
SELECT runid, jobid, status, start_time, end_time, return_message
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'ciclo-eventos')
ORDER BY start_time DESC
LIMIT 20;
```

### Probar la función manualmente

```sql
-- Ejecutar una vez manualmente (útil para pruebas)
SELECT public.ciclo_eventos();
```

### Pausar el job temporalmente

```sql
SELECT cron.unschedule('ciclo-eventos');
```

### Reactivar el job

```sql
SELECT cron.schedule(
  'ciclo-eventos',
  '* * * * *',
  'SELECT public.ciclo_eventos()'
);
```

### Verificar eventos que deberían haber cambiado de estatus

```sql
-- Ver programados cuya hora de inicio ya pasó (no procesados aún o con problema)
SELECT id, titulo, fecha_inicio, hora_inicio, estatus
FROM public.eventos
WHERE estatus = 'programado'
  AND (fecha_inicio + hora_inicio) AT TIME ZONE 'America/Caracas' <= NOW();

-- Ver en_curso cuya hora de fin ya pasó
SELECT id, titulo, fecha_fin, hora_fin, estatus
FROM public.eventos
WHERE estatus = 'en_curso'
  AND (fecha_fin + hora_fin) AT TIME ZONE 'America/Caracas' <= NOW();
```

Si estas consultas retornan filas, significa que el job no está corriendo o hubo
un error. Revisar `cron.job_run_details`.

---

*Documentación generada para UniAsist — ciclo de vida de eventos.*
