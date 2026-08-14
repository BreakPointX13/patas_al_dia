# Nota de Obsidian: `SesionInicialScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/sesion_inicial_screen.dart`

Es el `home` de `MaterialApp` en `main.dart` — la primera pantalla que se construye al abrir la app, antes que `LoginScreen` o `NavegacionPrincipalScreen`.

## 🎯 Propósito del Archivo

Decide, en cada arranque de la app, a qué pantalla ir: consulta si hay un usuario con `sesionActiva = true` guardado en SQLite (vía `UsuarioNotifier.cargarSesionActiva()`) y navega a `NavegacionPrincipalScreen` si lo hay, o a `LoginScreen` si no. Resuelve el bug original que motivó esta pantalla: antes, `LoginScreen` era el `home` fijo, así que cada reapertura de la app creaba un usuario invitado nuevo y las mascotas del usuario anterior quedaban sin sesión que las mostrara.

Desde el 2026-08-12 apunta a `NavegacionPrincipalScreen` (ver `navegacionPrincipalScreen.md`) en vez de a `HomeScreen` directo — esta pantalla solo decide *si* hay sesión activa, no *qué pestaña* mostrar primero; eso lo decide `NavegacionPrincipalScreen` por sí sola, sin recibir ningún parámetro.

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Es el patrón "splash / auth gate": una pantalla intermedia, casi siempre invisible para el usuario (dura milisegundos con SQLite local), que resuelve de forma asíncrona si hay una sesión guardada antes de decidir la primera pantalla real. Evita mostrar login a alguien que ya "inició sesión" antes.

### 🐾 En Nuestro Proyecto "Patas al día"

Es un `ConsumerStatefulWidget` porque necesita ejecutar código asíncrono **una sola vez** al arrancar (igual razón que `HomeScreen` es `ConsumerStatefulWidget` y no `ConsumerWidget`), y mientras tanto mostrar algo en pantalla (`CircularProgressIndicator`).

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `WidgetsBinding.instance.addPostFrameCallback`

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) => _verificarSesion());
}
```

A diferencia de `HomeScreen` (que llama a `ref.read(...)` directo en `initState`), acá se espera al primer frame renderizado antes de disparar la consulta. No es estrictamente necesario para esta lógica en particular, pero es la forma segura de disparar navegación (`Navigator.of(context)...`) desde `initState`, porque garantiza que el `BuildContext` ya está completamente montado en el árbol de widgets.

### 2. `_verificarSesion()`

```dart
Future<void> _verificarSesion() async {
  final haySesionActiva = await ref.read(usuarioProvider.notifier).cargarSesionActiva();

  if (!mounted) {
    return;
  }

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => haySesionActiva
          ? const NavegacionPrincipalScreen()
          : const LoginScreen(),
    ),
  );
}
```

- **`cargarSesionActiva()`** ya deja el usuario cargado en `usuarioProvider` si existe — así `HomeScreen` (pestaña Mascotas dentro de `NavegacionPrincipalScreen`) no necesita volver a buscarlo, `ref.read(usuarioProvider)!.id` en su `initState` ya lo encuentra listo.
- **`if (!mounted) return;`**: mismo motivo que el `if (!context.mounted)` de `LoginScreen` — guarda de seguridad después de un `await`.
- **`pushReplacement`**: esta pantalla de decisión nunca debe quedar en el stack de navegación (no tiene sentido volver a ella con el botón "atrás").
