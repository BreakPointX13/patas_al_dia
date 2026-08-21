# Nota de Obsidian: `SyncService`

## 📁 Ubicación en el Proyecto

`lib/services/sync_service.dart`

## 🎯 Propósito del Archivo

Es el motor de sincronización en dos sentidos entre la base local (SQLite) y Supabase (Postgres + Storage), para usuarios registrados (`esInvitado == false`). Antes de este archivo, un usuario registrado no tenía ninguna diferencia real frente a un invitado: sus mascotas, agenda, documentos y medicamentos vivían solo en el dispositivo donde se cargaron, sin respaldo ni forma de verlos desde otro teléfono. Es la Fase 6 (última fase grande) del plan de Supabase — ver `decisiones_arquitectura.md`, entrada del 2026-08-20/21.

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Sincronizar datos entre un dispositivo y un servidor en dos sentidos (no solo respaldo unidireccional) es uno de los problemas clásicos más difíciles de la ingeniería de software: hay que decidir qué pasa cuando el mismo dato cambió en dos lugares a la vez (resolución de conflictos), cómo se propaga un borrado sin dejar rastro "fantasma", y cómo evitar que un dispositivo reenvíe sin parar datos que ya están al día. Sistemas grandes (Google Drive, Notion) usan algoritmos de resolución de conflictos mucho más sofisticados (CRDTs, vector clocks); para una app de este tamaño, el estándar de la industria es un enfoque más simple: timestamp por fila + "gana el cambio más reciente".

### 🐾 En Nuestro Proyecto "Patas al día"

`SyncService` implementa exactamente ese enfoque simple, decidido explícitamente con el usuario antes de programar (ver `decisiones_arquitectura.md`): **dos sentidos, automático pero no instantáneo** (se agrupan cambios, no se sincroniza en cada tecla — ver `main.dart` para los tres disparadores), **sincroniza todo** (las 4 entidades del core, incluidos sus archivos — fotos, PDFs, no solo las filas de la base) y **gana el cambio más reciente** en un conflicto, sin merge manual ni avisos al usuario.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** Suele usarse una cola de cambios persistente (outbox pattern) con reintentos exponenciales y un servicio de sincronización que corre en segundo plano incluso con la app cerrada (WorkManager en Android, BGTaskScheduler en iOS).
- **Nuestro Enfoque:** Sin cola persistente aparte — la "cola" de lo que falta empujar *es* la tabla misma, filtrada por la columna `pendiente_push` (ver más abajo). Sin sincronización con la app cerrada — coherente con que el resto de la app tampoco depende de procesos en segundo plano (ver `pendientes_ios.md`), y con que el usuario explícitamente prefirió simplicidad por sobre cobertura total ("automático pero no instantáneo", no "en tiempo real").

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `sincronizar()` — punto de entrada único

```dart
Future<void> sincronizar() async {
  final usuario = _ref.read(usuarioProvider);
  if (usuario == null || usuario.esInvitado) return;
  if (_ref.read(sincronizandoProvider)) return; // ya hay una corrida en curso
  ...
}
```

- **Dos guardas antes de hacer nada:** invitado/sin sesión (un invitado no tiene identidad estable contra la cual sincronizar), y "ya hay una corrida en curso" — con tres disparadores automáticos independientes (ver `main.dart`), es perfectamente posible que el timer de 5 minutos y el evento de "app pasa a segundo plano" quieran dispararse casi al mismo tiempo; sin esta guarda, correrían dos sincronizaciones en paralelo, pisándose entre sí.
- **`sincronizandoProvider` cumple doble función** — ver `syncProvider.md`: señal visible para la UI ("Sincronizando...") y bandera de "corrida en curso", sin necesitar un flag privado aparte dentro de esta clase.

### 2. `_sincronizarInterno` — el paso 0 obligatorio (bootstrap de `usuarios`)

```dart
await client.from('usuarios').upsert({
  'id': usuarioId,
  'email': usuario?.email,
  'es_invitado': false,
});
```

