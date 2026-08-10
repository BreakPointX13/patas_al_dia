# Nota de Obsidian: `AjustesScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/ajustes_screen.dart`

Se accede desde el ícono de engranaje del `AppBar` de `HomeScreen`.

## 🎯 Propósito del Archivo

Pantalla de ajustes de la app. Por ahora tiene una sola opción, "Cerrar sesión"; es el lugar natural donde agregar más adelante otras preferencias (notificaciones, cuenta, etc.) sin volver a tocar `HomeScreen`.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

`ConsumerWidget` (no necesita estado propio ni ciclo de vida, igual que `LoginScreen`). Usa `ListView` con un único `ListTile` en vez de una lista de botones sueltos, para que agregar más opciones a futuro sea directo (un `ListTile` más).

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `_cerrarSesion(BuildContext context, WidgetRef ref)`

```dart
Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
  await ref.read(usuarioProvider.notifier).cerrarSesion();

  if (!context.mounted) {
    return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginScreen()),
    (route) => false,
  );
}
```

- **`cerrarSesion()`** (en `UsuarioNotifier`) marca `sesionActiva = false` en SQLite sin borrar al usuario — ver `usuarioNotifier.md`.
- **`pushAndRemoveUntil(..., (route) => false)`**: a diferencia del `pushReplacement` que usan `LoginScreen` y `SesionInicialScreen` (que reemplazan solo la pantalla actual), acá hace falta vaciar **todo** el stack de navegación — si solo se reemplazara `AjustesScreen`, `HomeScreen` seguiría debajo y el botón "atrás" desde `LoginScreen` volvería a una sesión que ya se cerró. El callback `(route) => false` le dice "no conserves ninguna ruta anterior".
