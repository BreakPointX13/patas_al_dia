import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patas_al_dia/main.dart';

void main() {
  testWidgets('LoginScreen muestra el título y ambas opciones de acceso', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('Patas al Día'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Continuar como invitado'), findsOneWidget);
  });

  testWidgets(
    'Tocar "Iniciar sesión" muestra el aviso de que no está disponible',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();

      expect(
        find.text(
          'Inicio de sesión no disponible todavía: estamos en fase de desarrollo.',
        ),
        findsOneWidget,
      );
    },
  );
}
