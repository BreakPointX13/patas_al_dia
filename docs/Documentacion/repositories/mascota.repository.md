# Nota de Obsidian: `MascotaRepository`

## 📁 Ubicación en el Proyecto

`lib/data/repositories/mascota_repository.dart`

## 🎯 Propósito del Archivo

Esta clase implementa el **patrón Repository** para la entidad `Mascota`: concentra en un único lugar todas las operaciones CRUD (Crear, Leer, Actualizar, Eliminar) que interactúan con la tabla `mascotas` de SQLite. Es la capa intermedia entre `DatabaseHelper` (que solo abre la conexión) y las futuras pantallas/providers, que nunca deberían escribir SQL directamente.

---

## 🗺️ Mapa de Conexión Conceptual (Repository Pattern)

### 🏛️ En un Proyecto Estándar de la Industria

El **Repository Pattern** es uno de los patrones más usados en arquitectura de software: aísla la lógica de negocio de los detalles de persistencia (SQL, API REST, archivos, etc.). En vez de que un widget o un provider ejecute consultas SQL directamente, le pide al repository "dame las mascotas de este usuario" o "guarda esta mascota", sin saber ni importar si por debajo hay SQLite, una API en la nube o un archivo JSON. Esto permite, por ejemplo, cambiar de SQLite a Supabase en el futuro tocando solo el repository, sin modificar ni una línea de la UI.

### 🐾 En Nuestro Proyecto "Patas al día"

`MascotaRepository` es la única clase que le habla directamente a la tabla `mascotas` a través de `DatabaseHelper.instance.database`. Expone cinco métodos, uno por operación CRUD, todos trabajando con `MascotaModel` (nunca con `Map<String, dynamic>` crudo) hacia afuera. Esto significa que cuando construyamos las pantallas de mascotas, van a llamar a `MascotaRepository().obtenerMascotasPorUsuario(id)` y van a recibir objetos Dart ya tipados, listos para usar.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** Muchas apps grandes agregan una interfaz abstracta (`abstract class MascotaRepositoryInterface`) para poder inyectar repositorios falsos (mocks) en tests, y frameworks como Riverpod la usan para el patrón de inyección de dependencias.
- **Nuestro Enfoque:** Al ser un proyecto en construcción y sin necesidad aún de tests con mocks, implementamos el repository de forma concreta y directa. El día que agreguemos tests o cambiemos de motor de datos, esta clase concentra el único punto de cambio necesario.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `crearMascota(MascotaModel mascota)`

- **Definición Estándar:** Operación **Create** del CRUD. En SQL equivale a un `INSERT INTO`.
- **En Nuestro Proyecto:** Usa `db.insert('mascotas', mascota.toMap())` — reutiliza el `toMap()` que ya construimos en el modelo, así el repository no necesita saber los nombres exactos de las columnas.
- **Nota:** Devuelve el mismo objeto `mascota` que recibió, no un nuevo objeto leído de la base. Esto asume que el `id` ya viene generado (UUID) desde antes de llamar a este método.

### 2. `obtenerMascotasPorUsuario(String usuarioId)`

- **Definición Estándar:** Operación **Read** filtrada — el equivalente a `SELECT * FROM mascotas WHERE usuario_id = ?`.
- **En Nuestro Proyecto:** Usa `db.query()` con `where: 'usuario_id = ?'` y `whereArgs: [usuarioId]`. El uso de `?` en vez de concatenar el valor directamente en el string previene **inyección SQL** — `sqflite` escapa el valor de `whereArgs` de forma segura.
- **Lógica Compleja — Mapeo de Colección:** `db.query()` siempre devuelve `List<Map<String, dynamic>>`, sin importar cuántas columnas tenga la tabla. Convertimos esa lista cruda a `List<MascotaModel>` con `maps.map((mapa) => MascotaModel.fromMap(mapa)).toList()`: `.map()` aplica `fromMap` a cada fila, y `.toList()` materializa el resultado (por defecto `.map()` devuelve un `Iterable` perezoso que no se puede indexar ni recorrer dos veces).

