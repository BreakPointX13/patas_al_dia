import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/repositories/documento_repository.dart';

final documentoRepositoryProvider = Provider<DocumentoRepository>((ref) {
  return DocumentoRepository();
});
