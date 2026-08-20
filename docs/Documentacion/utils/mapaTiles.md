# Nota de Obsidian: `mapa_tiles.dart`

## 📁 Ubicación en el Proyecto

`lib/presentation/utils/mapa_tiles.dart`

Usado por `MapaScreen` y `DetalleReporteMascotaExtraviadaScreen` — cualquier pantalla futura que agregue un `FlutterMap` debería usar esto en vez de escribir su propio `TileLayer`.

## 🎯 Propósito del Archivo

Centraliza qué proveedor de teselas (tiles) usa cada `FlutterMap` de la app, y la atribución obligatoria que va con ellas — para no repetir la misma URL/lógica en cada pantalla con mapa.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. CARTO Positron/Dark Matter, en vez de los tiles crudos de OpenStreetMap (2026-08-19)

```dart
String urlTilesSegunTema(BuildContext context) {
  final esOscuro = Theme.of(context).brightness == Brightness.dark;
  return esOscuro
      ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
      : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
}
```

La primera versión del mapa usaba `tile.openstreetmap.org` directo — el estilo por defecto de OpenStreetMap, visualmente básico ("feo", palabras del usuario al probarlo). CARTO Basemaps ofrece varios estilos gratis y sin API key sobre los mismos datos de OpenStreetMap — Positron (claro, minimalista) y Dark Matter (oscuro) son explícitamente la pareja diseñada para verse coherente entre sí, uno pensado para cada tema. Se mantiene el mismo criterio de costo cero que ya llevó a elegir `flutter_map` por sobre `google_maps_flutter` (ver `decisiones_arquitectura.md`, "Mapa, punto 3").

**`Theme.of(context).brightness`, mismo patrón que el resto de la app:** ya existía este criterio para decidir colores según el tema (ver `_colorTextoSobreFondo` en `agenda_screen.dart`) — acá se aplica por primera vez a un recurso externo (una URL de tiles), no a un color propio. El mapa cambia de estilo solo, siguiendo la preferencia de tema que el usuario ya eligió en Ajustes (Sistema/Claro/Oscuro), sin que el módulo Mapa tenga que ofrecer su propio selector.

### 2. `atribucionMapa` — un solo `RichAttributionWidget` compartido

```dart
final atribucionMapa = RichAttributionWidget(
  attributions: [
    TextSourceAttribution('© OpenStreetMap contributors', onTap: () {}),
    TextSourceAttribution('© CARTO', onTap: () {}),
  ],
);
```

Dos atribuciones, no una: los tiles de CARTO están construidos sobre datos de OpenStreetMap más el estilo visual propio de CARTO — la política de uso de ambos exige mencionarlos, no solo a OpenStreetMap (que era la única atribución de la versión anterior). Es una variable de módulo (`final`, no una función) porque no depende de nada dinámico como sí depende `urlTilesSegunTema` del tema activo — el mismo widget se reutiliza tal cual en cada `FlutterMap` que lo importe, sin problema por ser la misma instancia usada en más de un lugar del árbol de widgets a la vez (cada punto de uso obtiene su propio `Element`/estado interno, es el mismo patrón que reusar cualquier constante `const Text(...)`).

### 3. `minZoom`/`maxZoom` en cada `TileLayer`, no solo en `MapOptions` (2026-08-19, bug real encontrado en el dispositivo)

El usuario reportó un crash rojo de Flutter ("Infinity or NaN toInt") al interactuar mucho con el zoom del mapa. Un primer intento de arreglo puso `minZoom`/`maxZoom` solo en `MapOptions` (que limita hasta dónde el usuario puede hacer zoom con los dedos) — no alcanzó, el crash volvió a pasar. Se capturó el log real del dispositivo (`adb logcat`, sin pedirle nada al usuario más que repetir la acción) para confirmar la causa exacta antes de intentar un segundo arreglo a ciegas:

```
Unhandled Exception: Unsupported operation: Infinity or NaN toInt
#0  double.toInt
#1  double.floor
#2  _floor (package:flutter_map/src/layer/tile_layer/tile_range.dart:36:25)
#3  new DiscreteTileRange.fromPixelBounds (.../tile_range.dart:61:9)
#4  TileRangeCalculator.calculate (.../tile_range_calculator.dart:31:30)
#5  _TileLayerState._onTileUpdateEvent (.../tile_layer.dart:632:51)
```

El cálculo que falla (`TileRangeCalculator.calculate`, dentro de `TileLayer`, no de `MapOptions`) es el que decide qué teselas pedir según el nivel de zoom actual — un bug conocido de `flutter_map` cuando ese cálculo llega a un zoom fuera de rango. `MapOptions.minZoom`/`maxZoom` limita el *gesto* del usuario, pero `TileLayer` hace su propio cálculo de rango de teselas con su propia noción de límites — si no se le pasan los mismos límites explícitamente, puede terminar calculando para un zoom inválido (ej. durante una animación de zoom con inercia que overshoot momentáneamente más allá del límite del gesto). La solución real fue duplicar los mismos límites (`minZoom: 2, maxZoom: 19`) en el propio `TileLayer`, no solo en `MapOptions` — ambos deben coincidir.
