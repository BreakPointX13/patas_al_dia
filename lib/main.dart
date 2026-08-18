import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:patas_al_dia/presentation/screens/sesion_inicial_screen.dart';
import 'package:patas_al_dia/presentation/theme/tema_app.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';
import 'package:patas_al_dia/services/notificacion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  await NotificacionService.instance.inicializar();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioProvider);
    final escalaTexto = usuario?.escalaTexto ?? 1.0;
    final themeMode = switch (usuario?.tema) {
      'claro' => ThemeMode.light,
      'oscuro' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return MaterialApp(
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
          child: child!,
        );
      },
      title: 'Patas al Día',
      theme: temaClaro,
      darkTheme: temaOscuro,
      themeMode: themeMode,
      home: const SesionInicialScreen(),
    );
  }
}
