import 'package:patas_al_dia/data/database/database_helper.dart';
import 'package:patas_al_dia/data/models/medicamento_evento_model.dart';

class MedicamentoEventoRepository {
  Future<MedicamentoEventoModel> crearMedicamentoEvento(
    MedicamentoEventoModel medicamento,
  ) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert('medicamentos_evento', medicamento.toMap());

    return medicamento;
  }

  Future<List<MedicamentoEventoModel>> obtenerMedicamentosPorEvento(
    String agendaEventoId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medicamentos_evento',
      where: 'agenda_evento_id = ?',
      whereArgs: [agendaEventoId],
    );
    return maps.map((mapa) => MedicamentoEventoModel.fromMap(mapa)).toList();
  }

  Future<int> actualizarMedicamentoEvento(
    MedicamentoEventoModel medicamento,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final int filasActualizadas = await db.update(
      'medicamentos_evento',
      medicamento.toMap(),
      where: 'id = ?',
      whereArgs: [medicamento.id],
    );
    return filasActualizadas;
  }

  Future<int> eliminarMedicamentoEvento(String id) async {
    final db = await DatabaseHelper.instance.database;
    final int filasEliminadas = await db.delete(
      'medicamentos_evento',
      where: 'id = ?',
      whereArgs: [id],
    );

    return filasEliminadas;
  }
}
