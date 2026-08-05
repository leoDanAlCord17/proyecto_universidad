/**
 * test_carga_supabase.js
 *
 * Prueba de carga (k6) contra la API de Supabase que consume Activiti
 * (Flutter Web/PWA + Supabase BaaS — sin backend propio). Simula hasta 100
 * usuarios concurrentes ejecutando el flujo típico de la app: login, carga
 * inicial de datos, registro de asistencia y consulta de analítica.
 *
 * IMPORTANTE — este script escribe datos reales:
 *   - La Fase 3 inserta filas reales en la tabla `asistencia`, asociadas al
 *     `TEST_EVENTO_ID` que le indiques. NO apuntes esto a un evento real de
 *     producción con estudiantes reales — usa un evento de prueba dedicado
 *     y bórralo (junto a las filas de asistencia que genere) al terminar.
 *   - La Fase 4 llama a `estadisticas_resumen`, que es de solo lectura.
 *
 * Ver la guía de uso al final de este archivo (instalación, comando de
 * ejecución y cómo interpretar los resultados).
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// ─── Configuración vía variables de entorno ────────────────────────────────

const SUPABASE_URL = __ENV.SUPABASE_URL;
const SUPABASE_ANON_KEY = __ENV.SUPABASE_ANON_KEY;

// Cuenta de prueba para el login (Fase 1). Para un test más realista, usa
// varias cuentas separadas por coma en TEST_USER_EMAILS / TEST_USER_PASSWORDS
// (mismo orden, mismo largo) — si solo das una, todos los VUs la reutilizan,
// lo cual es una simplificación razonable para una primera pasada, pero no
// simula 100 identidades distintas ni el costo real de 100 logins únicos.
const TEST_USER_EMAILS = (__ENV.TEST_USER_EMAILS || __ENV.TEST_USER_EMAIL || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);
const TEST_USER_PASSWORDS = (__ENV.TEST_USER_PASSWORDS || __ENV.TEST_USER_PASSWORD || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

// Evento de prueba dedicado (ver advertencia arriba) contra el que se
// registrará asistencia en la Fase 3. Si no se define, la Fase 3 se omite
// y se reporta una sola vez por VU (no se cuenta como fallo del test).
const TEST_EVENTO_ID = __ENV.TEST_EVENTO_ID || '';

// Pool opcional de usuario_id (UUID de la tabla `usuarios`, no el auth uid)
// que representan "asistentes" distintos escaneados en la Fase 3. Sin esto,
// cada VU registra asistencia con su propio usuario_id (resuelto tras el
// login), lo cual solo simula un asistente por cuenta de prueba disponible.
const TEST_ATTENDEE_IDS = (__ENV.TEST_ATTENDEE_IDS || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  throw new Error(
    'Faltan SUPABASE_URL y/o SUPABASE_ANON_KEY. Pásalas con -e SUPABASE_URL=... -e SUPABASE_ANON_KEY=... (ver guía al final del archivo).',
  );
}
if (TEST_USER_EMAILS.length === 0 || TEST_USER_PASSWORDS.length !== TEST_USER_EMAILS.length) {
  throw new Error(
    'Falta TEST_USER_EMAILS/TEST_USER_PASSWORDS (o TEST_USER_EMAIL/TEST_USER_PASSWORD) — deben tener la misma cantidad de elementos.',
  );
}

// ─── Métricas propias ───────────────────────────────────────────────────────

const authFailRate = new Rate('auth_fail_rate');
const escrituraFailRate = new Rate('asistencia_fail_rate');
const rpcFailRate = new Rate('analitica_fail_rate');

// ─── Escenario y umbrales ───────────────────────────────────────────────────

export const options = {
  scenarios: {
    carga_progresiva: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '20s', target: 20 }, // Carga baja
        { duration: '40s', target: 100 }, // Ramp-up a carga objetivo
        { duration: '2m', target: 100 }, // Pico sostenido
        { duration: '20s', target: 0 }, // Ramp-down
      ],
      gracefulRampDown: '15s',
    },
  },
  thresholds: {
    // Requeridos — el test se marca en rojo si se incumplen.
    http_req_duration: ['p(95)<800'],
    http_req_failed: ['rate<0.02'],

    // Desglose por fase — ayuda a ubicar EN QUÉ operación está el cuello de
    // botella en vez de solo saber que "algo" fue lento. No abortan el test
    // si fallan (abortOnFail no está activado), son informativos.
    'http_req_duration{fase:auth}': ['p(95)<800'],
    'http_req_duration{fase:carga_inicial}': ['p(95)<800'],
    'http_req_duration{fase:escritura_asistencia}': ['p(95)<800'],
    'http_req_duration{fase:analitica_rpc}': ['p(95)<800'],
  },
};

// ─── Setup — corre una sola vez antes de levantar VUs ──────────────────────

export function setup() {
  if (!TEST_EVENTO_ID) {
    console.warn(
      '[setup] TEST_EVENTO_ID no está definido — la Fase 3 (asistencia) se omitirá en toda la corrida.',
    );
  }

  // Login de humo con la primera credencial, para fallar rápido con un
  // mensaje claro si las credenciales o la URL están mal, en vez de que
  // los 100 VUs fallen en login uno por uno durante el ramp-up.
  const res = http.post(
    `${SUPABASE_URL}/auth/v1/token?grant_type=password`,
    JSON.stringify({ email: TEST_USER_EMAILS[0], password: TEST_USER_PASSWORDS[0] }),
    { headers: { apikey: SUPABASE_ANON_KEY, 'Content-Type': 'application/json' } },
  );
  if (res.status !== 200) {
    throw new Error(
      `[setup] Login de smoke test falló (status ${res.status}): ${res.body}. Revisa SUPABASE_URL, SUPABASE_ANON_KEY y las credenciales de TEST_USER_EMAILS/PASSWORDS.`,
    );
  }
  return {};
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function headersAutenticados(token) {
  return {
    apikey: SUPABASE_ANON_KEY,
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
}

/** YYYY-MM-DD para los parámetros p_fecha_inicio/p_fecha_fin del RPC. */
function fechaISO(d) {
  return d.toISOString().slice(0, 10);
}

