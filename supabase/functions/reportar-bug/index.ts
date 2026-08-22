// Edge Function: reportar-bug
//
// Recibe una descripción de texto y, opcionalmente, una imagen (base64), y
// arma un correo real vía Resend (https://resend.com) hacia el correo del
// desarrollador. Corre en el servidor porque RESEND_API_KEY es un secreto
// que nunca puede viajar en el código del cliente (Flutter) — mismo motivo
// que eliminar-cuenta necesita SUPABASE_SERVICE_ROLE_KEY server-side.
//
// A propósito NO exige JWT/sesión (a diferencia de eliminar-cuenta): un
// usuario invitado, sin cuenta, también tiene que poder reportar un bug —
// coherente con que ninguna funcionalidad core de la app exige registro
// (regla 2 de CLAUDE.md).
//
// Ver: lib/services/reportar_bug_service.dart y
// docs/Documentacion/services/reportarBugService.md.

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const CORREO_DESTINO = 'breakpointx.dev@gmail.com';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  let body: { descripcion?: string; imagenBase64?: string; imagenNombre?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Cuerpo inválido' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const descripcion = body.descripcion?.trim();
  if (!descripcion) {
    return new Response(JSON.stringify({ error: 'Falta la descripción' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const attachments = body.imagenBase64
    ? [{ filename: body.imagenNombre ?? 'captura.jpg', content: body.imagenBase64 }]
    : [];

  const resendResponse = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${Deno.env.get('RESEND_API_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'Patas al Día <onboarding@resend.dev>',
      to: CORREO_DESTINO,
      subject: 'Reporte de bug — Patas al Día',
      text: descripcion,
      attachments,
    }),
  });

  if (!resendResponse.ok) {
    const detalle = await resendResponse.text();
    return new Response(JSON.stringify({ error: detalle }), {
      status: 502,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
