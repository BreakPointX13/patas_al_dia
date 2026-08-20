# Nota de Obsidian: `UsuarioRepository`

## 📁 Ubicación en el Proyecto

`lib/data/repositories/usuario_repository.dart`

## 🎯 Propósito del Archivo

Implementa el patrón Repository para la entidad `Usuario`: concentra las operaciones CRUD sobre la tabla `usuarios`, la única tabla del esquema que no depende de ninguna otra (todas las demás cuelgan de ella vía `usuario_id` o transitivamente). Es la base del login híbrido invitado/registrado.

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

En apps con login híbrido (invitado + cuenta registrada), el repository de usuario suele ser el más sensible de todos: además de CRUD básico, típicamente coordina la transición de "invitado" a "registrado" (migrar datos locales a una cuenta real) y el flag de sincronización. Un error acá puede duplicar datos o perder el vínculo entre el usuario local y el remoto.

### 🐾 En Nuestro Proyecto "Patas al día"

Desde Login real (2026-08-19, ver `decisiones_arquitectura.md`), `UsuarioRepository` ya no es solo CRUD base: también envuelve las llamadas a Supabase Auth (registrar, iniciar sesión, cerrar sesión — ver puntos 6-8) y la lógica de "convertir invitado en registrado" (punto 9). La sincronización del resto de los datos (mascotas/agenda/documentos) con Supabase sigue pendiente, fase aparte.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** El repository de usuario suele mezclarse con la lógica de autenticación (login, tokens, sesiones).
- **Nuestro Enfoque:** Lo mantenemos puramente como acceso a datos (CRUD sobre SQLite). La lógica de "quién está logueado ahora" y el manejo de sesión van a vivir en la capa de estado (`providers`/`bloc`, aún por definir), no acá — separación de responsabilidades.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `crearUsuario(UsuarioModel usuario)`

- **Definición Estándar:** Operación **Create** — `INSERT INTO usuarios`.
- **En Nuestro Proyecto:** Idéntica en estructura a `MascotaRepository.crearMascota`: usa `usuario.toMap()` y `db.insert()`. El `id` (UUID) y el flag `esInvitado` ya vienen resueltos en el `UsuarioModel` antes de llegar acá — este método no decide si el usuario es invitado o no, solo persiste lo que recibe.

### 2. `obtenerUsuarioPorId(String id)`

- **Definición Estándar:** Operación **Read** de un único registro por clave primaria.
- **En Nuestro Proyecto:** Mismo patrón que `MascotaRepository.obtenerMascotaPorId` — devuelve `Future<UsuarioModel?>` (nullable) porque el `id` buscado podría no existir. Usa el retorno temprano (`if (maps.isEmpty) return null;`) antes de convertir `maps.first`.
- **Nota:** A diferencia de `mascotas`, la tabla `usuarios` no tiene una consulta equivalente a "obtener todos por usuario padre" — cada `UsuarioRepository` opera sobre un usuario a la vez, identificado por su propio `id`.

### 3. `actualizarUsuario(UsuarioModel usuario)`

- **Definición Estándar:** Operación **Update** — `UPDATE usuarios SET ... WHERE id = ?`.
- **En Nuestro Proyecto:** Usa `db.update('usuarios', usuario.toMap(), where: 'id = ?', whereArgs: [usuario.id])`, devolviendo `Future<int>` con la cantidad de filas afectadas. Este método será clave más adelante para actualizar `ultimaSincronizacion` cada vez que el usuario sincronice con Supabase, y para setear `esInvitado = false` cuando un invitado se registre.

### 4. `obtenerUsuarioConSesionActiva()`

- **Definición Estándar:** Operación **Read** de un único registro, pero filtrando por un flag de estado (`sesion_activa = 1`) en vez de por clave primaria.
- **En Nuestro Proyecto:** Igual estructura que `obtenerUsuarioPorId`, cambiando el `where`. `limit: 1` es solo una salvaguarda — en el diseño actual de un único usuario por dispositivo, nunca debería haber más de una fila con `sesion_activa = 1` a la vez. La usa `SesionInicialScreen` al arrancar la app para decidir si saltar `LoginScreen`.

### 5. `eliminarUsuario(String id)`

- **Definición Estándar:** Operación **Delete** — `DELETE FROM usuarios WHERE id = ?`.
- **En Nuestro Proyecto:** Igual que en `MascotaRepository.eliminarMascota`, se apoya en el `ON DELETE CASCADE` definido en `DatabaseHelper`. **Hallazgo del 2026-08-19 (Login real), corregido el mismo día al implementar "Eliminar cuenta":** `database_helper.dart` no activaba `PRAGMA foreign_keys = ON` — sin eso, SQLite no aplicaba ningún `ON DELETE CASCADE` declarado en el schema, así que este método (y `eliminarMascota`) en realidad dejaban huérfanas las filas hijas en vez de borrarlas en cascada. Ya corregido (ver `database.helper.md`, punto 8b) — ahora sí borra en cascada de verdad.

### 6. `registrarConEmail`, `iniciarSesionConEmail`, `cerrarSesionSupabase` (2026-08-19)

```dart
Future<AuthResponse> registrarConEmail({required String email, required String password}) {
  return Supabase.instance.client.auth.signUp(email: email, password: password);
}
Future<AuthResponse> iniciarSesionConEmail({required String email, required String password}) {
  return Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
}
Future<void> cerrarSesionSupabase() {
  return Supabase.instance.client.auth.signOut();
}
```

