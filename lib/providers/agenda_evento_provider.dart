import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/repositories/agenda_evento_repository.dart';

final agendaEventoRepositoryProvider = Provider<AgendaEventoRepository>((ref) {
  return AgendaEventoRepository();
});
