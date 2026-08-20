# Nota de Obsidian: `MapaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/mapa_screen.dart`

Tercera pestaña del navbar inferior (`NavegacionPrincipalScreen`), junto a Mascotas y Agenda — hasta ahora un placeholder ("Próximamente"), primer contenido real: el aviso de política de uso.

## 🎯 Propósito del Archivo

Cuerpo real del módulo Mapa: mapa (`flutter_map`) con los reportes activos que tienen ubicación, más una fila horizontal aparte para los que no, un FAB para crear un reporte nuevo (en cualquiera de sus tres variantes, ver `formularioReporteMascotaExtraviadaScreen.md`), y el aviso de política de uso que se muestra la primera vez que un usuario entra a esta pestaña.

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

### 5. `_cargarReportes()` — reactivo, sin paquete de conectividad (2026-08-19)

```dart
Future<void> _cargarReportes() async {
  setState(() { _cargando = true; _error = false; });
  try {
    await ref.read(mascotaExtraviadaProvider.notifier).cargarReportesActivos();
  } catch (_) {
    _error = true;
  } finally {
    if (mounted) setState(() => _cargando = false);
  }
}
```

Se llama una sola vez desde `initState()` (no está atado al cambio de pestaña como el aviso — cargar datos en segundo plano apenas arranca la app no genera ninguna intrusión visual, a diferencia de un diálogo). Mismo criterio "sin conexión" que el resto del módulo (ver `formularioReporteMascotaExtraviadaScreen.md`, punto 5): se intenta la consulta y, si falla, `_error = true` muestra un texto (`errorCargarReportes`) con un botón para reintentar — sin ningún paquete de detección de conectividad.

### 6. Mapa como único contenido de la pantalla (2026-08-19, simplificado el mismo día)

```dart
final conUbicacion = reportes.where((r) => r.ubicacionLat != null && r.ubicacionLng != null).toList();
```

Hasta el mismo día, la ubicación era opcional en el formulario de reporte, así que un mapa por sí solo no podía mostrar todos los reportes activos — uno sin coordenadas no tiene dónde dibujarse. Se probaron dos soluciones (una vista de lista completa aparte, descartada por complejidad; después una fila horizontal fija de chips, y por último un botón que abría un `showModalBottomSheet`) antes de que el usuario decidiera resolverlo de raíz: la ubicación pasó a ser **obligatoria** en el formulario (ver `formularioReporteMascotaExtraviadaScreen.md`, punto 3) — con eso, nunca va a haber reportes sin ubicación, y todo el mecanismo de "reportes sin ubicación" (botón, bottom sheet, claves de traducción) se sacó por completo, sin dejarlo como código muerto.

`conUbicacion` se mantiene como filtro defensivo (no como feature) — solo protege contra reportes de prueba viejos, de antes del cambio a obligatoria, que puedan haber quedado sin ubicación en la base (el `!` de `reporte.ubicacionLat!` al armar cada `Marker` crashearía si alguno fuera `null`). Reportes así simplemente no se dibujan en el mapa; no hay ninguna otra forma de acceder a ellos desde la UI.

Los marcadores se colorean por `tipo` (amarillo para `'perdido'`, azul para `'encontrado'`, ver `iconoTipoReporte.md`) para poder distinguir de un vistazo qué tipo de reporte es cada uno, sin tener que entrar al detalle.

**Bug encontrado al probar: el mapa no se dibujaba con cero reportes activos.** La primera versión tenía `if (reportes.isEmpty) return Center(child: Text(l10n.sinReportesActivos));` como guarda temprana — con la lista de Supabase todavía vacía (antes de publicar el primer reporte), esa condición se cumplía siempre y el `FlutterMap` nunca llegaba a construirse, dejando la pestaña Mapa mostrando solo texto, sin ningún mapa interactivo detrás. El usuario lo notó probando ("solo falta añadir el mapa"). Se corrigió sacando esa guarda por completo: `_construirMapa(conUbicacion)` ahora se construye siempre (dentro de un `Stack`), y el aviso de "sin reportes" pasa a ser un `Card` flotante (`Positioned(top: 12, left: 12, right: 12, ...)`) que se superpone al mapa en vez de reemplazarlo — el mapa queda navegable de entrada, incluso sin ningún reporte publicado todavía.

