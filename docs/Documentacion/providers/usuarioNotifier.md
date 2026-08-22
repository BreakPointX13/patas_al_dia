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

### 2. `crearUsuario(UsuarioModel usuario)`, `actualizarUsuario(UsuarioModel usuario)`

```dart
Future<void> crearUsuario(UsuarioModel usuario) async {
  final repo = ref.read(usuarioRepositoryProvider);
  await repo.crearUsuario(usuario);
  state = usuario;
}
```

Los dos siguen la misma estructura de tres pasos que ya conocemos (pedir repository → operar contra la base → actualizar `state`), pero el último paso es siempre un reemplazo directo (`state = usuario`), nunca una reconstrucción de lista.

`cargarUsuario(String id)` (`state = await repo.obtenerUsuarioPorId(id)`) existía acá también, pero se borró el 2026-08-21 por código muerto — nunca tuvo ningún llamador; el arranque de sesión siempre pasa por `cargarSesionActiva()` (punto 3) o por `_activarSesionLocal()` (login/registro/recuperación). El método del repository que usaba, `obtenerUsuarioPorId`, sigue en uso desde otro lado (`convertirAInvitadoRegistrado`), así que no se tocó. Ver `decisiones_arquitectura.md`.

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
  if (!state!.esInvitado) {
    await repo.cerrarSesionSupabase();
  }
  await repo.actualizarUsuario(state!.copyWith(sesionActiva: false));
  state = null;
}
```

- **`cargarSesionActiva()`**: la llama `SesionInicialScreen` una sola vez al arrancar la app. Devuelve `bool` (no solo actualiza `state`) porque quien la llama necesita decidir, en el mismo `await`, a qué pantalla navegar — `true` si había un usuario con sesión activa (va a `HomeScreen`), `false` si no (va a `LoginScreen`).
- **`cerrarSesion()`**: a diferencia de `eliminarUsuario()`, **no borra** la fila de `usuarios` — usa `actualizarUsuario` con `copyWith(sesionActiva: false)` para conservar los datos (por si vuelve a entrar), y solo después limpia el `state` en memoria. Mismo patrón de retorno temprano que `eliminarUsuario()` para evitar operar sobre un `state` nulo. **Desde Login real (2026-08-19):** si el usuario no es invitado, primero cierra también la sesión real de Supabase Auth (`repo.cerrarSesionSupabase()`) — un invitado puede tener una sesión anónima de Supabase de paso (creada por el módulo Mapa), pero esa sesión no tiene relación con su id local, así que no se toca en ese caso.

### 4. `eliminarUsuario()` — "Eliminar cuenta" (2026-08-19, antes sin usar desde ninguna UI)

```dart
Future<void> eliminarUsuario() async {
  if (state == null) {
    return;
  }

  final repo = ref.read(usuarioRepositoryProvider);
  if (!state!.esInvitado) {
    await repo.eliminarCuentaSupabase();
    await repo.cerrarSesionSupabase();
  }
  await repo.eliminarUsuario(state!.id);
  state = null;
}
```

Existía desde antes (CRUD base), pero nunca estuvo conectado a ningún botón de la UI hasta "Eliminar cuenta" en `AjustesScreen` (ver `ajustesScreen.md`) — se extendió en el lugar en vez de crear un método nuevo, porque ya hacía exactamente lo que hacía falta para un invitado (borrar la fila local).

**Para un usuario registrado, primero borra la cuenta remota — y si eso falla, no se borra nada local.** `eliminarCuentaSupabase()` (ver `usuario.repository.md`, punto 6c) puede fallar (sin conexión, error del servidor) — como es un `await` normal, una excepción ahí interrumpe el método entero, antes de llegar a `repo.eliminarUsuario(state!.id)`. Es una decisión deliberada: mejor dejar la cuenta remota y los datos locales intactos (que el usuario pueda reintentar) que borrar los datos del dispositivo mientras la cuenta remota sigue existiendo, un estado a medio camino confuso de recuperar.

**Con `PRAGMA foreign_keys` ya activado (ver `database.helper.md`, punto 8b), `repo.eliminarUsuario(state!.id)` ahora sí borra en cascada** — mascotas, agenda, documentos y reportes locales de esa cuenta desaparecen con la fila de `usuarios`, no antes de esta fecha.

El resto del método sigue siendo particular por lo mismo que ya notaba esta sección:
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

### 9. `registrarUsuario({email, password})` (2026-08-19)

```dart
Future<void> registrarUsuario({required String email, required String password}) async {
  final repo = ref.read(usuarioRepositoryProvider);
  final respuesta = await repo.registrarConEmail(email: email, password: password);
  if (respuesta.user?.identities?.isEmpty ?? false) {
    throw const AuthException('El correo ya está registrado', code: 'user_already_exists');
  }
  final nuevoId = respuesta.user!.id;
  if (state != null) {
    state = await repo.convertirAInvitadoRegistrado(invitadoActual: state!, nuevoId: nuevoId, email: email);
  } else {
    final nuevo = UsuarioModel(id: nuevoId, email: email, esInvitado: false);
    await repo.crearUsuario(nuevo);
    state = nuevo;
  }
}
```

Primer método del provider que orquesta Supabase Auth + SQLite local en el mismo lugar — hasta ahora todos hablaban solo de SQLite. Cubre las dos formas de llegar acá (ver `registroScreen.md`): con un invitado ya usando la app (`state != null`, se convierte conservando sus datos vía `convertirAInvitadoRegistrado`) o sin ningún usuario local todavía (`state == null`, se crea uno nuevo desde cero).

**El chequeo de `identities?.isEmpty`** cubre un caso particular de Supabase: con "Confirm email" activado, registrarse con un correo que **ya tiene una cuenta confirmada** no devuelve ningún error (por diseño, para no revelar si un correo existe o no) — devuelve una respuesta de "éxito" sin sesión, y la única señal real de que no pasó nada nuevo es que `identities` viene vacío. Sin este chequeo, se terminaría llamando a `convertirAInvitadoRegistrado` con el `auth.uid()` de otra cuenta (la que ya existía), reasignando los datos locales a un id ajeno sin haber verificado nada. Se lanza un `AuthException` propio con `code: 'user_already_exists'` para que caiga en el mismo camino de manejo de errores que cualquier otro fallo de Auth (ver `errorAutenticacion.md`).

### 10. `iniciarSesion({email, password})` (2026-08-19)

```dart
Future<void> iniciarSesion({required String email, required String password}) async {
  final repo = ref.read(usuarioRepositoryProvider);
  final respuesta = await repo.iniciarSesionConEmail(email: email, password: password);
  final id = respuesta.user!.id;
  final existente = await repo.obtenerUsuarioPorId(id);
  if (existente != null) {
    final reactivado = existente.copyWith(sesionActiva: true);
    await repo.actualizarUsuario(reactivado);
    state = reactivado;
  } else {
    final nuevo = UsuarioModel(id: id, email: email, esInvitado: false);
    await repo.crearUsuario(nuevo);
    state = nuevo;
  }
}
```

Como el id local es el mismo `auth.uid()` de Supabase (ver `convertirAInvitadoRegistrado`), buscar `existente` por ese id alcanza para distinguir dos casos: **mismo dispositivo de siempre** (ya había una fila local con ese id, solo estaba con `sesionActiva = false` — se reactiva tal cual, con todos sus datos intactos) o **dispositivo nuevo** (no hay fila local todavía — se crea una vacía). El segundo caso queda "vacío" a propósito: no hay Sync todavía, así que las mascotas que esa cuenta tenga guardadas en otro dispositivo no aparecen acá hasta que esa fase se implemente — ver `decisiones_arquitectura.md`.

**Refactorizado (mismo día) en `_activarSesionLocal({id, email})`** — este bloque de "buscar existente, reactivar o crear vacío" pasó a un método privado compartido, porque `completarRecuperacion` (punto 11) necesita exactamente la misma lógica al final. `iniciarSesion` quedó reducida a `final respuesta = ...; await _activarSesionLocal(id: respuesta.user!.id, email: email);`.

### 11. `completarRecuperacion({nuevaContrasena})` (2026-08-19, con enlace — sin `email`/`codigo`)

```dart
Future<void> completarRecuperacion({required String nuevaContrasena}) async {
  final repo = ref.read(usuarioRepositoryProvider);
  await repo.actualizarContrasena(nuevaContrasena);
  final usuarioSupabase = Supabase.instance.client.auth.currentUser!;
  await _activarSesionLocal(id: usuarioSupabase.id, email: usuarioSupabase.email!);
}
```

Último paso de "olvidé mi contraseña" (ver `recuperarContrasenaScreen.md`, `nuevaContrasenaScreen.md` y `usuario.repository.md`, punto 6b). **Sin parámetros `email`/`codigo`** (a diferencia de la versión descartada con código de 6 dígitos) — cuando esto se llama, el enlace del correo ya estableció una sesión de recuperación válida (capturada en `main.dart`), así que `Supabase.instance.client.auth.currentUser` ya tiene el `id`/`email` de la cuenta, no hace falta que la pantalla los vuelva a pasar. De ahí en más es exactamente lo mismo que un login exitoso, por eso reusa `_activarSesionLocal` en vez de repetir la lógica de "buscar o crear" otra vez.

### 12. `cambiarContrasena({contrasenaActual, nuevaContrasena})` (2026-08-21, retoque post-Sync)

```dart
Future<void> cambiarContrasena({
  required String contrasenaActual,
  required String nuevaContrasena,
}) async {
  final repo = ref.read(usuarioRepositoryProvider);
  await repo.iniciarSesionConEmail(email: state!.email!, password: contrasenaActual);
  await repo.actualizarContrasena(nuevaContrasena);
}
```

Usado por `CambiarContrasenaScreen` (ver `cambiarContrasenaScreen.md`) — a diferencia del punto 11, acá **sí** hace falta probar la identidad antes de aceptar el cambio, porque no hay ningún enlace de correo de por medio: solo una sesión ya iniciada en el teléfono. Reautentica con `iniciarSesionConEmail` (mismo método que usa `iniciarSesion()`, punto 10) usando la contraseña que el usuario escribe como "actual" — si está mal, Supabase la rechaza con `invalid_credentials` y la excepción sube tal cual hasta la pantalla, sin llegar nunca a `actualizarContrasena`. `state!.email!` reusa el correo de la sesión ya activa, no hace falta pedirlo de nuevo.
