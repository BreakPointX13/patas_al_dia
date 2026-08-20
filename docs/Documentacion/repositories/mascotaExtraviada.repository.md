# Nota de Obsidian: `MascotaExtraviadaRepository`

## 📁 Ubicación en el Proyecto

`lib/data/repositories/mascota_extraviada_repository.dart`

Primer repository del proyecto que no habla con `DatabaseHelper` (SQLite local), sino con `Supabase.instance.client` — ver `mascotaExtraviada.model.md` para el porqué.

## 🎯 Propósito del Archivo

CRUD sobre la tabla `mascotas_extraviadas` de Supabase, más `obtenerReportesActivos()` (la consulta que alimenta el mapa: solo reportes con `resuelto = false`) y `denunciarReporte()` (moderación manual, ver punto 6).

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
client.from('mascotas_extraviadas').select().eq('resuelto', false).order('fecha_publicacion', ascending: false);
```

La consulta principal del módulo: trae todos los reportes activos (`resuelto = false`), sin importar su `tipo` — un reporte "encontré una mascota" (`tipo = 'encontrado'`) es tan activo como uno "perdí mi mascota" hasta que alguien lo cierre, ver `mascotaExtraviada.model.md`, punto 4, para el porqué de este campo separado. Más recientes primero. Como la política de lectura es pública (`mascotas_extraviadas_lectura_publica`, `using (true)`), esta consulta funciona sin sesión — cualquiera puede ver el mapa, esté o no logueado.

### 3. `obtenerReportePorId(String id)`

Usa `.maybeSingle()` (de `supabase_flutter`) en vez de traer una lista y quedarse con el primero — devuelve directamente `Map<String, dynamic>?`, `null` si no existe. Mismo criterio de retorno nullable que `obtenerDocumentoPorId`.

### 4. `actualizarReporte(MascotaExtraviadaModel reporte)`

```dart
client.from('mascotas_extraviadas').update(reporte.toMap()).eq('id', reporte.id).select();
```

El `.select()` al final no es para leer datos — en `supabase_flutter`/PostgREST, un `update()` sin `.select()` no devuelve las filas afectadas, así que no hay forma de saber cuántas se actualizaron sin pedirlo explícitamente. Se usa acá solo para poder devolver `filasActualizadas.length`, mismo tipo de retorno (`Future<int>`) que `actualizarDocumento`/`actualizarMascota`. Sirve, por ejemplo, para marcar un reporte como resuelto: se llama con el mismo objeto pero `resuelto: true`.

### 5. `eliminarReporte(MascotaExtraviadaModel reporte)` — también borra la foto del bucket (2026-08-20)

```dart
Future<void> eliminarReporte(MascotaExtraviadaModel reporte) async {
  if (reporte.mascotaFotoUrl != null) {
    try {
      final extension = reporte.mascotaFotoUrl!.split('.').last;
      final rutaStorage = '${reporte.usuarioId}/${reporte.id}.$extension';
      await client.storage.from('fotos_reportes').remove([rutaStorage]);
    } catch (e) {
      debugPrint('DEBUG eliminarReporte: no se pudo borrar la foto del bucket: $e');
    }
  }
  await client.from('mascotas_extraviadas').delete().eq('id', reporte.id);
}
```

**Antes recibía solo el `id`** y hacía un único `delete()` sobre la fila — sin relaciones que dependan de ella (a diferencia de `mascotas`/`agenda_eventos`, acá no hay `ON DELETE CASCADE` de ninguna tabla hija), era una operación de un solo nivel, igual que `eliminarDocumento`.

**Hallazgo del 2026-08-20:** borrar la fila nunca tocaba la foto en Supabase Storage — la foto quedaba huérfana en el bucket `fotos_reportes` para siempre, ocupando espacio sin que nada la use (ver `decisiones_arquitectura.md`). Se corrigió recibiendo el `MascotaExtraviadaModel` completo (no solo el `id`) para poder reconstruir la ruta del archivo en el bucket (`usuarioId/reporteId.ext`, mismo patrón que arma `subirFoto`, ver punto 5b) y borrarlo antes de borrar la fila.

**El borrado de la foto es "best effort"** — envuelto en `try/catch` que solo hace `debugPrint` si falla, sin relanzar la excepción. Si el borrado de la foto fallara (sin conexión, política de RLS faltante, etc.), no debe bloquear el borrado del reporte en sí, que es la acción principal que pidió el usuario.

**Requiere una política de `delete` en `storage.objects`** que no existía hasta esta fecha — el bucket solo tenía políticas de lectura e inserción (ver `TablaMaestraAppVetMovil1.sql`, sección 7). Sin la política `fotos_reportes_borrar_dueno`, Supabase rechazaba el `remove(...)` por RLS, y como el error caía en el `catch` silencioso de arriba, el bug pasó desapercibido hasta probarlo a mano. La política nueva restringe el borrado al dueño de la foto: `(storage.foldername(name))[1] = auth.uid()::text` compara el primer segmento de la ruta (el `usuarioId`) contra la sesión actual.

### 5b. `subirFoto({usuarioId, reporteId, rutaLocal})` (2026-08-19)

```dart
Future<String> subirFoto({required String usuarioId, required String reporteId, required String rutaLocal}) async {
  final extension = rutaLocal.split('.').last;
  final rutaStorage = '$usuarioId/$reporteId.$extension';
  await client.storage.from('fotos_reportes').upload(rutaStorage, File(rutaLocal));
  return client.storage.from('fotos_reportes').getPublicUrl(rutaStorage);
}
```

Primer método del proyecto que habla con Supabase **Storage** en vez de la base de datos (`client.storage` en vez de `client.from(...)`). Sube la foto obligatoria del reporte (ver `formularioReporteMascotaExtraviadaScreen.md`, punto 6) al bucket `fotos_reportes` (creado junto con sus políticas en `TablaMaestraAppVetMovil1.sql`, sección 7) y devuelve la URL pública resultante — como el bucket es de lectura pública, esa URL sirve tal cual para mostrar la imagen sin volver a autenticarse (ver `detalleReporteMascotaExtraviadaScreen.md`).

**La ruta `usuarioId/reporteId.ext` no tiene ningún efecto sobre permisos** — la política de subida (`fotos_reportes_subir_autenticado`) solo exige `auth.uid() is not null`, no valida la ruta en sí. Es simplemente para mantener las fotos ordenadas por usuario y evitar que el nombre de archivo choque entre reportes distintos (dos reportes con el mismo `reporteId` es imposible por ser un UUID, pero dos usuarios subiendo una foto llamada igual en su galería sí podría chocar sin el prefijo).

**Se llama antes de `crearReporte()`, no después:** `FormularioReporteMascotaExtraviadaScreen._publicarReporte()` sube la foto primero y recién arma el `MascotaExtraviadaModel` con la URL resultante en `mascotaFotoUrl` — necesita que la subida ya haya terminado (y no haya fallado) antes de insertar la fila.

### 6. `denunciarReporte(String reporteId)` (2026-08-19)

```dart
Future<void> denunciarReporte(String reporteId) async {
  final usuarioId = await obtenerUsuarioIdSupabase();
  try {
    await client.from('denuncias_reportes').insert({'id': const Uuid().v4(), 'reporte_id': reporteId, 'usuario_id': usuarioId});
  } on PostgrestException catch (e) {
    if (e.code != '23505') rethrow;
  }
}
```

Primera pieza de la moderación manual del módulo (ver `decisiones_arquitectura.md`, "Moderación de contenido"): registra "quién denunció qué reporte" en `denuncias_reportes`, sin motivo de texto libre (decisión del usuario) — el desarrollador revisa el reporte denunciado directo desde el panel de Supabase, no hace falta más contexto.

- **Sí crea sesión, a diferencia del resto de las lecturas:** `denunciarReporte` llama a `obtenerUsuarioIdSupabase()` (que crea una sesión anónima si todavía no existe) — a diferencia de leer/ver reportes, denunciar exige saber quién es el usuario, por la restricción `unique (reporte_id, usuario_id)` de la tabla (ver el `.sql`).
- **`'23505'` — código estándar de Postgres para violación de restricción única.** Si el mismo usuario intenta denunciar el mismo reporte dos veces, la base rechaza el segundo insert con este código; se ignora silenciosamente en vez de propagar el error, porque para quien denuncia el resultado que le importa (que el reporte quede denunciado) ya se cumplió la primera vez — no hace falta que se entere de si era su primer o segundo intento.
