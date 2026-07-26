import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/repositories/usuario_repository.dart';
import 'package:patas_al_dia/data/models/usuario_model.dart';

final usuarioRepositoryProvider = Provider<UsuarioRepository>((ref) {
  return UsuarioRepository();
});

class UsuarioNotifier extends Notifier<UsuarioModel?> {
  @override
  UsuarioModel? build() {
    return null;
  }

  Future<void> cargarUsuario(String id) async {
    final repo = ref.read(usuarioRepositoryProvider);
    state = await repo.obtenerUsuarioPorId(id);
  }

  Future<void> crearUsuario(UsuarioModel usuario) async {
    final repo = ref.read(usuarioRepositoryProvider);
    await repo.crearUsuario(usuario);
    state = usuario;
  }

  Future<void> actualizarUsuario(UsuarioModel usuario) async {
    final repo = ref.read(usuarioRepositoryProvider);
    await repo.actualizarUsuario(usuario);
    state = usuario;
  }

  Future<void> eliminarUsuario() async {
    if (state == null) {
      return;
    }

    final repo = ref.read(usuarioRepositoryProvider);
    await repo.eliminarUsuario(state!.id);
    state = null;
  }
}

final usuarioProvider = NotifierProvider<UsuarioNotifier, UsuarioModel?>(() {
  return UsuarioNotifier();
});
