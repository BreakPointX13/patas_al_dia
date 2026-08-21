import 'package:patas_al_dia/data/database/database_helper.dart';
import 'package:patas_al_dia/data/models/medicamento_evento_model.dart';

class MedicamentoEventoRepository {
  // Para el motor de sync (2026-08-20) — ver mascota_repository.dart,
  // obtenerPendientesDePush, para el criterio general (filtra por
  // `pendiente_push`, no por fecha). Acá el usuario se resuelve vía doble
  // join (agenda_eventos -> mascotas).
  Future<List<MedicamentoEventoModel>> obtenerPendientesDePush(
    String usuarioId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    const subconsulta =
        'SELECT id FROM agenda_eventos WHERE mascota_id IN (SELECT id FROM mascotas WHERE usuario_id = ?)';
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM medicamentos_evento WHERE agenda_evento_id IN ($subconsulta) AND pendiente_push = 1',
      [usuarioId],
    );
    return maps.map((mapa) => MedicamentoEventoModel.fromMap(mapa)).toList();
  }

  // Ver mascota_repository.dart, marcarComoSincronizadas, mismo criterio.
  Future<void> marcarComoSincronizadas(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final signosDePregunta = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE medicamentos_evento SET pendiente_push = 0 WHERE id IN ($signosDePregunta)',
      ids,
    );
  }

  // Ver mascota_repository.dart, guardarDesdeSync, mismo criterio. Acá no
  // hay tabla hija que dependa de `medicamentos_evento` (sin riesgo de
  // cascada), pero se corrige igual por consistencia y por el mismo
  // problema de `pendiente_push` quedando mal seteado.
  Future<void> guardarDesdeSync(MedicamentoEventoModel medicamento) async {
    final db = await DatabaseHelper.instance.database;
    final mapa = medicamento.toMap();
    mapa['pendiente_push'] = 0;
    final columnas = mapa.keys.toList();
    final actualizaciones = columnas
        .where((c) => c != 'id')
        .map((c) => '$c = excluded.$c')
        .join(', ');
    await db.rawInsert(
      'INSERT INTO medicamentos_evento (${columnas.join(', ')}) '
      'VALUES (${List.filled(columnas.length, '?').join(', ')}) '
      'ON CONFLICT(id) DO UPDATE SET $actualizaciones',
      columnas.map((c) => mapa[c]).toList(),
    );
  }

  Future<MedicamentoEventoModel> crearMedicamentoEvento(
    MedicamentoEventoModel medicamento,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final conTimestamp = medicamento.copyWith(actualizadoEn: DateTime.now().toUtc());
    final mapa = conTimestamp.toMap();
    mapa['pendiente_push'] = 1;

    await db.insert('medicamentos_evento', mapa);

    return conTimestamp;
  }

  // Filtra `eliminado = 0` — ver mascota_repository.dart, mismo criterio.
  Future<List<MedicamentoEventoModel>> obtenerMedicamentosPorEvento(
    String agendaEventoId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medicamentos_evento',
      where: 'agenda_evento_id = ? AND eliminado = 0',
      whereArgs: [agendaEventoId],
    );
    return maps.map((mapa) => MedicamentoEventoModel.fromMap(mapa)).toList();
  }

  Future<int> actualizarMedicamentoEvento(
    MedicamentoEventoModel medicamento,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final conTimestamp = medicamento.copyWith(actualizadoEn: DateTime.now().toUtc());
    final mapa = conTimestamp.toMap();
    mapa['pendiente_push'] = 1;

    final int filasActualizadas = await db.update(
      'medicamentos_evento',
      mapa,
      where: 'id = ?',
      whereArgs: [medicamento.id],
    );
    return filasActualizadas;
  }

  // Soft-delete simple, sin hijos (2026-08-20, Sync) — ver
  // mascota_repository.dart para el porqué del soft-delete en general.
  Future<int> eliminarMedicamentoEvento(String id) async {
    final db = await DatabaseHelper.instance.database;
    final ahora = DateTime.now().toUtc().toIso8601String();

    return db.rawUpdate(
      'UPDATE medicamentos_evento SET eliminado = 1, eliminado_en = ?, actualizado_en = ?, pendiente_push = 1 WHERE id = ?',
      [ahora, ahora, id],
    );
  }
}
