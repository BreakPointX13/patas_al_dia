# Nota de Obsidian: `UsuarioNotifier` y `usuarioProvider`

## 📁 Ubicación en el Proyecto

`lib/providers/usuario_provider.dart` (parte inferior del archivo, después de `usuarioRepositoryProvider`)

## 🎯 Propósito del Archivo

Es la "pizarra" del usuario actual: mantiene en memoria el usuario que está usando la app en este momento (invitado o registrado), y se actualiza sola cuando se crea, edita o elimina.

**A diferencia de `MascotasNotifier`, `AgendaEventoNotifier` y `DocumentoNotifier`, este NO maneja una lista.** La tabla `usuarios` es la raíz del esquema — la app solo necesita saber "quién es el usuario actual", no una colección de usuarios. Por eso el estado es `UsuarioModel?` (un único objeto, o `null` si todavía no se cargó ninguno), no `List<UsuarioModel>`.

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Es común que el "usuario actual" de una app se maneje con un estado de tipo objeto único nullable (o un enum de "estado de sesión": sin sesión / invitado / autenticado), en vez de una colección — porque conceptualmente solo puede haber un usuario activo en el dispositivo a la vez.

### 🐾 En Nuestro Proyecto "Patas al día"

`UsuarioNotifier` extiende `Notifier<UsuarioModel?>` en vez de `Notifier<List<UsuarioModel>>`. Esto simplifica bastante los métodos: como no hay lista que recorrer, no hace falta ni el operador spread (`...`), ni `.map()`, ni `.where()` — cada método simplemente **reemplaza el objeto completo**.

### 🔄 Comparativa y Ventajas Técnicas

- **Los otros tres Notifiers:** necesitan reconstruir la lista entera con cada cambio, preservando los elementos que no cambiaron.
- **`UsuarioNotifier`:** no hay nada que preservar — al no ser una colección, "actualizar" y "crear" terminan siendo la misma operación desde el punto de vista del estado (`state = usuario;`), aunque llamen a métodos distintos del repository por debajo.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `build()` devuelve `null`, no `[]`

```dart
@override
UsuarioModel? build() {
  return null;
}
```

El estado inicial es "todavía no hay usuario cargado" — a diferencia de los Notifiers de lista, donde el estado inicial vacío es `[]` (una lista sin elementos, pero una lista al fin).

### 2. `cargarUsuario(String id)`, `crearUsuario(UsuarioModel usuario)`, `actualizarUsuario(UsuarioModel usuario)`

```dart
Future<void> crearUsuario(UsuarioModel usuario) async {
  final repo = ref.read(usuarioRepositoryProvider);
  await repo.crearUsuario(usuario);
  state = usuario;
}
```

Los tres siguen la misma estructura de tres pasos que ya conocemos (pedir repository → operar contra la base → actualizar `state`), pero el último paso es siempre un reemplazo directo (`state = usuario` o `state = await repo.obtenerUsuarioPorId(id)`), nunca una reconstrucción de lista.

### 3. `cargarSesionActiva()` y `cerrarSesion()`

```dart
Future<bool> cargarSesionActiva() async {
  final repo = ref.read(usuarioRepositoryProvider);
  state = await repo.obtenerUsuarioConSesionActiva();
  return state != null;
}

Future<void> cerrarSesion() async {
  if (state == null) {
    return;
  }

  final repo = ref.read(usuarioRepositoryProvider);
  await repo.actualizarUsuario(state!.copyWith(sesionActiva: false));
  state = null;
}
```

- **`cargarSesionActiva()`**: la llama `SesionInicialScreen` una sola vez al arrancar la app. Devuelve `bool` (no solo actualiza `state`) porque quien la llama necesita decidir, en el mismo `await`, a qué pantalla navegar — `true` si había un usuario con sesión activa (va a `HomeScreen`), `false` si no (va a `LoginScreen`).
- **`cerrarSesion()`**: a diferencia de `eliminarUsuario()`, **no borra** la fila de `usuarios` — usa `actualizarUsuario` con `copyWith(sesionActiva: false)` para conservar los datos del invitado (por si vuelve a entrar), y solo después limpia el `state` en memoria. Mismo patrón de retorno temprano que `eliminarUsuario()` para evitar operar sobre un `state` nulo.

### 4. `eliminarUsuario()` — sin parámetros, con retorno temprano

```dart
Future<void> eliminarUsuario() async {
  if (state == null) {
    return;
  }

  final repo = ref.read(usuarioRepositoryProvider);
  await repo.eliminarUsuario(state!.id);
  state = null;
}
```

El más particular de los cuatro:
- **No recibe ningún argumento** — a diferencia de `eliminarMascota(String id)` (que sí recibe el id de *cuál* mascota borrar de la lista), acá solo puede haber un usuario en `state`, así que no hace falta indicar cuál.
- **Retorno temprano (`if (state == null) return;`)** — evita intentar borrar algo que no existe.
- **El operador `!` en `state!.id`** — le dice a Dart "en este punto estoy seguro de que `state` no es `null`" (porque el `if` de arriba ya lo garantizó). Es distinto de `!=` (desigualdad): acá el `!` va *después* de una variable para "desenvolverla" de su nulabilidad, no antes de una expresión para negarla.
- **Orden importa:** `state = null;` va al final, después de usar `state!.id` — si se pusiera antes, `state!.id` fallaría en tiempo de ejecución porque ya no habría nada que desenvolver.

### 5. `actualizarEscalaTexto(double escalaTexto)` (2026-08-18)

```dart
Future<void> actualizarEscalaTexto(double escalaTexto) async {
  if (state == null) {
    return;
  }
  await actualizarUsuario(state!.copyWith(escalaTexto: escalaTexto));
}
```

Método de conveniencia sobre `actualizarUsuario` — en vez de que cada pantalla que necesite cambiar el tamaño de letra tenga que escribir `ref.read(usuarioProvider.notifier).actualizarUsuario(usuario.copyWith(escalaTexto: ...))` a mano (y acordarse de manejar el caso `state == null`), esto lo encapsula en un solo método con un nombre que dice qué hace. Ver el uso en `ajustesScreen.md` y cómo se aplica globalmente en `main.dart`.

### 6. `actualizarTema(String tema)` (2026-08-18)

```dart
Future<void> actualizarTema(String tema) async {
  if (state == null) {
    return;
  }
  await actualizarUsuario(state!.copyWith(tema: tema));
}
```

Mismo patrón exacto que `actualizarEscalaTexto` — método de conveniencia sobre `actualizarUsuario`, para la preferencia de modo claro/oscuro/sistema. Ver `ajustesScreen.md` y `temaApp.md`.

### 7. `actualizarIdioma(String idioma)` (2026-08-18)

Mismo patrón otra vez, esta vez para la preferencia de idioma (`'sistema'`/`'es'`/`'en'`/`'pt'`). Ver `sistemaIdiomas.md`.

### 8. `marcarAvisoMapaVisto()` (2026-08-19)

```dart
Future<void> marcarAvisoMapaVisto() async {
  if (state == null) {
    return;
  }
  await actualizarUsuario(state!.copyWith(avisoMapaVisto: true));
}
```

Mismo patrón otra vez, pero sin parámetro — a diferencia de `actualizarTema`/`actualizarIdioma` (que reciben el valor nuevo desde afuera, porque el usuario elige entre varias opciones), acá solo hay una dirección posible (`false` → `true`, nunca al revés desde la UI), así que no hace falta recibir nada. Lo llama `MapaScreen` después de que el usuario cierra el diálogo de política de uso — ver `mapaScreen.md`.
