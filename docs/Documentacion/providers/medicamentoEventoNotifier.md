# Nota de Obsidian: `MedicamentoEventoNotifier` y `medicamentoEventoProvider`

## 📁 Ubicación en el Proyecto

`lib/providers/medicamento_evento_provider.dart`

## 🎯 Propósito del Archivo

"Pizarra" en memoria de los medicamentos del evento que se está viendo/editando. Creado el 2026-08-14, calco exacto de `AgendaEventoNotifier` — ver `agendaEventoNotifier.md` para el desglose operador por operador.

---

## ⚙️ Glosario — nota específica

### `cargarMedicamentosDeEvento(String agendaEventoId)`

Reemplaza todo el `state` con los medicamentos de un evento puntual. Importante: el `state` de este provider es una lista **global y compartida** (mismo diseño que `agendaEventosProvider`), no una por evento — cada pantalla que lo usa (`FormularioAgendaEventoScreen`, `DetalleAgendaEventoScreen`) debe llamar a este método al entrar para asegurarse de que el `state` refleja el evento correcto antes de leerlo. `FormularioAgendaEventoScreen` en particular no usa el `state` de este provider para su lista editable en pantalla (mantiene una copia local mutable, ver `formularioAgendaEventoScreen.md`) — sí usa el repository directo para la carga inicial y este notifier solo para persistir los cambios al guardar.
