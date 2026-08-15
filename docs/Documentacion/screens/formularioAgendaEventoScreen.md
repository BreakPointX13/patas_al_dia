# Nota de Obsidian: `FormularioAgendaEventoScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/formulario_agenda_evento_screen.dart`

Se abre desde `AgendaScreen` (crear, eligiendo antes futuro/pasado) o desde `DetalleAgendaEventoScreen` (editar).

## 🎯 Propósito del Archivo

Formulario único crear/editar de un evento de agenda — mismo patrón que `FormularioMascotaScreen` — pero con una complejidad extra: el formulario cambia de forma según si el evento es "futuro" (recordatorio) o "pasado" (registro de historial), y una parte del formulario se habilita sola según la fecha. Reescrito por completo el 2026-08-14 (la primera versión, más simple, no tenía esta lógica).

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Decisión del usuario tras varias vueltas de diseño (ver las entradas del 2026-08-12/13/14 en `decisiones_arquitectura.md`): en vez de dos pantallas separadas para "evento futuro" y "evento pasado", es **una sola pantalla** que cambia qué campos pide y permite según el modo — evita duplicar los campos y la lógica de medicamentos/documentos en dos archivos.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `esEventoPasado` — solo importa al crear

```dart
final bool esEventoPasado; // default false
```

Solo se usa cuando `eventoExistente == null` (creando). Determina dos cosas: los límites del selector de fecha (`_seleccionarFechaHora`, futuro solo permite fechas desde ahora; pasado solo permite hasta ahora) y el título del `AppBar`. **No** se guarda en el modelo ni en la base de datos — no hace falta, porque la fecha elegida ya deja el evento naturalmente en el pasado o el futuro.

**Bug encontrado y corregido (2026-08-14):** `showDatePicker` sí limita el *día* a "hoy o antes" para un evento pasado, pero `showTimePicker` no tiene forma de limitar la *hora* — si se elegía "hoy" como fecha y una hora posterior a la actual, el `DateTime` combinado quedaba técnicamente en el futuro sin que el usuario lo notara, y ese evento terminaba comportándose como "futuro" (campos reducidos, sin medicamentos/documentos) al editarlo después, de forma inconsistente con otros eventos pasados creados en otro momento del día. Se corrigió validando la combinación fecha+hora después de ambos pickers: si da en el futuro para un evento pasado, se rechaza con un aviso en vez de guardarla.

**Bug encontrado y corregido (2026-08-15):** `fechaRealizada` (el campo que dice si el evento ya se cumplió) quedaba `null` incluso creando un evento pasado — el usuario tenía que ir después a `DetalleAgendaEventoScreen` y tocar el switch "Marcar como realizado" a mano, algo redundante con haber elegido "Evento pasado" en el primer paso. Se corrigió en `_guardar()`: si es un evento nuevo y `widget.esEventoPasado`, `fechaRealizada` se completa sola con la misma `_fechaProgramada` elegida.

### 2. `_esFechaFutura` y `_segundaMitadVisible` — la lógica central del formulario

```dart
bool get _esFechaFutura =>
    _fechaProgramada != null && _fechaProgramada!.isAfter(DateTime.now());

bool get _segundaMitadVisible {
  if (widget.eventoExistente == null && widget.esEventoPasado) {
    return true;
  }
  return _fechaProgramada != null && !_esFechaFutura;
}
```

Estos dos getters, no un campo de estado guardado, deciden qué se ve en pantalla — se recalculan en cada `build()`:

- **Recordatorio** (switch + selector de horas antes) solo se muestra si `_esFechaFutura` — no tiene sentido programar un aviso para algo que ya pasó. Como se calcula a partir de la fecha elegida (no de `esEventoPasado`), esto también cubre el caso de editar más adelante un evento que se creó como "futuro": en cuanto pasa su fecha, el recordatorio deja de ofrecerse solo.
- **Segunda mitad** (observaciones, medicamentos, documentos, próxima consulta) se muestra si la fecha ya no es futura — **excepto** al crear un evento pasado, donde se fuerza a `true` desde el inicio (corrección del 2026-08-14: antes exigía elegir primero la fecha, lo cual no tenía sentido si el usuario ya sabía que estaba registrando algo del pasado).