/** Credencial de prueba para este VU — reparte el pool entre los VUs. */
function credencialParaEsteVU() {
  const i = (__VU - 1) % TEST_USER_EMAILS.length;
  return { email: TEST_USER_EMAILS[i], password: TEST_USER_PASSWORDS[i] };
}

/**
 * usuario_id (tabla `usuarios`, no el auth uid) a usar como "asistente"
 * simulado en la Fase 3. Con pool definido, cicla entre VU + iteración para
 * variar el asistente en cada escritura; sin pool, cae al propio usuario_id
 * resuelto tras el login.
 */
function attendeeIdParaEstaIteracion(usuarioIdPropio) {
  if (TEST_ATTENDEE_IDS.length === 0) return usuarioIdPropio;
  const idx = (__VU + __ITER) % TEST_ATTENDEE_IDS.length;
  return TEST_ATTENDEE_IDS[idx];
}

// Sesión cacheada por VU — cada instancia de VU en k6 corre en su propia VM
// de JS con su propio estado de módulo, así que este objeto persiste entre
// iteraciones de un mismo VU sin necesidad de VU-scoped storage explícito.
// Sin esto, cada iteración volvía a llamar /auth/v1/token, y con 100 VUs
// iterando cada 4-12s eso dispara el rate-limit de Supabase Auth mucho antes
// de generar carga real sobre Postgres/RPC — no es así como se comporta un
// usuario real (inicia sesión una vez y reutiliza el token).
//
// Tres estados posibles, no dos: `undefined` (aún no se intentó), un objeto
// de sesión (login exitoso) o `null` (se intentó y falló — NO reintentar).
// La primera versión de este script solo distinguía "tengo sesión" de "no
// tengo sesión", así que un VU cuyo login fallaba lo reintentaba en CADA
// iteración siguiente (con apenas 1s de espera) durante el resto del test —
// eso convirtió un fallo puntual de rate-limit en una tormenta de
// reintentos contra /auth/v1/token que dominó una corrida completa.
let sesionVU; // undefined hasta el primer intento

function iniciarSesionVU() {
  const { email, password } = credencialParaEsteVU();

  const loginRes = http.post(
    `${SUPABASE_URL}/auth/v1/token?grant_type=password`,
    JSON.stringify({ email, password }),
    {
      headers: { apikey: SUPABASE_ANON_KEY, 'Content-Type': 'application/json' },
      tags: { fase: 'auth' },
    },
  );

  const loginOk = check(loginRes, {
    'login: status 200': (r) => r.status === 200,
    'login: recibe access_token': (r) => !!r.json('access_token'),
  });
  authFailRate.add(!loginOk);
  if (!loginOk) return null; // intentado y falló — se cachea el fallo, no se reintenta

  return {
    token: loginRes.json('access_token'),
    authUid: loginRes.json('user.id'),
  };
}

// ─── Flujo del usuario virtual ──────────────────────────────────────────────

