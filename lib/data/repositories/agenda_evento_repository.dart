import 'package:patas_al_dia/data/database/database_helper.dart';
import 'package:patas_al_dia/data/models/agenda_evento_model.dart';

class AgendaEventoRepository {
  Future<AgendaEventoModel> crearAgendaEvento(
    AgendaEventoModel agendaEvento,
  ) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert('agenda_eventos', agendaEvento.toMap());

    return agendaEvento;
  }

  Future<List<AgendaEventoModel>> obtenerAgendaEventoPorMascota(
    String mascotaId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'agenda_eventos',
      where: 'mascota_id = ?',
      whereArgs: [mascotaId],
    );
    return maps.map((mapa) => AgendaEventoModel.fromMap(mapa)).toList();
  }

  Future<AgendaEventoModel?> obtenerAgendaEventoPorId(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'agenda_eventos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) {
      return null;
    }
    return AgendaEventoModel.fromMap(maps.first);
  }

  Future<int> actualizarAgendaEvento(AgendaEventoModel agendaEvento) async {
    final db = await DatabaseHelper.instance.database;

    final int filasActualizadas = await db.update(
      'agenda_eventos',
      agendaEvento.toMap(),
      where: 'id = ?',
      whereArgs: [agendaEvento.id],
    );
    return filasActualizadas;
  }

  Future<int> eliminarAgendaEvento(String id) async {
    final db = await DatabaseHelper.instance.database;
    final int filasEliminadas = await db.delete(
      'agenda_eventos',
      where: 'id = ?',
      whereArgs: [id],
    );

    return filasEliminadas;
  }
}
