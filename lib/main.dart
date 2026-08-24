import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:patas_al_dia/data/models/usuario_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/nueva_contrasena_screen.dart';
import 'package:patas_al_dia/presentation/screens/sesion_inicial_screen.dart';
import 'package:patas_al_dia/presentation/theme/tema_app.dart';
import 'package:patas_al_dia/providers/sync_provider.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';
import 'package:patas_al_dia/services/notificacion_service.dart';
import 'package:patas_al_dia/services/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Necesaria para poder navegar desde fuera del árbol de widgets — el
// listener de abajo (AuthChangeEvent.passwordRecovery) se dispara cuando el
// usuario toca el enlace de "olvidé mi contraseña" en su correo, en
// cualquier momento de la vida de la app, sin ningún BuildContext propio a
// mano. Ver recuperarContrasenaScreen.md / nuevaContrasenaScreen.md.
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  // supabase_flutter captura solo el enlace (usa app_links por debajo, ver
  // AndroidManifest.xml/Info.plist para el esquema patasaldia://) y
  // establece una sesión de recuperación — acá solo hace falta reaccionar a
  // ese evento navegando a la pantalla de contraseña nueva.
  Supabase.instance.client.auth.onAuthStateChange.listen(
    (data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const NuevaContrasenaScreen()),
        );
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      // El enlace puede estar vencido o ya usado — Supabase lo reporta como
      // un error del stream, no un evento. Sin BuildContext fácil acá para
      // mostrar un mensaje traducido, se deja el log; el usuario ve la app
      // arrancar normal (sin la pantalla de contraseña nueva) en vez de
      // quedar colgado en ningún lado.
      debugPrint('DEBUG onAuthStateChange error (enlace de recuperación): $error');
    },
  );
  await initializeDateFormatting('es_ES');
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('pt_BR');
  await NotificacionService.instance.inicializar();

  // Bug conocido de flutter_map (2026-08-24, ver decisiones_arquitectura.md):
  // usa un tamaño de cámara "imposible" (literalmente Infinity) como valor
  // de arranque mientras el mapa recién se está armando en pantalla. Si un
  // gesto (toque, pellizco) llega justo en esa ventana, dispara un cálculo
  // roto que se repite en cadena por cada evento pendiente de la misma
  // racha — decenas de excepciones por milisegundo, cada una imprimiendo un
  // stack trace completo, hasta agotar la memoria y congelar la app. No se
  // puede parchar la librería directo; acá se ignora puntualmente esta
  // excepción conocida (nunca otras) para que la racha se vacíe rápido y en
  // silencio, en vez de con el costo de imprimir cada una.
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error is UnsupportedError && error.message == 'Infinity or NaN toInt') {
      return true;
    }
    return false;
  };

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  Timer? _timerSync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciarTimerSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerSync?.cancel();
    super.dispose();
  }

  // Corre mientras la app está en primer plano — se reinicia cada vez que
  // vuelve a `resumed` y se cancela al pasar a `paused` (ver
  // didChangeAppLifecycleState). La guarda de invitado/sin sesión vive
  // adentro de SyncService, no hace falta repetirla acá.
  void _iniciarTimerSync() {
    _timerSync?.cancel();
    _timerSync = Timer.periodic(
      const Duration(minutes: 5),
      (_) => ref.read(syncServiceProvider).sincronizar(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _iniciarTimerSync();
      ref.read(syncServiceProvider).sincronizar();
    } else if (state == AppLifecycleState.paused) {
      _timerSync?.cancel();
      // Intento best-effort antes de pasar a segundo plano — puede no
      // alcanzar a terminar si el sistema mata el proceso, pero cubre el
      // caso común de que solo se minimice.
      ref.read(syncServiceProvider).sincronizar();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dispara al momento exacto en que el usuario pasa a ser "elegible
    // para sync" (con sesión y no invitado) — cubre de una sola vez
    // arranque en frío con sesión ya existente, login, registro y
    // conversión de invitado a registrado.
    ref.listen<UsuarioModel?>(usuarioProvider, (anterior, actual) {
      final anteriorElegible = anterior != null && !anterior.esInvitado;
      final actualElegible = actual != null && !actual.esInvitado;
      if (!anteriorElegible && actualElegible) {
        ref.read(syncServiceProvider).sincronizar();
      }
    });
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
      navigatorKey: navigatorKey,
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
