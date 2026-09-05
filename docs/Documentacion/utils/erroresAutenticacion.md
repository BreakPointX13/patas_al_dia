# Nota de Obsidian: `mensajeErrorAutenticacion`

## 📁 Ubicación en el Proyecto

`lib/presentation/utils/errores_autenticacion.dart`

Usado por `RegistroScreen` e `IniciarSesionScreen` (ver sus respectivos `.md`).

## 🎯 Propósito del Archivo

Traduce los códigos de error más comunes de Supabase Auth (`AuthException`) a un mensaje ya localizado — mismo criterio que el resto del proyecto con Supabase (ver, por ejemplo, `formularioReporteMascotaExtraviadaScreen.md`, punto 5): nunca se le muestra al usuario el texto crudo en inglés que devuelve la API.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `mensajeErrorAutenticacion(AppLocalizations l10n, AuthException e)`

```dart
String mensajeErrorAutenticacion(AppLocalizations l10n, AuthException e) {
  switch (e.code) {
    case 'invalid_credentials': return l10n.errorCredencialesInvalidas;
    case 'email_not_confirmed': return l10n.errorEmailNoConfirmado;
    case 'weak_password': return l10n.errorContrasenaCorta;
    case 'user_already_exists':
    case 'email_exists': return l10n.errorEmailYaRegistrado;
    default: return l10n.errorAutenticacionGenerico;
  }
}
```

Función pura (sin `BuildContext`, sin estado) — se le pasa el `l10n` ya resuelto desde la pantalla que la llama, en vez de leerlo ella misma, para que sea trivial de testear si en algún momento se agregan tests.

**Por qué está separada en un archivo propio, en vez de vivir dentro de `RegistroScreen` o `IniciarSesionScreen`:** las dos pantallas necesitan exactamente la misma traducción de errores — duplicar el `switch` en ambas violaría el mismo principio de "sin código repetido" que ya sigue el resto del proyecto (ver, por ejemplo, `etiquetas_localizadas.dart`, compartido entre varias pantallas).

**`e.code` (2026-09-05, antes `e is AuthApiException ? e.code : null`):** `code` vive en `AuthException`, la clase base — `AuthApiException` no le agrega nada nuevo, solo suma `statusCode` y se usa para errores que sí vinieron de una respuesta HTTP del servidor. El chequeo de tipo anterior asumía (mal) que `code` era exclusivo de `AuthApiException`, así que descartaba el código de cualquier `AuthException` "simple" — exactamente el caso de `UsuarioNotifier.registrarUsuario` (ver `usuarioNotifier.md`, punto 9), que lanza `AuthException(..., code: 'user_already_exists')` a mano, no un `AuthApiException`. **Bug real encontrado por un tester:** registrarse con un correo ya usado siempre mostraba el mensaje genérico en vez de "ese correo ya está registrado", porque el código nunca llegaba a evaluarse en el `switch`. Otras subclases sin `code` real (ej. `AuthRetryableFetchException`, sin conexión) siguen cayendo al mensaje genérico igual que antes — `code` ahí es `null` de por sí, no por el chequeo de tipo que se sacó.

**Códigos cubiertos, de los que documenta Supabase:** `invalid_credentials` (contraseña o correo incorrectos al iniciar sesión), `email_not_confirmed` (falta confirmar el correo — con "Confirm email" activado en el proyecto, ver `registroScreen.md`), `weak_password` (menos de 6 caracteres, aunque la app ya valida esto antes de llamar a la API), `user_already_exists`/`email_exists` (correo ya registrado — este último también se lanza a mano desde `UsuarioNotifier.registrarUsuario` cuando Supabase responde con éxito obfuscado, ver `usuarioNotifier.md`, punto 9), `otp_expired` (mapeado a `errorEnlaceInvalido` — Supabase reusa este código también para un enlace de recuperación vencido o ya usado, no solo para códigos de un solo uso; ver `recuperarContrasenaScreen.md`). Cualquier otro código cae al mensaje genérico en vez de fallar o mostrar texto sin traducir.

**Decisión explícita del usuario (2026-09-05): en `IniciarSesionScreen` el correo inexistente NO se distingue de la contraseña incorrecta** — ambos casos siguen cayendo en `invalid_credentials` → `errorCredencialesInvalidas` ("Correo o contraseña incorrectos"), a propósito. Supabase no distingue los dos casos en su respuesta (protección estándar contra enumeración de cuentas); revelarlo requeriría una Edge Function propia con la clave de servicio para consultar si el correo existe antes de intentar el login — evaluado y descartado por ahora, priorizando no exponer un endpoint que cualquiera podría usar para probar qué correos tienen cuenta en la app.
