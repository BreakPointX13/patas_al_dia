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
