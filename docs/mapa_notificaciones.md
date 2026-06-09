# Mapa de notificaciones — UniAsist

Referencia de todos los puntos del código donde se envían notificaciones.
Cada notificación usa la Edge Function `enviar-notificacion` que guarda en la tabla
`notificaciones` (centro in-app) y envía FCM push al dispositivo del usuario.

---

## N1 — Cuenta aprobada

**Cuándo**: un administrador aprueba la solicitud de registro de un usuario.

**Quién recibe**: el usuario cuya cuenta fue aprobada.

**Archivo**: `lib/funcionalidades/revision_usuarios/revision_usuarios_cubit.dart`

**Método**: `aprobarUsuario(usuarioId)`

**Mensaje**:
- Título: `Cuenta aprobada`
- Cuerpo: `Tu cuenta fue aprobada. Ya puedes acceder a UniAsist.`
- Tipo: `aprobacion`

---

## N2 — Cuenta rechazada

**Cuándo**: un administrador rechaza la solicitud de registro.

**Quién recibe**: el usuario rechazado.

**Archivo**: `lib/funcionalidades/revision_usuarios/revision_usuarios_cubit.dart`

**Método**: `rechazarUsuario(usuarioId)`

**Mensaje**:
- Título: `Solicitud rechazada`
- Cuerpo: `Tu solicitud de cuenta fue rechazada.`
- Tipo: `aprobacion`

---

## N3 — Cuenta suspendida

**Cuándo**: un administrador suspende la cuenta de un usuario activo.

**Quién recibe**: el usuario suspendido.

**Archivo**: `lib/funcionalidades/revision_usuarios/revision_usuarios_cubit.dart`

**Método**: `suspenderUsuario(usuarioId)`

**Mensaje**:
- Título: `Cuenta suspendida`
- Cuerpo: `Tu cuenta ha sido suspendida. Contacta a un administrador.`
- Tipo: `aprobacion`

---

## N4 — Asignado como colaborador

**Cuándo**: un administrador asigna a un usuario como colaborador de un evento.

**Quién recibe**: el usuario asignado.

**Archivo**: `lib/funcionalidades/colaboradores_evento/colaboradores_evento_cubit.dart`

**Método**: `asignarColaborador(usuarioId, eventoId)`

**Mensaje**:
- Título: `Nuevo rol en evento`
- Cuerpo: `Fuiste asignado como colaborador en el evento "[título]".`
- Tipo: `evento`
- Entidad: el evento (`entidad_tipo: 'evento'`)

---

## N5 — Removido como colaborador

**Cuándo**: un administrador quita a un colaborador de un evento.

**Quién recibe**: el colaborador removido.

**Archivo**: `lib/funcionalidades/colaboradores_evento/colaboradores_evento_cubit.dart`

**Método**: `removerColaborador(usuarioId, eventoId)`

**Mensaje**:
- Título: `Rol removido`
- Cuerpo: `Fuiste removido como colaborador del evento "[título]".`
- Tipo: `evento`
- Entidad: el evento

---

## N6 — Rol asignado

**Cuándo**: un administrador asigna un rol del sistema a un usuario.

**Quién recibe**: el usuario al que se le asignó el rol.

**Archivo**: `lib/funcionalidades/gestionar_roles/gestionar_roles_cubit.dart`

**Método**: `asignarRol(usuarioId, rolId)`

**Mensaje**:
- Título: `Rol asignado`
- Cuerpo: `Se te asignó el rol "[nombre del rol]" en el sistema.`
- Tipo: `aprobacion`

---

## N7 — Rol removido

**Cuándo**: un administrador quita un rol del sistema a un usuario.

**Quién recibe**: el usuario al que se le quitó el rol.

**Archivo**: `lib/funcionalidades/gestionar_roles/gestionar_roles_cubit.dart`

**Método**: `removerRol(usuarioId, rolId)`

**Mensaje**:
- Título: `Rol removido`
- Cuerpo: `Se te removió el rol "[nombre del rol]" en el sistema.`
- Tipo: `aprobacion`

---

## N8 — Evento publicado

**Cuándo**: un administrador publica un evento (cambia estatus de `borrador` a `programado`).

**Quién recibe**: usuarios cuya combinación de tags coincide con al menos un grupo
de audiencia del evento. Solo aplica para eventos de alcance `dirigido`; los eventos
`general` no envían notificación masiva.

**Archivo**: `lib/funcionalidades/crear_evento/crear_evento_cubit.dart`

**Método**: `_guardar(estatus: EstatusEvento.programado)` → llamado desde `publicarEvento()`

**Lógica de audiencia**: `CrearEventoRepositorio.obtenerUsuariosIdsDirigidos(eventoId)`
consulta `evento_grupos_tags` y `usuarios_tags` para encontrar usuarios con los
tags del evento.

**Mensaje**:
- Título: `Nuevo evento: [título]`
- Cuerpo: `Se publicó un nuevo evento al que puedes asistir.`
- Tipo: `evento`
- Entidad: el evento

