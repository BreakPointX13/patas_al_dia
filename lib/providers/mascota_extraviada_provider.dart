import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/mascota_extraviada_model.dart';
import 'package:patas_al_dia/data/repositories/mascota_extraviada_repository.dart';

// Instancia única del repository. Habla directo con Supabase (esta entidad no vive en SQLite).
final mascotaExtraviadaRepositoryProvider = Provider<MascotaExtraviadaRepository>((
  ref,
) {
  return MascotaExtraviadaRepository();
});

// Guarda en memoria los reportes de mascotas perdidas que se ven en el mapa.
class MascotaExtraviadaNotifier extends Notifier<List<MascotaExtraviadaModel>> {
  @override
  List<MascotaExtraviadaModel> build() {
    return [];
  }

  // Trae de Supabase los reportes que siguen sin resolverse.
  Future<void> cargarReportesActivos() async {
    final repo = ref.read(mascotaExtraviadaRepositoryProvider);
    state = await repo.obtenerReportesActivos();
  }

  // Publica un reporte nuevo y lo agrega al estado en memoria.
  Future<void> publicarReporte(MascotaExtraviadaModel reporte) async {
    final repo = ref.read(mascotaExtraviadaRepositoryProvider);
    await repo.crearReporte(reporte);
    state = [reporte, ...state];
  }

  // Marca un reporte como resuelto (mascota encontrada) y lo saca de la lista.
  Future<void> marcarComoResuelto(MascotaExtraviadaModel reporte) async {
    final repo = ref.read(mascotaExtraviadaRepositoryProvider);
    final actualizado = reporte.copyWith(resuelto: true);
    await repo.actualizarReporte(actualizado);
    // Ya no es un reporte activo — sale de la lista, mismo criterio que
    // "obtenerReportesActivos" (que solo trae resuelto = false).
    state = state.where((r) => r.id != reporte.id).toList();
  }

  // Borra un reporte (y su foto en Storage) y lo saca del estado en memoria.
  Future<void> eliminarReporte(MascotaExtraviadaModel reporte) async {
    final repo = ref.read(mascotaExtraviadaRepositoryProvider);
    await repo.eliminarReporte(reporte);
    state = state.where((r) => r.id != reporte.id).toList();
  }

  // Suma una denuncia a un reporte (para moderación futura).
  Future<void> denunciarReporte(String reporteId) async {
    final repo = ref.read(mascotaExtraviadaRepositoryProvider);
    await repo.denunciarReporte(reporteId);
  }
}

final mascotaExtraviadaProvider =
    NotifierProvider<MascotaExtraviadaNotifier, List<MascotaExtraviadaModel>>(() {
      return MascotaExtraviadaNotifier();
    });
