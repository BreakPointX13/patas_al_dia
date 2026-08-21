import 'package:patas_al_dia/data/database/database_helper.dart';
import 'package:patas_al_dia/data/models/agenda_evento_model.dart';

class AgendaEventoRepository {
  // Para el motor de sync (2026-08-20) — ver mascota_repository.dart,
  // obtenerPendientesDePush, para el criterio general (filtra por
  // `pendiente_push`, no por fecha). Acá el usuario se resuelve vía join a
  // `mascotas` (no hay usuario_id directo en esta tabla).
  Future<List<AgendaEventoModel>> obtenerPendientesDePush(
    String usuarioId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM agenda_eventos WHERE mascota_id IN (SELECT id FROM mascotas WHERE usuario_id = ?) AND pendiente_push = 1',
      [usuarioId],
    );
    return maps.map((mapa) => AgendaEventoModel.fromMap(mapa)).toList();
  }

  // Ver mascota_repository.dart, marcarComoSincronizadas, mismo criterio.
  Future<void> marcarComoSincronizadas(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final signosDePregunta = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE agenda_eventos SET pendiente_push = 0 WHERE id IN ($signosDePregunta)',
      ids,
    );
  }

  // Ver mascota_repository.dart, guardarDesdeSync, mismo criterio — acá
  // corrige el mismo bug real: un `agenda_evento` con `medicamentos_evento`
  // locales sin sincronizar se los borraba de verdad al traer un pull sobre
  // el evento (`ON DELETE CASCADE` disparado por el borrado oculto de
  // `INSERT OR REPLACE`).
  Future<void> guardarDesdeSync(AgendaEventoModel agendaEvento) async {
    final db = await DatabaseHelper.instance.database;
    final mapa = agendaEvento.toMap();
    mapa['pendiente_push'] = 0;
    final columnas = mapa.keys.toList();
    final actualizaciones = columnas
        .where((c) => c != 'id')
        .map((c) => '$c = excluded.$c')
        .join(', ');
    await db.rawInsert(
      'INSERT INTO agenda_eventos (${columnas.join(', ')}) '
      'VALUES (${List.filled(columnas.length, '?').join(', ')}) '
      'ON CONFLICT(id) DO UPDATE SET $actualizaciones',
      columnas.map((c) => mapa[c]).toList(),
    );
  }

  Future<AgendaEventoModel> crearAgendaEvento(
    AgendaEventoModel agendaEvento,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final conTimestamp = agendaEvento.copyWith(actualizadoEn: DateTime.now().toUtc());
    final mapa = conTimestamp.toMap();
    mapa['pendiente_push'] = 1;

    await db.insert('agenda_eventos', mapa);

    return conTimestamp;
  }

  // Filtra `eliminado = 0` — ver mascota_repository.dart, mismo criterio.
  Future<List<AgendaEventoModel>> obtenerAgendaEventoPorMascota(
    String mascotaId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'agenda_eventos',
      where: 'mascota_id = ? AND eliminado = 0',
      whereArgs: [mascotaId],
    );
    return maps.map((mapa) => AgendaEventoModel.fromMap(mapa)).toList();
  }

  Future<List<AgendaEventoModel>> obtenerAgendaEventosPorMascotas(
    List<String> mascotaIds,
  ) async {
    if (mascotaIds.isEmpty) {
      return [];
    }

    final db = await DatabaseHelper.instance.database;
    final signosDePregunta = List.filled(mascotaIds.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      'agenda_eventos',
      where: 'mascota_id IN ($signosDePregunta) AND eliminado = 0',
      whereArgs: mascotaIds,
    );
    return maps.map((mapa) => AgendaEventoModel.fromMap(mapa)).toList();
  }

  // Sin filtrar por `eliminado` a propósito — ver mascota_repository.dart,
  // mismo criterio (lo necesita el motor de sync).
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
    final conTimestamp = agendaEvento.copyWith(actualizadoEn: DateTime.now().toUtc());
    final mapa = conTimestamp.toMap();
    mapa['pendiente_push'] = 1;

    final int filasActualizadas = await db.update(
      'agenda_eventos',
      mapa,
      where: 'id = ?',
      whereArgs: [agendaEvento.id],
    );
    return filasActualizadas;
  }

  // Soft-delete (2026-08-20, Sync) — a diferencia de eliminarMascota, acá
  // la cascada NO es uniforme: medicamentos_evento sí se soft-deletea en
  // cascada (mismo `ON DELETE CASCADE` real del schema), pero documentos
  // solo se desvincula (`evento_id = NULL`, preserva el `ON DELETE SET
  // NULL` original) — el documento sobrevive, ver
  // decisiones_arquitectura.md. Bump de `actualizado_en` en los documentos
  // desvinculados también, para que ese cambio se empuje en el próximo sync.
  Future<int> eliminarAgendaEvento(String id) async {
    final db = await DatabaseHelper.instance.database;
    final ahora = DateTime.now().toUtc().toIso8601String();
    late int filasEliminadas;

    await db.transaction((txn) async {
      filasEliminadas = await txn.rawUpdate(
        'UPDATE agenda_eventos SET eliminado = 1, eliminado_en = ?, actualizado_en = ?, pendiente_push = 1 WHERE id = ?',
        [ahora, ahora, id],
      );
      await txn.rawUpdate(
        'UPDATE medicamentos_evento SET eliminado = 1, eliminado_en = ?, actualizado_en = ?, pendiente_push = 1 WHERE agenda_evento_id = ?',
        [ahora, ahora, id],
      );
      await txn.rawUpdate(
        'UPDATE documentos SET evento_id = NULL, actualizado_en = ?, pendiente_push = 1 WHERE evento_id = ?',
        [ahora, id],
      );
    });

    return filasEliminadas;
  }
}
