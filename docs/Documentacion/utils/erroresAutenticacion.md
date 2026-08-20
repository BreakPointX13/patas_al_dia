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
  final codigo = e is AuthApiException ? e.code : null;
  switch (codigo) {
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

**`e is AuthApiException ? e.code : null`:** `AuthException` es la clase base de Supabase Auth; `AuthApiException` (la que sí trae `code`) es la variante que llega cuando el servidor respondió con un error concreto. Otras subclases (ej. `AuthRetryableFetchException`, sin conexión) no tienen `code` — para esas, cae directo al mensaje genérico (`errorAutenticacionGenerico`).

**Códigos cubiertos, de los que documenta Supabase:** `invalid_credentials` (contraseña o correo incorrectos al iniciar sesión), `email_not_confirmed` (falta confirmar el correo — con "Confirm email" activado en el proyecto, ver `registroScreen.md`), `weak_password` (menos de 6 caracteres, aunque la app ya valida esto antes de llamar a la API), `user_already_exists`/`email_exists` (correo ya registrado — este último también se lanza a mano desde `UsuarioNotifier.registrarUsuario` cuando Supabase responde con éxito obfuscado, ver `usuarioNotifier.md`, punto 9), `otp_expired` (mapeado a `errorEnlaceInvalido` — Supabase reusa este código también para un enlace de recuperación vencido o ya usado, no solo para códigos de un solo uso; ver `recuperarContrasenaScreen.md`). Cualquier otro código cae al mensaje genérico en vez de fallar o mostrar texto sin traducir.
