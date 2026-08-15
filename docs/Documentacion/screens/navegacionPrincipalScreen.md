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
