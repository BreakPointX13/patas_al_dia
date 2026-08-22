import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/agenda_evento_model.dart';
import 'package:patas_al_dia/data/repositories/agenda_evento_repository.dart';

// Instancia única del repository, para no crearla de nuevo en cada pantalla.
final agendaEventoRepositoryProvider = Provider<AgendaEventoRepository>((ref) {
  return AgendaEventoRepository();
});

// Guarda en memoria la agenda ya cargada, para que la UI no lea SQLite en cada build.
class AgendaEventoNotifier extends Notifier<List<AgendaEventoModel>> {
  @override
  List<AgendaEventoModel> build() {
    return [];
  }

  // Trae de SQLite todos los eventos de las mascotas indicadas.
  Future<void> cargarAgendaEventosDeMascotas(List<String> mascotaIds) async {
    final repo = ref.read(agendaEventoRepositoryProvider);
    state = await repo.obtenerAgendaEventosPorMascotas(mascotaIds);
  }

  // Guarda un evento nuevo y lo agrega al estado en memoria.
  Future<void> agregarAgendaEvento(AgendaEventoModel agendaEvento) async {
    final repo = ref.read(agendaEventoRepositoryProvider);
    await repo.crearAgendaEvento(agendaEvento);
    state = [...state, agendaEvento];
  }

  // Guarda los cambios de un evento existente y refresca el estado en memoria.
  Future<void> actualizarAgendaEvento(AgendaEventoModel agendaEvento) async {
    final repo = ref.read(agendaEventoRepositoryProvider);
    await repo.actualizarAgendaEvento(agendaEvento);
    state = state
        .map((e) => e.id == agendaEvento.id ? agendaEvento : e)
        .toList();
  }

  // Borra (soft-delete) un evento y lo saca del estado en memoria.
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
