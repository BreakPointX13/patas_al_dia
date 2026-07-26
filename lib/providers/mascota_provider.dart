import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/repositories/mascota_repository.dart';

final mascotaRepositoryProvider = Provider<MascotaRepository>((ref) {
  return MascotaRepository();
});
