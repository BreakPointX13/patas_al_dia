# Nota de Obsidian: `MedicamentoEventoRepository`

## 📁 Ubicación en el Proyecto

`lib/data/repositories/medicamento_evento_repository.dart`

## 🎯 Propósito del Archivo

CRUD sobre la tabla `medicamentos_evento`. Creado el 2026-08-14, es un calco exacto del patrón de `AgendaEventoRepository` — mismos cinco métodos (`crear`, `obtenerPorEvento`, `obtenerPorId` no aplica acá porque no se necesitó, `actualizar`, `eliminar`), mismo uso de `where`/`whereArgs` parametrizado. Ver `agendaEvento.repository.md` para el desglose operador por operador si hace falta.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### `obtenerMedicamentosPorEvento(String agendaEventoId)`

Filtra por `agenda_evento_id = ?`. Es el método que usa `FormularioAgendaEventoScreen` para precargar los medicamentos existentes al editar un evento, y `DetalleAgendaEventoScreen` para mostrarlos.
