# Nota de Obsidian: `DocumentoNotifier` y `documentosProvider`

## 📁 Ubicación en el Proyecto

`lib/providers/documento_provider.dart` (parte inferior del archivo, después de `documentoRepositoryProvider`)

## 🎯 Propósito del Archivo

Es la "pizarra" de los documentos: mantiene en memoria la lista de documentos (carnets, exámenes, recetas) de una mascota puntual, y se actualiza sola cuando se crea, edita o elimina un documento.

**Este archivo es un calco exacto de `MascotasNotifier`** — mismo patrón, mismos operadores, solo cambia la entidad. Para el desglose detallado de cada operador (`...`, `? :`, `.map()`, `.where()`) con la chuleta de referencia, ver `mascotasNotifier.md`. Acá solo se documentan las diferencias puntuales.

---

## ⚙️ Glosario — diferencias respecto a `MascotasNotifier`

### 1. `Notifier<List<DocumentoModel>>`

El estado es una lista de documentos, no de mascotas. El resto de la estructura (`build()` devolviendo `[]`) es idéntico.

### 2. `cargarDocumentos(String mascotaId)`

```dart
Future<void> cargarDocumentos(String mascotaId) async {
  final repo = ref.read(documentoRepositoryProvider);
  state = await repo.obtenerDocumentosPorMascota(mascotaId);
}
```

Filtra por `mascotaId`, igual que `AgendaEventoNotifier` — `documentos` también depende de `mascotas`. No filtra por `evento_id` todavía (esa consulta quedó pendiente en el propio `DocumentoRepository`, ver `documento.repository.md`).

### 3. `agregarDocumento`, `actualizarDocumento`, `eliminarDocumento`

Idénticos en estructura a `agregarMascota`, `actualizarMascota` y `eliminarMascota` respectivamente — spread (`[...state, documento]`), `.map()` + ternario comparando por `id`, y `.where()` excluyendo por `id`. Ver `mascotasNotifier.md` para la explicación operador por operador si hace falta refrescar la memoria.