export default function () {
  // ── Fase 1: autenticación (solo la primera iteración de este VU) ────────
  if (sesionVU === undefined) {
    sesionVU = iniciarSesionVU();
  }
  if (!sesionVU) {
    // Login falló (o ya había fallado antes) — no hay sesión que reutilizar
    // y no se reintenta. Se cuenta la iteración como vacía y listo; el VU
    // sigue "ocupando" su cupo de VUs pero no vuelve a golpear /auth/v1/token.
    sleep(1);
    return;
  }

  const { token, authUid } = sesionVU;
  const headers = headersAutenticados(token);

  sleep(randomEntre(1, 3));

  // ── Fase 2: carga inicial de la app (Inicio/Eventos) ────────────────────
  const eventosRes = http.get(`${SUPABASE_URL}/rest/v1/eventos?select=*`, {
    headers,
    tags: { fase: 'carga_inicial' },
  });
  check(eventosRes, { 'eventos: status 200': (r) => r.status === 200 });

  const tagsRes = http.get(`${SUPABASE_URL}/rest/v1/tags?select=*&estatus=eq.true`, {
    headers,
    tags: { fase: 'carga_inicial' },
  });
  check(tagsRes, { 'tags: status 200': (r) => r.status === 200 });

  // Resuelve el usuario_id de negocio (tabla `usuarios`) a partir del auth
  // uid — el mismo paso que hace la app tras el login, y lo necesitamos
  // como fallback de "asistente" en la Fase 3 si no hay TEST_ATTENDEE_IDS.
  const perfilRes = http.get(
    `${SUPABASE_URL}/rest/v1/usuarios?select=id&auth_id=eq.${authUid}`,
    { headers, tags: { fase: 'carga_inicial' } },
  );
  check(perfilRes, { 'perfil: status 200': (r) => r.status === 200 });
  const perfil = perfilRes.json();
  const usuarioIdPropio = Array.isArray(perfil) && perfil.length > 0 ? perfil[0].id : null;

  sleep(randomEntre(1, 3));

  // ── Fase 3: escritura — registrar asistencia (simula escaneo de QR) ─────
  if (TEST_EVENTO_ID) {
    const attendeeId = attendeeIdParaEstaIteracion(usuarioIdPropio);

    if (attendeeId) {
      const payload = JSON.stringify({
        evento_id: TEST_EVENTO_ID,
        usuario_id: attendeeId,
        estatus: 'presente',
      });

      const asistenciaRes = http.post(`${SUPABASE_URL}/rest/v1/asistencia`, payload, {
        headers: { ...headers, Prefer: 'return=minimal' },
        tags: { fase: 'escritura_asistencia' },
        // `asistencia` SÍ tiene una restricción única sobre
        // (evento_id, usuario_id) — `asistencia_evento_usuario_uq` (es un
        // índice único, no aparece como constraint formal en pg_constraint,
        // por eso no se detectó en la revisión inicial del esquema). Con un
        // pool de asistentes más chico que el número de escrituras durante
        // la corrida, repetir (evento, asistente) es esperado y correcto —
        // sin esto, k6 cuenta cada 409 como fallo en http_req_failed pese a
        // que el check de abajo ya lo acepta como resultado válido.
        responseCallback: http.expectedStatuses(201, 409),
      });

      const escrituraOk = check(asistenciaRes, {
        'asistencia: 201 o 409': (r) => r.status === 201 || r.status === 409,
      });
      escrituraFailRate.add(!escrituraOk);
    }
  }

  sleep(randomEntre(1, 3));

  // ── Fase 4: analítica — estrés de RPC/Postgres ──────────────────────────
  const hoy = new Date();
  const hace30Dias = new Date(hoy.getTime() - 30 * 24 * 60 * 60 * 1000);

  const rpcPayload = JSON.stringify({
    p_fecha_inicio: fechaISO(hace30Dias),
    p_fecha_fin: fechaISO(hoy),
    p_tipo_ids: null,
    p_creador_ids: null,
    p_tag_ids: null,
  });

  const rpcRes = http.post(`${SUPABASE_URL}/rest/v1/rpc/estadisticas_resumen`, rpcPayload, {
    headers,
    tags: { fase: 'analitica_rpc' },
  });
  const rpcOk = check(rpcRes, { 'estadisticas_resumen: status 200': (r) => r.status === 200 });
  rpcFailRate.add(!rpcOk);

  sleep(randomEntre(1, 3));
}

