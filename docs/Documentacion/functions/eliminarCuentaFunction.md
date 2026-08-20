# Nota de Obsidian: Edge Function `eliminar-cuenta`

## 📁 Ubicación en el Proyecto

`supabase/functions/eliminar-cuenta/index.ts`

Primer código del proyecto que **no** corre en el dispositivo del usuario — corre en el servidor de Supabase (Deno, no Dart/Flutter). Invocada desde `UsuarioRepository.eliminarCuentaSupabase()` (ver `usuario.repository.md`, punto 6c).

## 🎯 Propósito del Archivo

Borra la cuenta de Supabase Auth (`auth.users`) del usuario que llama. Existe porque el cliente (la app, con la "publishable key") no tiene permiso para borrar cuentas — esa operación exige la "service_role key", un secreto que solo puede vivir en un servidor. Parte de "Eliminar cuenta" (2026-08-19, ver `decisiones_arquitectura.md`).

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Dos clientes de Supabase distintos, con dos claves distintas, dentro de la misma función:

1. **Cliente "de usuario"** (`SUPABASE_ANON_KEY`, la misma clave pública que usa la app) — solo para validar el JWT que llega en el header `Authorization` y averiguar quién es el que llama (`auth.getUser()`). No puede borrar nada.
2. **Cliente "admin"** (`SUPABASE_SERVICE_ROLE_KEY`) — el único con permiso para `auth.admin.deleteUser(...)`.

Las tres variables de entorno que usa (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`) las inyecta Supabase solo en cada Edge Function — no hace falta configurarlas a mano en ningún panel.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. Sin parámetros — el JWT decide a quién borrar

```ts
const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
// ...
const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id);
```

La función no recibe ningún `id` en el body de la petición — usa el `id` del usuario autenticado por el JWT que llega en el header. Decisión de seguridad deliberada: si aceptara un `id` como parámetro, cualquiera con acceso a la clave pública (que no es secreta, ver `supabaseConfig.md`) podría intentar borrar la cuenta de cualquier otra persona con solo cambiar ese parámetro. Al depender solo del JWT, la función **solo puede borrar la cuenta del que la está llamando**, sin importar qué parámetros se le manden.

### 2. `Supabase.instance.client.functions.invoke('eliminar-cuenta')` — el JWT viaja solo

Del lado de Flutter (`UsuarioRepository.eliminarCuentaSupabase`), no hace falta armar el header `Authorization` a mano — `functions.invoke(...)` lo adjunta automáticamente con el JWT de la sesión activa del cliente. Si no hay ninguna sesión activa, la función recibe la petición sin ese header y responde `401` (ver el chequeo `if (!authHeader)` al principio del archivo).

### 3. Verificación de JWT — la hace Supabase antes de correr el código

Por defecto (sin pasar `--no-verify-jwt` al desplegar), el runtime de Edge Functions de Supabase valida el JWT **antes** de ejecutar el código de la función — un JWT vencido o inválido nunca llega a correr `Deno.serve(...)`. La verificación manual dentro de la función (`supabaseClient.auth.getUser()`) es una segunda capa, no la única: además de confirmar que el JWT es válido, la necesitamos para **obtener** el `user.id`, no solo para validarlo.

### 4. Despliegue — `--use-api`, no Docker

```
supabase functions deploy eliminar-cuenta --use-api
```

El flujo normal de `supabase functions deploy` empaqueta la función corriendo un contenedor local (Docker) — en esta máquina (Fedora, con Podman en vez de Docker) el bind-mount del código local hacia el contenedor fallaba (`entrypoint path does not exist`, aunque el archivo sí existía en el host — un problema de compatibilidad Podman/Docker del bundler, no del código). La flag `--use-api` evita el contenedor por completo: sube el código y lo empaqueta del lado del servidor de Supabase. Vale la pena recordar esta flag para el próximo redeploy si la máquina sigue usando Podman.

**CLI instalado sin `sudo`:** por el mismo motivo que el despliegue evitó Docker, la instalación del CLI evitó el paquete `.rpm` (pedía una contraseña que esta sesión no podía proveer de forma interactiva) — se usó el binario suelto (`.tar.gz`) descomprimido directo en `~/.local/bin` (ya en el `PATH` del usuario), sin tocar el sistema.