Ninguna de las dos reglas necesita saber si el evento se creó como "futuro" o "pasado" una vez guardado — alcanza con comparar la fecha guardada contra el reloj actual. Esto es intencional: evita persistir un campo extra solo para diferenciar los dos modos de creación.

### 3. `_eventoId` fijo desde el arranque

```dart
late final String _eventoId = widget.eventoExistente?.id ?? const Uuid().v4();
```

A diferencia de `FormularioMascotaScreen` (que genera el id recién al guardar), acá el id se fija apenas se construye el widget — porque los medicamentos y documentos que se van agregando **antes** de guardar necesitan poder referenciar el id del evento (`agendaEventoId`, `eventoId`) aunque el evento todavía no exista en la base de datos.

### 4. Medicamentos y documentos: lista local + diff al guardar

```dart
List<MedicamentoEventoModel> _medicamentos = [];
List<MedicamentoEventoModel> _medicamentosOriginales = [];
```

Igual que la foto en `FormularioMascotaScreen`, los medicamentos y documentos que se van agregando/editando/quitando en pantalla viven en listas locales (`_medicamentos`, `_documentos`), no se persisten uno por uno al tocar "Agregar". Al editar un evento existente, `_cargarMedicamentosExistentes()`/`_cargarDocumentosExistentes()` traen la lista guardada directo del repository (no del provider — ver `medicamentoEventoNotifier.md`) y la copian tanto a la lista editable como a `_.*Originales` (foto de referencia).

Al guardar (`_guardar()`), se compara `_medicamentos` contra `_medicamentosOriginales` por `id`: lo que está en la lista actual pero no en la original es nuevo (`agregar`); lo que está en ambas se actualiza (`actualizar`); lo que estaba en la original pero ya no está en la actual se borró (`eliminar`). Mismo mecanismo para documentos.

### 5. `_abrirDialogoMedicamento` / `_abrirSelectorDocumento` + `_abrirDialogoDatosDocumento`

Diálogos modales (`showDialog`/`showModalBottomSheet`) que arman el objeto (`MedicamentoEventoModel`/`DocumentoModel`) y lo devuelven vía `Navigator.pop(resultado)` — el llamador decide si es un alta (`.add`) o una edición (reemplaza por índice) según si el `id` del resultado ya estaba en la lista. `_abrirSelectorDocumento` muestra primero una tarjeta con 3 opciones (Tomar foto / Elegir imagen de galería / Elegir PDF — `image_picker` para las dos primeras, `file_picker` para la tercera) y recién después abre el diálogo de título/tipo con el archivo ya elegido.

### 6. "Programar próxima consulta" — crea un evento de seguimiento aparte

```dart
if (_proximaConsultaActiva && _proximaConsultaFecha != null) {
  final seguimiento = AgendaEventoModel(
    id: const Uuid().v4(),
    mascotaId: evento.mascotaId,
    tipoEvento: evento.tipoEvento,
    titulo: evento.titulo,
    fechaProgramada: DateTime(..., horaOriginal.hour, horaOriginal.minute),
    recordatorioHorasAntes: 24,
  );
  await ref.read(agendaEventosProvider.notifier).agregarAgendaEvento(seguimiento);
  await NotificacionService.instance.programarRecordatorio(seguimiento);
}
```

No es un campo del evento actual — es un **evento nuevo e independiente**, con el mismo título y mascota, en el día que el usuario elige (reutilizando la misma hora del evento original, sin pedir una hora nueva), con recordatorio fijo de 24 horas antes. No queda ningún vínculo guardado entre el evento original y este de seguimiento — si más adelante hiciera falta rastrear esa relación, habría que agregar un campo nuevo (ej. `eventoOrigenId`), pero no se justificó para el alcance actual.
