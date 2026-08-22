import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_al_dia/data/database/database_helper.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';

// Guarda y consulta las mascotas del usuario; es el modelo de referencia
// para el patrón de sync/soft-delete que copian los demás repositories.
class MascotaRepository {
  // Sube la foto de una mascota al Storage de Supabase.
  // Sync (2026-08-20) — bucket privado `fotos_mascotas` (ver
  // TablaMaestraAppVetMovil1.sql, sección 9), mismo patrón de ruta que
  // `fotos_reportes` (usuarioId/entidadId.ext, ver
  // mascotaExtraviada.repository.md). `upsert: true` porque editar la foto
  // de una mascota vuelve a subir a la MISMA ruta.
  Future<String> subirFoto({
    required String usuarioId,
    required String mascotaId,
    required String rutaLocal,
  }) async {
    final client = Supabase.instance.client;
    final extension = rutaLocal.split('.').last;
    final rutaStorage = '$usuarioId/$mascotaId.$extension';
    await client.storage
        .from('fotos_mascotas')
        .upload(
          rutaStorage,
          File(rutaLocal),
          fileOptions: const FileOptions(upsert: true),
        );
    return rutaStorage;
  }

  // Descarga la foto de una mascota desde el Storage de Supabase.
  Future<Uint8List> descargarFoto(String rutaStorage) {
    final client = Supabase.instance.client;
    return client.storage.from('fotos_mascotas').download(rutaStorage);
  }

  // Para el motor de sync, justo después de subir la foto (2026-08-20) —
  // a propósito NO usa guardarDesdeSync acá: al ser un REPLACE INTO,
  // pisaría `pendiente_push` con su DEFAULT (0) antes de que el upsert a
  // Supabase termine, y si ese upsert fallara justo después, la fila
  // quedaría marcada como sincronizada sin haber llegado nunca a la tabla.
  Future<void> actualizarFotoRutaNube(String id, String ruta) async {
    final db = await DatabaseHelper.instance.database;
    await db.rawUpdate(
      'UPDATE mascotas SET foto_ruta_nube = ? WHERE id = ?',
      [ruta, id],
    );
  }

