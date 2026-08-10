import 'package:patas_al_dia/data/database/database_helper.dart';
import 'package:patas_al_dia/data/models/usuario_model.dart';

class UsuarioRepository {
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
}
