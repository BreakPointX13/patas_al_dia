# Nota de Obsidian: `DetalleReporteMascotaExtraviadaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/detalle_reporte_mascota_extraviada_screen.dart`

Se abre al tocar un marcador del mapa en `MapaScreen`.

## 🎯 Propósito del Archivo

Muestra todos los datos de un reporte (foto, tipo, especie, recompensa si corresponde, contacto, descripción, fecha, mini-mapa con la ubicación) y da acceso a las acciones sobre un reporte ya publicado: denunciar (cualquiera), o marcar como resuelto/eliminar (solo el dueño del reporte).

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Mismo patrón de guarda que `DetalleMascotaScreen`/`DetalleDocumentoScreen`: busca el reporte por id dentro de `mascotaExtraviadaProvider` en cada `build()` (reactivo — si se elimina mientras la pantalla está abierta, se entera solo), y si no lo encuentra, vuelve atrás en vez de crashear.

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
