# Nota de Obsidian: `TarjetaClara`

## 📁 Ubicación en el Proyecto

`lib/presentation/widgets/tarjeta_clara.dart`

Reemplaza a `Card` en los 5 lugares donde se usaba antes: `HomeScreen` (lista de mascotas), `DetalleMascotaScreen` (3 usos, uno por grupo de datos) y `DocumentosScreen` (lista de documentos).

## 🎯 Propósito del Archivo

Envuelve un `Card` normal para que su contenido (texto, íconos) se vea **siempre** como en modo claro — fondo Durazno, texto Café texto oscuro — sin importar si el resto de la app está en modo oscuro. Nace al implementar modo oscuro (2026-08-18, ver `decisiones_arquitectura.md`).

---

## 🗺️ Mapa de Conexión Conceptual

### El problema que resuelve

Las tarjetas Durazno de esta app son un color de acento fijo — no un "fondo" que deba invertirse con el tema (ver `temaApp.md`, punto 2). El problema es que el color de la tarjeta en sí (`CardThemeData.color`) es independiente del color del *texto* que Flutter le pone adentro por defecto: un `ListTile` sin estilos propios toma su color de texto/ícono de `Theme.of(context).colorScheme.onSurface`, que en modo oscuro es un color **claro** (pensado para verse sobre un fondo oscuro). Sin este widget, una `Card` Durazno en modo oscuro tendría texto claro sobre fondo claro — prácticamente ilegible.

### La solución

```dart
class TarjetaClara extends StatelessWidget {
  final Widget child;
  const TarjetaClara({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(data: temaClaro, child: Card(child: child));
  }
}
```

`Theme(data: temaClaro, ...)` crea un `Theme` nuevo, anidado, que solo afecta a su `child` — todo lo que esté adentro de `TarjetaClara` (el `Card` y lo que sea que se le pase como `child`, típicamente un `ListTile`) se renderiza como si la app entera estuviera en modo claro, sin importar el tema real que esté activo más arriba en el árbol de widgets. Reutiliza literalmente `temaClaro` (la misma instancia que usa `main.dart` para el tema claro real de la app, ver `temaApp.md`) en vez de construir un `ThemeData` aparte — garantiza que una tarjeta se vea *exactamente* igual que en modo claro, sin margen para que las dos definiciones se desincronicen con el tiempo.

### 🔄 Comparativa y Ventajas Técnicas

- **Alternativa descartada — colorear cada `Card` a mano:** se podría haber envuelto cada `ListTile` con `DefaultTextStyle`/`IconTheme` explícitos apuntando a Café texto. Se descartó porque habría que repetirlo en los 5 lugares (y en cualquier futuro lugar que use tarjetas), y solo cubre texto/íconos — no otros widgets Material que también leen del `Theme` (como el color de un `Switch` o `Checkbox`, si algún día aparecen dentro de una tarjeta). Envolver con un `Theme` completo cubre todos los casos de una vez.
- **Por qué no tocar `CardThemeData` global en cambio:** `CardThemeData.color` (Durazno) ya es igual en los dos temas — el problema nunca fue el color de la tarjeta, sino el texto que Flutter calcula automáticamente para lo que va *adentro*. Cambiar el tema global no resuelve eso; hace falta fijar el brillo de ese subárbol específico, que es justo lo que hace `Theme(data: temaClaro, ...)`.