- **Hallazgo real de la fase de diseño, no un ajuste menor:** `mascotas.usuario_id` tiene un `FOREIGN KEY` real hacia `public.usuarios(id)` en Postgres — no es solo una política de RLS contra `auth.uid()`. La tabla `public.usuarios` nunca se pobló durante Login real (documentado explícitamente como pendiente en esa fase, ver `decisiones_arquitectura.md`, entrada del 2026-08-19). Sin este paso, el primer `push` de una mascota de cualquier usuario fallaría siempre por violación de FK.
- **`upsert` parcial, no sincronizar preferencias:** solo escribe `id`/`email`/`es_invidado` — no toca `tema`/`idioma`/`escala_texto` ni ningún otro campo de preferencias. Esto no es "sincronizar el usuario", es lo mínimo para que el FK de `mascotas` no rechace la fila.
- **Si este paso falla, se aborta toda la corrida** (`return` inmediato, sin intentar ninguna de las 4 entidades) — sin la fila de `usuarios`, cualquier intento de `push` de una mascota fallaría igual, así que no vale la pena intentarlo.

### 3. Orden de las 4 entidades — Mascota → AgendaEvento → MedicamentoEvento → Documento

Es el mismo orden tanto al empujar como al traer, y no es arbitrario: es el orden seguro para los `FOREIGN KEY` del schema — un hijo nunca se procesa antes que su padre. Empujar un `AgendaEvento` antes que su `Mascota` fallaría por FK en Supabase; traer un `Documento` antes que su `Mascota` fallaría por FK en SQLite (`PRAGMA foreign_keys = ON`, ver `database.helper.md`, punto 8b).

### 4. Manejo de errores por entidad — `huboError`, no aborta todo

```dart
var huboError = false;
try { await _sincronizarMascotas(usuarioId, desde); }
catch (e) { debugPrint('DEBUG sync mascotas: $e'); huboError = true; }
// ... mismo patrón para las otras 3 entidades
if (huboError) return; // no avanza el reloj
```

- **Cada entidad tiene su propio `try/catch`:** si falla la red a mitad de `_sincronizarDocumentos` (por ejemplo), las 3 entidades anteriores ya alcanzaron a sincronizarse igual — no se pierde ese trabajo solo porque la última falló.
- **Si *cualquier* entidad falló, `ultimaSincronizacion` no avanza.** La ventana completa se reintenta en la próxima corrida — seguro de repetir porque tanto el `upsert` (empujar) como "gana el cambio más reciente" (traer) son idempotentes: repetir un `push`/`pull` que ya se hizo con éxito no cambia nada.

### 5. `pendiente_push` — qué se empuja, y el bug real que corrigió (2026-08-21)

```dart
final locales = await repo.obtenerPendientesDePush(usuarioId);
// ... push ...
await client.from('mascotas').upsert(payload);
await repo.marcarComoSincronizadas(aEmpujar.map((m) => m.id).toList());
```

- **Primera versión (Fase 1, no sobrevivió al checkpoint de la Fase 3):** decidía qué empujar filtrando `actualizado_en > desde` (la fecha de la última sincronización exitosa). Parecía razonable pero mezclaba dos cosas distintas: "esto lo edité yo en este dispositivo" y "esto tiene una fecha más reciente que la última sync" — una fila recién **traída** por pull también cumple esa segunda condición. Resultado real, reproducido probando el checkpoint: el dispositivo volvía a empujar una fila que acababa de traer, con su valor viejo, pisando sin darse cuenta una edición más nueva que hubiera llegado de otro dispositivo mientras tanto — justo lo que "gana el cambio más reciente" prometía evitar.
- **La solución:** columna `pendiente_push` (ver `database.helper.md`, punto 9), prendida solo por escrituras genuinamente locales (`crear`/`actualizar`/`eliminar` en los 4 repositories) y apagada solo por `marcarComoSincronizadas` (después de un `push` exitoso) o implícitamente por `guardarDesdeSync` (una fila que llega por pull nace con `pendiente_push` en su `DEFAULT`, 0 — ver punto 7). El `push` de cada entidad pasó de comparar fechas a un filtro directo: `WHERE pendiente_push = 1`.
- **`marcarComoSincronizadas` corre *después* del `upsert`, nunca antes** — si el `upsert` a Supabase falla, esta llamada nunca se ejecuta y la fila queda con `pendiente_push = 1`, lista para reintentarse en la corrida siguiente.

### 6. `_ganaElLocal` — resolución de conflictos en el *pull*

```dart
bool _ganaElLocal(DateTime? localEn, DateTime? remotoEn) {
  if (localEn == null || remotoEn == null) return false;
  return !remotoEn.isAfter(localEn);
}
```

