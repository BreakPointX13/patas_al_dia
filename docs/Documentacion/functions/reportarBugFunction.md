# Nota de Obsidian: Edge Function `reportar-bug`

## 📁 Ubicación en el Proyecto

`supabase/functions/reportar-bug/index.ts`

Invocada desde `ReportarBugService.enviarReporte()` (ver `reportarBugService.md`).

## 🎯 Propósito del Archivo

Recibe una descripción de texto y, opcionalmente, una imagen (en base64), y arma un correo real hacia el desarrollador vía [Resend](https://resend.com). Pendiente desde el 2026-08-18 (ver memoria de sesión, ya resuelta), pospuesta explícitamente hasta tener un backend con Supabase — ver `decisiones_arquitectura.md`.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Segunda función server-side del proyecto, después de `eliminar-cuenta` (ver `eliminarCuentaFunction.md`) — mismo motivo de fondo: hay un secreto (acá `RESEND_API_KEY`, ahí `SUPABASE_SERVICE_ROLE_KEY`) que nunca puede viajar en el código del cliente.

**Diferencia clave con `eliminar-cuenta`: acá no se exige JWT/sesión.** Un usuario invitado, sin cuenta, tiene que poder reportar un bug igual que uno registrado — es coherente con la regla 2 de `CLAUDE.md` ("ninguna funcionalidad core debe requerir registro obligatorio"). No hay ningún dato del usuario que identificar ni proteger acá — es un envío de correo, no una operación sobre la cuenta de nadie.

### 🔄 Por qué Resend y no otra cosa

Se evaluó antes (ver memoria de sesión, entrada original) mandar el correo directo desde el cliente con `url_launcher`/`mailto:` o `share_plus` — ninguna cubre "destinatario prellenado + imagen adjunta" a la vez, es una limitación de plataforma. Con Supabase ya en pie, la alternativa real es un servicio de envío de correo transaccional llamado desde una Edge Function. Resend se eligió por tener una API HTTP simple (un solo `POST`, sin SDK necesario desde Deno) y un nivel gratis que alcanza sin problema para el volumen esperado de reportes de bugs de esta app.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. Sin autenticación, a propósito

```ts
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  // ... sin ningún chequeo de Authorization
```

A diferencia de `eliminar-cuenta` (que exige un JWT válido y borra la cuenta de quien lo manda), esta función no identifica a nadie — cualquiera con la `apikey` pública del proyecto (la misma que ya usa el cliente Flutter, no es secreta) puede llamarla. El único dato sensible es `RESEND_API_KEY`, que nunca se expone: vive como variable de entorno de la función, inyectada por Supabase desde `supabase secrets set` (no aparece en el código ni en el repo).

### 2. `attachments` — solo si hay imagen

```ts
const attachments = body.imagenBase64
  ? [{ filename: body.imagenNombre ?? 'captura.jpg', content: body.imagenBase64 }]
  : [];
```

La imagen es opcional del lado del usuario (ver `reportarBugScreen.md`) — si no se adjuntó ninguna, `attachments` queda como un array vacío, que Resend acepta sin problema (un correo sin adjuntos, solo el texto). El formato que espera Resend para adjuntos en base64 es exactamente `{filename, content}`, sin necesitar convertir a otro formato del lado del cliente.

### 3. `from: 'onboarding@resend.dev'` — límite del nivel gratis, no un problema para este caso

Sin verificar un dominio propio en Resend, solo se puede enviar **desde** `onboarding@resend.dev` (una dirección de prueba de la plataforma) y — mientras la cuenta esté en modo sandbox — únicamente **hacia** el correo con el que se creó la cuenta de Resend. Como la cuenta se creó con `breakpointx.dev@gmail.com` (el mismo correo al que tienen que llegar los reportes), esta restricción no afecta en nada al caso de uso real: total, el único destinatario que necesita esta función es justamente ese correo. Si en algún momento se quisiera mandar reportes a otro destinatario, o usar un remitente con la marca propia (`reportes@patasaldia.dev`, por ejemplo), ahí sí haría falta verificar un dominio en Resend.

### 4. Código de error `502`, no `500`, si Resend rechaza el envío

```ts
if (!resendResponse.ok) {
  const detalle = await resendResponse.text();
  return new Response(JSON.stringify({ error: detalle }), { status: 502, ... });
}
```

`502 Bad Gateway` en vez del genérico `500` — esta función en sí no falló, falló el servicio externo que intentó llamar (Resend). Es una distinción menor pero más precisa: ayuda a distinguir, revisando logs más adelante, un bug en esta función de un problema del lado de Resend (cuota agotada, key inválida, etc.).
