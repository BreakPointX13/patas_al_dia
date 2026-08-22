import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/services/sync_service.dart';

// Instancia única del motor de sync.
final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));

// Doble función (2026-08-20, Sync): señal visible para la UI
// ("sincronizando...", ver ajustesScreen.md) Y bandera de "ya hay una
// sincronización en curso" (SyncService la revisa antes de arrancar otra) —
// no hace falta un flag privado aparte para eso.
class SincronizandoNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void establecer(bool valor) => state = valor;
}

final sincronizandoProvider = NotifierProvider<SincronizandoNotifier, bool>(
  SincronizandoNotifier.new,
);
