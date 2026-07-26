import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/documento_model.dart';
import 'package:patas_al_dia/data/repositories/documento_repository.dart';

final documentoRepositoryProvider = Provider<DocumentoRepository>((ref) {
  return DocumentoRepository();
});

class DocumentoNotifier extends Notifier<List<DocumentoModel>> {
  @override
  List<DocumentoModel> build() {
    return [];
  }

  Future<void> cargarDocumentos(String mascotaId) async {
    final repo = ref.read(documentoRepositoryProvider);
    state = await repo.obtenerDocumentosPorMascota(mascotaId);
  }

  Future<void> agregarDocumento(DocumentoModel documento) async {
    final repo = ref.read(documentoRepositoryProvider);
    await repo.crearDocumento(documento);
    state = [...state, documento];
  }

  Future<void> actualizarDocumento(DocumentoModel documento) async {
    final repo = ref.read(documentoRepositoryProvider);
    await repo.actualizarDocumento(documento);
    state = state.map((d) => d.id == documento.id ? documento : d).toList();
  }

  Future<void> eliminarDocumento(String id) async {
    final repo = ref.read(documentoRepositoryProvider);
    await repo.eliminarDocumento(id);
    state = state.where((d) => d.id != id).toList();
  }
}

final documentosProvider = NotifierProvider<DocumentoNotifier, List<DocumentoModel>>(() {
  return DocumentoNotifier();
});
