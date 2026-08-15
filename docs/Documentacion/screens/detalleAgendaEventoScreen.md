# Nota de Obsidian: `DetalleAgendaEventoScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/detalle_agenda_evento_screen.dart`

Se abre al tocar un evento en `AgendaScreen`.

## 🎯 Propósito del Archivo

Muestra todos los datos de un evento de agenda (incluidos medicamentos y documentos adjuntos), permite marcarlo como realizado y da acceso a editarlo. Reescrita el 2026-08-14 para incorporar los campos nuevos (recordatorio, medicamentos, documentos) — la primera versión solo mostraba los campos básicos del evento.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

`ConsumerStatefulWidget` (no `ConsumerWidget`): necesita `initState` para disparar la carga de medicamentos y documentos del evento apenas se abre la pantalla, igual razón que `HomeScreen`.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `initState()` — carga de medicamentos y documentos

```dart
ref.read(medicamentoEventoProvider.notifier).cargarMedicamentosDeEvento(widget.eventoId);
ref.read(documentosProvider.notifier).cargarDocumentosDeEvento(widget.eventoId);
```

A diferencia de `FormularioAgendaEventoScreen` (que mantiene copias locales editables), esta pantalla es de solo lectura + una acción (marcar realizado), así que sí usa directo el `state` de los providers vía `ref.watch`, sin necesidad de listas locales.

### 2. `_alternarRealizado(AgendaEventoModel evento)`

```dart
final eventoActualizado = evento.copyWith(
  fechaRealizada: evento.fechaRealizada == null ? DateTime.now() : null,
);
```

El `SwitchListTile` de "Marcar como realizado" es en realidad un toggle sobre `fechaRealizada`: si estaba `null` (no realizado), lo llena con la fecha actual; si ya tenía una fecha, lo vuelve a `null` (permite deshacer el marcado por error).

### 3. `_eliminarEvento(AgendaEventoModel evento)`

Pide confirmación (`AlertDialog`) antes de borrar — es una acción destructiva. Antes de eliminar el evento, cancela su recordatorio pendiente (`NotificacionService.instance.cancelarRecordatorio`) para no dejar una notificación programada apuntando a un evento que ya no existe. El borrado en sí (`agendaEventosProvider.notifier.eliminarAgendaEvento`) dispara en cascada, a nivel de SQLite, el borrado de sus medicamentos (`ON DELETE CASCADE`) y desvincula sus documentos sin borrarlos (`ON DELETE SET NULL`, ver `documento.model.md`) — la pantalla no necesita borrar esas filas a mano.

### 4. Miniatura de documentos según tipo de archivo

```dart
leading: documento.fileExtension == 'pdf'
    ? const Icon(Icons.picture_as_pdf)
    : ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(File(documento.filePath), width: 40, height: 40, fit: BoxFit.cover),
      ),
```

Para imágenes, se muestra una vista previa real leyendo el archivo del dispositivo (`Image.file`); para PDF, solo un ícono — no hay renderizador de PDF en el proyecto todavía (se agregaría, si hace falta, cuando se construya la pantalla general de Documentos, ver el roadmap en `CLAUDE.md`). Tocar un documento no lo abre todavía — ver la misma nota en `formularioAgendaEventoScreen.md` sobre el alcance actual de esta feature.
