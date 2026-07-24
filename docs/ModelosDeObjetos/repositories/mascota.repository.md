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

### 5. `eliminarMascota(String id)`

- **Definición Estándar:** Operación **Delete** — el equivalente a `DELETE FROM mascotas WHERE id = ?`.
- **En Nuestro Proyecto:** Usa `db.delete('mascotas', where: 'id = ?', whereArgs: [id])`, estructuralmente casi idéntico a `actualizarMascota` pero sin el mapa de valores nuevos (no hace falta, porque se borra la fila entera).
- **Efecto en Cascada:** Como la tabla `mascotas` fue creada con `FOREIGN KEY (mascota_id) REFERENCES mascotas (id) ON DELETE CASCADE` en `agenda_eventos`, `documentos` y `mascotas_extraviadas`, eliminar una mascota borra automáticamente todos sus eventos, documentos y reportes asociados a nivel de motor SQLite, sin que este repository tenga que orquestar esas eliminaciones manualmente.
