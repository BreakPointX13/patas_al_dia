# Nota de Obsidian: `NavegacionPrincipalScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/navegacion_principal_screen.dart`

Es el nuevo destino de `SesionInicialScreen` cuando hay sesión activa, en reemplazo directo de `HomeScreen` en ese rol (`HomeScreen` sigue existiendo, pero ahora vive *dentro* de esta pantalla, como raíz de la pestaña Mascotas).

## 🎯 Propósito del Archivo

Pantalla "marco" de toda la app: arma la barra de navegación inferior (Mascotas / Agenda / Mapa) y aloja las tres pestañas principales. Cada pestaña mantiene su propio estado y su propia pila de navegación por separado — ver la entrada del 2026-08-12 en `decisiones_arquitectura.md` para el porqué de esta decisión frente a la alternativa más simple (un solo `Navigator` compartido).

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Es el patrón "bottom navigation con Navigator anidado", el mismo que usan apps como Instagram o YouTube: cada pestaña se comporta como una mini-app independiente con su propio historial de pantallas, y la barra inferior queda fija encima de todas.

### 🐾 En Nuestro Proyecto "Patas al día"

`StatefulWidget` simple (no `ConsumerStatefulWidget`): esta pantalla no necesita hablar con ningún provider directamente, solo administra en qué pestaña está el usuario.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `List<GlobalKey<NavigatorState>> _navegadoresPorPestana`

```dart
final List<GlobalKey<NavigatorState>> _navegadoresPorPestana =
    List.generate(3, (_) => GlobalKey<NavigatorState>());
```

Cada pestaña tiene su propio `Navigator` (más abajo), y cada `Navigator` necesita una `GlobalKey` propia para que el resto del código pueda referirse a "el `Navigator` de la pestaña 0" y llamar métodos sobre él (`.pop()`, `.canPop()`, `.popUntil()`) desde afuera.

### 2. `_construirPestana(int indice)`

```dart
Widget _construirPestana(int indice) {
  return Navigator(
    key: _navegadoresPorPestana[indice],
    onGenerateRoute: (settings) => MaterialPageRoute(
      builder: (context) => _pantallasRaiz[indice],
    ),
  );
}
```

Crea un `Navigator` completo e independiente para una pestaña, con su pantalla raíz (`HomeScreen`, `AgendaScreen` o `MapaScreen`) como única ruta inicial. A partir de ahí, cualquier `Navigator.of(context).push(...)` que se haga *dentro* de esa pestaña (por ejemplo, abrir `DetalleMascotaScreen` desde `HomeScreen`) se apila en este `Navigator`, no en el de la app entera.

### 3. `IndexedStack`

```dart
body: IndexedStack(
  index: _indiceActual,
  children: List.generate(3, _construirPestana),
),
```

Construye las tres pestañas al mismo tiempo pero solo *muestra* la que corresponde a `_indiceActual`. La diferencia con reconstruir una sola pestaña cada vez (por ejemplo, con un `IndexedStack` reemplazado por un simple `if`) es que las otras dos quedan vivas en memoria — no pierden su scroll, su pila de navegación ni ningún estado al cambiar de pestaña y volver.

### 4. `_cambiarPestana(int indice)` — tocar la pestaña activa de nuevo

```dart
void _cambiarPestana(int indice) {
  if (indice == _indiceActual) {
    _navegadoresPorPestana[indice].currentState?.popUntil(
      (route) => route.isFirst,
    );
    return;
  }
  setState(() => _indiceActual = indice);
}
```

Si el usuario toca la pestaña en la que ya está, en vez de no hacer nada, se manda esa pestaña de vuelta a su pantalla raíz (`popUntil((route) => route.isFirst)`) — el mismo comportamiento que se ve en apps como Instagram al tocar dos veces el mismo ícono.

### 4b. Barra inferior más baja (2026-08-16), esquinas rectas (2026-08-19)

Altura reducida (76, antes 80 por defecto de `NavigationBar`). Tuvo esquinas superiores curvas desde el 2026-08-16 (`ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))`) hasta que el usuario pidió volver a un rectángulo normal, sin curvas — se sacó el `ClipRRect` que envolvía el `Container` de la barra.

### 4c. Barra inferior propia, en vez de `NavigationBar` de Material (2026-08-16)

Durante la pasada de colores (ver la entrada correspondiente en `decisiones_arquitectura.md`), el `NavigationBar` de Material se reemplazó por una barra armada a mano (`_construirItemBarra`, un `Row` de 3 `Expanded` dentro de un `Container`). Motivo: el indicador de pestaña seleccionada de `NavigationBar` solo colorea un óvalo alrededor del ícono, dejando la etiqueta de texto suelta sin ningún tratamiento visual — el usuario pidió explícitamente que el "iluminado" fuera un solo panel envolviendo ícono *y* texto juntos, algo que el widget estándar no permite configurar.

```dart
Widget _construirItemBarra(int indice) {
  final seleccionado = indice == _indiceActual;
  return Expanded(
    child: InkWell(
      onTap: () => _cambiarPestana(indice),
      child: Center(
        child: AnimatedContainer(
          width: 92, // ancho fijo — ver más abajo
          decoration: BoxDecoration(
            color: seleccionado ? const Color(0xFFF3C98F) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [Icon(...), Text(...)]),
        ),
      ),
    ),
  );
}
```

