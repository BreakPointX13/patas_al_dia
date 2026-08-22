# Nota de Obsidian: `MedicamentoEventoRepository`

## 📁 Ubicación en el Proyecto

`lib/data/repositories/medicamento_evento_repository.dart`

## 🎯 Propósito del Archivo

CRUD sobre la tabla `medicamentos_evento`. Creado el 2026-08-14, es un calco exacto del patrón de `AgendaEventoRepository` — mismos métodos (`crear`, `obtenerPorEvento`, `obtenerPorId`, `actualizar`, `eliminar`), mismo uso de `where`/`whereArgs` parametrizado. Ver `agendaEvento.repository.md` para el desglose operador por operador si hace falta.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### `obtenerMedicamentosPorEvento(String agendaEventoId)`

Filtra por `agenda_evento_id = ?`. Es el método que usa `FormularioAgendaEventoScreen` para precargar los medicamentos existentes al editar un evento, y `DetalleAgendaEventoScreen` para mostrarlos.

### Sync (2026-08-20/21)

Mismo patrón que `AgendaEventoRepository` (ver `agendaEvento.repository.md`) y `MascotaRepository` (ver `mascota.repository.md`, puntos 5-8): `eliminarMedicamentoEvento` pasó a ser soft-delete simple (sin hijos propios), `crear`/`actualizar` estampan `actualizadoEn` y `pendiente_push = 1`, y se sumaron `obtenerPendientesDePush`/`marcarComoSincronizadas`/`guardarDesdeSync` para el motor de sync (ver `syncService.md`).

### `obtenerMedicamentoEventoPorId(String id)` (2026-08-21, corrige un hallazgo real)

- **La primera versión de Sync no tenía este método** — el razonamiento en su momento fue que "un medicamento no se edita campo a campo desde dos dispositivos en la práctica, siempre se reemplaza entero desde el formulario del evento", así que el *pull* guardaba cada medicamento directo con `guardarDesdeSync`, sin comparar conflictos primero (a diferencia de las otras 3 entidades sincronizadas, que sí lo hacen).
- **Encontrado en una revisión de código completa del proyecto, no en una prueba puntual:** esa suposición no es una garantía real — nada en el schema ni en la UI impide editar un medicamento en dos dispositivos dentro de la misma ventana de sync. Sin comparar conflictos, una edición local todavía sin subir (`pendiente_push = 1`) se perdía sin aviso ante un pull, y sin ninguna forma de reintentar después: `guardarDesdeSync` apaga `pendiente_push` sin condición. Es la misma clase de bug que el de "Bug real 2" en `decisiones_arquitectura.md` (la confusión entre "lo traje" y "lo edité"), pero para la única entidad que había quedado afuera de esa corrección.
- **Sin filtrar por `eliminado`**, mismo motivo que `obtenerMascotaPorId`/`obtenerAgendaEventoPorId`/`obtenerDocumentoPorId`: el motor de sync necesita poder comparar también una fila localmente borrada.
- Con este método, `_sincronizarMedicamentosEvento` en `sync_service.dart` queda exactamente simétrico a las otras 3 entidades: compara `local?.actualizadoEn` contra `remoto.actualizadoEn` con `_ganaElLocal` antes de aplicar el pull. Verificado con una prueba real de conflicto en las dos direcciones (local gana, remoto gana) usando ediciones directas en Supabase.
