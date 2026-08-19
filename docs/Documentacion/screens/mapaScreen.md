# Nota de Obsidian: `MapaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/mapa_screen.dart`

Tercera pestaña del navbar inferior (`NavegacionPrincipalScreen`), junto a Mascotas y Agenda — hasta ahora un placeholder ("Próximamente"), primer contenido real: el aviso de política de uso.

## 🎯 Propósito del Archivo

Todavía es mayormente un placeholder — el contenido real del módulo Mapa (lista/mapa de reportes activos, ver `formularioReporteMascotaExtraviadaScreen.md`) está pendiente. Lo que sí tiene desde el 2026-08-19 es el aviso de política de uso que se muestra la primera vez que un usuario entra a esta pestaña.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 0. `indiceActualNotifier` — por qué no alcanza con `initState()` (2026-08-19, bug encontrado al probar)

`NavegacionPrincipalScreen` arma las tres pestañas con `IndexedStack` dentro de `Navigator`s propios con `GlobalKey` (ver `navegacionPrincipalScreen.md`) — eso significa que **las tres pantallas se construyen desde el arranque de la app**, aunque solo una esté visible, y encima cada `Navigator` solo genera su ruta inicial una vez (no se reconstruye al cambiar de pestaña). Consecuencia: el primer intento de este aviso (mostrarlo desde `initState()` de `MapaScreen`) se disparaba apenas arrancaba la app, no cuando el usuario realmente tocaba la pestaña Mapa — el usuario lo notó probando ("es posible desplegar el anuncio cuando uno ingresa al módulo mapa en vez de que sea desde el inicio").

La solución fue agregarle a `MapaScreen` un `ValueNotifier<int> indiceActualNotifier` — la misma instancia que `NavegacionPrincipalScreen` actualiza en `_cambiarPestana()` cada vez que el usuario toca una pestaña. Como es un objeto mutable (no un valor primitivo capturado en el momento de construir el widget), `MapaScreen` puede agregarle un listener en `initState()` y enterarse en tiempo real de cambios de pestaña futuros, aunque la pantalla en sí ya esté montada desde el principio:

```dart
static const _indiceMapa = 2; // mismo orden que _pantallasRaiz/_iconosDestino

void _alCambiarPestana() {
  if (widget.indiceActualNotifier.value == _indiceMapa) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarAvisoSiCorresponde());
  }
}
```

`_pantallasRaiz` en `NavegacionPrincipalScreen` pasó de `static const` a un getter de instancia (`List<Widget> get _pantallasRaiz => [...]`) porque ya no puede ser una constante de compilación — necesita pasarle `_indiceNotifier` (un campo de la instancia) a `MapaScreen`.

### 1. `_mostrarAvisoSiCorresponde()` — una sola vez, no en cada visita

```dart
Future<void> _mostrarAvisoSiCorresponde() async {
  final usuario = ref.read(usuarioProvider);
  if (usuario == null || usuario.avisoMapaVisto || _mostrandoAviso || !mounted) return;
  _mostrandoAviso = true;
  ...
  await showDialog<void>(context: context, barrierDismissible: false, ...);
  await ref.read(usuarioProvider.notifier).marcarAvisoMapaVisto();
}
```

Se llama vía `WidgetsBinding.instance.addPostFrameCallback` desde `_alCambiarPestana()` (mismo patrón que el resto de las pantallas del proyecto que necesitan hacer algo apenas termina un `build()` — no se puede mostrar un diálogo en medio de un ciclo de build). Chequea `usuario.avisoMapaVisto` (ver `usuario.model.md`) antes de mostrar nada — si ya está en `true`, no hace nada. `_mostrandoAviso` es una guarda aparte (no persistida, solo dura mientras la pantalla está montada): evita abrir el diálogo dos veces si el usuario entra y sale de la pestaña Mapa varias veces seguidas antes de llegar a cerrarlo la primera vez. Decisión explícita del usuario sobre la frecuencia: se prefirió mostrarlo una única vez (con el costo de tener que reinstalar la app para agregar la columna nueva) en vez de mostrarlo en cada visita a la pestaña, que sería más insistente con el uso normal.

### 2. `barrierDismissible: false` — hay que leerlo, no se puede saltar

El diálogo no se cierra tocando afuera ni con el botón "atrás" — la única salida es el botón "Entendido", que además es el que dispara `marcarAvisoMapaVisto()`. Tiene sentido tratándose de un aviso de política de uso: si se pudiera descartar sin leerlo, perdería el propósito (informar sobre el uso adecuado del módulo y motivar a denunciar contenido que no corresponda).

### 3. Logo de la app en el diálogo

```dart
title: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Image.asset('assets/images/logo_patas_al_dia.png', width: 64, height: 64),
    const SizedBox(height: 12),
    Text(l10n.avisoMapaTitulo, textAlign: TextAlign.center),
  ],
),
```

Pedido explícito del usuario, "para darle más profesionalismo" — mismo asset que ya usa `LoginScreen` (`assets/images/logo_patas_al_dia.png`, ver `loginScreen.md`), a un tamaño más chico (64 vs. 140) por tratarse de un ícono dentro de un diálogo, no la pantalla completa de bienvenida. Se pone dentro del slot `title` del `AlertDialog` (envuelto en una `Column`), no como un widget aparte arriba — es la forma estándar de Material de centrar contenido mixto (imagen + texto) en el encabezado de un diálogo.

### 4. Por qué esto vive en `MapaScreen` y no en un widget separado

A diferencia de `SeparadorSeccionFicha`/`TarjetaClara` (widgets reutilizables en varias pantallas), este diálogo solo se muestra desde un único lugar — no hay necesidad de extraerlo a `presentation/widgets/` todavía. Si en el futuro apareciera un segundo lugar que necesite mostrar la misma política (por ejemplo, un link "Política de uso de Mapa" en `AjustesScreen`), ahí sí valdría la pena extraerlo.

### 5. Pendiente: contenido real de la pestaña, y el botón "Denunciar"

El cuerpo de la pantalla (`Center(child: Text('Próximamente'))`) sigue siendo un placeholder — la lista/mapa de reportes activos (`mascotaExtraviadaProvider.cargarReportesActivos()`, ver `mascotaExtraviadaNotifier.md`) todavía no está construida. Cuando se construya, cada reporte va a necesitar un botón "Denunciar este aviso" (mecanismo de moderación acordado con el usuario: denuncia manual + revisión del desarrollador desde el panel de Supabase, sin ocultado automático ni moderación por IA) — pendiente de diseñar la tabla de denuncias y la UI correspondiente.
