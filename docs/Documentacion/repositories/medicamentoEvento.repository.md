# Nota de Obsidian: `MedicamentoEventoRepository`

## 📁 Ubicación en el Proyecto

`lib/data/repositories/medicamento_evento_repository.dart`

## 🎯 Propósito del Archivo

CRUD sobre la tabla `medicamentos_evento`. Creado el 2026-08-14, es un calco exacto del patrón de `AgendaEventoRepository` — mismos cinco métodos (`crear`, `obtenerPorEvento`, `obtenerPorId` no aplica acá porque no se necesitó, `actualizar`, `eliminar`), mismo uso de `where`/`whereArgs` parametrizado. Ver `agendaEvento.repository.md` para el desglose operador por operador si hace falta.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### `obtenerMedicamentosPorEvento(String agendaEventoId)`

Filtra por `agenda_evento_id = ?`. Es el método que usa `FormularioAgendaEventoScreen` para precargar los medicamentos existentes al editar un evento, y `DetalleAgendaEventoScreen` para mostrarlos.

### Sync (2026-08-20/21)

Mismo patrón que `AgendaEventoRepository` (ver `agendaEvento.repository.md`) y `MascotaRepository` (ver `mascota.repository.md`, puntos 5-8): `eliminarMedicamentoEvento` pasó a ser soft-delete simple (sin hijos propios), `crear`/`actualizar` estampan `actualizadoEn` y `pendiente_push = 1`, y se sumaron `obtenerPendientesDePush`/`marcarComoSincronizadas`/`guardarDesdeSync` para el motor de sync (ver `syncService.md`). Única diferencia respecto a los otros tres repositories: en el *pull*, `sync_service.dart` guarda cada medicamento directo con `guardarDesdeSync`, sin comparar conflictos primero — un medicamento no se edita campo a campo desde dos dispositivos en la práctica, siempre se reemplaza entero desde el formulario del evento, así que no hizo falta un `obtenerMedicamentoPorId`.
