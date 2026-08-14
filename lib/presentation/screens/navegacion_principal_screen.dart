import 'package:flutter/material.dart';
import 'package:patas_al_dia/presentation/screens/agenda_screen.dart';
import 'package:patas_al_dia/presentation/screens/home_screen.dart';
import 'package:patas_al_dia/presentation/screens/mapa_screen.dart';

/// Pantalla "marco": contiene la barra de navegación inferior y las tres
/// pestañas principales (Mascotas, Agenda, Mapa). Cada pestaña tiene su
/// propio Navigator independiente, así que conserva su propia pila de
/// pantallas y su estado al cambiar entre pestañas.
class NavegacionPrincipalScreen extends StatefulWidget {
  const NavegacionPrincipalScreen({super.key});

  @override
  State<NavegacionPrincipalScreen> createState() =>
      _NavegacionPrincipalScreenState();
}

class _NavegacionPrincipalScreenState
    extends State<NavegacionPrincipalScreen> {
  int _indiceActual = 0;

  final List<GlobalKey<NavigatorState>> _navegadoresPorPestana =
      List.generate(3, (_) => GlobalKey<NavigatorState>());

  static const _pantallasRaiz = [HomeScreen(), AgendaScreen(), MapaScreen()];

  void _cambiarPestana(int indice) {
    if (indice == _indiceActual) {
      _navegadoresPorPestana[indice].currentState?.popUntil(
        (route) => route.isFirst,
      );
      return;
    }
    setState(() => _indiceActual = indice);
  }

  Widget _construirPestana(int indice) {
    return Navigator(
      key: _navegadoresPorPestana[indice],
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) => _pantallasRaiz[indice],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navegadorActual = _navegadoresPorPestana[_indiceActual].currentState;

    return PopScope(
      canPop: !(navegadorActual?.canPop() ?? false),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        navegadorActual?.pop();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _indiceActual,
          children: List.generate(3, _construirPestana),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indiceActual,
          onDestinationSelected: _cambiarPestana,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.pets), label: 'Mascotas'),
            NavigationDestination(
              icon: Icon(Icons.event_note),
              label: 'Agenda',
            ),
            NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
          ],
        ),
      ),
    );
  }
}
