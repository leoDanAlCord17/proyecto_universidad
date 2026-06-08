import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ServiceAccount {
  client_email: string
  private_key: string
  project_id: string
}

// Convierte el PEM de la private key a ArrayBuffer para Web Crypto
async function pemToArrayBuffer(pem: string): Promise<ArrayBuffer> {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\\n/g, '') // \n literales que Supabase Secrets guarda como texto
    .replace(/\s/g, '')
  const binary = atob(base64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes.buffer
}

// Base64url sin padding (requerido para JWT)
function toBase64Url(data: Uint8Array): string {
  return btoa(String.fromCharCode(...data))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

// Genera un JWT firmado con RS256 y lo intercambia por un access token de Google
async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const encoder = new TextEncoder()

  const header = toBase64Url(encoder.encode(JSON.stringify({ alg: 'RS256', typ: 'JWT' })))
  const payload = toBase64Url(encoder.encode(JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  })))

  const signingInput = `${header}.${payload}`

  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    await pemToArrayBuffer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    encoder.encode(signingInput),
  )

  const jwt = `${signingInput}.${toBase64Url(new Uint8Array(signature))}`

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  const tokenData = await tokenRes.json()
  return tokenData.access_token
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { usuario_ids, titulo, cuerpo } = await req.json()

    if (!usuario_ids?.length || !titulo || !cuerpo) {
      return new Response(
        JSON.stringify({ error: 'Faltan parámetros: usuario_ids, titulo, cuerpo' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    console.log('1. Parámetros recibidos:', { usuario_ids, titulo, cuerpo })

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Obtiene los tokens FCM de los usuarios destino
    const { data: tokens, error } = await supabase
      .from('tokens_dispositivo')
      .select('token')
      .in('usuario_id', usuario_ids)

    console.log('2. Tokens encontrados:', tokens?.length ?? 0, 'Error DB:', error?.message)

    if (error) throw new Error(`DB error: ${error.message} (code: ${error.code})`)
    if (!tokens?.length) {
      return new Response(
        JSON.stringify({ enviados: 0, motivo: 'Sin tokens registrados' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Lee la service account desde la variable de entorno secreta
    console.log('3. Leyendo FIREBASE_SERVICE_ACCOUNT...')
    const saRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!saRaw) throw new Error('FIREBASE_SERVICE_ACCOUNT no está configurado')
    const sa: ServiceAccount = JSON.parse(saRaw)
    console.log('4. Service account cargada, project_id:', sa.project_id)
    const accessToken = await getAccessToken(sa)
    console.log('5. Access token obtenido, enviando a FCM...')

    // FCM HTTP v1 no soporta multicast — envía uno por uno en paralelo
    const resultados = await Promise.all(
      tokens.map(({ token }: { token: string }) =>
        fetch(
          `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${accessToken}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              message: {
                token,
                notification: { title: titulo, body: cuerpo },
                webpush: {
                  notification: {
                    icon: '/icons/Icon-192.png',
                    badge: '/icons/Icon-192.png',
                    requireInteraction: false,
                  },
                },
              },
            }),
          },
        )
      ),
    )

    const enviados = resultados.filter((r) => r.ok).length

    return new Response(
      JSON.stringify({ enviados, total: tokens.length }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (e) {
    const mensaje = e instanceof Error
      ? { error: e.message, tipo: e.name, stack: e.stack }
      : { error: JSON.stringify(e) }
    console.error('ERROR en enviar-notificacion:', JSON.stringify(mensaje))
    return new Response(
      JSON.stringify(mensaje),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
