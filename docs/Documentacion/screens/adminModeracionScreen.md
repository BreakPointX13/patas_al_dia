# Nota de Obsidian: `AdminModeracionScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/admin_moderacion_screen.dart`

Se accede desde `AjustesScreen` — un ítem que solo aparece cuando `usuario.email == correoAdmin` (ver `supabase_config.dart`).

## 🎯 Propósito del Archivo

Tres pestañas de moderación del módulo Mapa (2026-08-25, ampliado 2026-09-27 — ver `decisiones_arquitectura.md`):

- **Denunciados**: reportes con al menos una denuncia, con la opción de borrarlos. Diseño original (reemplaza revisar/borrar a mano desde el Table Editor de Supabase).
- **Todos**: cualquier reporte activo, denunciado o no — el admin pidió poder actuar sobre cualquier reporte, no solo los ya denunciados por otros usuarios.
- **Bloqueados**: usuarios restringidos de publicar en el módulo, con opción de desbloquear.

Bloquear al autor de un reporte (botón nuevo, ícono `Icons.block`) está disponible desde las dos primeras pestañas, no solo desde "Bloqueados" — es la acción natural en el momento: el admin ve un reporte problemático y decide ahí mismo si además de borrarlo (o sin borrarlo) conviene restringir a quien lo publicó.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Solo un admin fijo, identificado por correo (no hay tabla de roles): `usuario.email == correoAdmin` en la app decide si se **muestra** el ítem en `AjustesScreen`, y la política RLS `denuncias_reportes_leer_admin` (compara `auth.jwt() ->> 'email'` contra el mismo correo, ver `TablaMaestraAppVetMovil1.sql`) decide si la consulta **funciona** del lado del servidor — la primera es solo UX, la segunda es la protección real. Lo mismo para borrar: la política `mascotas_extraviadas_borrar_dueno` se extendió para aceptar también al admin, no solo al dueño del reporte.

`ReporteDenunciado` y `UsuarioBloqueado` (en `mascota_extraviada_repository.dart`, no models aparte) empareja un `MascotaExtraviadaModel` con su conteo de denuncias, y un id de usuario con su fecha de bloqueo, respectivamente — ninguno de los dos encaja como campo del model existente.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. Listas ya resueltas en el estado (`List<T>?`), no `FutureBuilder` — cambiado 2026-09-27

```dart
List<ReporteDenunciado>? _denunciados;
List<MascotaExtraviadaModel>? _activos;
List<UsuarioBloqueado>? _bloqueados;
```

Pantalla de uso raro (un solo admin, no en el camino común de la app) — se decidió no construir un `AsyncNotifier` aparte solo para esto. `null` = todavía cargando, `[]` = cargó y no hay nada.

**Versión original (2026-08-25), con `FutureBuilder`:** cada pestaña guardaba un `Future` (`_futuroDenunciados`, etc.) reasignado con `setState` tras cada acción, confiando en que `FutureBuilder` detectara el `Future` nuevo y volviera a pedir los datos a Supabase. Un tester reportó que, tras borrar un reporte, la lista de esta misma pantalla no se refrescaba de forma confiable. Se cambió al patrón más directo: cada acción (`_eliminar`/`_bloquear`/`_desbloquear`) actualiza a mano la lista en memoria correspondiente (sacar o agregar un elemento) en el mismo `setState`, sin depender de ningún viaje de red nuevo ni de ninguna sutileza de cuándo `FutureBuilder` decide resuscribirse. Más simple, más inmediato, y sin la clase `FutureBuilder` de por medio.

### 1e. `_eliminar()` pasa por `mascotaExtraviadaProvider.notifier`, no por el repository directo — bug real: "el mapa no se actualiza" (2026-09-27)

```dart
await ref.read(mascotaExtraviadaProvider.notifier).eliminarReporte(reporte);
```

Antes llamaba a `ref.read(mascotaExtraviadaRepositoryProvider).eliminarReporte(reporte)` directo — borraba bien de Supabase, pero `mascotaExtraviadaProvider` (la copia en memoria que `MapaScreen` mira con `ref.watch`, ver `mapaScreen.md`) nunca se enteraba. Un tester reportó justo esto: borrar un reporte desde moderación no lo sacaba del mapa hasta cerrar y reabrir la app entera (recién ahí `cargarReportesActivos()` volvía a pedir la lista completa a Supabase, ya sin ese reporte). `MascotaExtraviadaNotifier.eliminarReporte()` (en `mascota_extraviada_provider.dart`) ya hacía las dos cosas correctamente (borra en Supabase y actualiza su propio `state`); el bug era simplemente no estar usando ese método acá. Este cambio es independiente del punto 1 (esta pantalla sigue sacando el reporte a mano de sus propias listas también, ver arriba) — son dos copias en memoria distintas (`mascotaExtraviadaProvider.state` para el mapa, `_denunciados`/`_activos` acá) que ahora se actualizan cada una por su cuenta.

