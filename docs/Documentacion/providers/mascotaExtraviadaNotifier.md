# Nota de Obsidian: `MascotaExtraviadaNotifier` y `mascotaExtraviadaProvider`

## 📁 Ubicación en el Proyecto

`lib/providers/mascota_extraviada_provider.dart`

## 🎯 Propósito del Archivo

Mantiene en memoria la lista de reportes **activos** (`resuelto = false`) — de cualquier `tipo` (perdido o encontrado, ver `mascotaExtraviada.model.md`, punto 4). Mismo patrón general que `DocumentoNotifier`/`MascotasNotifier` (spread al agregar, `.map()`/`.where()` al actualizar/eliminar), con una diferencia de fondo: el repository que usa (`MascotaExtraviadaRepository`) habla con Supabase, no con SQLite local — ver `mascotaExtraviada.repository.md`.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `cargarReportesActivos()`

Trae todos los reportes activos desde Supabase (lectura pública, no requiere sesión) — pensado para alimentar la UI de Mapa.

### 2. `publicarReporte(MascotaExtraviadaModel reporte)`

Igual en forma a `agregarDocumento`/`agregarMascota` (`state = [...]`), pero agrega el reporte nuevo al **principio** de la lista (`[reporte, ...state]`), no al final — coincide con el orden de `obtenerReportesActivos()` en el repository (`fecha_publicacion` descendente, más reciente primero), para que el estado en memoria no quede desordenado respecto a lo que se vería si se recargara desde Supabase.

### 3. `marcarComoResuelto(MascotaExtraviadaModel reporte)` (2026-08-19, antes `marcarComoEncontrado`)

```dart
final actualizado = reporte.copyWith(resuelto: true);
await repo.actualizarReporte(actualizado);
state = state.where((r) => r.id != reporte.id).toList();
```

No es un `actualizarDocumento` genérico (que reemplazaría el ítem en la lista) — acá el ítem se **saca** de la lista tras actualizarlo, porque el estado en memoria de este provider representa específicamente "reportes activos", y un reporte con `resuelto = true` deja de calzar con esa definición, sin importar su `tipo`. Se renombró desde `marcarComoEncontrado`: el nombre viejo asumía que "resolver" siempre significa "se encontró" — ya no es cierto con el flujo "encontré una mascota", donde resolver significa "el dueño la reclamó". Si en algún momento se agrega una pantalla "mis reportes" (activos + resueltos), va a necesitar su propio estado separado — este `state` no le sirve tal cual.

### 4. `eliminarReporte(MascotaExtraviadaModel reporte)` (recibe el modelo completo desde 2026-08-20)

Mismo patrón que `eliminarDocumento`/`eliminarMascota` — `.where()` excluyendo por `id`. Recibe el `MascotaExtraviadaModel` entero, no solo el `id` (cambio del 2026-08-20) — el repository necesita `mascotaFotoUrl`/`usuarioId` para poder borrar también la foto del bucket al borrar el reporte, ver `mascotaExtraviada.repository.md`, punto 5.

### 5. `denunciarReporte(String reporteId)` (2026-08-19)

Delegación directa a `MascotaExtraviadaRepository.denunciarReporte` (ver punto 6 de `mascotaExtraviada.repository.md`) — sin tocar `state`, porque denunciar un reporte no cambia nada de lo que se muestra en el mapa (el reporte sigue activo hasta que el desarrollador lo revise a mano).

### 6. Por qué no hay un `cargarMisReportes` o similar todavía

A propósito no se agregó una consulta "reportes del usuario actual" — no hace falta todavía: en la pantalla de detalle de un reporte (ver `mapaScreen.md`), cada reporte que el usuario ve en el mapa ya trae su propio `usuarioId`, así que la UI puede decidir localmente si mostrar acciones de editar/eliminar comparando ese campo contra el `auth.uid()` de la sesión activa — sin necesitar una consulta aparte. Se agrega si en el futuro hace falta una pantalla dedicada a "mis reportes".
