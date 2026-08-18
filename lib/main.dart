import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/sesion_inicial_screen.dart';
import 'package:patas_al_dia/presentation/theme/tema_app.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';
import 'package:patas_al_dia/services/notificacion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('pt_BR');
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
    final locale = switch (usuario?.idioma) {
      'es' => const Locale('es'),
      'en' => const Locale('en'),
      'pt' => const Locale('pt'),
      _ => null, // 'sistema' (o sin usuario todavía) — sigue el del sistema
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
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SesionInicialScreen(),
    );
  }
}
