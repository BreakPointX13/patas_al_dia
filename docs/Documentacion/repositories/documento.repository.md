# Nota de Obsidian: `DocumentoRepository`

## 📁 Ubicación en el Proyecto

`lib/data/repositories/documento_repository.dart`

## 🎯 Propósito del Archivo

Implementa el patrón Repository para la entidad `Documento`: concentra las operaciones CRUD sobre la tabla `documentos` (carnets, exámenes, recetas y demás archivos adjuntos a una mascota). Es la tabla con el esquema de relaciones más rico del proyecto: depende de `mascotas` de forma obligatoria y, opcionalmente, de `agenda_eventos`.

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Cuando una tabla tiene más de una foreign key, es común que el repository termine ofreciendo varias formas de consultar el mismo dato: "todos los documentos de esta mascota", "todos los documentos de este evento en particular", "documentos próximos a vencer". Cada una de esas vistas suele mapear a un método distinto, todos apoyados en la misma tabla base.

### 🐾 En Nuestro Proyecto "Patas al día"

Por ahora `DocumentoRepository` solo cubre la consulta por `mascota_id` (la vista principal: "todos los documentos de esta mascota") además del CRUD por `id`. La consulta por `evento_id` (documentos asociados a un evento puntual, como la boleta de una vacuna) y la de vencimientos próximos (usando `fecha_vencimiento` y `recordatorio_vencimiento`) quedan pendientes para cuando se construya la pantalla de documentos — se agregan como métodos nuevos sobre este mismo repository, sin tocar los que ya existen.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** El manejo de archivos adjuntos (PDFs, imágenes) suele delegarse enteramente a un servicio de Storage (S3, Firebase Storage), y la base de datos solo guarda la URL.
- **Nuestro Enfoque:** Local-first: `filePath` apunta a una ruta local en el dispositivo mientras el usuario sea invitado. El campo `sincronizadoNube` (booleano) es la marca que indica si ese archivo ya se subió a Supabase Storage — la migración de local a nube se hará más adelante, sin cambiar el esquema de esta tabla.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `crearDocumento(DocumentoModel documento)`

- **Definición Estándar:** Operación **Create** — `INSERT INTO documentos`.
- **En Nuestro Proyecto:** Mismo patrón que el resto de los repositories: `db.insert('documentos', documento.toMap())`. El nombre de tabla (`documentos`) y el de cada columna deben coincidir exactamente con los definidos en `DatabaseHelper._onCreate` — como son strings, un error de tipeo acá no lo detecta el compilador, solo se ve en tiempo de ejecución.

### 2. `obtenerDocumentosPorMascota(String mascotaId)`

- **Definición Estándar:** Operación **Read** filtrada — el equivalente a `SELECT * FROM documentos WHERE mascota_id = ?`.
- **En Nuestro Proyecto:** Mismo patrón que `obtenerAgendaEventoPorMascota`: `db.query()` con `where`/`whereArgs` parametrizado y conversión con `maps.map((mapa) => DocumentoModel.fromMap(mapa)).toList()`. Es la consulta que alimenta la pantalla "documentos de esta mascota".

### 3. `obtenerDocumentoPorId(String id)`

- **Definición Estándar:** Operación **Read** de un único registro por clave primaria.
- **En Nuestro Proyecto:** Devuelve `Future<DocumentoModel?>` (nullable), con el mismo patrón de retorno temprano (`if (maps.isEmpty) return null;`) usado en el resto de los repositories, para evitar el `StateError` de llamar `.first` sobre una lista vacía.

### 4. `actualizarDocumento(DocumentoModel documento)`

- **Definición Estándar:** Operación **Update** — `UPDATE documentos SET ... WHERE id = ?`.
- **En Nuestro Proyecto:** Usa `db.update('documentos', documento.toMap(), where: 'id = ?', whereArgs: [documento.id])`. Este método será el que marque `sincronizadoNube = true` una vez que el archivo se suba a Supabase Storage.

### 5. `eliminarDocumento(String id)`

- **Definición Estándar:** Operación **Delete** — `DELETE FROM documentos WHERE id = ?`.
- **En Nuestro Proyecto:** Usa `db.delete('documentos', where: 'id = ?', whereArgs: [id])`. A diferencia de eliminar una mascota o un evento (que arrastran documentos en cascada o los desvinculan), eliminar un documento es una operación de un solo nivel: no tiene ninguna tabla hija que dependa de él en el esquema actual.
