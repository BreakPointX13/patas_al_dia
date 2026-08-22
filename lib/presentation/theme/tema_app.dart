import 'package:flutter/material.dart';

// Paleta base para modo claro, generada desde el color Naranja de la marca.
final colorSchemeClaro = ColorScheme.fromSeed(
  seedColor: const Color(0xFFD06D1F),
  surface: const Color(0xFFFFF7EC),
);

// Misma semilla de color, versión oscura.
final colorSchemeOscuro = ColorScheme.fromSeed(
  seedColor: const Color(0xFFD06D1F),
  brightness: Brightness.dark,
);

// Arma un ThemeData completo (AppBar, botones, tarjetas, tipografía) a
// partir de un ColorScheme — se reutiliza igual para claro y oscuro.
ThemeData _construirTema(ColorScheme colorScheme) {
  return ThemeData(
    colorScheme: colorScheme,
    fontFamily: 'SourceSans3',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFE0812F),
      foregroundColor: Color(0xFF7A4A22),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFD06D1F),
      foregroundColor: Color(0xFFFFF7EC),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFF3C98F),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF3C98F),
        foregroundColor: const Color(0xFF7A4A22),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
      titleMedium: TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// Naranja/Durazno/Café texto se mantienen igual en los dos temas — son
// colores de acento fijos de la marca, no dependen del brillo general de
// la app (ver decisiones_arquitectura.md, entrada del 2026-08-18). Lo único
// que cambia entre temas es el fondo: Crema en claro, gris oscuro cálido
// en oscuro.
final temaClaro = _construirTema(
  colorSchemeClaro,
).copyWith(scaffoldBackgroundColor: const Color(0xFFFBF0E2));

final temaOscuro = _construirTema(
  colorSchemeOscuro,
).copyWith(scaffoldBackgroundColor: const Color(0xFF1E1811));
