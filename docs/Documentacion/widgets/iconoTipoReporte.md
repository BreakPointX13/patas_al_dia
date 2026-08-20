# Nota de Obsidian: `IconoTipoReporte`

## 📁 Ubicación en el Proyecto

`lib/presentation/widgets/icono_tipo_reporte.dart`

Usado en `MapaScreen` (marcadores del mapa, burbuja de reporte seleccionado, chips de "sin ubicación") y `DetalleReporteMascotaExtraviadaScreen` (marcador del mini-mapa, `Chip` de tipo).

## 🎯 Propósito del Archivo

Ícono compuesto para representar un reporte del módulo Mapa: la misma pata (`Icons.pets`) que ya usa el navbar inferior, encerrada en un triángulo de advertencia — amarillo para mascota perdida, azul para mascota encontrada. Reemplaza al pin rojo/verde (`Icons.location_on`) de la primera versión, pedido explícito del usuario para que se distinga mejor de un vistazo qué tipo de reporte es cada uno.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `Icons.change_history` como "marco" de triángulo

```dart
Stack(
  alignment: Alignment.center,
  children: [
    Icon(Icons.change_history, color: color, size: size),
    Padding(
      padding: EdgeInsets.only(top: size * 0.18),
      child: Icon(Icons.pets, color: Colors.black87, size: size * 0.42),
    ),
  ],
)
```

Material no tiene un ícono "pata dentro de un triángulo" — se compone con dos íconos existentes en un `Stack`, en vez de sumar un SVG a medida o un paquete de íconos nuevo. `Icons.change_history` es, tal cual, un triángulo relleno apuntando hacia arriba (el nombre viene de su uso original en Material, sin relación con lo que representa acá) — se reutiliza solo por su forma.

**`Padding(top: size * 0.18)` — centrar dentro del triángulo, no del recuadro:** un triángulo no es simétrico verticalmente respecto al centro de su caja contenedora — su "centro de masa" visual queda más abajo. Sin este ajuste, la pata quedaría corrida hacia arriba, viéndose descentrada dentro del triángulo. El desplazamiento y el tamaño de la pata (`size * 0.42`) se ajustaron a ojo hasta verse proporcionados dentro del marco.

### 2. Colores fijos por tipo, no los mismos rojo/verde de antes

```dart
static const _colorPerdido = Colors.amber;
static const _colorEncontrado = Colors.blue;
```

La primera versión usaba rojo/verde (semántica "peligro"/"resuelto", tomada un poco a la ligera de otras apps). El pedido del usuario fue específico: amarillo de advertencia para "perdido" (más parecido a un cartel real de "atención, se busca") y azul para "encontrado" — colores que no chocan con el resto de la paleta de la app (Naranja/Durazno), ya que este es un ícono de estado funcional, no un elemento de marca.

### 3. `size` configurable — mismo widget, contextos distintos

El marcador del mapa lo usa a tamaño completo (36, el valor por defecto); la burbuja y el `Chip` de tipo lo usan más chico (28/22) para no desbalancear un `ListTile`/`Chip` que ya tiene su propio texto al lado. Ningún llamador reimplementa el `Stack` — todos pasan por este único widget, así que un ajuste futuro al diseño (por ejemplo, cambiar el color o la forma) se aplica en un solo lugar.

### 4. Bug de paso corregido: el marcador del mini-mapa ignoraba el `tipo` real

`DetalleReporteMascotaExtraviadaScreen` tenía su marcador con `Icon(Icons.location_on, color: Colors.red, ...)` — siempre rojo, sin mirar `reporte.tipo`, a diferencia del resto de los lugares donde sí se distinguía perdido/encontrado. Al reemplazarlo por `IconoTipoReporte(tipo: reporte.tipo)` de paso quedó corregido — un reporte "encontrado" ahora también se ve azul en su propio mini-mapa, coherente con cómo se ve en el mapa general.
