# Nota de Obsidian: `tema_app.dart`

## 📁 Ubicación en el Proyecto

`lib/presentation/theme/tema_app.dart`

Primer archivo de una carpeta `theme/` nueva, hermana de `screens/`/`widgets/` dentro de `presentation/`. Usado por `main.dart` (tema de la app) y `TarjetaClara` (ver `tarjetaClara.md`).

## 🎯 Propósito del Archivo

Centraliza los dos `ThemeData` de la app (`temaClaro`/`temaOscuro`) — antes vivían como un único `ThemeData` inline dentro de `main.dart`. Se separó a su propio archivo al agregar modo oscuro (2026-08-18, ver `decisiones_arquitectura.md`), porque ahora hace falta construir el mismo tema dos veces (una por brillo) y, además, `TarjetaClara` necesita poder importar `temaClaro` sin crear una dependencia circular con `main.dart`.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `_construirTema(ColorScheme colorScheme)` — una función, dos temas

```dart
ThemeData _construirTema(ColorScheme colorScheme) {
  return ThemeData(
    colorScheme: colorScheme,
    fontFamily: 'SourceSans3',
    appBarTheme: const AppBarTheme(...),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(...),
    cardTheme: CardThemeData(...),
    textTheme: const TextTheme(...),
  );
}

final temaClaro = _construirTema(colorSchemeClaro).copyWith(scaffoldBackgroundColor: const Color(0xFFFBF0E2));
final temaOscuro = _construirTema(colorSchemeOscuro).copyWith(scaffoldBackgroundColor: const Color(0xFF1E1811));
```

En vez de escribir dos `ThemeData` completos y duplicar `appBarTheme`/`floatingActionButtonTheme`/`cardTheme`/`textTheme` (que son **idénticos** entre claro y oscuro — ver punto 2), se arma una sola función que recibe el `ColorScheme` (lo único que realmente cambia entre los dos temas) y devuelve el resto ya armado. `copyWith` al final agrega el único campo que tampoco puede compartirse: el color de fondo del `Scaffold`.

### 2. Por qué la mayoría de los colores de la app NO cambian con el tema

`AppBarTheme`, `FloatingActionButtonThemeData`, `CardThemeData` y `ElevatedButtonThemeData` quedan con los mismos colores literales (Naranja, Naranja marca, Durazno, Café texto) en `temaClaro` y `temaOscuro`. No es un descuido: son colores de **acento fijo** de la marca — el `AppBar` y el FAB son barras/botones de color vivo que no se "oscurecen" conceptualmente (siguen siendo naranjas, con o sin modo oscuro), y las `Card` (fondo Durazno) están pensadas para verse siempre como paneles claros, incluso sobre un fondo de app oscuro — ver `tarjetaClara.md` para cómo se protege el texto de adentro de esas tarjetas de heredar el tema oscuro.

Lo único que efectivamente cambia entre `colorSchemeClaro`/`colorSchemeOscuro` y entre `temaClaro`/`temaOscuro` es:
- El `ColorScheme` base (`ColorScheme.fromSeed(..., brightness: Brightness.dark)` para oscuro) — de ahí sale el color por defecto de diálogos, `Slider`, `SegmentedButton`, etc., para que esos widgets estándar de Material se vean coherentes con el modo oscuro sin tener que configurarlos a mano uno por uno.
- `scaffoldBackgroundColor`: Crema (`#FBF0E2`) en claro, gris oscuro cálido (`#1E1811`, no negro puro — para mantener la calidez de la paleta de marca) en oscuro.

### 3. `colorSchemeClaro`/`colorSchemeOscuro` como variables de nivel superior, no dentro de la función

Se exponen aparte (no ocultas dentro de `_construirTema`) porque `main.dart` no las necesita directo, pero podrían hacer falta en algún otro lugar que necesite saber "¿esto es claro o oscuro?" sin depender de `Theme.of(context).brightness` — por ahora ningún archivo las importa aparte de `tema_app.dart` mismo, es una decisión de exposición conservadora más que una necesidad actual.

### 4. `elevatedButtonTheme` agregado tras probar en el dispositivo (2026-08-18, mismo día)

```dart
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFF3C98F),
    foregroundColor: const Color(0xFF7A4A22),
  ),
),
```

Antes, ningún `ElevatedButton` de la app tenía un `style` explícito por defecto — se apoyaban en el estilo que Material deriva automáticamente de `colorScheme.primary`/`onPrimary`. En modo oscuro, ese color derivado resultaba casi negro, y los botones "Guardar" de los formularios (`FormularioMascotaScreen`, `FormularioAgendaEventoScreen`, `FormularioDocumentoScreen`) quedaban invisibles contra el fondo oscuro nuevo. Se agregó este tema global (Durazno de fondo, Café texto de letra — el mismo par de colores que usan las tarjetas) para que **todo** `ElevatedButton` sin `style` propio use ese aspecto por defecto, en vez de repetir `ElevatedButton.styleFrom(...)` en cada formulario. Los botones que sí necesitan un color distinto (como "Eliminar" en rojo, en los diálogos de confirmación de `DetalleMascotaScreen`/`DetalleAgendaEventoScreen`) siguen funcionando igual — su `style` explícito tiene prioridad sobre este default del tema.