- **`width: 92` fijo:** la primera versión dejaba que el panel se ajustara al ancho del texto (`mainAxisSize.min`), lo que hacía que "Mascotas" tuviera un panel visiblemente más ancho que "Mapa" al seleccionarse — inconsistencia que el usuario notó de inmediato. Un ancho fijo, igual para las 3 pestañas, lo resuelve sin tener que medir el texto más largo en tiempo de ejecución.
- **El texto nunca cambia de color** (siempre Café texto `#7A4A22`, seleccionada o no) — a propósito: el usuario probó primero una versión donde el texto se oscurecía/engordaba al seleccionarse (imitando el color+peso del ícono) y pidió deshacerlo; el único indicador de selección es el fondo del panel.
- **`_destinos`** (record `{icono, etiqueta}`, no una clase nueva) reemplaza los `NavigationDestination` que traía `NavigationBar` — se conserva la misma lista de 3 (Mascotas/Agenda/Mapa) pero como datos propios en vez de un widget de Material.

### 5. `PopScope` — el botón "atrás" del dispositivo

```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    final navegadorActual = _navegadoresPorPestana[_indiceActual].currentState;
    if (navegadorActual != null && navegadorActual.canPop()) {
      navegadorActual.pop();
    } else {
      SystemNavigator.pop();
    }
  },
  ...
)
```

Sin esto, el botón "atrás" de Android cerraría la app entera en vez de retroceder dentro de la pestaña activa (porque, para el `Navigator` raíz de `MaterialApp`, `NavegacionPrincipalScreen` es una sola ruta sin nada más apilado encima — no "sabe" que hay Navigators anidados adentro con su propio historial).

**Bug encontrado y corregido (2026-08-14):** la primera versión calculaba `canPop: !(navegadorActual?.canPop() ?? false)` una sola vez, leyendo `navegadorActual` en el momento del `build()` de `NavegacionPrincipalScreen`. El problema: empujar una pantalla nueva *dentro* de una pestaña (por ejemplo, abrir `FormularioAgendaEventoScreen` desde `AgendaScreen`) no hace que `NavegacionPrincipalScreen` se reconstruya — solo se mueve el `Navigator` anidado de esa pestaña, que es un widget aparte. Como resultado, `canPop` quedaba con un valor viejo (`true`, calculado antes de empujar nada), y el botón "atrás" del sistema cerraba la app entera en vez de volver a la pantalla anterior dentro de la pestaña.

**La solución:** fijar `canPop` siempre en `false`, para que el sistema *siempre* delegue la decisión a `onPopInvokedWithResult` — y ahí sí, recién en el momento real de la pulsación, se consulta `navegadorActual.canPop()` fresco (no un valor guardado de antes). Si la pestaña activa tiene algo para retroceder, se hace `navegadorActual.pop()`; si no, se llama a `SystemNavigator.pop()` (de `package:flutter/services.dart`) para cerrar la app, ya que `canPop: false` le quitó ese control por defecto al sistema.

- `canPop`: le dice al sistema si esta pantalla, vista desde afuera, tiene algo para retroceder. Se calcula preguntándole al `Navigator` de la pestaña activa si él puede retroceder (`canPop()`); si puede, `canPop` acá es `false` a propósito, para que el sistema **no** cierre nada solo y nos deje interceptar el gesto.
- `onPopInvokedWithResult`: si el sistema no pudo hacer el pop solo (`didPop == false`), se le pide al `Navigator` de la pestaña activa que retroceda él (`navegadorActual?.pop()`).
- Cuando la pestaña activa ya está en su raíz (no tiene nada para retroceder), `canPop` vuelve a ser `true` y el botón atrás sí cierra la app normalmente.

### 6. Etiquetas del navbar vía `AppLocalizations` (2026-08-18)

`_destinos` (el record `{icono, etiqueta}` original) se dividió en dos: `_iconosDestino` (`static const`, no cambia con el idioma) y una lista de etiquetas armada dentro de `_construirItemBarra(BuildContext context, int indice)` a partir de `AppLocalizations.of(context)` — un record `static const` no puede contener el resultado de `l10n.navMascotas` (no es una constante de compilación), así que dejó de tener sentido guardar íconos y etiquetas juntos en la misma estructura. Ver `sistemaIdiomas.md`.

### 7. `_indiceNotifier` — avisarle a una pestaña ya montada que cambió el índice (2026-08-19)

```dart
final _indiceNotifier = ValueNotifier<int>(0);

List<Widget> get _pantallasRaiz => [
  const HomeScreen(),
  const AgendaScreen(),
  MapaScreen(indiceActualNotifier: _indiceNotifier),
];
```

`_pantallasRaiz` pasó de `static const` a un getter de instancia porque `MapaScreen` necesita recibir `_indiceNotifier` — un objeto mutable, no puede vivir dentro de una lista `const`. Se agregó porque `MapaScreen` necesitaba enterarse de cuándo el usuario entra *de verdad* a la pestaña Mapa (para mostrar un aviso una sola vez, ver `mapaScreen.md`, punto 0) — algo que su propio `initState()` no puede resolver solo, dado que `IndexedStack` (punto 3) construye las tres pantallas desde el arranque, no cuando se seleccionan. `_cambiarPestana()` actualiza `_indiceNotifier.value` junto con `_indiceActual` (el `int` que ya existía, usado para `IndexedStack.index` y para resaltar la pestaña activa) — dos formas de guardar lo mismo: `_indiceActual` para lo que necesita leerse de forma síncrona en `build()`, `_indiceNotifier` para lo que necesita *notificarse* a un widget que ya está montado.
