import 'package:patas_al_dia/data/database/database_helper.dart';
import 'package:patas_al_dia/data/models/documento_model.dart';

class DocumentoRepository {
  Future<DocumentoModel> crearDocumento(DocumentoModel documento) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert('documentos', documento.toMap());

    return documento;
  }

  Future<List<DocumentoModel>> obtenerDocumentosPorMascota(
    String mascotaId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documentos',
      where: 'mascota_id = ?',
      whereArgs: [mascotaId],
    );

    return maps.map((mapa) => DocumentoModel.fromMap(mapa)).toList();
  }

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

  Future<int> actualizarDocumento(DocumentoModel documento) async {
    final db = await DatabaseHelper.instance.database;

    final int filasActualizadas = await db.update(
      'documentos',
      documento.toMap(),
      where: 'id = ?',
      whereArgs: [documento.id],
    );

    return filasActualizadas;
  }

  Future<int> eliminarDocumento(String id) async {
    final db = await DatabaseHelper.instance.database;
    final int filasEliminadas = await db.delete(
      'documentos',
      where: 'id = ?',
      whereArgs: [id],
    );

    return filasEliminadas;
  }
}
