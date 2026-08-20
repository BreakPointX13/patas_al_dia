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
