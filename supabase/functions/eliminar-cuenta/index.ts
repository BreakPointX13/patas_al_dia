// Edge Function: eliminar-cuenta
//
// Un usuario no puede borrar su propia cuenta de Supabase Auth con la clave
// pública que usa el cliente (Flutter) — esa operación (auth.admin.deleteUser)
// exige la "service_role key", un secreto que nunca puede viajar en el
// código de la app. Esta función corre en el servidor de Supabase, donde
// SUPABASE_SERVICE_ROLE_KEY sí está disponible (inyectada sola, no hace
// falta configurarla a mano).
//
// No recibe ningún id como parámetro: identifica a quién borrar a partir
// del JWT de la sesión que llama (header Authorization, que el cliente de
// Flutter adjunta solo vía `functions.invoke`) — así nadie puede pedir
// borrar una cuenta que no es la suya.
//
// Ver: lib/data/repositories/usuario_repository.dart (eliminarCuentaSupabase)
// y docs/Documentacion/repositories/usuario.repository.md.

import { createClient } from 'jsr:@supabase/supabase-js@2';

// CORS (2026-08-21, agregado para el borrado de cuenta desde la web — ver
// docs/Documentacion/decisiones_arquitectura.md). Hasta acá esta función
// solo la llamaba la app Flutter (Dart nativo, sin navegador de por medio
// — CORS no aplica) vía `functions.invoke`. La página web
// (PatasAlDiaWeb/eliminar-cuenta-*.html) la llama desde un navegador con
// `fetch`, que sí exige que el servidor conteste el preflight `OPTIONS` y
// mande `Access-Control-Allow-Origin` en cada respuesta, o el navegador
// bloquea la respuesta antes de que el código JS la vea. `*` es seguro
// acá — CORS solo protege al *navegador*, la seguridad real la sigue
// dando el JWT (ver abajo), no el origen de la petición.
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Falta el header de autorización' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Cliente "de usuario" (clave pública) solo para validar el JWT y saber
  // quién está llamando — no puede borrar nada por sí solo.
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: authHeader } } },
  );

  const {
    data: { user },
    error: userError,
  } = await supabaseClient.auth.getUser();

  if (userError || !user) {
    return new Response(JSON.stringify({ error: 'No se pudo verificar la identidad' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Cliente "admin" (service_role key, solo disponible acá en el servidor)
  // — el único que puede borrar cuentas.
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  );

  const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id);

  if (deleteError) {
    return new Response(JSON.stringify({ error: deleteError.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
