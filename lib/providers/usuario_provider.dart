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

  Future<bool> cargarSesionActiva() async {
    final repo = ref.read(usuarioRepositoryProvider);
    state = await repo.obtenerUsuarioConSesionActiva();
    return state != null;
  }

  Future<void> cerrarSesion() async {
    if (state == null) {
      return;
    }

    final repo = ref.read(usuarioRepositoryProvider);
    await repo.actualizarUsuario(state!.copyWith(sesionActiva: false));
    state = null;
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

  Future<void> actualizarEscalaTexto(double escalaTexto) async {
    if (state == null) {
      return;
    }
    await actualizarUsuario(state!.copyWith(escalaTexto: escalaTexto));
  }

  Future<void> actualizarTema(String tema) async {
    if (state == null) {
      return;
    }
    await actualizarUsuario(state!.copyWith(tema: tema));
  }

  Future<void> actualizarIdioma(String idioma) async {
    if (state == null) {
      return;
    }
    await actualizarUsuario(state!.copyWith(idioma: idioma));
  }

  Future<void> marcarAvisoMapaVisto() async {
    if (state == null) {
      return;
    }
    await actualizarUsuario(state!.copyWith(avisoMapaVisto: true));
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
