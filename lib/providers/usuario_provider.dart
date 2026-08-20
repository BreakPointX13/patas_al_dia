import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    // Solo cierra la sesión de Supabase Auth para usuarios registrados — un
    // invitado puede tener (o no) una sesión anónima de Supabase creada de
    // paso por el módulo Mapa (ver mascotaExtraviada.repository.md), sin
    // relación con su id local; no hace falta tocarla acá.
    if (!state!.esInvitado) {
      await repo.cerrarSesionSupabase();
    }
    await repo.actualizarUsuario(state!.copyWith(sesionActiva: false));
    state = null;
  }

  // Registra una cuenta real (Login real, 2026-08-19, ver
  // decisiones_arquitectura.md) y, si ya había un invitado usando la app
  // (con mascotas/agenda/documentos ya cargados), lo convierte en registrado
  // conservando todos sus datos — decisión explícita del usuario. Si no
  // había ningún usuario local todavía (alguien que entra directo a
  // registrarse, sin haber tocado "Continuar como invitado" antes), crea uno
  // nuevo desde cero.
  Future<void> registrarUsuario({
    required String email,
    required String password,
  }) async {
    final repo = ref.read(usuarioRepositoryProvider);
    final respuesta = await repo.registrarConEmail(
      email: email,
      password: password,
    );
    // Con "Confirm email" activado en Supabase, registrarse con un correo
    // que ya tiene una cuenta confirmada no devuelve un error (por diseño,
    // para no revelar si un correo existe o no) — devuelve una respuesta
    // "éxito" sin sesión, pero con `identities` vacío como única señal real.
    // Sin este chequeo, se terminaría reasignando los datos locales al id de
    // otra persona sin haber verificado nada. Ver `errores_autenticacion.dart`.
    if (respuesta.user?.identities?.isEmpty ?? false) {
      throw const AuthException(
        'El correo ya está registrado',
        code: 'user_already_exists',
      );
    }
    final nuevoId = respuesta.user!.id;

    if (state != null) {
      state = await repo.convertirAInvitadoRegistrado(
        invitadoActual: state!,
        nuevoId: nuevoId,
        email: email,
      );
    } else {
      final nuevo = UsuarioModel(id: nuevoId, email: email, esInvitado: false);
      await repo.crearUsuario(nuevo);
      state = nuevo;
    }
  }

  // Inicia sesión con una cuenta ya registrada. El id local pasa a ser el
  // mismo `auth.uid()` de Supabase (ver convertirAInvitadoRegistrado) — si
  // ya existe una fila local con ese id (mismo dispositivo de siempre, solo
  // había cerrado sesión), se reactiva tal cual, con todos sus datos
  // intactos. Si no existe (dispositivo nuevo), se crea una fila vacía: por
  // ahora no hay Sync todavía, así que sus mascotas guardadas en la nube no
  // aparecen acá hasta que esa fase se implemente.
  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final repo = ref.read(usuarioRepositoryProvider);
    final respuesta = await repo.iniciarSesionConEmail(
      email: email,
      password: password,
    );
    await _activarSesionLocal(id: respuesta.user!.id, email: email);
  }

  // Último paso de "olvidé mi contraseña" (2026-08-19, ver
  // decisiones_arquitectura.md) — se llama desde NuevaContrasenaScreen,
  // reached solo después de que main.dart ya capturó el enlace de
  // recuperación y estableció una sesión de recuperación válida (ver
  // AuthChangeEvent.passwordRecovery) — por eso no recibe `email` ni
  // `codigo`, solo la contraseña nueva: `currentUser` ya está disponible.
  Future<void> completarRecuperacion({required String nuevaContrasena}) async {
    final repo = ref.read(usuarioRepositoryProvider);
    await repo.actualizarContrasena(nuevaContrasena);
    final usuarioSupabase = Supabase.instance.client.auth.currentUser!;
    await _activarSesionLocal(
      id: usuarioSupabase.id,
      email: usuarioSupabase.email!,
    );
  }

  // Compartido entre iniciarSesion() y completarRecuperacion() — mismo
  // criterio en los dos casos: si ya hay una fila local con ese id (mismo
  // dispositivo de siempre), se reactiva con todos sus datos intactos; si no
  // (dispositivo nuevo), se crea una vacía. Sin Sync todavía (fase
  // siguiente), no hay forma de traer datos guardados en otro dispositivo.
  Future<void> _activarSesionLocal({
    required String id,
    required String email,
  }) async {
    final repo = ref.read(usuarioRepositoryProvider);
    final existente = await repo.obtenerUsuarioPorId(id);
    if (existente != null) {
      final reactivado = existente.copyWith(sesionActiva: true);
      await repo.actualizarUsuario(reactivado);
      state = reactivado;
    } else {
      final nuevo = UsuarioModel(id: id, email: email, esInvitado: false);
      await repo.crearUsuario(nuevo);
      state = nuevo;
    }
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

  // "Eliminar cuenta" (2026-08-19, ver decisiones_arquitectura.md). Para un
  // usuario registrado, primero borra la cuenta real de Supabase Auth (vía
  // Edge Function, ver `eliminarCuentaSupabase` en el repository) — si eso
  // falla (sin conexión, error del servidor), la excepción se propaga y
  // ACÁ TERMINA todo: no se borra nada local todavía. Recién si el borrado
  // remoto tuvo éxito se borra la fila local (con cascada real ahora que
  // `PRAGMA foreign_keys` está activado — ver `database_helper.dart`).
  // Deliberado: mejor dejar la cuenta intacta que borrar los datos locales
  // de alguien cuya cuenta remota sigue existiendo.
  Future<void> eliminarUsuario() async {
    if (state == null) {
      return;
    }

    final repo = ref.read(usuarioRepositoryProvider);
    if (!state!.esInvitado) {
      await repo.eliminarCuentaSupabase();
      await repo.cerrarSesionSupabase();
    }
    await repo.eliminarUsuario(state!.id);
    state = null;
  }
}

final usuarioProvider = NotifierProvider<UsuarioNotifier, UsuarioModel?>(() {
  return UsuarioNotifier();
});
