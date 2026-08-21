# Nota de Obsidian: `AgendaEventoRepository`

## 📁 Ubicación en el Proyecto

`lib/data/repositories/agenda_evento_repository.dart`

## 🎯 Propósito del Archivo

Implementa el patrón Repository para la entidad `AgendaEvento`: concentra las operaciones CRUD sobre la tabla `agenda_eventos` (vacunas, controles, tratamientos con recordatorio). A diferencia de `UsuarioRepository`, esta tabla cuelga de `mascotas` vía `mascota_id`, siguiendo el mismo esquema de dependencia que ya vimos en `MascotaRepository` (que a su vez cuelga de `usuarios`).

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Las tablas de "agenda" o "eventos programados" en apps de salud/veterinaria suelen ser las más consultadas por rango de fechas (próximos eventos, eventos vencidos, historial). El repository que las maneja normalmente expone consultas específicas por fecha además del CRUD básico, para poder alimentar vistas de calendario o notificaciones push.

### 🐾 En Nuestro Proyecto "Patas al día"

Por ahora `AgendaEventoRepository` cubre el CRUD base filtrando por `mascota_id` (para listar la agenda de una mascota puntual) y por `id` (para operar sobre un evento específico). Las consultas por rango de fecha (ej. "próximos 7 días" o "vencidos") quedan para cuando se construya la pantalla de agenda — se agregarán como métodos adicionales sobre este mismo repository, reutilizando el patrón `where`/`whereArgs` ya establecido.

Desde Sync (2026-08-20/21) suma además `obtenerPendientesDePush`/`marcarComoSincronizadas` (mismo criterio que `MascotaRepository`, ver `mascota.repository.md`, puntos 6-8) y `guardarDesdeSync` para el motor de sincronización — ver `syncService.md`.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** Muchas apps delegan el cálculo de "próxima repetición" (ej. recordar la próxima vacuna cada `N` meses) a un job en el backend o a una Cloud Function.
- **Nuestro Enfoque:** Como la app es local-first, ese cálculo va a vivir en Dart, probablemente como un método auxiliar sobre `AgendaEventoModel` o en la capa de providers, usando el campo `repetirCadaMeses` que ya existe en el modelo. El repository solo persiste el dato; no calcula fechas.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `crearAgendaEvento(AgendaEventoModel agendaEvento)`

- **Definición Estándar:** Operación **Create** — `INSERT INTO agenda_eventos`.
- **En Nuestro Proyecto:** Mismo patrón que `crearMascota`/`crearUsuario`: `db.insert('agenda_eventos', agendaEvento.toMap())`. El nombre de tabla debe coincidir exactamente con el definido en `DatabaseHelper._onCreate` (`agenda_eventos`, snake_case) — a diferencia de un nombre de clase o variable, SQLite no valida este string en tiempo de compilación, así que un typo acá solo se detecta en tiempo de ejecución.

### 2. `obtenerAgendaEventoPorMascota(String mascotaId)`

- **Definición Estándar:** Operación **Read** filtrada — el equivalente a `SELECT * FROM agenda_eventos WHERE mascota_id = ?`.
- **En Nuestro Proyecto:** Mismo patrón que `obtenerMascotasPorUsuario`: `db.query()` con `where`/`whereArgs` parametrizado (previene inyección SQL), y conversión de la lista cruda con `maps.map((mapa) => AgendaEventoModel.fromMap(mapa)).toList()`. Esta es la consulta que va a alimentar la pantalla de "agenda de esta mascota".

### 3. `obtenerAgendaEventoPorId(String id)`

- **Definición Estándar:** Operación **Read** de un único registro por clave primaria.
- **En Nuestro Proyecto:** Devuelve `Future<AgendaEventoModel?>` (nullable). Usa el patrón de retorno temprano: `if (maps.isEmpty) return null;` antes de convertir `maps.first`, evitando la excepción `StateError` que lanzaría `maps.first` sobre una lista vacía.

### 4. `actualizarAgendaEvento(AgendaEventoModel agendaEvento)`

- **Definición Estándar:** Operación **Update** — `UPDATE agenda_eventos SET ... WHERE id = ?`.
- **En Nuestro Proyecto:** Usa `db.update('agenda_eventos', agendaEvento.toMap(), where: 'id = ?', whereArgs: [agendaEvento.id])`. Este método es clave para marcar un evento como realizado: se actualiza `fechaRealizada` (hoy `null` hasta que la mascota reciba, por ejemplo, la vacuna).

### 5. `obtenerAgendaEventosPorMascotas(List<String> mascotaIds)`

- **Definición Estándar:** Operación **Read** filtrada con múltiples valores — el equivalente a `SELECT * FROM agenda_eventos WHERE mascota_id IN (?, ?, ...)`.
- **En Nuestro Proyecto:** Agregado el 2026-08-14 para alimentar la pestaña Agenda del navbar, que puede mostrar los eventos de **todas** las mascotas del usuario a la vez (o de un subconjunto elegido con el filtro), no solo de una. El número de `?` en la cláusula `IN (...)` se arma dinámicamente con `List.filled(mascotaIds.length, '?').join(',')`, y `whereArgs: mascotaIds` sigue estando parametrizado (sin concatenar los ids directo en el string SQL) — mismo nivel de seguridad que el resto de las queries del proyecto. Si `mascotaIds` está vacío, devuelve `[]` sin tocar la base de datos, para no ejecutar un `IN ()` inválido en SQL.

### 6. `eliminarAgendaEvento(String id)` — soft-delete desde Sync (2026-08-20, corrige esta nota)

- **Ya no es un `DELETE` real** — ver `mascota.repository.md`, punto 5, para el porqué general (Sync necesita que un borrado deje rastro para poder empujarlo). Acá la cascada **no es uniforme**, a diferencia de `eliminarMascota`:
  - `agenda_eventos` (el evento en sí) y `medicamentos_evento` (sus medicamentos) → soft-delete real (`eliminado = 1, eliminado_en = ?`), mismo `ON DELETE CASCADE` que tenía el schema.
  - `documentos` → **no** se soft-deletea. Solo `UPDATE documentos SET evento_id = NULL, ...`, preservando el `ON DELETE SET NULL` original: el documento sobrevive, solo se desvincula del evento (ej. la boleta de la vacuna no desaparece, deja de estar ligada a esa consulta puntual).
- **Las tres tablas suman `actualizado_en` y `pendiente_push = 1`** en la misma transacción — incluida `documentos`: desvincular un evento es un cambio real que también hay que empujar en el próximo sync, aunque esa fila no se haya "borrado".