### 3. `obtenerMascotaPorId(String id)`

- **Definición Estándar:** Operación **Read** de un único registro por clave primaria — el equivalente a `SELECT * FROM mascotas WHERE id = ? LIMIT 1`.
- **En Nuestro Proyecto:** A diferencia del método anterior, este devuelve `Future<MascotaModel?>` (nullable), porque el `id` buscado podría no existir en la tabla.
- **Lógica Compleja — Retorno Temprano (Early Return):** Como `db.query()` siempre devuelve una lista aunque busques por un id único, el método primero chequea `if (maps.isEmpty) { return null; }` antes de intentar leer un elemento. Sin este chequeo, `maps.first` en una lista vacía lanzaría una excepción (`StateError`) en tiempo de ejecución. Recién si la lista no está vacía, se convierte `maps.first` con `MascotaModel.fromMap(...)`.

### 4. `actualizarMascota(MascotaModel mascota)`

- **Definición Estándar:** Operación **Update** — el equivalente a `UPDATE mascotas SET ... WHERE id = ?`.
- **En Nuestro Proyecto:** Usa `db.update('mascotas', mascota.toMap(), where: 'id = ?', whereArgs: [mascota.id])`. A diferencia de `crearMascota`, acá el `where` es obligatorio: sin él, `db.update()` sobrescribiría **todas** las filas de la tabla con los mismos valores.
- **Valor de Retorno:** Devuelve `Future<int>` — la cantidad de filas afectadas por la actualización. Un valor `0` indica que ese `id` no existía en la tabla (útil para detectar errores silenciosos más adelante, por ejemplo si se intenta actualizar una mascota ya eliminada).

### 5. `eliminarMascota(String id)` — soft-delete desde Sync (2026-08-20, corrige esta nota)

- **Ya no es un `DELETE` real.** Sync (ver más abajo, punto 8, y `syncService.md`) necesita que un borrado se pueda "empujar" a otro dispositivo — un `DELETE` no deja ningún rastro que sincronizar. Se reemplazó por una transacción manual (`db.transaction`) con `UPDATE ... SET eliminado = 1, eliminado_en = ?, actualizado_en = ?, pendiente_push = 1`, en cuatro tablas: `mascotas`, `agenda_eventos`, `medicamentos_evento` y `documentos` (todas las filas hijas de esta mascota).
- **Por qué no alcanza con el `ON DELETE CASCADE` real del schema:** ese cascade (ver `database.helper.md`, punto 8b) sigue activo y sigue siendo correcto para un `DELETE` de verdad, pero acá no se ejecuta ningún `DELETE` — el soft-delete tiene que imitar a mano el mismo alcance (mascota + su agenda + los medicamentos de esa agenda + sus documentos), porque un `UPDATE` no dispara ninguna cascada de foreign keys.
- **Transacción explícita, no repositories separados:** las cuatro escrituras corren dentro de `db.transaction((txn) async {...})`, con `txn.rawUpdate` directo sobre cada tabla — mismo patrón ya usado en `UsuarioRepository.convertirAInvitadoRegistrado` — para que las cuatro sean atómicas (o se aplican las cuatro, o ninguna).
- **Las filas "borradas" se siguen leyendo:** `obtenerMascotasPorUsuario` filtra `eliminado = 0` (no las muestra en la UI), pero `obtenerMascotaPorId` no filtra por `eliminado` a propósito — el motor de sync necesita poder encontrar y comparar una fila localmente borrada al resolver conflictos.

### 6. `obtenerPendientesDePush(String usuarioId)` (2026-08-21, reemplaza a `obtenerModificadosDesde`)