### 7. `_abrirOpcionesReportar()` / `_elegirMascotaParaPerdida()` — el FAB cubre las tres variantes (2026-08-19)

El FAB abre un `showModalBottomSheet` con dos opciones: "Perdí una mascota" y "Encontré una mascota" (`opcionReportarPerdida`/`opcionReportarEncontrada`). La segunda navega directo a `FormularioReporteMascotaExtraviadaScreen(tipo: 'encontrado')` (siempre `mascota: null`, ver el formulario). La primera llama a `_elegirMascotaParaPerdida()`, que:

```dart
final mascotas = ref.read(mascotasProvider);
if (mascotas.isEmpty) {
  _irAFormulario(tipo: 'perdido'); // directo, sin selector — no hay entre qué elegir
  return;
}
final resultado = await showModalBottomSheet<Object?>(
  ...
  for (final mascota in mascotas) ListTile(..., onTap: () => Navigator.of(context).pop(mascota)),
  ListTile(title: Text(l10n.opcionMascotaNoRegistrada), onTap: () => Navigator.of(context).pop(_mascotaNoRegistrada)),
);
if (resultado == null || !mounted) return; // cerrado sin elegir nada
_irAFormulario(mascota: resultado == _mascotaNoRegistrada ? null : resultado as MascotaModel, tipo: 'perdido');
```

**`_mascotaNoRegistrada` — un sentinel, no `null` directo:** el selector necesita distinguir tres resultados posibles (elegir una mascota de la lista, elegir "otra mascota no registrada", o cerrar el bottom sheet sin elegir nada) usando un tipo de retorno que solo tiene dos estados naturales (`Object?` con `null` o no-`null`). Sin un valor distinto para "no registrada", devolver `null` en ese caso sería indistinguible de "el usuario canceló" — `const _mascotaNoRegistrada = Object();` (una constante de módulo, comparada por identidad) resuelve la ambigüedad sin necesitar una clase/enum nuevo solo para esto.

- **Si el usuario no tiene ninguna mascota registrada, el selector ni se muestra** — va directo al formulario con `mascota: null`, porque no habría nada entre qué elegir.

**`floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat`** (2026-08-19) — mismo patrón que el FAB de `HomeScreen`/`AgendaScreen` (ver `decisiones_arquitectura.md`, entrada del 2026-08-12): centrado abajo, no en la esquina inferior derecha por defecto de Material — pedido explícito del usuario para mantener consistencia visual entre las tres pestañas principales.

### 8. Tiles y atribución — ver `mapaTiles.md`

`_construirMapa` usa `urlTilesSegunTema(context)` y `atribucionMapa` (`lib/presentation/utils/mapa_tiles.dart`) en vez de escribir la URL/atribución acá directo — el mismo helper lo usa `DetalleReporteMascotaExtraviadaScreen`. Ver `mapaTiles.md` para el detalle completo: por qué se cambió de los tiles crudos de OpenStreetMap a CARTO Positron/Dark Matter (el usuario los encontró "feos" al probar la primera versión), y por qué cambian solos según el tema claro/oscuro de la app.

### 9. `_reporteSeleccionado` — burbuja al tocar un marcador, no navegación directa (2026-08-19)

Pedido explícito del usuario, agregado después de probar la primera versión ("me gustaría que los reportes hechos se reflejen en el mapa con una burbuja"). Antes, tocar un marcador navegaba directo a `DetalleReporteMascotaExtraviadaScreen` — ahora abre primero una tarjeta flotando sobre el mapa (mismo patrón que Google Maps/Apple Maps: nombre, tipo, botón de cerrar), y solo al tocar esa tarjeta se navega al detalle completo.

```dart
MascotaExtraviadaModel? _reporteSeleccionado;

// En el MarkerLayer:
onTap: () => setState(() => _reporteSeleccionado = reporte),

// En MapOptions:
onTap: (_, _) => setState(() => _reporteSeleccionado = null), // tocar el mapa vacío cierra la burbuja

// En el Stack, superpuesta al mapa:
if (_reporteSeleccionado != null)
  Positioned(bottom: 12, left: 12, right: 12, child: Card(child: ListTile(
    leading: Icon(Icons.pets, color: ...), // rojo/verde según tipo
    title: Text(_reporteSeleccionado!.mascotaNombre ?? l10n.mascotaFallback),
    subtitle: Text(...), // tipoPerdidoChip / tipoEncontradoChip
    trailing: IconButton(icon: Icon(Icons.close), onPressed: () => setState(() => _reporteSeleccionado = null)),
    onTap: () => _abrirDetalle(_reporteSeleccionado!.id),
  ))),
```

