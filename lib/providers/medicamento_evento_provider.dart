import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/medicamento_evento_model.dart';
import 'package:patas_al_dia/data/repositories/medicamento_evento_repository.dart';

// Instancia única del repository, para no crearla de nuevo en cada pantalla.
final medicamentoEventoRepositoryProvider =
    Provider<MedicamentoEventoRepository>((ref) {
      return MedicamentoEventoRepository();
    });

// Guarda en memoria los medicamentos ya cargados, para que la UI no lea SQLite en cada build.
class MedicamentoEventoNotifier extends Notifier<List<MedicamentoEventoModel>> {
  @override
  List<MedicamentoEventoModel> build() {
    return [];
  }

  // Trae de SQLite los medicamentos recetados en un evento de agenda.
  Future<void> cargarMedicamentosDeEvento(String agendaEventoId) async {
    final repo = ref.read(medicamentoEventoRepositoryProvider);
    state = await repo.obtenerMedicamentosPorEvento(agendaEventoId);
  }

  // Guarda un medicamento nuevo y lo agrega al estado en memoria.
  Future<void> agregarMedicamentoEvento(
    MedicamentoEventoModel medicamento,
  ) async {
    final repo = ref.read(medicamentoEventoRepositoryProvider);
    await repo.crearMedicamentoEvento(medicamento);
    state = [...state, medicamento];
  }

  // Guarda los cambios de un medicamento existente y refresca el estado en memoria.
  Future<void> actualizarMedicamentoEvento(
    MedicamentoEventoModel medicamento,
  ) async {
    final repo = ref.read(medicamentoEventoRepositoryProvider);
    await repo.actualizarMedicamentoEvento(medicamento);
    state = state
        .map((m) => m.id == medicamento.id ? medicamento : m)
        .toList();
  }

  // Borra (soft-delete) un medicamento y lo saca del estado en memoria.
  Future<void> eliminarMedicamentoEvento(String id) async {
    final repo = ref.read(medicamentoEventoRepositoryProvider);
    await repo.eliminarMedicamentoEvento(id);
    state = state.where((m) => m.id != id).toList();
  }
}

final medicamentoEventoProvider =
    NotifierProvider<MedicamentoEventoNotifier, List<MedicamentoEventoModel>>(
      () {
        return MedicamentoEventoNotifier();
      },
    );