  // Para el motor de sync (2026-08-20) — a diferencia de
  // obtenerMascotasPorUsuario, NO filtra `eliminado`: necesita encontrar
  // también las filas borradas para poder empujar el borrado a otro
  // dispositivo. Filtra por `pendiente_push`, no por fecha — un `actualizado_en`
  // más nuevo que la última sync no significa "lo edité yo", puede ser una
  // fila que sync acaba de traer por pull (ver decisiones_arquitectura.md,
  // el hallazgo de por qué `obtenerModificadosDesde` empujaba de vuelta filas
  // recién traídas). `pendiente_push` es la única fuente de verdad de "esto
  // lo tocó este dispositivo y todavía no se subió".
  Future<List<MascotaModel>> obtenerPendientesDePush(String usuarioId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mascotas',
      where: 'usuario_id = ? AND pendiente_push = 1',
      whereArgs: [usuarioId],
    );
    return maps.map((mapa) => MascotaModel.fromMap(mapa)).toList();
  }

  // Se llama después de un push exitoso — apaga la bandera de las filas que
  // ya se subieron, para que no se vuelvan a empujar en la próxima corrida.
  Future<void> marcarComoSincronizadas(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final signosDePregunta = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE mascotas SET pendiente_push = 0 WHERE id IN ($signosDePregunta)',
      ids,
    );
  }

  // Para el motor de sync (2026-08-20) — a diferencia de crearMascota/
  // actualizarMascota, NO pisa `actualizado_en` con la hora actual: tiene
  // que preservar el valor que ya trae la fila (local, al empujar; remota,
  // al traer), porque ese valor es la base de la próxima comparación de
  // conflictos. `insert` con `ConflictAlgorithm.replace` cubre insertar y
  // actualizar en una sola llamada.
  //
  // NO usa `ConflictAlgorithm.replace` (2026-08-21, corrige un bug real de
  // pérdida de datos) — `INSERT OR REPLACE` en SQLite, ante un conflicto de
  // PRIMARY KEY, primero BORRA la fila existente y recién ahí inserta la
  // nueva. Con `PRAGMA foreign_keys = ON` (ver database.helper.md, punto
  // 8b), ese borrado oculto dispara el `ON DELETE CASCADE` real hacia
  // agenda_eventos/documentos — traer por pull la edición de una mascota
  // que ya tenía agenda/documentos locales borraba esos hijos de verdad
  // (no soft-delete), aunque el pull nunca los haya tocado. Se reemplaza
  // por un upsert manual (`INSERT ... ON CONFLICT(id) DO UPDATE`), que es
  // un UPDATE real para una fila existente — no dispara ninguna acción de
  // foreign key. Ver decisiones_arquitectura.md.
  Future<void> guardarDesdeSync(MascotaModel mascota) async {
    final db = await DatabaseHelper.instance.database;
    final mapa = mascota.toMap();
    // pendiente_push = 0 explícito: esta fila queda al día con el
    // servidor (viene de un pull), no hay nada local pendiente de subir.
    mapa['pendiente_push'] = 0;
    final columnas = mapa.keys.toList();
    final actualizaciones = columnas
        .where((c) => c != 'id')
        .map((c) => '$c = excluded.$c')
        .join(', ');
    await db.rawInsert(
      'INSERT INTO mascotas (${columnas.join(', ')}) '
      'VALUES (${List.filled(columnas.length, '?').join(', ')}) '
      'ON CONFLICT(id) DO UPDATE SET $actualizaciones',
      columnas.map((c) => mapa[c]).toList(),
    );
  }

  // Crea una mascota nueva y la marca pendiente de subir a la nube.
  Future<MascotaModel> crearMascota(MascotaModel mascota) async {
    final db = await DatabaseHelper.instance.database;
    // actualizado_en lo fija el repository, no quien llama — Sync (ver
    // sync_service.dart) lo necesita en cada create/update, no solo al
    // editar. Mismo criterio en el resto de los repositories.
    final conTimestamp = mascota.copyWith(actualizadoEn: DateTime.now().toUtc());
    final mapa = conTimestamp.toMap();
    mapa['pendiente_push'] = 1;

    await db.insert('mascotas', mapa);

    return conTimestamp;
  }

  // Filtra `eliminado = 0` — desde Sync (2026-08-20), borrar una mascota es
  // soft-delete (ver eliminarMascota), así que las filas "borradas" siguen
  // existiendo en la tabla. Ver decisiones_arquitectura.md.
  Future<List<MascotaModel>> obtenerMascotasPorUsuario(String usuarioId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mascotas',
      where: 'usuario_id = ? AND eliminado = 0',
      whereArgs: [usuarioId],
    );

    return maps.map((mapa) => MascotaModel.fromMap(mapa)).toList();
  }

  // Sin filtrar por `eliminado` a propósito — el motor de sync necesita
  // poder encontrar y comparar una fila localmente borrada al resolver
  // conflictos (gana el cambio más reciente), no solo las visibles en la UI.
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

  // Actualiza una mascota existente y la marca pendiente de subir a la nube.
  Future<int> actualizarMascota(MascotaModel mascota) async {
    final db = await DatabaseHelper.instance.database;
    final conTimestamp = mascota.copyWith(actualizadoEn: DateTime.now().toUtc());
    final mapa = conTimestamp.toMap();
    mapa['pendiente_push'] = 1;

    final int filasActualizadas = await db.update(
      'mascotas',
      mapa,
      where: 'id = ?',
      whereArgs: [mascota.id],
    );

    return filasActualizadas;
  }

  // Soft-delete, no DELETE real (2026-08-20, Sync) — un DELETE no deja
  // ningún rastro que sincronizar a otro dispositivo. Cascada manual en una
  // transacción (mismo patrón que
  // UsuarioRepository.convertirAInvitadoRegistrado: `txn.rawUpdate` directo
  // sobre las tablas, no llamando a otros repositories, para que las
  // cuatro escrituras sean atómicas) — respeta el mismo alcance que el
  // `ON DELETE CASCADE` real del schema: agenda_eventos, documentos y los
  // medicamentos_evento de esos eventos quedan también soft-deleted.
  Future<int> eliminarMascota(String id) async {
    final db = await DatabaseHelper.instance.database;
    final ahora = DateTime.now().toUtc().toIso8601String();
    late int filasEliminadas;

    await db.transaction((txn) async {
      filasEliminadas = await txn.rawUpdate(
        'UPDATE mascotas SET eliminado = 1, eliminado_en = ?, actualizado_en = ?, pendiente_push = 1 WHERE id = ?',
        [ahora, ahora, id],
      );
      await txn.rawUpdate(
        'UPDATE agenda_eventos SET eliminado = 1, eliminado_en = ?, actualizado_en = ?, pendiente_push = 1 WHERE mascota_id = ?',
        [ahora, ahora, id],
      );
      await txn.rawUpdate(
        '''UPDATE medicamentos_evento SET eliminado = 1, eliminado_en = ?, actualizado_en = ?, pendiente_push = 1
           WHERE agenda_evento_id IN (SELECT id FROM agenda_eventos WHERE mascota_id = ?)''',
        [ahora, ahora, id],
      );
      await txn.rawUpdate(
        'UPDATE documentos SET eliminado = 1, eliminado_en = ?, actualizado_en = ?, pendiente_push = 1 WHERE mascota_id = ?',
        [ahora, ahora, id],
      );
    });

    return filasEliminadas;
  }
}