- Se evalúa fila por fila, para cada resultado de `pull`: si el local es igual o más nuevo que el remoto, no hay nada que pisar (`continue`, se salta esa fila). Si el remoto es estrictamente más nuevo, gana — se aplica con `guardarDesdeSync`.
- **`localEn == null` (fila nunca vista en este dispositivo) siempre pierde** frente a cualquier remoto — no hay nada local que "defender" todavía.
- Esta comparación es sobre objetos `DateTime` de Dart, no sobre texto — a diferencia del filtro SQL de `pendiente_push`/`obtenerPendientesDePush` (que si comparara fechas como texto sería vulnerable al mismo bug de zona horaria del punto 5), `DateTime.isAfter()` compara correctamente sin importar si un valor es UTC y el otro no (ambos se resuelven a microsegundos desde época internamente). Aun así, **todos** los `actualizadoEn` se guardan en UTC de forma consistente (ver `mascota.model.md`, punto 7) — no por esta comparación puntual, sino por el filtro SQL de `push`, que si comparara fechas mezcladas sí daría resultados incorrectos.

### 7. Subida de archivos — "una sola vez", y por qué no usa `guardarDesdeSync`

```dart
if (m.fotoUrl != null && m.fotoRutaNube == null) {
  final ruta = await repo.subirFoto(usuarioId: usuarioId, mascotaId: m.id, rutaLocal: m.fotoUrl!);
  m = m.copyWith(fotoRutaNube: ruta);
  await repo.actualizarFotoRutaNube(m.id, ruta);
}
```

- **Condición `fotoRutaNube == null`:** la foto se sube una sola vez, no en cada sync — editar cualquier otro campo de la mascota no dispara una re-subida del mismo archivo. Limitación conocida y aceptada por simplicidad: reemplazar la foto más tarde no se detecta automáticamente (quedaría igual en Storage) — no había forma barata de detectar "el archivo cambió" sin comparar bytes o guardar un hash aparte, y no se justificó la complejidad para este caso.
- **`repo.actualizarFotoRutaNube`, no `repo.guardarDesdeSync`, para guardar la ruta subida** (2026-08-21, corrige un riesgo introducido por el propio fix del punto 5): `guardarDesdeSync` fija `pendiente_push = 0` explícitamente (ver `mascota.repository.md`, punto 8). Si se usara acá, apagaría `pendiente_push` a mitad de camino, **antes** de que el `upsert` de la fila completa a Supabase termine. Si ese `upsert` fallara justo después de subir la foto (ej. se cortó la red), la fila quedaría marcada como sincronizada sin que sus datos (nombre, especie, etc.) hubieran llegado nunca a la tabla `mascotas` de Supabase, y no se reintentaría en la corrida siguiente. `actualizarFotoRutaNube` hace un `UPDATE` puntual sobre una sola columna (`foto_ruta_nube`), sin tocar `pendiente_push`, evitando ese riesgo. Mismo patrón para `archivoRutaNube` en documentos (`actualizarArchivoRutaNube`).

### 10. `guardarDesdeSync` — de `INSERT OR REPLACE` a un upsert manual (2026-08-21, bug real de pérdida de datos)

Encontrado en la prueba final combinada del plan de Sync, probando varias entidades a la vez: editar una mascota desde "otro dispositivo" (simulado vía API) hacía que, al traerla por pull, sus eventos de agenda y documentos **locales** desaparecieran de verdad — no soft-delete, filas genuinamente borradas de SQLite, sin que el pull las hubiera tocado.

**Causa:** los 4 `guardarDesdeSync` (uno por repository) usaban `db.insert(tabla, mapa, conflictAlgorithm: ConflictAlgorithm.replace)`. En SQLite, `INSERT OR REPLACE` ante un conflicto de `PRIMARY KEY` no es un `UPDATE` disfrazado: primero **borra** la fila conflictiva y recién ahí inserta la nueva. Con `PRAGMA foreign_keys = ON` activo (ver `database.helper.md`, punto 8b), ese borrado oculto **sí** dispara las acciones de foreign key declaradas en el schema (`ON DELETE CASCADE` en `agenda_eventos`/`documentos` hacia `mascotas`, y en `medicamentos_evento` hacia `agenda_eventos`) — exactamente como si se hubiera hecho un `DELETE` explícito. Traer por pull la actualización de una mascota que ya tenía hijos locales los arrastraba a todos en una cascada real, sin que el código de sync lo hubiera pedido ni supiera que estaba pasando.

