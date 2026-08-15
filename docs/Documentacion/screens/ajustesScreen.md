# Nota de Obsidian: `AjustesScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/ajustes_screen.dart`

Se accede desde `MenuUsuarioAvatar` (ver `menuUsuarioAvatar.md`), presente en el `AppBar` de las tres pestañas de `NavegacionPrincipalScreen` — antes se accedía solo desde un ícono de engranaje propio de `HomeScreen`.

## 🎯 Propósito del Archivo

Pantalla de ajustes de la app. Por ahora tiene una sola opción, "Cerrar sesión"; es el lugar natural donde agregar más adelante otras preferencias (notificaciones, cuenta, etc.) sin volver a tocar `HomeScreen`.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

`ConsumerWidget` (no necesita estado propio ni ciclo de vida, igual que `LoginScreen`). Usa `ListView` con un único `ListTile` en vez de una lista de botones sueltos, para que agregar más opciones a futuro sea directo (un `ListTile` más).

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `_confirmarCerrarSesion` (2026-08-15)

Antes de llamar a `_cerrarSesion`, pide confirmación con un `AlertDialog`. Se agregó porque, como invitado, no existe forma de "volver a entrar" a la misma sesión después de cerrarla (no hay credencial que recordar) — cerrar sesión es, en la práctica, irreversible desde la UI, aunque los datos no se borren literalmente de SQLite (ver el punto 3). El texto del diálogo se lo dice explícitamente al usuario antes de que lo haga sin querer.

### 2. `_cerrarSesion(BuildContext context, WidgetRef ref)`

```dart
Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
  await ref.read(usuarioProvider.notifier).cerrarSesion();

  ref.invalidate(mascotasProvider);
  ref.invalidate(agendaEventosProvider);
  ref.invalidate(medicamentoEventoProvider);
  ref.invalidate(documentosProvider);

  if (!context.mounted) {
    return;
  }

  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginScreen()),
    (route) => false,
  );
}
```

- **`cerrarSesion()`** (en `UsuarioNotifier`) marca `sesionActiva = false` en SQLite sin borrar al usuario — ver `usuarioNotifier.md`.
- **`ref.invalidate(...)`** (agregado el 2026-08-15, ver el bug correspondiente en `decisiones_arquitectura.md`): fuerza a que cada provider vuelva a su estado inicial (`build()` devuelve `[]`) la próxima vez que algo lo lea. Sin esto, un invitado nuevo (creado después de cerrar sesión) podía ver por un momento — o de forma persistente en `AgendaScreen`, por una condición de carrera con `mascotasProvider` — datos del invitado anterior, porque estos providers son globales y no se "resetean" solos solo por navegar a otra pantalla.
- **`pushAndRemoveUntil(..., (route) => false)`**: a diferencia del `pushReplacement` que usan `LoginScreen` y `SesionInicialScreen` (que reemplazan solo la pantalla actual), acá hace falta vaciar **todo** el stack de navegación — si solo se reemplazara `AjustesScreen`, `NavegacionPrincipalScreen` seguiría debajo y el botón "atrás" desde `LoginScreen` volvería a una sesión que ya se cerró. El callback `(route) => false` le dice "no conserves ninguna ruta anterior".
- **`rootNavigator: true`**: desde el 2026-08-12, `AjustesScreen` se abre empujada dentro del `Navigator` propio de la pestaña activa (ver `navegacionPrincipalScreen.md`), no en el `Navigator` de toda la app. Sin este parámetro, `Navigator.of(context)` resolvería al `Navigator` de esa pestaña, y `pushAndRemoveUntil` solo vaciaría la pila de esa pestaña — `LoginScreen` quedaría empujado ahí adentro, con la barra inferior del shell todavía visible alrededor. `rootNavigator: true` fuerza a que apunte siempre al `Navigator` más externo (el de `MaterialApp`), sin importar desde qué pestaña se haya abierto esta pantalla.