- **El problema que reemplaza:** la primera versión de este método filtraba por fecha (`actualizado_en > desde`) para decidir qué empujar a Supabase. Eso mezclaba dos cosas distintas: "esto lo edité yo en este dispositivo" y "esto tiene una fecha reciente" — una fila recién *traída* por pull también tiene una fecha reciente, así que el dispositivo la volvía a empujar en la corrida siguiente, sin comparar contra lo que hubiera en Supabase en ese momento, pisando cualquier edición más nueva que hubiera llegado de otro lado mientras tanto. Encontrado probando el checkpoint de la Fase 3 del plan de Sync — ver `decisiones_arquitectura.md`.
- **La solución:** columna `pendiente_push INTEGER DEFAULT 0`, que es la única fuente de verdad de "esto lo tocó este dispositivo y todavía no se subió". Este método pasó a ser `SELECT * FROM mascotas WHERE usuario_id = ? AND pendiente_push = 1`, sin ningún parámetro de fecha.
- **Sin filtrar por `eliminado`**, mismo motivo que `obtenerMascotaPorId`: una mascota borrada también necesita empujarse (para que el borrado llegue a otro dispositivo).

### 7. `marcarComoSincronizadas(List<String> ids)` (2026-08-21)

Apaga `pendiente_push` (`UPDATE mascotas SET pendiente_push = 0 WHERE id IN (...)`) para las filas que se acaban de subir con éxito. `sync_service.dart` lo llama siempre *después* de que el `upsert` a Supabase ya terminó sin error — si el `upsert` fallara, esta llamada nunca se ejecuta y la fila sigue con `pendiente_push = 1`, lista para reintentarse en la próxima corrida.

### 8. `guardarDesdeSync(MascotaModel mascota)` / `crearMascota` y `actualizarMascota` marcan `pendiente_push` (2026-08-20/21)

- **`crearMascota`/`actualizarMascota`** ahora estampan `actualizadoEn: DateTime.now().toUtc()` (ver el punto 9) y agregan `pendiente_push = 1` al mapa antes de escribir — cualquier edición hecha en este dispositivo queda marcada para subirse en la próxima sincronización.
- **`guardarDesdeSync`** es el método que usa el motor de sync para escribir una fila que **llegó** de Supabase (`db.insert(..., conflictAlgorithm: ConflictAlgorithm.replace)`, equivalente local del `upsert` remoto). A propósito no incluye `pendiente_push` en el mapa que escribe — como es un `INSERT OR REPLACE`, cualquier columna no mencionada queda en su `DEFAULT` (0), así que una fila recién traída por pull nace correctamente marcada como "no pendiente de push" (ya coincide con lo que hay en el servidor, no hay nada que reenviar).

### 9. `actualizarFotoRutaNube(String id, String ruta)` (2026-08-21)

Usado por el motor de sync justo después de subir una foto a Storage, para guardar la ruta del bucket (`foto_ruta_nube`) sin tocar `pendiente_push`. A propósito **no** usa `guardarDesdeSync` para esto: como ese método es un `REPLACE INTO`, pisaría `pendiente_push` con su `DEFAULT` (0) antes de que el `upsert` de la fila completa a Supabase termine — si ese `upsert` fallara justo después de subir la foto, la fila quedaría marcada como sincronizada sin haber llegado nunca a la tabla `mascotas` de Supabase. Un `UPDATE` puntual sobre una sola columna evita ese riesgo.

### 10. `subirFoto` / `descargarFoto` — Storage (2026-08-20)

Bucket privado `fotos_mascotas` (a diferencia de `fotos_reportes`, público — una foto de mascota es privada). Mismo patrón de ruta que `fotos_reportes` (`usuarioId/entidadId.ext`, ver `mascotaExtraviada.repository.md`), pero con 4 políticas en vez de 3: `upload(..., fileOptions: FileOptions(upsert: true))` (necesario porque editar la foto de una mascota vuelve a subir a la misma ruta) exige política de `update`, además de `select`/`insert`/`delete`. `foto_ruta_nube` guarda la **ruta dentro del bucket, no una URL** — un bucket privado no tiene URL pública estable (`getPublicUrl()` da 403); `descargarFoto` usa `.download(ruta)` en su lugar. Ver `TablaMaestraAppVetMovil1.sql`, sección 9, y `syncService.md`.