**Por qué no se detectó antes:** en las Fases 1 y 2, casi todas las filas traídas por pull eran **nuevas** para el dispositivo (primera vez que se veía ese `id`) — `REPLACE` solo borra cuando hay un conflicto real de PK, así que insertar una fila nunca vista antes nunca disparó la rama de borrado. Recién en la prueba final, al traer la actualización de una mascota que **ya tenía** agenda/documentos locales, se dio la condición exacta para activar el bug.

**Riesgo real, no solo cosmético:** si el dispositivo hubiera tenido una edición local de un hijo (un evento, un documento) todavía sin subir (`pendiente_push = 1`) en el momento exacto de un pull sobre su mascota padre, esa edición se habría perdido para siempre — nunca llegó a Supabase, y el borrado-cascada la eliminó localmente antes de que pudiera subirse.

**La solución:** los 4 `guardarDesdeSync` arman un upsert manual con SQL crudo — `INSERT INTO tabla (columnas...) VALUES (...) ON CONFLICT(id) DO UPDATE SET columna = excluded.columna, ...`. Ante una fila existente, esto ejecuta un `UPDATE` real (no un `DELETE` + `INSERT`), así que no dispara ninguna acción de foreign key. `pendiente_push` se fija en `0` de forma explícita en el mapa antes de armar la consulta (no se deja como columna omitida) — ver `mascota.repository.md`, punto 8, para el detalle completo y el porqué de ese seteo explícito.

### 8. Descarga de archivos — cuándo se dispara, y `fotoUrl`/`filePath` como campos local-only

```dart
var fotoUrlLocal = local?.fotoUrl;
if (remoto.fotoRutaNube != null && fotoUrlLocal == null) {
  final bytes = await repo.descargarFoto(remoto.fotoRutaNube!);
  ...
  fotoUrlLocal = rutaLocal;
}
await repo.guardarDesdeSync(remoto.copyWith(fotoUrl: fotoUrlLocal));
```

- **Por qué dos campos, no uno (`fotoUrl` vs `fotoRutaNube`):** `fotoUrl`/`filePath` quedan **local-only** — nunca se sobreescriben con un pull, así el dispositivo de origen sigue mostrando la foto al instante sin depender de la red. `fotoRutaNube`/`archivoRutaNube` viajan por el sync — cuando otro dispositivo trae la fila y no tiene el archivo todavía, lo descarga acá y recién ahí completa su propio `fotoUrl`/`filePath` local. Se descartó un solo campo "ruta o URL, se detecta al renderizar" — hubiera exigido tocar cada lugar que ya renderiza `FileImage(File(fotoUrl))` sin quitar la complejidad real, solo moverla.
- **Se descarga solo si `fotoUrlLocal` es `null`:** si el dispositivo ya tiene el archivo (aunque venga de antes de este sync), no se vuelve a descargar. Un fallo de descarga (red) se registra con `debugPrint` y no bloquea el resto del `pull` — la fila igual se guarda, con `fotoUrl: null`, y la descarga se reintenta en una corrida futura (mientras `fotoRutaNube` no sea `null` y `fotoUrl` local siga siendo `null`, la condición se vuelve a cumplir).
- **`fotoRutaNube`/`archivoRutaNube` guardan la ruta dentro del bucket, no una URL** — un bucket privado (`fotos_mascotas`, `archivos_documentos`, a diferencia del público `fotos_reportes`) no tiene URL pública estable; `getPublicUrl()` sobre un objeto privado da 403. `descargarFoto`/`descargarArchivo` usan `.download(ruta)` en su lugar.

### 9. Recarga de providers al final de una corrida exitosa

```dart
await _ref.read(mascotasProvider.notifier).cargarMascotas(usuarioId);
final mascotaIds = _ref.read(mascotasProvider).map((m) => m.id).toList();
await _ref.read(agendaEventosProvider.notifier).cargarAgendaEventosDeMascotas(mascotaIds);
```

`HomeScreen`/`AgendaScreen` viven en un `IndexedStack` (se construyen una sola vez en toda la vida de la app, ver `navegacionPrincipalScreen.md`) — sin esta recarga explícita, un cambio traído por sync quedaría invisible hasta reiniciar la app. `DocumentosScreen`/`DetalleAgendaEventoScreen` no lo necesitan: se instancian de nuevo cada vez que se navega a ellas, así que ya leen datos frescos solas.
