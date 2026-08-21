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
- **Nuestro Enfoque:** Local-first: `filePath` es **local-only** (`String?`, ver punto 7) — nunca viaja a Supabase ni se sobreescribe con un pull, así el dispositivo de origen sigue mostrando el archivo al instante sin depender de la red. `archivoRutaNube` (agregado en Sync, 2026-08-20, reemplaza al viejo `sincronizadoNube` booleano que nunca se llegó a usar) guarda la ruta del archivo dentro del bucket de Storage una vez subido.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `crearDocumento(DocumentoModel documento)`

- **Definición Estándar:** Operación **Create** — `INSERT INTO documentos`.
- **En Nuestro Proyecto:** Mismo patrón que el resto de los repositories: `db.insert('documentos', documento.toMap())`. El nombre de tabla (`documentos`) y el de cada columna deben coincidir exactamente con los definidos en `DatabaseHelper._onCreate` — como son strings, un error de tipeo acá no lo detecta el compilador, solo se ve en tiempo de ejecución.

### 2. `obtenerDocumentosPorMascota(String mascotaId)`

- **Definición Estándar:** Operación **Read** filtrada — el equivalente a `SELECT * FROM documentos WHERE mascota_id = ?`.
- **En Nuestro Proyecto:** Mismo patrón que `obtenerAgendaEventoPorMascota`: `db.query()` con `where`/`whereArgs` parametrizado y conversión con `maps.map((mapa) => DocumentoModel.fromMap(mapa)).toList()`. Es la consulta que alimenta la pantalla "documentos de esta mascota".

### 3. `obtenerDocumentosPorEvento(String eventoId)`

- **Definición Estándar:** Operación **Read** filtrada por la foreign key opcional — `SELECT * FROM documentos WHERE evento_id = ?`.
- **En Nuestro Proyecto:** Agregado el 2026-08-14 para que `FormularioAgendaEventoScreen` y `DetalleAgendaEventoScreen` puedan mostrar solo los documentos adjuntos a un evento puntual (ej. la receta que se adjuntó desde esa consulta), en vez de todos los documentos de la mascota. Mismo patrón `where`/`whereArgs` que el resto de las consultas.

### 3b. `obtenerEventoIdsConDocumento(List<String> eventoIds)` (2026-08-16)

- **Definición Estándar:** consulta agregada — `SELECT DISTINCT evento_id FROM documentos WHERE evento_id IN (...)`, devolviendo solo las claves, no las filas completas.
- **En Nuestro Proyecto:** Devuelve `Set<String>` (no `List<DocumentoModel>`) porque a quien la llama (`AgendaScreen`, ver `agendaScreen.md`) solo le importa el booleano "¿este evento tiene algún documento adjunto?" para pintar un chip en el timeline — traer los documentos completos hubiera sido desperdiciar memoria y ancho de banda para un dato que no se muestra. Se arma el `IN (...)` con `List.filled(eventoIds.length, '?').join(',')` como placeholders y `whereArgs: eventoIds`, evitando concatenar los ids directo en el SQL. Devuelve un `Set` vacío sin tocar la base si `eventoIds` viene vacío (puede pasar si la mascota filtrada todavía no tiene ningún evento cargado).

### 4. `obtenerDocumentoPorId(String id)`

- **Definición Estándar:** Operación **Read** de un único registro por clave primaria.
- **En Nuestro Proyecto:** Devuelve `Future<DocumentoModel?>` (nullable), con el mismo patrón de retorno temprano (`if (maps.isEmpty) return null;`) usado en el resto de los repositories, para evitar el `StateError` de llamar `.first` sobre una lista vacía.

### 5. `actualizarDocumento(DocumentoModel documento)`

- **Definición Estándar:** Operación **Update** — `UPDATE documentos SET ... WHERE id = ?`.
- **En Nuestro Proyecto:** Usa `db.update('documentos', documento.toMap(), where: 'id = ?', whereArgs: [documento.id])`. Desde Sync (2026-08-20/21), agrega `actualizadoEn: DateTime.now().toUtc()` y `pendiente_push = 1` al mapa antes de escribir (ver punto 7).

### 6. `eliminarDocumento(String id)` — soft-delete desde Sync (2026-08-20, corrige esta nota)

- **Ya no es un `DELETE` real** — ver `mascota.repository.md`, punto 5, para el porqué general. Sigue siendo una operación de un solo nivel (sin tabla hija que dependa de `documentos`), así que el cambio es simple: `UPDATE documentos SET eliminado = 1, eliminado_en = ?, actualizado_en = ?, pendiente_push = 1 WHERE id = ?`.

### 7. Sync (2026-08-20/21) — `pendiente_push`, `obtenerPendientesDePush`, `marcarComoSincronizadas`, `guardarDesdeSync`, `actualizarArchivoRutaNube`

Mismo patrón que `MascotaRepository` — ver `mascota.repository.md`, puntos 6-9, para el detalle completo (incluido el bug real que `obtenerPendientesDePush` corrige, encontrado probando el checkpoint de la Fase 3 de Sync). Acá el usuario se resuelve vía join a `mascotas` (no hay `usuario_id` directo en esta tabla). `actualizarArchivoRutaNube(id, ruta)` es el equivalente de `actualizarFotoRutaNube` — se usa justo después de subir el archivo, sin tocar `pendiente_push`, por el mismo motivo (evitar que un `upsert` fallido justo después deje la fila marcada como sincronizada sin haber llegado a Supabase).

### 8. `subirArchivo` / `descargarArchivo` — Storage (2026-08-20)

Bucket privado `archivos_documentos` — mismo patrón que `fotos_mascotas` (ver `mascota.repository.md`, punto 10): ruta `usuarioId/documentoId.ext`, 4 políticas (select/insert/update/delete), `archivo_ruta_nube` guarda la ruta del bucket, no una URL (bucket privado, sin URL pública estable). Ver `TablaMaestraAppVetMovil1.sql`, sección 9, y `syncService.md`.
