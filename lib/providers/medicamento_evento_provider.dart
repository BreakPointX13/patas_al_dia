import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/medicamento_evento_model.dart';
import 'package:patas_al_dia/data/repositories/medicamento_evento_repository.dart';

final medicamentoEventoRepositoryProvider =
    Provider<MedicamentoEventoRepository>((ref) {
      return MedicamentoEventoRepository();
    });

class MedicamentoEventoNotifier extends Notifier<List<MedicamentoEventoModel>> {
  @override
  List<MedicamentoEventoModel> build() {
    return [];
  }

  Future<void> cargarMedicamentosDeEvento(String agendaEventoId) async {
    final repo = ref.read(medicamentoEventoRepositoryProvider);
    state = await repo.obtenerMedicamentosPorEvento(agendaEventoId);
  }

  Future<void> agregarMedicamentoEvento(
    MedicamentoEventoModel medicamento,
  ) async {
    final repo = ref.read(medicamentoEventoRepositoryProvider);
    await repo.crearMedicamentoEvento(medicamento);
    state = [...state, medicamento];
  }

  Future<void> actualizarMedicamentoEvento(
    MedicamentoEventoModel medicamento,
  ) async {
    final repo = ref.read(medicamentoEventoRepositoryProvider);
    await repo.actualizarMedicamentoEvento(medicamento);
    state = state
        .map((m) => m.id == medicamento.id ? medicamento : m)
        .toList();
  }

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
