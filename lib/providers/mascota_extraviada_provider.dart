import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/mascota_extraviada_model.dart';
import 'package:patas_al_dia/data/repositories/mascota_extraviada_repository.dart';

final mascotaExtraviadaRepositoryProvider = Provider<MascotaExtraviadaRepository>((
  ref,
) {
  return MascotaExtraviadaRepository();
});

class MascotaExtraviadaNotifier extends Notifier<List<MascotaExtraviadaModel>> {
  @override
  List<MascotaExtraviadaModel> build() {
    return [];
  }

  Future<void> cargarReportesActivos() async {
    final repo = ref.read(mascotaExtraviadaRepositoryProvider);
    state = await repo.obtenerReportesActivos();
  }

  Future<void> publicarReporte(MascotaExtraviadaModel reporte) async {
    final repo = ref.read(mascotaExtraviadaRepositoryProvider);
    await repo.crearReporte(reporte);
    state = [reporte, ...state];
  }

  Future<void> marcarComoEncontrado(MascotaExtraviadaModel reporte) async {
    final repo = ref.read(mascotaExtraviadaRepositoryProvider);
    final actualizado = reporte.copyWith(estado: 'encontrado');
    await repo.actualizarReporte(actualizado);
    // Ya no es un reporte activo — sale de la lista, mismo criterio que
    // "obtenerReportesActivos" (que solo trae estado = 'perdido').
    state = state.where((r) => r.id != reporte.id).toList();
  }

  Future<void> eliminarReporte(String id) async {
    final repo = ref.read(mascotaExtraviadaRepositoryProvider);
    await repo.eliminarReporte(id);
    state = state.where((r) => r.id != id).toList();
  }
}

final mascotaExtraviadaProvider =
    NotifierProvider<MascotaExtraviadaNotifier, List<MascotaExtraviadaModel>>(() {
      return MascotaExtraviadaNotifier();
    });