---

## N9 — Evento cancelado

**Estado**: no implementado. No existe funcionalidad de cancelación de eventos en el código actual.

---

## N10 — Evento iniciado

**Estado**: no implementado. No existe funcionalidad para cambiar un evento a estatus `en_curso`.

---

## N11 — Evento cerrado

**Cuándo**: el administrador o colaborador cierra el evento desde el panel de control.

**Quién recibe**: todos los usuarios con un rol asignado en el evento
(tabla `eventos_usuarios_roles`).

**Archivo**: `lib/funcionalidades/panel_control_evento/panel_control_cubit.dart`

**Método**: `cerrarEvento()`

**Lógica de audiencia**: `PanelControlRepositorio.obtenerColaboradoresIds(eventoId)`
consulta `eventos_usuarios_roles` y deduplica por usuario.

**Mensaje**:
- Título: `Evento cerrado`
- Cuerpo: `El evento "[título]" fue cerrado.`
- Tipo: `evento`
- Entidad: el evento

---

## N12 — Entrada registrada por QR

**Cuándo**: el escáner de QR registra exitosamente la entrada de un asistente.

**Quién recibe**: el usuario cuyo QR fue escaneado.

**Archivo**: `lib/funcionalidades/escanear_qr/escanear_qr_cubit.dart`

**Método**: `procesarQr(rawValue)` cuando `registrado == true`

**Nota**: `rawValue` es el `usuario_id` codificado en el QR del usuario.
Solo se envía si es la primera vez que se registra (no en re-escaneos).

**Mensaje**:
- Título: `Asistencia registrada`
- Cuerpo: `Tu entrada a "[título del evento]" fue registrada.`
- Tipo: `asistencia`
- Entidad: el evento

---

## N13 — Marcado como ausente automáticamente

**Cuándo**: el evento se cierra con la opción `marcar_ausentes_auto` activada.
Los usuarios con estatus `esperado` que no registraron entrada quedan como `ausente`.

**Quién recibe**: los usuarios que tenían estatus `esperado` en la tabla `asistencia`
justo antes de que se ejecutara el marcado automático.

**Archivo**: `lib/funcionalidades/panel_control_evento/panel_control_cubit.dart`

**Método**: `cerrarEvento()`, después de `marcarAusentesAuto()`

**Lógica**: `PanelControlRepositorio.obtenerEsperadosIds(eventoId)` se consulta
**antes** de `marcarAusentesAuto()` para capturar los IDs mientras aún tienen
estatus `esperado`.

**Mensaje**:
- Título: `Ausencia registrada`
- Cuerpo: `Fuiste marcado como ausente en "[título del evento]".`
- Tipo: `asistencia`
- Entidad: el evento

---

## Resumen rápido

| # | Disparador | Quién envía | Quién recibe |
|---|---|---|---|
| N1 | Aprobación de cuenta | Admin | Usuario aprobado |
| N2 | Rechazo de cuenta | Admin | Usuario rechazado |
| N3 | Suspensión de cuenta | Admin | Usuario suspendido |
| N4 | Asignación de colaborador | Admin | Colaborador asignado |
| N5 | Remoción de colaborador | Admin | Colaborador removido |
| N6 | Asignación de rol | Admin | Usuario con nuevo rol |
| N7 | Remoción de rol | Admin | Usuario sin rol |
| N8 | Publicación de evento | Admin | Audiencia dirigida del evento |
| N9 | Cancelación de evento | — | No implementado |
| N10 | Inicio de evento | — | No implementado |
| N11 | Cierre de evento | Admin/Colaborador | Colaboradores del evento |
| N12 | Escaneo de QR exitoso | Escáner | Usuario escaneado |
| N13 | Marcado ausente automático | Sistema (al cerrar) | Usuarios con estatus esperado |

---

## Cómo se envía cada notificación

Todos los puntos anteriores llaman a la misma Edge Function de Supabase:

```dart
await Supabase.instance.client.functions.invoke(
  'enviar-notificacion',
  body: {
    'usuario_ids': [...],   // lista de IDs destino
    'titulo': '...',
    'cuerpo': '...',
    'tipo': 'evento' | 'asistencia' | 'aprobacion' | 'general',
    'entidad_id': '...',    // opcional — UUID del objeto relacionado
    'entidad_tipo': '...',  // opcional — 'evento', etc.
  },
);
```

La Edge Function hace dos cosas en orden:
1. Inserta filas en `notificaciones` (una por usuario) → aparece en el centro in-app.
2. Consulta `tokens_dispositivo` y envía FCM push a cada dispositivo registrado.

Si el envío FCM falla por token inválido (`UNREGISTERED` / `INVALID_ARGUMENT`),
el token se elimina automáticamente de `tokens_dispositivo`.

Ver `docs/notificaciones_push.md` para la arquitectura completa del sistema.
