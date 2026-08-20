import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_al_dia/data/database/database_helper.dart';
import 'package:patas_al_dia/data/models/usuario_model.dart';
import 'package:patas_al_dia/services/supabase_config.dart';

class UsuarioRepository {
  // Login real (2026-08-19) — a diferencia de la sesión anónima del módulo
  // Mapa (ver mascotaExtraviada.repository.md), acá sí se propagan las
  // excepciones de Supabase Auth tal cual (`AuthException`), sin atraparlas
  // acá: mismo criterio del resto del proyecto, la pantalla que llama decide
  // qué mensaje mostrar según el error real (ver errores_autenticacion.dart).
  Future<AuthResponse> registrarConEmail({
    required String email,
    required String password,
  }) {
    return Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> iniciarSesionConEmail({
    required String email,
    required String password,
  }) {
    return Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> cerrarSesionSupabase() {
    return Supabase.instance.client.auth.signOut();
  }

  // Eliminar cuenta (2026-08-19, ver decisiones_arquitectura.md) — un
  // usuario no puede borrar su propia cuenta de Supabase Auth con la clave
  // pública que usa el cliente: esa operación (`auth.admin.deleteUser`)
  // exige la "service_role key", un secreto que nunca puede viajar en el
  // código de la app. Por eso esto invoca una Edge Function
  // (`supabase/functions/eliminar-cuenta`, corre en el servidor de
  // Supabase, con la service_role key como variable de entorno) en vez de
  // llamar a la API de Auth directo. `functions.invoke` adjunta sola el JWT
  // de la sesión activa como header de autorización — la función usa ese
  // JWT para saber a quién borrar, no recibe ningún id como parámetro (así
  // nadie puede pedir borrar una cuenta que no es la suya).
  Future<void> eliminarCuentaSupabase() async {
    await Supabase.instance.client.functions.invoke('eliminar-cuenta');
  }

  // "Olvidé mi contraseña" con enlace por correo (2026-08-19, ver
  // decisiones_arquitectura.md) — se prefería un código de 6 dígitos (mismo
  // motivo que evitar el magic link en el login normal: sin deep linking),
  // pero eso exige tener SMTP propio configurado en Supabase para poder
  // editar la plantilla de correo y mostrar el código. Sin SMTP propio (el
  // caso de este proyecto), el enlace es la única opción que funciona con el
  // correo por defecto — así que acá sí hace falta el deep link
  // (`patasaldia://reset-password`, ver `supabase_config.dart`,
  // AndroidManifest.xml e Info.plist). El enlace establece la sesión de
  // recuperación solo (lo captura `main.dart`, ver
  // AuthChangeEvent.passwordRecovery) — no hace falta un método aparte para
  // "verificar" nada acá, a diferencia del enfoque de código que se
  // descartó.
  Future<void> enviarCorreoRecuperacion(String email) {
    return Supabase.instance.client.auth.resetPasswordForEmail(
      email,
      redirectTo: supabaseRedirectRecuperarContrasena,
    );
  }

  Future<void> actualizarContrasena(String nuevaContrasena) {
    return Supabase.instance.client.auth.updateUser(
      UserAttributes(password: nuevaContrasena),
    );
  }

  Future<UsuarioModel> crearUsuario(UsuarioModel usuario) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert('usuarios', usuario.toMap());

    return usuario;
  }

  Future<UsuarioModel?> obtenerUsuarioPorId(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) {
      return null;
    }
    return UsuarioModel.fromMap(maps.first);
  }

  Future<UsuarioModel?> obtenerUsuarioConSesionActiva() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'usuarios',
      where: 'sesion_activa = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return UsuarioModel.fromMap(maps.first);
  }

  Future<int> actualizarUsuario(UsuarioModel usuario) async {
    final db = await DatabaseHelper.instance.database;
    final int filasActualizadas = await db.update(
      'usuarios',
      usuario.toMap(),
      where: 'id = ?',
      whereArgs: [usuario.id],
    );

    return filasActualizadas;
  }

  Future<int> eliminarUsuario(String id) async {
    final db = await DatabaseHelper.instance.database;
    final int filasEliminadas = await db.delete(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );

    return filasEliminadas;
  }

  // Convierte un invitado en usuario registrado (decisión del usuario,
  // 2026-08-19, ver decisiones_arquitectura.md, entrada "Login real"): el id
  // local pasa a ser el mismo `auth.uid()` de Supabase, no un id aparte —
  // pensado para que Sync (la fase siguiente) no necesite traducir entre dos
  // sistemas de ids. Como el `id` es la PK de `usuarios` y no hay
  // `ON UPDATE CASCADE` declarado en el schema (además, `PRAGMA foreign_keys`
  // nunca se activa en este proyecto — ver mapaScreen.md/decisiones, hallazgo
  // pendiente aparte), no se puede hacer un UPDATE directo sobre el id: se
  // crea la fila nueva, se reasignan las mascotas y se borra la fila vieja,
  // las tres operaciones en una sola transacción para que no quede a medio
  // camino si algo falla.
  //
  // Toca la tabla `mascotas` (de otro repository) porque es la única con una
  // referencia directa a `usuarios.id` en el schema — mantener las dos
  // operaciones dentro de la misma transacción exige que vivan juntas acá,
  // no separadas entre dos repositories.
  Future<UsuarioModel> convertirAInvitadoRegistrado({
    required UsuarioModel invitadoActual,
    required String nuevoId,
    required String email,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final nuevoUsuario = invitadoActual.copyWith(
      id: nuevoId,
      email: email,
      esInvitado: false,
      fechaRegistro: DateTime.now(),
    );

    await db.transaction((txn) async {
      await txn.insert('usuarios', nuevoUsuario.toMap());
      await txn.update(
        'mascotas',
        {'usuario_id': nuevoId},
        where: 'usuario_id = ?',
        whereArgs: [invitadoActual.id],
      );
      await txn.delete(
        'usuarios',
        where: 'id = ?',
        whereArgs: [invitadoActual.id],
      );
    });

    return nuevoUsuario;
  }
}