- **Posición fija (abajo, centrada), no anclada al pixel del marcador:** hacer que la burbuja seleccione la posición exacta del marcador en la pantalla (siguiéndolo al hacer zoom/pan) requeriría convertir coordenadas geográficas a coordenadas de pantalla en tiempo real, algo que `flutter_map` no expone de forma simple sin un paquete adicional (ej. `flutter_map_marker_popup`). Se optó por una tarjeta fija en la parte inferior del mapa — mismo patrón simplificado que usan varias apps de mapas para el "marcador seleccionado", sin sumar una dependencia nueva solo para esto.
- **Cerrar tocando el mapa vacío:** `MapOptions.onTap` (distinto del `onTap` de cada `Marker`) se dispara al tocar cualquier punto del mapa que no sea un marcador — se usa para deseleccionar, mismo comportamiento esperado que tocar "afuera" de un popup en cualquier app de mapas.

### 10. Las dos tarjetas nuevas también necesitaban `TarjetaClara` (2026-08-19, bug de modo oscuro)

Tanto el aviso "sin reportes activos" como la burbuja de reporte seleccionado se escribieron primero con `Card` directo — el usuario lo encontró ilegible en modo oscuro (texto invisible). Es el mismo bug ya resuelto para `HomeScreen`/`DetalleMascotaScreen`/`DocumentosScreen` en la pasada de modo oscuro (ver `decisiones_arquitectura.md`, entrada del 2026-08-18): el `CardTheme` global fija el fondo en Durazno en los dos temas, pero el color del texto por defecto sí sigue el tema activo — en modo oscuro, texto claro sobre fondo Durazno claro es invisible. Se reemplazaron los dos `Card` por `TarjetaClara` (ver `tarjetaClara.md`), que fuerza ese subárbol a verse siempre en modo claro sin importar el tema real de la app. Vale la pena recordar esta regla para cualquier `Card` nuevo que se agregue en el futuro: si el fondo de la tarjeta no cambia con el tema, su contenido necesita `TarjetaClara`, no un `Card` simple.

### 11. `_reporteSeleccionadoId` en vez de guardar el objeto — bug real: la burbuja sobrevivía a un reporte borrado (2026-08-19)

El usuario reportó que, al borrar un reporte desde `DetalleReporteMascotaExtraviadaScreen`, la burbuja de abajo (punto 9) seguía mostrándolo en `MapaScreen`. Causa: `_reporteSeleccionado` guardaba una **copia** del objeto `MascotaExtraviadaModel` en el momento de tocar el marcador — el `if (_reporteSeleccionado != null)` que controla la burbuja nunca volvía a mirar si ese reporte seguía existiendo en el provider, solo si la variable local era `null`. Borrar el reporte actualiza `mascotaExtraviadaProvider` (el marcador desaparece del mapa, correctamente), pero la burbuja no tiene ninguna razón para enterarse de ese cambio si sigue apuntando a su propia copia vieja.

```dart
String? _reporteSeleccionadoId; // antes: MascotaExtraviadaModel? _reporteSeleccionado

// En build/_construirCuerpo, cada vez, a partir de la lista actual del provider:
MascotaExtraviadaModel? reporteSeleccionado;
if (_reporteSeleccionadoId != null) {
  for (final r in reportes) {
    if (r.id == _reporteSeleccionadoId) { reporteSeleccionado = r; break; }
  }
}
// La burbuja usa reporteSeleccionado (local, recalculado), no un campo de estado con el objeto.
```

Mismo patrón exacto que ya usa `DetalleReporteMascotaExtraviadaScreen` para buscar el reporte por id en cada `build()` (ver ese doc, punto 0 implícito) — se guarda solo el **id** en el estado, y el objeto se busca de nuevo en la lista reactiva del provider en cada reconstrucción. Con esto, si el reporte ya no está en `reportes` (borrado, o el filtro de resuelto lo saca de "activos"), `reporteSeleccionado` da `null` solo, y la burbuja se cierra sin necesidad de ningún código extra para detectar el borrado — es una consecuencia automática de no guardar una copia obsoleta.
