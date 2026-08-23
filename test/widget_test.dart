import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/login_screen.dart';

// Envuelve un widget con lo mismo que main.dart le da a toda la app
// (Riverpod + AppLocalizations) — sin esto, cualquier pantalla que use
// `AppLocalizations.of(context)` explota en el test.
Widget _appDePrueba(Widget home) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('es'), // fijo, para no depender del idioma del entorno de test
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void main() {
  testWidgets('LoginScreen muestra el título y las opciones de acceso', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_appDePrueba(const LoginScreen()));

    expect(find.text('Patas al Día'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Continuar como invitado'), findsOneWidget);
    expect(find.text('Política de privacidad'), findsOneWidget);
  });

  testWidgets('Tocar "Iniciar sesión" abre la pantalla de inicio de sesión', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_appDePrueba(const LoginScreen()));

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Correo electrónico'), findsOneWidget);
  });
}
