import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
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

  static const _iconosDestino = [Icons.pets, Icons.event_note, Icons.map];

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

  // Barra propia (en vez del NavigationBar de Material) para que la "luz"
  // de la pestaña activa sea un panel que envuelve ícono + texto juntos,
  // en vez de solo el ícono como hace el indicador estándar de Material 3.
  Widget _construirItemBarra(BuildContext context, int indice) {
    final l10n = AppLocalizations.of(context);
    final etiquetas = [l10n.navMascotas, l10n.navAgenda, l10n.navMapa];
    final seleccionado = indice == _indiceActual;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _cambiarPestana(indice),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 92,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: seleccionado
                  ? const Color(0xFFF3C98F)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconosDestino[indice],
                  color: const Color(0xFF7A4A22),
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  etiquetas[indice],
                  style: const TextStyle(
                    color: Color(0xFF7A4A22),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Siempre en false: así el botón "atrás" del sistema pasa siempre por
      // onPopInvokedWithResult, donde se consulta el Navigator de la pestaña
      // activa en el momento real de la pulsación (no un valor calculado en
      // el último build de este widget, que puede haber quedado desactualizado
      // si se navegó dentro de la pestaña sin que este widget se reconstruya).
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        final navegadorActual =
            _navegadoresPorPestana[_indiceActual].currentState;
        if (navegadorActual != null && navegadorActual.canPop()) {
          navegadorActual.pop();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _indiceActual,
          children: List.generate(3, _construirPestana),
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          child: Container(
            height: 76,
            color: const Color(0xFFE0812F),
            child: SafeArea(
              top: false,
              child: Row(
                children: List.generate(
                  _iconosDestino.length,
                  (indice) => _construirItemBarra(context, indice),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
