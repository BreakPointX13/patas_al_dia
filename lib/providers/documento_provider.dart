import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/documento_model.dart';
import 'package:patas_al_dia/data/repositories/documento_repository.dart';

// Instancia única del repository, para no crearla de nuevo en cada pantalla.
final documentoRepositoryProvider = Provider<DocumentoRepository>((ref) {
  return DocumentoRepository();
});

// Guarda en memoria los documentos ya cargados, para que la UI no lea SQLite en cada build.
class DocumentoNotifier extends Notifier<List<DocumentoModel>> {
  @override
  List<DocumentoModel> build() {
    return [];
  }

  // Trae de SQLite todos los documentos de una mascota.
  Future<void> cargarDocumentos(String mascotaId) async {
    final repo = ref.read(documentoRepositoryProvider);
    state = await repo.obtenerDocumentosPorMascota(mascotaId);
  }

  // Trae de SQLite los documentos adjuntos a un evento de agenda.
  Future<void> cargarDocumentosDeEvento(String eventoId) async {
    final repo = ref.read(documentoRepositoryProvider);
    state = await repo.obtenerDocumentosPorEvento(eventoId);
  }

  // Guarda un documento nuevo y lo agrega al estado en memoria.
  Future<void> agregarDocumento(DocumentoModel documento) async {
    final repo = ref.read(documentoRepositoryProvider);
    await repo.crearDocumento(documento);
    state = [...state, documento];
  }

  // Guarda los cambios de un documento existente y refresca el estado en memoria.
  Future<void> actualizarDocumento(DocumentoModel documento) async {
    final repo = ref.read(documentoRepositoryProvider);
    await repo.actualizarDocumento(documento);
    state = state.map((d) => d.id == documento.id ? documento : d).toList();
  }

  // Borra (soft-delete) un documento y lo saca del estado en memoria.
  Future<void> eliminarDocumento(String id) async {
    final repo = ref.read(documentoRepositoryProvider);
    await repo.eliminarDocumento(id);
    state = state.where((d) => d.id != id).toList();
  }
}

final documentosProvider = NotifierProvider<DocumentoNotifier, List<DocumentoModel>>(() {
  return DocumentoNotifier();
});
