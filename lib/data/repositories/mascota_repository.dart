import 'package:patas_al_dia/data/database/database_helper.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';

class MascotaRepository {
  Future<MascotaModel> crearMascota(MascotaModel mascota) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert('mascotas', mascota.toMap());

    return mascota;
  }

  Future<List<MascotaModel>> obtenerMascotasPorUsuario(String usuarioId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mascotas',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
    );

    return maps.map((mapa) => MascotaModel.fromMap(mapa)).toList();
  }

  Future<MascotaModel?> obtenerMascotaPorId(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mascotas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) {
      return null;
    }
    return MascotaModel.fromMap(maps.first);
  }

  Future<int> actualizarMascota(MascotaModel mascota) async {
    final db = await DatabaseHelper.instance.database;

    final int filasActualizadas = await db.update(
      'mascotas',
      mascota.toMap(),
      where: 'id = ?',
      whereArgs: [mascota.id],
    );

    return filasActualizadas;
  }

  Future<int> eliminarMascota(String id) async {
    final db = await DatabaseHelper.instance.database;
    final int filasEliminadas = await db.delete(
      'mascotas',
      where: 'id = ?',
      whereArgs: [id],
    );

    return filasEliminadas;
  }
}