Los tres son envoltorios finos de `Supabase.instance.client.auth` — ninguno atrapa excepciones (`AuthException` se propaga tal cual), mismo criterio que el resto del proyecto con Supabase: quien llama decide qué mensaje mostrar (ver `errores_autenticacion.dart` / `errorAutenticacion.md`). Login real (2026-08-19) es la primera vez que este repository habla con Supabase — hasta ahora solo tocaba SQLite local.

### 6c. `eliminarCuentaSupabase` — llama a una Edge Function, no a la API de Auth directo (2026-08-19)

```dart
Future<void> eliminarCuentaSupabase() async {
  await Supabase.instance.client.functions.invoke('eliminar-cuenta');
}
```

A diferencia de los otros métodos de esta sección, este **no** llama a `Supabase.instance.client.auth` directo — no existe ninguna operación de cliente para "borrar mi propia cuenta". Borrar una cuenta de Supabase Auth (`auth.admin.deleteUser`) exige la "service_role key", una clave secreta con permisos totales sobre el proyecto que **nunca** puede viajar en el código de una app (a diferencia de la "publishable key" que sí vive en `supabase_config.dart`, ver `supabaseConfig.md`, punto 1). Por eso esto invoca una **Edge Function** (`supabase/functions/eliminar-cuenta/index.ts`, ver `eliminarCuentaFunction.md`) — código que corre en el servidor de Supabase, donde esa clave sí está disponible de forma segura.

`functions.invoke(...)` adjunta solo el JWT de la sesión activa como header `Authorization` — la función del lado del servidor usa ese JWT para saber a quién borrar (nunca recibe un id como parámetro), así que ni siquiera un usuario malicioso con la app modificada podría pedir borrar la cuenta de otra persona.

### 6b. `enviarCorreoRecuperacion`, `actualizarContrasena` (2026-08-19, con enlace — no código)

```dart
Future<void> enviarCorreoRecuperacion(String email) {
  return Supabase.instance.client.auth.resetPasswordForEmail(email, redirectTo: supabaseRedirectRecuperarContrasena);
}
Future<void> actualizarContrasena(String nuevaContrasena) {
  return Supabase.instance.client.auth.updateUser(UserAttributes(password: nuevaContrasena));
}
```

"Olvidé mi contraseña" — la primera versión de este método usaba un código de 6 dígitos (`verifyOTP`), pero se descartó al descubrir que editar la plantilla de correo (necesario para mostrar el código) exige tener SMTP propio configurado en Supabase — sin eso, el texto del correo queda fijo con el enlace por defecto. Se optó por el enlace, con `redirectTo` apuntando al esquema propio (`patasaldia://reset-password`, ver `supabase_config.dart`) — eso sí exige deep linking nativo (`AndroidManifest.xml`/`Info.plist`), lo mismo que se había evitado para el login normal, pero acá no había alternativa sin sumar infraestructura de correo. Ver `decisiones_arquitectura.md` y `recuperarContrasenaScreen.md`.

`actualizarContrasena` exige tener una sesión activa (lanza `AuthSessionMissingException` si no la hay) — la deja el propio enlace al abrirse (ver `nuevaContrasenaScreen.md`, punto 1), no un método aparte de este repository.

### 7. `convertirAInvitadoRegistrado` — no se puede actualizar el id, así que se recrea la fila (2026-08-19)

```dart
Future<UsuarioModel> convertirAInvitadoRegistrado({
  required UsuarioModel invitadoActual,
  required String nuevoId,
  required String email,
}) async {
  final nuevoUsuario = invitadoActual.copyWith(id: nuevoId, email: email, esInvitado: false, fechaRegistro: DateTime.now());
  await db.transaction((txn) async {
    await txn.insert('usuarios', nuevoUsuario.toMap());
    await txn.update('mascotas', {'usuario_id': nuevoId}, where: 'usuario_id = ?', whereArgs: [invitadoActual.id]);
    await txn.delete('usuarios', where: 'id = ?', whereArgs: [invitadoActual.id]);
  });
  return nuevoUsuario;
}
```

Implementa la decisión de "unificar ids" de Login real (ver `decisiones_arquitectura.md`): al registrarse, el `id` local pasa a ser el mismo `auth.uid()` de Supabase, para que Sync (la fase siguiente) no tenga que traducir entre dos sistemas de ids.

- **Por qué no es un `UPDATE usuarios SET id = ?`:** `id` es la clave primaria de `usuarios`, referenciada por `mascotas.usuario_id` — sin `ON UPDATE CASCADE` en el schema (y sin `PRAGMA foreign_keys` activado siquiera, ver punto 5), actualizar la PK en el lugar dejaría a `mascotas` apuntando a un id que ya no existe. Se opta por insertar la fila nueva, reasignar las mascotas, y recién borrar la vieja.
- **`db.transaction(...)`:** las tres operaciones tienen que ser atómicas — si el proceso se interrumpe entre el `insert` y el `delete`, quedaría una fila de usuario duplicada (o mascotas apuntando a un id ya borrado). `sqflite` revierte todo el bloque si cualquier operación adentro lanza una excepción.
- **Toca `mascotas`, una tabla que no es "suya":** es la única excepción a que este repository solo hable de `usuarios` — `mascotas` es la única tabla del schema con una referencia directa a `usuarios.id` (agenda/documentos/reportes cuelgan de `mascotas`, no de `usuarios`), así que reasignarla tiene que vivir en la misma transacción que el resto, no en un método aparte de `MascotaRepository` (rompería la atomicidad).
- **Se copian los campos del invitado** (`copyWith` sobre `invitadoActual`, no un `UsuarioModel` nuevo desde cero) — tema, idioma, escala de texto y `avisoMapaVisto` sobreviven a la conversión, solo cambian `id`/`email`/`esInvitado`/`fechaRegistro`.
