# Nota de Obsidian: `IniciarSesionScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/iniciar_sesion_screen.dart`

Se abre desde el botón "Iniciar sesión" de `LoginScreen` (ver `loginScreen.md`, punto 3). Desde acá, dos links: uno a `RegistroScreen` (`entrarComoApp: true`, el default) y otro a `RecuperarContrasenaScreen` (2026-08-19, "¿Olvidaste tu contraseña?" — ver `recuperarContrasenaScreen.md`).

## 🎯 Propósito del Archivo

Formulario real de email + contraseña contra Supabase Auth (`signInWithPassword`). Parte de Login real (2026-08-19, ver `decisiones_arquitectura.md`) — reemplaza el aviso "no disponible todavía" que tenía `LoginScreen` antes de esta fecha.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Mismo esqueleto que `RegistroScreen` (`ConsumerStatefulWidget` + `Form` + estado `_guardando`), con dos campos en vez de tres (sin "confirmar contraseña", no aplica al iniciar sesión).

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `_iniciarSesion()` — sin lógica de conversión, eso ya pasó al registrarse

```dart
await ref.read(usuarioProvider.notifier).iniciarSesion(email: ..., password: ...);
Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
  MaterialPageRoute(builder: (context) => const NavegacionPrincipalScreen()),
  (route) => false,
);
```

A diferencia de `RegistroScreen`, esta pantalla no tiene parámetro `entrarComoApp` — solo se llega acá desde `LoginScreen`, antes de que exista ningún usuario local ni ningún shell de la app montado, así que siempre navega "hacia adentro" sin excepciones.

`iniciarSesion()` (en `UsuarioNotifier`, ver `usuarioNotifier.md`, punto 10) decide entre reactivar una fila local ya existente (mismo dispositivo de siempre) o crear una vacía (dispositivo nuevo, sin Sync todavía) — esa decisión no le importa a esta pantalla, que solo espera el resultado y navega.

**Manejo de errores** — mismo patrón que `RegistroScreen`: `on AuthException catch` con `mensajeErrorAutenticacion(l10n, e)` (ver `errorAutenticacion.md`), más un `catch` genérico para cualquier otro error (ej. sin conexión). Los dos casos más probables acá son credenciales inválidas (`invalid_credentials`) y correo sin confirmar (`email_not_confirmed`, ver `registroScreen.md`, punto 2, sobre la confirmación por correo).

### 2. Validadores — más simples que en `RegistroScreen`

Solo "obligatorio" para email y contraseña — a propósito, sin el mismo regex de formato de email ni el mínimo de 6 caracteres que sí tiene `RegistroScreen`. No hace falta duplicar esas reglas acá: si el formato o el largo estuvieran mal, la cuenta nunca se pudo haber registrado en primer lugar, así que Supabase ya va a rechazar la combinación con `invalid_credentials` — validar de más acá solo agregaría fricción sin prevenir ningún error real.
