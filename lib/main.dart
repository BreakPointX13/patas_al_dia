import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/presentation/screens/sesion_inicial_screen.dart';
import 'package:patas_al_dia/services/notificacion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificacionService.instance.inicializar();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patas al Día',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD06D1F),
          surface: const Color(0xFFFFF7EC),
        ),
        scaffoldBackgroundColor: const Color(0xFFFBF0E2),
        fontFamily: 'SourceSans3',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const SesionInicialScreen(),
    );
  }
}
