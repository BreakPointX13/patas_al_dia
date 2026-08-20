# Nota de Obsidian: `supabase_config.dart`

## 📁 Ubicación en el Proyecto

`lib/services/supabase_config.dart`

## 🎯 Propósito del Archivo

Guarda las dos credenciales del proyecto de Supabase (Project URL y "publishable key") que usa `main.dart` para inicializar el cliente al arrancar la app. Primera pieza de la Fase 3 del plan de Supabase — ver `decisiones_arquitectura.md`, entrada del 2026-08-18 ("Arranca Supabase"), y `TablaMaestraAppVetMovil1.sql` para el esquema que este cliente termina consultando.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. La "publishable key" no es un secreto

```dart
const supabaseUrl = 'https://wegffggssmddbcbpdujv.supabase.co';
const supabasePublishableKey = 'sb_publishable_...';
```

A diferencia de una API key tradicional, la `publishable key` de Supabase está pensada para viajar dentro del cliente (la app instalada en el teléfono de cualquiera puede, en teoría, extraerla) — no hace falta ocultarla ni sacarla a variables de entorno. La protección real de los datos vive en las políticas de Row Level Security definidas en `TablaMaestraAppVetMovil1.sql` (cada tabla exige `usuario_id = auth.uid()` para leer/escribir, excepto la lectura pública de `mascotas_extraviadas`), no en mantener esta clave en secreto.

### 2. `Supabase.initialize` en `main.dart`, antes de `runApp`

```dart
await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
```

Se inicializa una sola vez al arrancar la app (mismo lugar y mismo criterio que `NotificacionService.instance.inicializar()` e `initializeDateFormatting`) — después de esto, `Supabase.instance.client` queda disponible en cualquier parte de la app sin volver a inicializar nada.

### 3. `supabaseClientProvider` — acceso vía Riverpod

```dart
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);
```

En `lib/providers/supabase_provider.dart`. Mismo patrón de DI simple que ya usa el resto del proyecto para exponer los repositories (`mascotaRepositoryProvider`, etc., ver `usuarioNotifier.md`) — cualquier código futuro que necesite hablarle a Supabase (login real, sync, Mapa) lo obtiene vía `ref.read(supabaseClientProvider)` en vez de llamar a `Supabase.instance.client` directo, para quedar coherente con cómo el resto de la app accede a sus dependencias.

### 4. `Anonymous Sign-ins` habilitado en el proyecto

Requisito de configuración en el dashboard de Supabase (Authentication → Sign In / Providers), no en código: sin esto, un usuario invitado (`esInvitado = true`, sin registro) no tendría ningún `auth.uid()` al cual atarse, y las políticas de RLS de `TablaMaestraAppVetMovil1.sql` (que comparan contra `auth.uid()`) rechazarían cualquier escritura suya. Habilitado por el usuario como parte de la Fase 2 del plan de Supabase.

### 5. `supabaseRedirectRecuperarContrasena` y `supabaseRedirectConfirmarCorreo` (2026-08-19/20)

```dart
const supabaseRedirectRecuperarContrasena = 'patasaldia://reset-password';
const supabaseRedirectConfirmarCorreo = 'https://breakpointx13.github.io/PatasAlDiaWeb/';
```

Dos destinos distintos para dos enlaces de correo distintos de Supabase Auth, cada uno resuelto de forma diferente:

- **Recuperar contraseña** → deep link (`patasaldia://reset-password`) — reabre la app directo, ver `nuevaContrasenaScreen.md`. Tiene sentido reabrir la app acá porque el evento que dispara (`AuthChangeEvent.passwordRecovery`) es inequívoco.
- **Confirmar correo** → página web externa (GitHub Pages, repo aparte y público — `PatasAlDiaWeb`, fuera de este repo). Se descartó el deep link para este caso: el evento que dispara la confirmación de registro (`AuthChangeEvent.signedIn`) es el mismo que dispara un login normal, así que reabrir la app ahí sería ambiguo sin lógica extra frágil. Se evaluó también subir la página a Supabase Storage (mismo bucket público que usa el resto del proyecto) — **no funciona**: Supabase Storage fuerza `Content-Type: text/plain` en cualquier archivo `.html` subido, sin importar qué se le pida al subirlo (medida de seguridad para no servir HTML/scripts arbitrarios bajo su propio dominio) — probado con tres métodos de subida distintos, los tres terminan igual.

**Ambas URLs tienen que estar en la lista de "Redirect URLs" del panel de Supabase** (Authentication → URL Configuration) — sin eso, Supabase ignora el `redirectTo`/`emailRedirectTo` pasado desde la app y cae al "Site URL" del proyecto (`http://localhost:3000`, nunca configurado), mostrando un error de conexión. Ver `decisiones_arquitectura.md`, entradas del 2026-08-19 y 2026-08-20.
