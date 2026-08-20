# Nota de Obsidian: `NuevaContrasenaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/nueva_contrasena_screen.dart`

Se abre desde `main.dart`, no desde ninguna otra pantalla con un botón — es el destino del enlace de "olvidé mi contraseña" que Supabase manda por correo (ver `recuperarContrasenaScreen.md`).

## 🎯 Propósito del Archivo

Último paso de "olvidé mi contraseña" (2026-08-19, ver `decisiones_arquitectura.md`): pide la contraseña nueva (+ confirmar) y la guarda. Cuando esta pantalla se muestra, ya existe una **sesión de recuperación** válida (la estableció el propio enlace, antes de que la pantalla se monte) — por eso no pide el correo de nuevo, ni ningún código.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Primera pantalla del proyecto que se navega desde **fuera** del árbol de widgets normal — no hay ningún `Navigator.of(context).push(...)` en respuesta a un tap del usuario dentro de la app; en cambio, `main.dart` la empuja desde un listener global cuando detecta el evento correcto. Ver punto 1.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. Cómo se llega acá: `main.dart` + `navigatorKey` + `AuthChangeEvent.passwordRecovery`

```dart
// main.dart
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  ...
  await Supabase.initialize(...);
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const NuevaContrasenaScreen()),
      );
    }
  });
  ...
  runApp(const ProviderScope(child: MyApp()));
}

// MaterialApp(navigatorKey: navigatorKey, ...)
```

Cuando el usuario toca el enlace del correo, el sistema operativo reabre (o abre por primera vez) la app con una URL propia (`patasaldia://reset-password`, registrada en `AndroidManifest.xml`/`Info.plist` — ver `recuperarContrasenaScreen.md`, punto 2). `supabase_flutter` captura esa URL sola (usa el paquete `app_links` por debajo, sin que este proyecto tenga que agregarlo a mano — ya viene como dependencia de `supabase_flutter`), intercambia el token que trae por una sesión válida, y notifica ese cambio disparando `AuthChangeEvent.passwordRecovery` en el stream `onAuthStateChange`.

**Por qué hace falta `navigatorKey`, un `GlobalKey<NavigatorState>` a nivel de archivo:** el listener que reacciona a ese evento vive en `main()`, fuera de cualquier widget — no tiene ningún `BuildContext` propio a mano para poder navegar. `navigatorKey`, pasado a `MaterialApp(navigatorKey: ...)`, es el mecanismo estándar de Flutter para navegar "desde afuera": `navigatorKey.currentState` da acceso al `NavigatorState` de toda la app en cualquier momento, sin necesitar un `context` local.

**`onError` del mismo listener:** Supabase reporta un enlace vencido o ya usado como un **error del stream** (`Supabase.instance.client.auth.notifyException(...)`), no como un evento de datos — por eso el `listen(...)` tiene un segundo callback `onError`. Por ahora solo hace `debugPrint` (sin `BuildContext` fácil ahí tampoco para mostrar un `SnackBar` traducido) — el usuario simplemente ve la app arrancar normal, sin la pantalla de contraseña nueva, en vez de quedar colgado en algún estado raro. Simplificación consciente, documentada acá por si en el futuro vale la pena sumar un `scaffoldMessengerKey` para avisar ese caso con un mensaje real.

### 2. `_restablecer()` — sin pedir el correo, ya hay sesión

```dart
await ref.read(usuarioProvider.notifier).completarRecuperacion(nuevaContrasena: _passwordController.text);
Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
  MaterialPageRoute(builder: (context) => const NavegacionPrincipalScreen()),
  (route) => false,
);
```

`completarRecuperacion` (ver `usuarioNotifier.md`, punto 11) actualiza la contraseña vía Supabase (`updateUser`, exige la sesión que ya existe) y activa la sesión local (mismo `_activarSesionLocal` que usa `iniciarSesion`, ver ese mismo doc) — de ahí en más es exactamente como un login exitoso, por eso esta pantalla navega directo adentro de la app con el mismo patrón (`pushAndRemoveUntil` + `rootNavigator: true`) que usan `IniciarSesionScreen`/`RegistroScreen`.

Mismo manejo de errores que el resto del módulo (`on AuthException catch` + `mensajeErrorAutenticacion`, ver `errorAutenticacion.md`).

### 3. Validadores — `validarContrasena` compartido con `RegistroScreen` (2026-08-20)

`validator: (valor) => validarContrasena(l10n, valor)` para la contraseña nueva (ver `validadorContrasena.md`: mínimo 8 caracteres, una mayúscula, un número), y "confirmar" sigue con su propia comparación de igualdad, sin extraer (dos líneas, no vale la pena la abstracción extra). Antes esta pantalla tenía su propio validador de una sola línea ("mínimo 6 caracteres") duplicado con `RegistroScreen` — al sumar tres reglas a la vez, se extrajo a una función compartida en vez de duplicar la lógica en las dos pantallas.
