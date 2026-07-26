import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/repositories/usuario_repository.dart';

final usuarioRepositoryProvider = Provider<UsuarioRepository>((ref) {
  return UsuarioRepository();
});