### 1f. Bloquear/eliminar navegan al detalle — `onTap` en `_tileReporte()` (2026-09-27)

Pedido de un tester: tocar una fila de reporte (en "Denunciados" o "Todos") ahora abre `DetalleReporteMascotaExtraviadaScreen`, igual que tocar un marcador en el mapa — antes la fila no hacía nada al tocarla, solo los dos íconos de la derecha (bloquear/eliminar) respondían. Se le pasa `reporteInicial: reporte` (ver `detalleReporteMascotaExtraviadaScreen.md`, punto 6) porque esta pantalla ya tiene el `MascotaExtraviadaModel` completo en mano — sin eso, la pantalla de detalle no lo encontraba (busca por id dentro de `mascotaExtraviadaProvider`, que solo trae reportes activos) y se cerraba sola en silencio.

**`await Navigator.of(context).push<bool>(...)`, no un `push` sin esperar nada — tercer bug encontrado probando este mismo punto:** si el admin ve un reporte propio desde acá (`esMio == true`) y lo borra o lo marca resuelto *adentro* del detalle, esta lista no se enteraba — quedaba con la copia vieja hasta salir y volver a entrar a la pantalla. `DetalleReporteMascotaExtraviadaScreen` ahora devuelve `true` en el `pop` cuando pasó algo así (ver ese doc, punto 7); acá se espera ese resultado y, si es `true`, se vuelve a pedir `_cargarDenunciados()`/`_cargarActivos()` a Supabase — a diferencia de `_eliminar()` (punto 1e, que saca el reporte a mano de las listas locales porque ya sabe exactamente cuál borrar), acá no se sabe si lo que cambió fue un borrado o solo un "marcar resuelto" (que saca al reporte de "Todos" pero lo deja en "Denunciados"), así que pedir todo de nuevo es más simple y confiable que tratar de replicar esa lógica a mano.

### 1b. `DefaultTabController` + `TabBar` en el `AppBar.bottom` (2026-09-27)

Patrón estándar de Flutter para pestañas simples sin necesidad de manejar el índice a mano (no hace falta un `TabController` propio ni `SingleTickerProviderStateMixin` — `DefaultTabController` ya se encarga). Primera pantalla del proyecto con pestañas — antes ninguna las necesitaba.

### 1c. `_tileReporte()` — misma fila para "Denunciados" y "Todos"

Las dos pestañas de reportes muestran exactamente la misma fila (ícono de tipo, nombre, botones de bloquear/eliminar) — solo cambia el subtítulo (cantidad de denuncias en una, fecha de publicación en la otra, vía `fechaHoraCorta()` de `etiquetas_localizadas.dart`). Se extrajo a un método compartido en vez de duplicar el `ListTile` en cada `FutureBuilder`.

### 1d. `_bloquear()` / `_desbloquear()` — acciones separadas de `_eliminar()`

Bloquear al autor de un reporte no borra el reporte en sí, y viceversa — son dos decisiones independientes a propósito (el admin puede querer borrar un reporte puntual sin restringir a su autor, o restringir a alguien sin necesariamente borrar todo lo que publicó). Cada una tiene su propio diálogo de confirmación (`confirmarAccion`, ver `dialogoConfirmacion.md`) con su propio texto.

**`item.usuarioId.substring(0, 8)`** en la pestaña "Bloqueados": un UUID completo (36 caracteres) es demasiado para mostrar en una lista — se trunca a los primeros 8 caracteres, suficiente para que el admin lo reconozca si lo necesita cruzar contra el panel de Supabase, sin ocupar toda la fila. No hay email ni nombre que mostrar en su lugar: un invitado bloqueado (sesión anónima) no tiene ninguno de los dos — ver la limitación real documentada en `decisiones_arquitectura.md`, entrada del 2026-09-27 (un invitado bloqueado puede evadirlo reinstalando la app, ver `mascotaExtraviada.repository.md`).

### 2. `obtenerReportesDenunciados()` no filtra por `resuelto`

Un reporte denunciado por contenido abusivo sigue necesitando revisión aunque su dueño ya lo haya marcado como resuelto — a diferencia de `mascotaExtraviadaProvider` (que solo carga activos, para el mapa), esta consulta trae reportes denunciados sin importar su estado.

### 3. Agrupado en Dart, no en SQL

Supabase (vía `postgrest`) no ofrece un `group by` directo desde el cliente sin una vista o función RPC aparte — con el volumen esperado de denuncias, se prefirió traer las filas de `denuncias_reportes` y contarlas en memoria (`Map<String, int>`) antes que sumar una vista nueva a la base solo para esto.
