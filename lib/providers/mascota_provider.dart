import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/data/repositories/mascota_repository.dart';

// Instancia única del repository, para no crearla de nuevo en cada pantalla.
final mascotaRepositoryProvider = Provider<MascotaRepository>((ref) {
  return MascotaRepository();
});

// Guarda en memoria las mascotas ya cargadas, para que la UI no lea SQLite en cada build.
class MascotasNotifier extends Notifier<List<MascotaModel>> {
  @override
  List<MascotaModel> build() {
    return [];
  }

  // Trae de SQLite todas las mascotas del usuario actual (o del invitado).
  Future<void> cargarMascotas(String usuarioId) async {
    final repo = ref.read(mascotaRepositoryProvider);
    state = await repo.obtenerMascotasPorUsuario(usuarioId);
  }

  // Guarda una mascota nueva y la agrega al estado en memoria.
  Future<void> agregarMascota(MascotaModel mascota) async {
    final repo = ref.read(mascotaRepositoryProvider);
    await repo.crearMascota(mascota);
    state = [...state, mascota];
  }

  // Guarda los cambios de una mascota existente y refresca el estado en memoria.
  Future<void> actualizarMascota(MascotaModel mascota) async {
    final repo = ref.read(mascotaRepositoryProvider);
    await repo.actualizarMascota(mascota);
    state = state.map((m) => m.id == mascota.id ? mascota : m).toList();
  }

  // Borra (soft-delete) una mascota y toda su información asociada.
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
