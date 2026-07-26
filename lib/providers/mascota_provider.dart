import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/data/repositories/mascota_repository.dart';

final mascotaRepositoryProvider = Provider<MascotaRepository>((ref) {
  return MascotaRepository();
});

class MascotasNotifier extends Notifier<List<MascotaModel>> {
  @override
  List<MascotaModel> build() {
    return [];
  }

  Future<void> cargarMascotas(String usuarioId) async {
    final repo = ref.read(mascotaRepositoryProvider);
    state = await repo.obtenerMascotasPorUsuario(usuarioId);
  }

  Future<void> agregarMascota(MascotaModel mascota) async {
    final repo = ref.read(mascotaRepositoryProvider);
    await repo.crearMascota(mascota);
    state = [...state, mascota];
  }

  Future<void> actualizarMascota(MascotaModel mascota) async {
    final repo = ref.read(mascotaRepositoryProvider);
    await repo.actualizarMascota(mascota);
    state = state.map((m) => m.id == mascota.id ? mascota : m).toList();
  }

  Future<void> eliminarMascota(String id) async {
    final repo = ref.read(mascotaRepositoryProvider);
    await repo.eliminarMascota(id);
    state = state.where((m) => m.id != id).toList();
  }
}

final mascotasProvider = NotifierProvider<MascotasNotifier, List<MascotaModel>>(
  () {
    return MascotasNotifier();
  },
);
