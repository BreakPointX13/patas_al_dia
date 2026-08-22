import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/agenda_evento_model.dart';
import 'package:patas_al_dia/data/repositories/agenda_evento_repository.dart';

final agendaEventoRepositoryProvider = Provider<AgendaEventoRepository>((ref) {
  return AgendaEventoRepository();
});

class AgendaEventoNotifier extends Notifier<List<AgendaEventoModel>> {
  @override
  List<AgendaEventoModel> build() {
    return [];
  }

  Future<void> cargarAgendaEventosDeMascotas(List<String> mascotaIds) async {
    final repo = ref.read(agendaEventoRepositoryProvider);
    state = await repo.obtenerAgendaEventosPorMascotas(mascotaIds);
  }

  Future<void> agregarAgendaEvento(AgendaEventoModel agendaEvento) async {
    final repo = ref.read(agendaEventoRepositoryProvider);
    await repo.crearAgendaEvento(agendaEvento);
    state = [...state, agendaEvento];
  }

  Future<void> actualizarAgendaEvento(AgendaEventoModel agendaEvento) async {
    final repo = ref.read(agendaEventoRepositoryProvider);
    await repo.actualizarAgendaEvento(agendaEvento);
    state = state
        .map((e) => e.id == agendaEvento.id ? agendaEvento : e)
        .toList();
  }

  Future<void> eliminarAgendaEvento(String id) async {
    final repo = ref.read(agendaEventoRepositoryProvider);
    await repo.eliminarAgendaEvento(id);
    state = state.where((e) => e.id != id).toList();
  }
}

final agendaEventosProvider =
    NotifierProvider<AgendaEventoNotifier, List<AgendaEventoModel>>(() {
      return AgendaEventoNotifier();
    });
