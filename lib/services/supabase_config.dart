// Credenciales del proyecto de Supabase. La "publishable key" (antes
// llamada "anon/public key") está pensada para vivir en el cliente — no es
// un secreto: la protección real de los datos la da Row Level Security
// (ver docs/Planificaciones/TablaMaestraAppVetMovil1.sql), no ocultar esta
// clave.
const supabaseUrl = 'https://wegffggssmddbcbpdujv.supabase.co';
const supabasePublishableKey = 'sb_publishable_-fBr5gLtpIM3aM6iJ2iEIw_BtGKy0cR';

// Esquema propio para volver a abrir la app desde el enlace de "olvidé mi
// contraseña" que manda Supabase Auth por correo (2026-08-19, ver
// decisiones_arquitectura.md) — registrado en AndroidManifest.xml e
// Info.plist. supabase_flutter lo captura solo y dispara
// AuthChangeEvent.passwordRecovery, ver main.dart.
const supabaseRedirectRecuperarContrasena = 'patasaldia://reset-password';

// Página estática (2026-08-20, ver decisiones_arquitectura.md) a la que
// redirige el enlace de "confirma tu correo" al registrarse — sin esto,
// Supabase redirige al "Site URL" del proyecto (http://localhost:3000, sin
// configurar), mostrando un error de conexión aunque la confirmación en sí
// ya haya funcionado. No usa deep linking (como la recuperación de
// contraseña) porque el evento que dispara la confirmación de registro
// (`AuthChangeEvent.signedIn`) es el mismo que un login normal — ambiguo
// sin lógica extra. Hosteada en GitHub Pages (repo aparte, público, solo
// para esta página) porque Supabase Storage fuerza `text/plain` en
// cualquier archivo .html subido (medida de seguridad, no hay forma de
// hacer que sirva HTML real).
const supabaseRedirectConfirmarCorreo =
    'https://breakpointx13.github.io/PatasAlDiaWeb/';

// Único admin de la app (2026-08-25, ver decisiones_arquitectura.md):
// moderación del módulo Mapa (ver reportes denunciados, borrarlos) estaba
// pensada para hacerse a mano desde el panel de Supabase — se movió a una
// pantalla dentro de la app, visible solo para esta cuenta. Comparado contra
// `usuario.email` (la cuenta registrada actual), no contra `auth.uid()` — no
// hay tabla de roles, es un único admin fijo. Las políticas RLS del lado de
// Supabase comparan este mismo correo vía `auth.jwt() ->> 'email'`.
const correoAdmin = 'breakpointx.dev@gmail.com';
