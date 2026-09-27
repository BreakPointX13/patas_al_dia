# Nota de Obsidian: `DetalleReporteMascotaExtraviadaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/detalle_reporte_mascota_extraviada_screen.dart`

Se abre al tocar un marcador del mapa en `MapaScreen`, o una fila en `AdminModeracionScreen` (2026-09-27, ver punto 6).

## 🎯 Propósito del Archivo

Muestra todos los datos de un reporte (foto, tipo, especie, recompensa si corresponde, contacto, descripción, fecha, mini-mapa con la ubicación) y da acceso a las acciones sobre un reporte ya publicado: denunciar (cualquiera), o marcar como resuelto/eliminar (solo el dueño del reporte).

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Mismo patrón de guarda que `DetalleMascotaScreen`/`DetalleDocumentoScreen`: busca el reporte por id dentro de `mascotaExtraviadaProvider` en cada `build()` (reactivo — si se elimina mientras la pantalla está abierta, se entera solo), y si no lo encuentra, cae a `reporteInicial` (ver punto 6) antes de volver atrás — solo vuelve atrás si ninguno de los dos lo tiene.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `esMio` — sin forzar una sesión de Supabase solo por mirar

```dart
final usuarioActualId = Supabase.instance.client.auth.currentSession?.user.id;
final esMio = usuarioActualId != null && usuarioActualId == reporte.usuarioId;
```

A diferencia de `denunciarReporte`/`crearReporte` (que sí crean una sesión anónima si hace falta, ver `mascotaExtraviada.repository.md`), acá se lee `currentSession` directo, **sin** llamar a `obtenerUsuarioIdSupabase()` — mirar el detalle de un reporte ajeno no debería generar una sesión de Supabase Auth nueva para alguien que todavía no publicó nada. Si `currentSession` es `null` (nunca se creó sesión), `esMio` es `false` automáticamente — no puede ser dueño de nada si nunca se identificó.

### 2. Acciones condicionadas a `esMio`

"Marcar como resuelto" y "Eliminar" (con el mismo patrón visual rojo que `DetalleMascotaScreen`/`DetalleDocumentoScreen` — confirmación con `confirmarAccion`, ver `dialogoConfirmacion.md`, botón rojo solo para eliminar) solo aparecen si `esMio` es `true`. "Denunciar este aviso" (`OutlinedButton.icon`, para diferenciarlo visualmente de las acciones destructivas) está siempre visible — cualquiera puede denunciar, incluido el propio dueño en teoría (no se bloquea, no vale la pena la complejidad de impedirlo).

### 3. Mini-mapa opcional dentro del detalle

Si el reporte tiene `ubicacionLat`/`ubicacionLng`, se muestra un `FlutterMap` chico (200 de alto, `ClipRRect` con bordes redondeados) centrado en el punto, con un único marcador — mismo mecanismo que el mapa general de `MapaScreen`, pero sin interacción de lista ni FAB, solo para ubicar visualmente el reporte puntual. Si no tiene ubicación, se muestra el texto `sinUbicacionLabel` en su lugar.

### 4. `especieValorMostrar(l10n, reporte.mascotaEspecie)` — sin `MascotaModel`

A diferencia de `especieMostrar(context, mascota)` (usado en pantallas que sí tienen una `MascotaModel` completa), acá se llama a la función base `especieValorMostrar` directo, porque `MascotaExtraviadaModel` no tiene el par especie/especiePersonalizada — ver `etiquetasLocalizadas.md`, punto 5, y `mascotaExtraviada.model.md`, punto 1.

### 5. Foto del reporte — `Image.network`, con guarda por compatibilidad (2026-08-19)

```dart
if (reporte.mascotaFotoUrl != null)
  ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(reporte.mascotaFotoUrl!, height: 220, width: double.infinity, fit: BoxFit.cover),
  ),
```

Se muestra arriba de todo, antes del `Chip` de tipo — es el dato más útil de un vistazo para reconocer a la mascota. Usa `Image.network` directo (no `FileImage`, la foto ya no es un archivo local en este punto — es la URL pública de Storage que devolvió `subirFoto()`, ver `mascotaExtraviada.repository.md`, punto 5b). El `if (reporte.mascotaFotoUrl != null)` no es una feature — la foto es obligatoria en el formulario desde esta misma fecha (ver `formularioReporteMascotaExtraviadaScreen.md`, punto 6), así que un reporte nuevo siempre la trae; el chequeo es solo para no crashear con algún reporte de prueba publicado antes de que la foto fuera obligatoria.

### 6. `reporteInicial` — reporte visto sin pasar por `mascotaExtraviadaProvider` (2026-09-27)

```dart
final MascotaExtraviadaModel? reporteInicial;
```

Bug real reportado por un tester: `AdminModeracionScreen` navegaba acá pasando solo `reporteId`, igual que `MapaScreen` — pero esta pantalla busca el reporte dentro de `mascotaExtraviadaProvider` (ver punto anterior), que **solo carga reportes activos** (`resuelto = false`, vía `cargarReportesActivos()`). Un reporte denunciado-y-ya-resuelto (pestaña "Denunciados" del admin puede mostrar esos, ver `adminModeracionScreen.md`, punto 2), o cualquier reporte visto desde el panel sin haber abierto antes `MapaScreen` en esa sesión, nunca estaba en ese provider — la pantalla no encontraba nada y volvía atrás sola en silencio, sin ningún error visible, dejando al admin sin poder ver el detalle de nada que tocara desde moderación.

Se agregó `reporteInicial` (opcional) como respaldo: `MapaScreen` sigue sin pasarlo (no lo necesita, su reporte siempre está en el provider); `AdminModeracionScreen` sí, porque ya tiene el `MascotaExtraviadaModel` completo en mano (viene de `obtenerReportesDenunciados()`/`obtenerReportesActivos()`, no hace falta volver a pedirlo). La búsqueda en el provider sigue siendo la fuente preferida (`reporte ??= widget.reporteInicial`) — si el reporte sí está ahí, se usa esa copia (reactiva a cambios), y `reporteInicial` solo entra cuando no lo está.

**No cambia `esMio` ni las acciones condicionadas a eso (punto 2)** — un admin viendo el reporte de otra persona sigue sin ver "Marcar como resuelto"/"Eliminar" acá (ya tiene esas acciones en la lista de moderación misma). Fuera de alcance del pedido original ("poder ver el reporte al pincharlo"), no se tocó.

### 7. `Navigator.of(context).pop(true)` en vez de `pop()` — segundo bug encontrado probando el punto 6 (2026-09-27)

```dart
await ref.read(mascotaExtraviadaProvider.notifier).eliminarReporte(reporte);
if (mounted) {
  Navigator.of(context).pop(true);
}
```

Mismo cambio en `_eliminar()` y `_marcarComoResuelto()`. El admin podía llegar acá con `esMio == true` (viendo un reporte propio, ver punto 6) y borrarlo o marcarlo resuelto desde adentro del detalle — pero el `pop()` de antes no le avisaba nada a `AdminModeracionScreen`, que sigue con su propia copia en memoria del reporte (ver `adminModeracionScreen.md`, punto 1): la lista de moderación no se enteraba del cambio hasta salir y volver a entrar a esa pantalla. `MapaScreen` (el otro lugar desde donde se navega acá) sigue sin usar el valor del `pop` — no lo necesita, ya escucha `mascotaExtraviadaProvider` con `ref.watch` y se entera solo. `AdminModeracionScreen._abrirDetalle()` sí espera el resultado y, si es `true`, vuelve a pedir sus listas a Supabase — ver ese doc.
