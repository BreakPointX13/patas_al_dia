# Nota de Obsidian: `RecuperarContrasenaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/recuperar_contrasena_screen.dart`

Se abre desde el link "¿Olvidaste tu contraseña?" de `IniciarSesionScreen` (ver `iniciarSesionScreen.md`). El paso siguiente del flujo completo no ocurre en esta pantalla — pasa en `NuevaContrasenaScreen` (ver su propio `.md`), a la que se llega tocando el enlace del correo, no navegando desde acá.

## 🎯 Propósito del Archivo

Pide el correo y dispara el enlace de recuperación de Supabase Auth (`resetPasswordForEmail`). "Olvidé mi contraseña", pendiente desde Login real (ver `decisiones_arquitectura.md`, entrada del 2026-08-19).

**Enlace por correo, no código de 6 dígitos — cambio de plan sobre la marcha.** La primera decisión (con el usuario) fue usar un código de 6 dígitos escrito a mano en la app, mismo motivo que evitar el magic link en el login normal: sin deep linking. Al ir a configurar la plantilla de correo en el panel de Supabase, apareció un bloqueo no anticipado: **Supabase no deja editar el texto de las plantillas de correo sin tener SMTP propio configurado** (usando el servicio de correo por defecto, el texto queda fijo, solo con el enlace visible, nunca con el código). Configurar SMTP propio es trabajo real (cuenta en un proveedor de correo, credenciales, etc.) — ante esa disyuntiva, se le presentó al usuario el trade-off actualizado y se optó por el enlace (con deep linking) en vez de sumar esa infraestructura.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

`ConsumerStatefulWidget` simple: un `Form` con el campo de correo, un estado `_enviado` que reemplaza el formulario por un mensaje de confirmación una vez enviado (sin volver a mostrar el campo — no hay nada más que hacer acá, el resto del flujo sigue por fuera de la app, en el correo).

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `_enviarEnlace()` — llama al repository directo, sin pasar por el provider

```dart
final repo = ref.read(usuarioRepositoryProvider);
await repo.enviarCorreoRecuperacion(_emailController.text.trim());
```

Igual que en la primera versión (con código): esta pantalla no toca `usuarioProvider` — todavía no hay ningún cambio de sesión ni de usuario, solo se le pide a Supabase que mande el correo.

**Sin revelar si el correo existe o no:** igual que `signUp()` (ver `registroScreen.md`), Supabase no distingue entre "correo registrado" y "correo no registrado" en la respuesta — siempre devuelve éxito. El mensaje (`avisoEnlaceEnviado`) está redactado a propósito como "si ese correo está registrado, te enviamos un enlace", en vez de confirmar que sí existe.

### 2. `redirectTo` — el dato que conecta esta pantalla con el deep link

```dart
// en UsuarioRepository.enviarCorreoRecuperacion:
Supabase.instance.client.auth.resetPasswordForEmail(email, redirectTo: supabaseRedirectRecuperarContrasena);
```

`supabaseRedirectRecuperarContrasena` (`'patasaldia://reset-password'`, en `lib/services/supabase_config.dart`) es el mismo esquema de URL registrado en `AndroidManifest.xml` e `Info.plist` — le dice a Supabase a qué URL apuntar el botón del correo. Sin este parámetro, Supabase usaría una URL de redirección genérica (configurable en su panel, "URL Configuration") que no necesariamente abre esta app.

### 3. Sin paso 2 en esta pantalla — el flujo continúa afuera de la app

A diferencia de la primera versión (código de 6 dígitos, que pedía el código en una segunda mitad de esta misma pantalla), acá no hay nada más que hacer una vez enviado el correo — el usuario cierra la app, revisa su bandeja de entrada, y toca el enlace. Eso reabre la app directamente en `NuevaContrasenaScreen` (ver ese `.md` y `main.dart`), sin volver a pasar por acá.