/** Entero aleatorio inclusive en [min, max] — evita depender de jslib externo. */
function randomEntre(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * GUÍA RÁPIDA DE USO
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * a) INSTALAR k6
 * ───────────────
 *   Windows (winget):    winget install k6 --source winget
 *   Windows (choco):     choco install k6
 *   macOS (brew):        brew install k6
 *   Linux (apt):         sudo apt install k6   (o ver https://k6.io/docs/get-started/installation)
 *   Verificar:            k6 version
 *
 * b) DATOS DE PRUEBA NECESARIOS ANTES DE CORRER
 * ───────────────────────────────────────────────
 *   1. Al menos una cuenta de usuario de prueba, ya aprobada (el flujo de
 *      aprobación de cuentas de la app debe estar completo para esa cuenta).
 *   2. Un evento de prueba DESECHABLE (no un evento real con estudiantes) —
 *      copia su `id` (UUID) para TEST_EVENTO_ID. Bórralo junto con las filas
 *      de `asistencia` que genere la corrida cuando termines:
 *        delete from public.asistencia where evento_id = '<TEST_EVENTO_ID>';
 *        delete from public.eventos where id = '<TEST_EVENTO_ID>';
 *   3. (Opcional, recomendado para >1 VU realista) varias cuentas de prueba
 *      y/o varios usuario_id de la tabla `usuarios` para TEST_ATTENDEE_IDS.
 *
 * c) COMANDO DE EJECUCIÓN
 * ─────────────────────────
 *   k6 run ^
 *     -e SUPABASE_URL="https://<tu-project-ref>.supabase.co" ^
 *     -e SUPABASE_ANON_KEY="<tu-anon-key>" ^
 *     -e TEST_USER_EMAILS="prueba1@correo.com,prueba2@correo.com" ^
 *     -e TEST_USER_PASSWORDS="clave1,clave2" ^
 *     -e TEST_EVENTO_ID="<uuid-del-evento-de-prueba>" ^
 *     -e TEST_ATTENDEE_IDS="<uuid-usuario-1>,<uuid-usuario-2>" ^
 *     load_testing/test_carga_supabase.js
 *
 *   (En bash/macOS/Linux cambia el continuador de línea `^` por `\`.)
 *   Con una sola cuenta de prueba basta con TEST_USER_EMAIL/TEST_USER_PASSWORD
 *   (singular) en vez de las variantes con lista.
 *
 * d) CÓMO INTERPRETAR LOS RESULTADOS EN CONSOLA
 * ────────────────────────────────────────────────
 *   Al terminar, k6 imprime un resumen con, entre otras, estas líneas clave:
 *
 *   - `http_reqs..............: 1234   41.2/s`
 *       Total de peticiones y RPS (requests por segundo) promedio — tu
 *       throughput real contra la API de Supabase durante todo el test.
 *
 *   - `http_req_duration.......: avg=... p(90)=... p(95)=... max=...`
 *       Si `p(95)` aparece en ROJO (por encima de 800ms), el threshold
 *       falló: al menos el 5% de las peticiones fue más lento que eso.
 *       Compara `http_req_duration{fase:analitica_rpc}` contra las demás
 *       fases — si el RPC de estadísticas es notablemente más lento que
 *       `carga_inicial` o `auth`, el cuello de botella está en Postgres
 *       (la función RPC, no la red ni la capa REST).
 *
 *   - `http_req_failed.........: 1.20%  ✓ 15   ✗ 1234`
 *       Porcentaje de peticiones con status >= 400 (o error de red). Si
 *       supera 2%, el segundo threshold falla. Revisa el desglose por fase
 *       (`auth_fail_rate`, `asistencia_fail_rate`, `analitica_fail_rate` en
 *       las métricas custom) para saber si el problema es de login, RLS al
 *       escribir asistencia, o el RPC de analítica.
 *
 *   - Fallos típicos y su causa más probable en este proyecto:
 *       · Muchos 401/403 en Fase 2/3 → problema de RLS (el usuario de
 *         prueba no tiene el `usuario_id`/permisos esperados) — no es un
 *         problema de carga, es de datos de prueba mal configurados.
 *       · 429 en Fase 1 (auth) → estás reutilizando muy pocas cuentas para
 *         demasiados VUs y GoTrue está limitando la tasa de logins; agrega
 *         más cuentas a TEST_USER_EMAILS/PASSWORDS.
 *       · Timeouts o `http_req_duration` alto SOLO en `analitica_rpc` →
 *         cuello de botella real en la función `estadisticas_resumen` o en
 *         los índices de las tablas que agrega — candidato a revisar con
 *         `EXPLAIN ANALYZE` en Supabase.
 *       · `http_req_duration` alto en TODAS las fases por igual → el
 *         cuello de botella es más genérico (el pooler de conexiones de
 *         Supabase, el plan/tamaño del proyecto, o la red), no una query
 *         puntual.
 * ═══════════════════════════════════════════════════════════════════════════
 */
