# Nota de Obsidian: `AgendaEventoNotifier` y `agendaEventosProvider`

## 📁 Ubicación en el Proyecto

`lib/providers/agenda_evento_provider.dart` (parte inferior del archivo, después de `agendaEventoRepositoryProvider`)

## 🎯 Propósito del Archivo

Es la "pizarra" de los eventos de agenda: mantiene en memoria la lista de eventos (vacunas, controles) de una mascota puntual, y se actualiza sola cuando se crea, edita o elimina un evento.

**Este archivo es un calco exacto de `MascotasNotifier`** — mismo patrón, mismos operadores, solo cambia la entidad. Para el desglose detallado de cada operador (`...`, `? :`, `.map()`, `.where()`) con la chuleta de referencia, ver `mascotasNotifier.md`. Acá solo se documentan las diferencias puntuales.

---

## ⚙️ Glosario — diferencias respecto a `MascotasNotifier`

### 1. `Notifier<List<AgendaEventoModel>>`

El estado es una lista de eventos, no de mascotas. El resto de la estructura (`build()` devolviendo `[]`) es idéntico.

### 2. `cargarAgendaEventosDeMascotas(List<String> mascotaIds)`

Agregado el 2026-08-14 junto con `obtenerAgendaEventosPorMascotas` en el repository (ver `agendaEvento.repository.md`). Es el método que usa `AgendaScreen` para cargar los eventos de todas las mascotas seleccionadas en el filtro, en vez de una sola — mismo patrón de reemplazo total de `state`, solo cambia qué trae el repository.

Reemplaza por completo a `cargarAgendaEventos(String mascotaId)` (el original de esta clase, un solo mascotaId), que se borró el 2026-08-21 por código muerto — nunca tuvo ningún llamador propio, cada pantalla que necesitaba la agenda de una sola mascota terminaba usando esta versión plural con una lista de un elemento. Ver `decisiones_arquitectura.md`.

### 3. `agregarAgendaEvento`, `actualizarAgendaEvento`, `eliminarAgendaEvento`

Idénticos en estructura a `agregarMascota`, `actualizarMascota` y `eliminarMascota` respectivamente — spread (`[...state, agendaEvento]`), `.map()` + ternario comparando por `id`, y `.where()` excluyendo por `id`. Ver `mascotasNotifier.md` para la explicación operador por operador si hace falta refrescar la memoria.
