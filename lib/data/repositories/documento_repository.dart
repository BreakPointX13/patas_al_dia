import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_al_dia/data/database/database_helper.dart';
import 'package:patas_al_dia/data/models/documento_model.dart';

// Guarda y consulta los documentos (carnet, exámenes, recetas) de una mascota.
class DocumentoRepository {
  // Sube el archivo (PDF o imagen) de un documento al Storage de Supabase.
  // Sync (2026-08-20) — ver mascota_repository.dart, mismo patrón, bucket
  // privado `archivos_documentos`.
  Future<String> subirArchivo({
    required String usuarioId,
    required String documentoId,
    required String rutaLocal,
  }) async {
    final client = Supabase.instance.client;
    final extension = rutaLocal.split('.').last;
    final rutaStorage = '$usuarioId/$documentoId.$extension';
    await client.storage
        .from('archivos_documentos')
        .upload(
          rutaStorage,
          File(rutaLocal),
          fileOptions: const FileOptions(upsert: true),
        );
    return rutaStorage;
  }

  // Descarga el archivo de un documento desde el Storage de Supabase.
  Future<Uint8List> descargarArchivo(String rutaStorage) {
    final client = Supabase.instance.client;
    return client.storage.from('archivos_documentos').download(rutaStorage);
  }

  // Guarda dónde quedó el archivo en la nube, sin tocar `pendiente_push`.
  // Ver mascota_repository.dart, actualizarFotoRutaNube, mismo motivo.
  Future<void> actualizarArchivoRutaNube(String id, String ruta) async {
    final db = await DatabaseHelper.instance.database;
    await db.rawUpdate(
      'UPDATE documentos SET archivo_ruta_nube = ? WHERE id = ?',
      [ruta, id],
    );
  }

  // Devuelve los documentos con cambios locales aún no subidos a la nube.
  // Para el motor de sync (2026-08-20) — ver mascota_repository.dart,
  // obtenerPendientesDePush, para el criterio general (filtra por
  // `pendiente_push`, no por fecha). Acá el usuario se resuelve vía join a
  // `mascotas`.
  Future<List<DocumentoModel>> obtenerPendientesDePush(
    String usuarioId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM documentos WHERE mascota_id IN (SELECT id FROM mascotas WHERE usuario_id = ?) AND pendiente_push = 1',
      [usuarioId],
    );
    return maps.map((mapa) => DocumentoModel.fromMap(mapa)).toList();
  }

  // Apaga la bandera de "pendiente de subir" tras un push exitoso.
  // Ver mascota_repository.dart, marcarComoSincronizadas, mismo criterio.
  Future<void> marcarComoSincronizadas(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final signosDePregunta = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE documentos SET pendiente_push = 0 WHERE id IN ($signosDePregunta)',
      ids,
    );
  }

  // Guarda (inserta o actualiza) un documento que llegó desde otro dispositivo.
  // Ver mascota_repository.dart, guardarDesdeSync, mismo criterio. Acá no
  // hay tabla hija que dependa de `documentos` (sin riesgo de cascada),
  // pero se corrige igual por consistencia y por el mismo problema de
  // `pendiente_push` quedando mal seteado.
  Future<void> guardarDesdeSync(DocumentoModel documento) async {
    final db = await DatabaseHelper.instance.database;
    final mapa = documento.toMap();
    mapa['pendiente_push'] = 0;
    final columnas = mapa.keys.toList();
    final actualizaciones = columnas
        .where((c) => c != 'id')
        .map((c) => '$c = excluded.$c')
        .join(', ');
    await db.rawInsert(
      'INSERT INTO documentos (${columnas.join(', ')}) '
      'VALUES (${List.filled(columnas.length, '?').join(', ')}) '
      'ON CONFLICT(id) DO UPDATE SET $actualizaciones',
      columnas.map((c) => mapa[c]).toList(),
    );
  }

  // Crea un documento nuevo y lo marca pendiente de subir a la nube.
  Future<DocumentoModel> crearDocumento(DocumentoModel documento) async {
    final db = await DatabaseHelper.instance.database;
    final conTimestamp = documento.copyWith(actualizadoEn: DateTime.now().toUtc());
    final mapa = conTimestamp.toMap();
    mapa['pendiente_push'] = 1;

    await db.insert('documentos', mapa);

    return conTimestamp;
  }

  // Devuelve los documentos activos (no borrados) de una mascota.
  // Filtra `eliminado = 0` — ver mascota_repository.dart, mismo criterio.
  Future<List<DocumentoModel>> obtenerDocumentosPorMascota(
    String mascotaId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documentos',
      where: 'mascota_id = ? AND eliminado = 0',
      whereArgs: [mascotaId],
    );

    return maps.map((mapa) => DocumentoModel.fromMap(mapa)).toList();
  }

  // Devuelve los documentos ligados a un evento de agenda puntual.
  Future<List<DocumentoModel>> obtenerDocumentosPorEvento(
    String eventoId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documentos',
      where: 'evento_id = ? AND eliminado = 0',
      whereArgs: [eventoId],
    );

    return maps.map((mapa) => DocumentoModel.fromMap(mapa)).toList();
  }

  // Indica qué eventos de agenda ya tienen algún documento adjunto.
  Future<Set<String>> obtenerEventoIdsConDocumento(
    List<String> eventoIds,
  ) async {
    if (eventoIds.isEmpty) {
      return {};
    }
    final db = await DatabaseHelper.instance.database;
    final placeholders = List.filled(eventoIds.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      'documentos',
      columns: ['evento_id'],
      distinct: true,
      where: 'evento_id IN ($placeholders) AND eliminado = 0',
      whereArgs: eventoIds,
    );
    return maps.map((mapa) => mapa['evento_id'] as String).toSet();
  }

  // Busca un documento por su id, incluidos los borrados.
  // Sin filtrar por `eliminado` a propósito — ver mascota_repository.dart,
  // mismo criterio (lo necesita el motor de sync).
  Future<DocumentoModel?> obtenerDocumentoPorId(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documentos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) {
      return null;
    }
    return DocumentoModel.fromMap(maps.first);
  }

  // Actualiza un documento existente y lo marca pendiente de subir a la nube.
  Future<int> actualizarDocumento(DocumentoModel documento) async {
    final db = await DatabaseHelper.instance.database;
    final conTimestamp = documento.copyWith(actualizadoEn: DateTime.now().toUtc());
    final mapa = conTimestamp.toMap();
    mapa['pendiente_push'] = 1;

    final int filasActualizadas = await db.update(
      'documentos',
      mapa,
      where: 'id = ?',
      whereArgs: [documento.id],
    );

    return filasActualizadas;
  }

  // "Borra" un documento (en realidad lo marca como eliminado).
  // Soft-delete simple, sin hijos (2026-08-20, Sync) — ver
  // mascota_repository.dart para el porqué del soft-delete en general.
  Future<int> eliminarDocumento(String id) async {
    final db = await DatabaseHelper.instance.database;
    final ahora = DateTime.now().toUtc().toIso8601String();

    return db.rawUpdate(
      'UPDATE documentos SET eliminado = 1, eliminado_en = ?, actualizado_en = ?, pendiente_push = 1 WHERE id = ?',
      [ahora, ahora, id],
    );
  }
}
