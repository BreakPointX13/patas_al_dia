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

Por ahora `UsuarioRepository` implementa solo el CRUD base (create, read, update, delete) sin lógica de migración — la lógica de "convertir invitado en registrado" y la sincronización con Supabase quedan para cuando se implemente el backend cloud (ver sección "Backend cloud" en `CLAUDE.md`). Esta clase es la base sobre la que se construirá esa lógica más adelante.

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

### 4. `eliminarUsuario(String id)`

- **Definición Estándar:** Operación **Delete** — `DELETE FROM usuarios WHERE id = ?`.
- **En Nuestro Proyecto:** Igual que en `MascotaRepository.eliminarMascota`, se apoya en el `ON DELETE CASCADE` definido en `DatabaseHelper`: borrar un usuario elimina automáticamente, a nivel de motor SQLite, todas sus mascotas (y en cadena, los eventos/documentos/reportes de esas mascotas). Es la operación más destructiva del esquema — en la UI final debería requerir confirmación explícita del usuario.
