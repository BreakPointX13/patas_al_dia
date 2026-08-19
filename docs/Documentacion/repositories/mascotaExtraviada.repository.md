# Nota de Obsidian: `MascotaExtraviadaRepository`

## 📁 Ubicación en el Proyecto

`lib/data/repositories/mascota_extraviada_repository.dart`

Primer repository del proyecto que no habla con `DatabaseHelper` (SQLite local), sino con `Supabase.instance.client` — ver `mascotaExtraviada.model.md` para el porqué.

## 🎯 Propósito del Archivo

CRUD sobre la tabla `mascotas_extraviadas` de Supabase, más `obtenerReportesActivos()` (la consulta que alimenta el mapa: solo reportes con `estado = 'perdido'`).

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Mismo patrón exacto que el resto de los repositories (`DocumentoRepository`, etc.) — cada método abre su propio acceso a la fuente de datos y hace una sola operación, sin estado propio en la clase. La única diferencia real es la fuente: `Supabase.instance.client.from('mascotas_extraviadas')...` en vez de `db.query('mascotas_extraviadas', ...)`. `supabase_flutter` ya devuelve `List<Map<String, dynamic>>`/`Map<String, dynamic>?`, así que `MascotaExtraviadaModel.fromMap`/`.toMap()` se usan exactamente igual que en un repository de SQLite.

### 🔄 Por qué no hay manejo de errores acá

Igual que el resto de los repositories del proyecto (que no atrapan excepciones de `sqflite`), este tampoco atrapa errores de red de Supabase — se dejan propagar tal cual. Es una decisión consultada con el usuario: el aviso de "sin conexión" en la pantalla de Mapa se resuelve de forma reactiva (intentar la consulta y, si falla, mostrar el aviso), no con un paquete de detección de conectividad — así que el repository debe dejar pasar el error, no silenciarlo, para que la pantalla pueda reaccionar a él.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `crearReporte(MascotaExtraviadaModel reporte)`

Operación **Create** — `client.from('mascotas_extraviadas').insert(reporte.toMap())`. La política de RLS `mascotas_extraviadas_insertar_dueno` exige que `usuario_id` del reporte coincida con `auth.uid()` de la sesión activa (ver `TablaMaestraAppVetMovil1.sql`) — si el reporte se arma con un `usuarioId` que no es el del usuario logueado (aunque sea invitado, vía Anonymous Sign-ins), Supabase rechaza el insert.

### 2. `obtenerReportesActivos()`

```dart
client.from('mascotas_extraviadas').select().eq('estado', 'perdido').order('fecha_publicacion', ascending: false);
```

La consulta principal del módulo: trae todos los reportes con `estado = 'perdido'` (no los ya marcados `'encontrado'`), más recientes primero. Como la política de lectura es pública (`mascotas_extraviadas_lectura_publica`, `using (true)`), esta consulta funciona sin sesión — cualquiera puede ver el mapa, esté o no logueado.

### 3. `obtenerReportePorId(String id)`

Usa `.maybeSingle()` (de `supabase_flutter`) en vez de traer una lista y quedarse con el primero — devuelve directamente `Map<String, dynamic>?`, `null` si no existe. Mismo criterio de retorno nullable que `obtenerDocumentoPorId`.

### 4. `actualizarReporte(MascotaExtraviadaModel reporte)`

```dart
client.from('mascotas_extraviadas').update(reporte.toMap()).eq('id', reporte.id).select();
```

El `.select()` al final no es para leer datos — en `supabase_flutter`/PostgREST, un `update()` sin `.select()` no devuelve las filas afectadas, así que no hay forma de saber cuántas se actualizaron sin pedirlo explícitamente. Se usa acá solo para poder devolver `filasActualizadas.length`, mismo tipo de retorno (`Future<int>`) que `actualizarDocumento`/`actualizarMascota`. Sirve, por ejemplo, para marcar un reporte como `'encontrado'`: se llama con el mismo objeto pero `estado` cambiado.

### 5. `eliminarReporte(String id)`

```dart
client.from('mascotas_extraviadas').delete().eq('id', id);
```

Sin relaciones que dependan de esta fila (a diferencia de `mascotas`/`agenda_eventos`, acá no hay `ON DELETE CASCADE` de ninguna tabla hija) — es una operación de un solo nivel, igual que `eliminarDocumento`.
