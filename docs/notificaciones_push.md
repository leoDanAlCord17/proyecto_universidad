# Sistema de notificaciones — UniAsist

## Tabla de contenido

1. [Resumen general](#resumen-general)
2. [Arquitectura](#arquitectura)
3. [Tablas de base de datos](#tablas-de-base-de-datos)
4. [Flujo de registro de dispositivo](#flujo-de-registro-de-dispositivo)
5. [Flujo de envío de notificación](#flujo-de-envío-de-notificación)
6. [Centro de notificaciones in-app](#centro-de-notificaciones-in-app)
7. [Service Worker de Firebase](#service-worker-de-firebase)
8. [Comportamiento en múltiples dispositivos](#comportamiento-en-múltiples-dispositivos)
9. [Limpieza de tokens muertos](#limpieza-de-tokens-muertos)
10. [Banner de activación](#banner-de-activación)
11. [Seguridad y RLS](#seguridad-y-rls)
12. [Puntos de disparo de notificaciones](#puntos-de-disparo-de-notificaciones)
13. [Cómo probar el sistema](#cómo-probar-el-sistema)
14. [Variables y secretos requeridos](#variables-y-secretos-requeridos)

---

## Resumen general

UniAsist tiene un sistema de notificaciones que opera en dos canales simultáneos:

| Canal | Descripción | Cuándo funciona |
|---|---|---|
| **Push (FCM)** | Notificación que aparece en el sistema operativo del dispositivo | Siempre que el usuario haya dado permiso al navegador |
| **In-app** | Notificación guardada en la base de datos, visible en la pantalla de notificaciones de la app | Siempre, con o sin permiso de push |

Ambos canales se activan con una sola llamada a la Edge Function `enviar-notificacion`. El sistema garantiza que el usuario siempre reciba la información: si no tiene push activado, la verá cuando abra la app.

---

## Arquitectura

```
Cubit / lógica de negocio
        │
        │ llama
        ▼
Supabase Edge Function
"enviar-notificacion"
        │
        ├──► INSERT en tabla "notificaciones"   ──► Centro in-app (Realtime)
        │
        └──► SELECT tokens_dispositivo
                    │
                    ▼
             Firebase FCM HTTP v1
                    │
                    ▼
          Navegador / dispositivo del usuario
                    │
                    ├── App en primer plano  ──► onMessage (Flutter)
                    └── App en segundo plano ──► Service Worker
```

### Componentes involucrados

| Componente | Tecnología | Archivo principal |
|---|---|---|
| Registro de token | Flutter + Firebase Messaging | `lib/compartido/notificaciones_push_servicio.dart` |
| Envío de notificaciones | Supabase Edge Function (Deno) | `supabase/functions/enviar-notificacion/index.ts` |
| Autenticación con Google | JWT RS256 + OAuth2 | Dentro de la Edge Function |
| Centro de notificaciones | Flutter + Supabase Realtime | `lib/funcionalidades/notificaciones/` |
| Notificaciones en segundo plano | Service Worker | `web/firebase-messaging-sw.js` |

---

## Tablas de base de datos

### `tokens_dispositivo`
Almacena el token FCM de cada dispositivo donde el usuario aceptó las notificaciones.

```sql
CREATE TABLE public.tokens_dispositivo (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id   uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  token        text NOT NULL UNIQUE,   -- identificador único del dispositivo/navegador
  plataforma   text NOT NULL DEFAULT 'web' CHECK (plataforma IN ('web','android','ios')),
  creado_en    timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now()
);
```

**Puntos clave:**
- `UNIQUE(token)`: un token identifica un dispositivo, no un usuario. Un usuario puede tener múltiples tokens (PC, teléfono, tablet).
- Se actualiza con `upsert` cada vez que el usuario abre la app, manteniendo `actualizado_en` fresco.
- Cuando FCM indica que un token es inválido, se elimina automáticamente.

### `notificaciones`
Almacena cada notificación enviada para que el usuario pueda verla en el centro in-app.

```sql
CREATE TABLE public.notificaciones (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id   uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  titulo       text NOT NULL,
  cuerpo       text NOT NULL,
  tipo         text NOT NULL DEFAULT 'general',  -- 'general','evento','asistencia','aprobacion'
  leida        boolean NOT NULL DEFAULT false,
  entidad_id   uuid,       -- ID de la entidad relacionada (ej: ID del evento)
  entidad_tipo text,       -- Tipo de entidad (ej: 'evento', 'usuario')
  creado_en    timestamptz NOT NULL DEFAULT now()
);
```

**Puntos clave:**
- Cada usuario en `usuario_ids` recibe su propia fila. Si se notifica a 10 usuarios, se insertan 10 filas.
- `tipo` controla el ícono y color que muestra la app.
- `entidad_id` + `entidad_tipo` permiten navegar directamente a la entidad relacionada en el futuro.
- El campo `leida` alimenta el badge de notificaciones no leídas en la barra superior.

---

## Flujo de registro de dispositivo

Este flujo ocurre automáticamente cuando el usuario inicia sesión en la app.

```
1. Usuario inicia sesión  →  AuthCubit emite estado "Autenticado"
2. main.dart escucha el stream de AuthCubit
3. Llama a NotificacionesPushServicio.inicializar(usuarioId)
4. Firebase solicita permiso al navegador
5. Si el usuario acepta → Firebase devuelve un token FCM único para ese navegador
6. El token se guarda en tokens_dispositivo con upsert (onConflict: 'token')
```

**Archivo:** `lib/compartido/notificaciones_push_servicio.dart`

```dart
// Fragmento simplificado del flujo
final settings = await _messaging.requestPermission(...);
if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

final token = await _messaging.getToken(vapidKey: _vapidKey);
await _supabase.from('tokens_dispositivo').upsert({
  'usuario_id': usuarioId,
  'token': token,
  'plataforma': 'web',
  'actualizado_en': DateTime.now().toIso8601String(),
}, onConflict: 'token');
```

**VAPID Key:** clave pública de Firebase que identifica la aplicación web ante el navegador. Se encuentra en Firebase Console → Project Settings → Cloud Messaging → Web Push certificates.

---

## Flujo de envío de notificación

Cuando un cubit necesita notificar a un usuario, llama a la Edge Function directamente mediante Supabase Functions.

### Paso a paso dentro de la Edge Function

```
1. Recibe: { usuario_ids, titulo, cuerpo, tipo, entidad_id?, entidad_tipo? }

2. INSERT en tabla "notificaciones" para cada usuario_id
   → garantiza que la notificación aparezca in-app aunque no haya tokens

3. SELECT tokens_dispositivo WHERE usuario_id IN (usuario_ids)
   → obtiene todos los tokens FCM activos

4. Si no hay tokens → retorna { guardadas: N, enviados: 0, motivo: 'Sin tokens' }

5. Carga FIREBASE_SERVICE_ACCOUNT desde los secretos de Supabase

6. Genera un JWT firmado con RS256 usando la private_key del service account

7. Intercambia el JWT por un Access Token de Google OAuth2
   (endpoint: https://oauth2.googleapis.com/token)

8. Para cada token: POST a FCM HTTP v1 API en paralelo
   (endpoint: https://fcm.googleapis.com/v1/projects/{project_id}/messages:send)

9. Revisa respuestas:
   - Si FCM retorna UNREGISTERED o INVALID_ARGUMENT → elimina ese token de la DB
   - Cuenta los enviados exitosos

10. Retorna { guardadas: N, enviados: M, total: T }
```

### Autenticación con Google (por qué es compleja)

Firebase FCM HTTP v1 requiere un Access Token de OAuth2, no una API key simple. El proceso:

1. Se crea un JWT con los datos del service account
2. Se firma con la clave privada RSA (RS256)
3. Se envía a Google para obtener un Access Token temporal
4. Ese token se usa en el header `Authorization: Bearer {token}` al llamar FCM

Este proceso se realiza en cada invocación de la Edge Function usando la API `crypto.subtle` de Web Crypto (disponible en Deno sin librerías externas).

### Llamar la Edge Function desde un cubit

```dart
await Supabase.instance.client.functions.invoke(
  'enviar-notificacion',
  body: {
    'usuario_ids': [usuarioId],
    'titulo': 'Tu solicitud fue aprobada',
    'cuerpo': 'Ya puedes acceder al sistema UniAsist.',
    'tipo': 'aprobacion',
    'entidad_id': usuarioId,
    'entidad_tipo': 'usuario',
  },
);
```

---

## Centro de notificaciones in-app

La pantalla de notificaciones (`NotificacionesPantalla`) lee directamente de la tabla `notificaciones` en Supabase.

### Arquitectura Flutter

```
NotificacionesPantalla (StatefulWidget)
    │
    └── BlocBuilder<NotificacionesCubit, NotificacionesEstado>
            │
            ├── NotificacionesCargando  →  CircularProgressIndicator
            ├── NotificacionesCargadas  →  ListView de tarjetas
            ├── NotificacionesError     →  VistaErrorApp con botón reintentar
            └── NotificacionesInicial   →  _VistaVacia
```

### Badge de no leídas

El `NotificacionesCubit` mantiene un stream en tiempo real del número de notificaciones no leídas:

```dart
// Stream que se actualiza automáticamente vía Supabase Realtime
Stream<int> streamCantidadNoLeidas(String usuarioId)
```

Este stream se inicia en `main.dart` cuando el usuario se autentica y alimenta el badge numérico visible en la barra superior de la app.

### Tipos de notificación y su representación visual

| Tipo | Ícono | Color |
|---|---|---|
| `evento` | `Icons.event_rounded` | Acento (morado) |
| `asistencia` | `Icons.how_to_reg_outlined` | Verde |
| `aprobacion` | `Icons.verified_user_outlined` | Ámbar |
| cualquier otro | `Icons.notifications_outlined` | Gris |

---

## Service Worker de Firebase

**Archivo:** `web/firebase-messaging-sw.js`

El service worker es un script que el navegador ejecuta en segundo plano, independientemente de si la app está abierta. Es necesario para recibir notificaciones push cuando la app está cerrada o minimizada.

```javascript
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({ /* config */ });
const messaging = firebase.messaging();

// No se usa onBackgroundMessage porque FCM muestra automáticamente
// las notificaciones que tienen campo 'notification' en el payload.
// onBackgroundMessage solo es necesario para mensajes data-only.
```

### Por qué NO usar `onBackgroundMessage` con payload de notificación

FCM tiene dos tipos de mensajes:
- **Notification message**: tiene campo `notification` → FCM lo muestra automáticamente en el sistema operativo
- **Data message**: solo tiene campo `data` → el desarrollador decide cómo mostrarlo

UniAsist usa *notification messages*. Si además se implementa `onBackgroundMessage`, el navegador muestra la notificación **dos veces**. Por eso el handler está omitido.

---

## Comportamiento en múltiples dispositivos

Un mismo usuario puede tener la app instalada en múltiples dispositivos (PC, teléfono, tablet). Cada dispositivo tiene su propio token FCM único.

```
Usuario "Juan"
├── Token A  →  PC (Chrome)
├── Token B  →  Teléfono Android (Chrome)
└── Token C  →  Tablet (Safari)
```

Cuando se envía una notificación a Juan, **llega a todos sus dispositivos activos**. Esto es el comportamiento estándar de apps como Gmail, Slack y WhatsApp.

Cada dispositivo recibe exactamente **una** notificación — no hay duplicados en el mismo dispositivo.

---

## Limpieza de tokens muertos

Un token se vuelve inválido cuando:
- El usuario elimina la PWA del navegador
- El navegador revoca el permiso de notificaciones
- El token expira (Firebase lo hace periódicamente)

La Edge Function detecta esto automáticamente revisando la respuesta de FCM:

```typescript
// Si FCM retorna estos códigos de error, el token ya no es válido
const tokensMuertos = resultados
  .filter(({ ok, body }) => {
    const code = body?.error?.status ?? ''
    return code === 'UNREGISTERED' || code === 'INVALID_ARGUMENT'
  })
  .map(({ token }) => token)

// Se eliminan de la DB para no enviarles notificaciones en el futuro
if (tokensMuertos.length > 0) {
  await supabase.from('tokens_dispositivo').delete().in('token', tokensMuertos)
}
```

---

## Banner de activación

Si un usuario no tiene ningún token registrado en `tokens_dispositivo`, la pantalla de notificaciones muestra un banner ámbar invitándolo a activar las notificaciones push.

**Lógica del banner:**
1. Al abrir la pantalla, se consulta `tokens_dispositivo` filtrando por `usuario_id`
2. Si no hay filas → se muestra el banner
3. Al presionar "Activar" → se llama `NotificacionesPushServicio.inicializar(usuarioId)`
4. El navegador muestra el diálogo de permiso del sistema operativo
5. Si el usuario acepta → el token se guarda y el banner desaparece automáticamente

**Estados del banner:**
- `_tieneToken == null` → verificando (no se muestra nada)
- `_tieneToken == false` → muestra el banner con botón "Activar"
- `_tieneToken == true` → no muestra nada (usuario ya tiene notificaciones activas)

---

## Seguridad y RLS

### `tokens_dispositivo`
```sql
-- El usuario solo puede gestionar sus propios tokens
-- La unión auth_id ↔ usuario_id es necesaria porque tokens_dispositivo
-- referencia public.usuarios, no auth.users directamente
CREATE POLICY "usuario gestiona sus tokens"
  ON public.tokens_dispositivo FOR ALL
  USING (
    usuario_id = (SELECT id FROM public.usuarios WHERE auth_id = auth.uid())
  );
-- La Edge Function usa SUPABASE_SERVICE_ROLE_KEY → bypasea RLS
```

### `notificaciones`
```sql
-- El usuario solo puede leer y marcar como leídas sus propias notificaciones
-- No puede INSERT (solo la Edge Function con service_role puede insertar)
CREATE POLICY "usuario lee sus notificaciones"
  ON public.notificaciones FOR SELECT
  USING (usuario_id = (SELECT id FROM public.usuarios WHERE auth_id = auth.uid()));

CREATE POLICY "usuario actualiza sus notificaciones"
  ON public.notificaciones FOR UPDATE
  USING (usuario_id = (SELECT id FROM public.usuarios WHERE auth_id = auth.uid()));
```

---

## Puntos de disparo de notificaciones

Estos son los eventos del sistema que generan notificaciones. Los marcados como ✅ están implementados.

| ID | Evento | Destinatario | Tipo | Estado |
|---|---|---|---|---|
| N1 | Usuario aprobado | Usuario aprobado | `aprobacion` | ✅ |
| N2 | Usuario rechazado | Usuario rechazado | `aprobacion` | ✅ |
| N3 | Usuario suspendido | Usuario suspendido | `aprobacion` | ✅ |
| N4 | Asignado como colaborador de evento | Colaborador | `evento` | ✅ |
| N5 | Removido como colaborador de evento | Colaborador | `evento` | ✅ |
| N6 | Rol asignado | Usuario | `aprobacion` | ✅ |
| N7 | Rol removido | Usuario | `aprobacion` | ✅ |
| N8 | Evento iniciado | Colaboradores | `evento` | ⏳ Pendiente |
| N9 | Evento finalizado | Colaboradores | `evento` | ⏳ Pendiente |
| N10 | Entrada registrada | Usuario asistente | `asistencia` | ⏳ Pendiente |
| N11 | Salida registrada | Usuario asistente | `asistencia` | ⏳ Pendiente |
| N12 | Marcado como ausente | Usuario | `asistencia` | ⏳ Pendiente |
| N13 | Lote de usuarios suspendido | Cada usuario | `aprobacion` | ⏳ Pendiente |

---

## Cómo probar el sistema

### Desde el panel de Supabase (Edge Function Test)

1. Ir a **Edge Functions** → `enviar-notificacion` → pestaña **Test**
2. Método: `POST`
3. Body:
```json
{
  "usuario_ids": ["UUID-del-usuario"],
  "titulo": "Título de prueba",
  "cuerpo": "Cuerpo de la notificación",
  "tipo": "general"
}
```
4. Click en **Send Request**

**Respuesta esperada (éxito):**
```json
{ "guardadas": 1, "enviados": 1, "total": 1 }
```

**Respuesta si el usuario no tiene token FCM registrado:**
```json
{ "guardadas": 1, "enviados": 0, "motivo": "Sin tokens registrados" }
```
*(La notificación igual queda guardada en la tabla y aparece in-app)*

### Verificar que la notificación llegó a la tabla

```sql
SELECT * FROM public.notificaciones
ORDER BY creado_en DESC
LIMIT 10;
```

---

## Variables y secretos requeridos

### Secretos de Supabase Edge Functions
*(configurar en Supabase Dashboard → Edge Functions → Secrets)*

| Secreto | Descripción |
|---|---|
| `FIREBASE_SERVICE_ACCOUNT` | JSON completo del service account de Firebase. Obtener en Firebase Console → Project Settings → Service accounts → Generate new private key |
| `SUPABASE_URL` | Disponible automáticamente en Edge Functions |
| `SUPABASE_SERVICE_ROLE_KEY` | Disponible automáticamente en Edge Functions |

### Constantes en el código Flutter
*(hardcodeadas en `notificaciones_push_servicio.dart`)*

| Constante | Descripción | Dónde obtenerla |
|---|---|---|
| `_vapidKey` | Clave pública VAPID para web push | Firebase Console → Project Settings → Cloud Messaging → Web Push certificates |

### Configuración de Firebase en `main.dart`

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: '...',
    authDomain: '...',
    projectId: '...',          // ← debe coincidir con el service account
    storageBucket: '...',
    messagingSenderId: '...',
    appId: '...',
  ),
);
```

> ⚠️ **Seguridad:** El service account JSON contiene una clave privada RSA. Nunca debe subirse al repositorio. Almacenarlo únicamente como secreto en Supabase Edge Functions.
