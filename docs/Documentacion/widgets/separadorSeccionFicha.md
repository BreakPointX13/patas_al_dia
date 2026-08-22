# Nota de Obsidian: `SeparadorSeccionFicha`

## 📁 Ubicación en el Proyecto

`lib/presentation/widgets/separador_seccion_ficha.dart`

Se usa en `FormularioMascotaScreen` y `DetalleMascotaScreen` para dividir los datos de una mascota en tres grupos: Mascota, Identificación y Datos.

## 🎯 Propósito del Archivo

Separador visual reutilizable entre grupos de campos: una línea Durazno a cada lado, con un ícono centrado que identifica el grupo que empieza. Nace de la pasada de agrupación visual del 2026-08-17 (ver `decisiones_arquitectura.md`).

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. Tres factory constructors, no un parámetro de tipo

```dart
factory SeparadorSeccionFicha.mascota({Key? key}) => ...
factory SeparadorSeccionFicha.identificacion({Key? key}) => ...
factory SeparadorSeccionFicha.datos({Key? key}) => ...
```

Cada uno arma el ícono correcto internamente (uno usa `Icons.pets` de Material, los otros dos cargan un SVG) y delega en el constructor real (`icono: Widget`). Evita que quien use el widget tenga que saber qué ícono/asset corresponde a cada sección — solo llama `SeparadorSeccionFicha.datos()` y listo.

### 2. `Icons.pets` para "Mascota", SVG para las otras dos

La sección "Mascota" reutiliza el mismo ícono de pata que ya usa la barra de navegación inferior (`Icons.pets`, de Material) — no hay un ícono a medida diseñado para esa sección. "Identificación" y "Datos" sí usan SVG propios (`assets/icons/ficha/identificacion.svg` y `datos.svg`, diseñados a medida por el usuario), renderizados con `flutter_svg`.

### 3. Los colores del separador no cambian con el tema oscuro (2026-08-18)

`Color(0xFFD06D1F)` (ícono) y `Color(0xFFF3C98F)` (líneas) quedan como constantes fijas, sin variante para modo oscuro — a diferencia de los textos "café texto" en `agenda_screen.dart`, acá no hace falta: una línea Durazno clara y un ícono Naranja marca se ven bien tanto sobre el fondo Crema (claro) como sobre el nuevo fondo oscuro, porque no son texto que necesite contraste alto para leerse — son elementos gráficos de acento, con suficiente contraste en los dos casos. Ver `decisiones_arquitectura.md`, entrada del 2026-08-18, para el criterio general de qué colores necesitan variante oscura y cuáles no.

### 4. Uso fuera de los tres factory constructors — `DocumentosScreen` (2026-08-18)

```dart
SeparadorSeccionFicha(
  icono: Row(
    mainAxisSize: MainAxisSize.min,
    children: [Icon(_iconoTipoDocumento(tipo), color: Color(0xFFD06D1F)), SizedBox(width: 8), Text(tipoDocumentoMostrar(l10n, tipo), style: TextStyle(color: _colorTextoSeparador(context)))],
  ),
)
```

Primer uso del widget fuera de sus tres factory constructors: `DocumentosScreen` llama al constructor base directo, pasando como `icono` un `Row` con ícono + texto (nombre del tipo de documento), en vez de solo un ícono — el parámetro siempre aceptó cualquier `Widget`, así que no hizo falta tocar `SeparadorSeccionFicha` en sí. La diferencia con Mascota/Identificación/Datos: acá las secciones son dinámicas (dependen de qué documentos existan), así que llevan texto además del ícono, decisión consultada con el usuario — ver `documentosScreen.md`, punto 4, para el detalle completo (íconos por tipo, color de texto con variante oscura).

### 5. Segundo uso fuera de los factory constructors — `AjustesScreen` (2026-08-21)

Mismo patrón exacto que `DocumentosScreen` (ícono + texto en un `Row`, con una copia local de la función de color con variante oscura) — a pedido explícito del usuario, que quería las nueve opciones de Ajustes agrupadas "de un estilo parecido" al de Documentos. Acá las secciones son fijas (Apoyo/Apariencia/Cuenta/Sesión), no dinámicas como en Documentos, pero se usó el mismo patrón de todos modos por consistencia visual entre pantallas. Ver `ajustesScreen.md`, punto 11.
