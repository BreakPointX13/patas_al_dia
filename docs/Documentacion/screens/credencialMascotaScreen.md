# Nota de Obsidian: `CredencialMascotaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/credencial_mascota_screen.dart`

Se abre desde `HomeScreen`: cada fila de la lista de mascotas tiene, además del toque normal (que abre `DetalleMascotaScreen`), un ícono `trailing` (`Icons.badge_outlined`) que abre esta pantalla directo, sin pasar por el detalle.

## 🎯 Propósito del Archivo

Muestra una "credencial" o carnet digital de la mascota: una tarjeta visual con foto grande, nombre, especie/raza, RUT, número de chip y esterilizado — pensada para mostrarse rápido (por ejemplo, en una veterinaria), a diferencia de `DetalleMascotaScreen`, que muestra *todos* los datos en un formato de lista. La primera versión era solo vista en pantalla; el ícono de compartir del `AppBar` (2026-08-17, segunda pasada) exporta la tarjeta como imagen PNG y abre la hoja de "compartir" nativa del sistema.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Mismo patrón de acceso por id que `DetalleMascotaScreen`: recibe `mascotaId` (no el objeto `MascotaModel` completo) y busca la mascota actualizada en `mascotasProvider` en cada `build()`, con la misma guarda por si la mascota ya no existe (`WidgetsBinding.instance.addPostFrameCallback` + `pop()`). Es una copia deliberada de ese patrón, no una casualidad — ver el porqué en `detalleMascotaScreen.md`.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** una "credencial" o carnet digital suele ser una vista de solo lectura, sin campos editables — distinta de una pantalla de detalle con acciones.
- **Nuestro Enfoque:** `ConsumerStatefulWidget` (a diferencia de `DetalleMascotaScreen`, que es `ConsumerWidget` sin estado propio) porque exportar la tarjeta necesita dos cosas que solo puede dar un `State`: un `GlobalKey` estable entre reconstrucciones (para encontrar el `RenderRepaintBoundary` de la tarjeta) y una bandera `_compartiendo` para deshabilitar el botón mientras se genera la imagen.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `mascota.especieTexto` — getter compartido en `MascotaModel`

```dart
String get especieTexto {
  if (especie == 'Otro' && especiePersonalizada != null) {
    return especiePersonalizada!;
  }
  return especie ?? 'No especificada';
}
```

Antes existía como una función privada (`_especieTexto`) duplicada en `home_screen.dart` y `detalle_mascota_screen.dart`. Al agregar esta tercera pantalla que necesitaba la misma lógica, se subió a `MascotaModel` como getter — ver `mascota.model.md`. Las tres pantallas ahora llaman `mascota.especieTexto` directamente.

### 2. `razaTexto` — especie y raza combinadas en una sola línea

```dart
final razaTexto = mascota.raza == null || mascota.raza!.trim().isEmpty
    ? mascota.especieTexto
    : '${mascota.especieTexto} · ${mascota.raza}';
```

La credencial muestra "Especie · Raza" en una sola línea bajo el nombre (a diferencia de `DetalleMascotaScreen`, que los muestra como dos filas separadas) — formato más compacto, acorde al espíritu de carnet. Si no hay raza cargada, se muestra solo la especie sin el separador `·` colgando.

### 3. Tarjeta como `Container` con `BoxDecoration`, no `Card`

La credencial no usa el `CardTheme` global (fondo Durazno, sin borde) — es un `Container` con su propio `BoxDecoration`: mismo fondo Durazno, pero con un borde Naranja marca de 3px alrededor de toda la tarjeta, para que se lea como un objeto físico (carnet) y no como una fila más de una lista. `constraints: BoxConstraints(maxWidth: 440)` evita que la tarjeta se estire a todo el ancho en pantallas grandes — se ve como una tarjeta de tamaño fijo, centrada, no como un panel de ancho completo. Tamaño de foto (radio 84), nombre (32px) y el resto del texto se agrandaron sobre la primera versión (foto 64, nombre 24px) porque, al probarlo, el usuario pidió una tarjeta y una letra más grandes y legibles.

**`_filaCredencial`: valor debajo de la etiqueta, no al lado (2026-08-17):** la primera versión ponía etiqueta y valor en un `Row` con `spaceBetween` (uno a cada extremo, como en `DetalleMascotaScreen`). El usuario probó con RUT y número de chip cortos y se veía bien, pero notó que con valores reales más largos, etiqueta y valor iban a chocar en la misma línea — se cambió a `Column` (etiqueta arriba, valor abajo, `crossAxisAlignment: CrossAxisAlignment.start`), mismo criterio que un `ListTile` con `title`/`subtitle`, sin límite de ancho compartido entre los dos textos.

**Alineación a la izquierda de las filas (2026-08-17, ajuste inmediato siguiente):** con el cambio anterior, las filas quedaron centradas como bloque dentro de la tarjeta (texto alineado a la izquierda *dentro* de cada fila, pero cada fila en sí centrada horizontalmente) — el `Column` principal de la tarjeta no tenía `crossAxisAlignment` explícito, así que usaba el valor por defecto (`center`), y cada `_filaCredencial` se dimensiona solo tan ancha como su contenido más largo, quedando centrada como bloque. Se corrigió agregando `crossAxisAlignment: CrossAxisAlignment.stretch` al `Column` principal, para que sus hijos (incluidas las filas) ocupen todo el ancho disponible y el texto quede pegado al borde izquierdo real de la tarjeta. Como la foto y el nombre/raza sí debían seguir centrados, la foto se envolvió en un `Center` explícito (`stretch` no centra automáticamente un hijo de tamaño fijo, solo le da el ancho disponible) — el nombre y la raza no necesitaron cambios porque ya usaban `textAlign: TextAlign.center`, que centra el texto dentro del ancho que se le dé, sea cual sea.

### 4. Ícono de acceso rápido en `HomeScreen`, con fondo propio

```dart
trailing: Container(
  decoration: const BoxDecoration(color: Color(0xFFD06D1F), shape: BoxShape.circle),
  child: IconButton(
    icon: const Icon(Icons.badge_outlined, color: Color(0xFFFFF7EC)),
    tooltip: 'Credencial',
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => CredencialMascotaScreen(mascotaId: mascota.id)),
    ),
  ),
),
```

El `trailing` de un `ListTile` es una zona de toque independiente del resto de la fila — tocar el ícono abre la credencial sin disparar el `onTap` del `ListTile` (que sigue abriendo `DetalleMascotaScreen`), sin necesidad de lógica extra para diferenciar ambos toques. El `Container` circular Naranja marca detrás del ícono se agregó porque, en la primera versión, el ícono suelto sobre la tarjeta Durazno no se leía como un botón tocable — mismo criterio de contraste que ya usa el FAB (fondo Naranja marca, ícono Crema clara).

### 5. Exportar y compartir como imagen (2026-08-17)

```dart
final boundary = _tarjetaKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
final imagen = await boundary.toImage(pixelRatio: 3);
final byteData = await imagen.toByteData(format: ui.ImageByteFormat.png);
final bytes = byteData!.buffer.asUint8List();

final archivo = File('${Directory.systemTemp.path}/credencial_$nombreMascota.png');
await archivo.writeAsBytes(bytes);

await SharePlus.instance.share(ShareParams(files: [XFile(archivo.path)], text: 'Credencial de $nombreMascota'));
```

El ícono de compartir del `AppBar` convierte la tarjeta (no la pantalla completa — el `RepaintBoundary` envuelve solo el `Container` de la credencial) en una imagen PNG y abre la hoja de "compartir" nativa del sistema con esa imagen adjunta.

- **`RepaintBoundary` + `_tarjetaKey`:** Flutter no puede "capturar como imagen" cualquier widget directamente — hace falta envolver la porción de árbol a capturar en un `RepaintBoundary`, que actúa como una capa de renderizado independiente. El `GlobalKey` (guardado en el `State`, no recreado en cada `build()`) es la forma de llegar desde código a ese `RenderRepaintBoundary` para pedirle `.toImage()`.
- **`pixelRatio: 3`:** sin este parámetro, `toImage()` captura al tamaño lógico de la tarjeta en pantalla (baja resolución); pedir un `pixelRatio` de 3 multiplica la resolución de salida, para que la imagen compartida se vea nítida incluso en pantallas grandes o al hacer zoom.
- **`Directory.systemTemp`** (de `dart:io`, sin dependencias nuevas) en vez de `path_provider`: alcanza para escribir el PNG temporal antes de compartirlo — `share_plus` copia igual el archivo a su propia carpeta de caché antes de generar la URI de contenido para compartir (`ShareFileProvider` en Android), así que no hace falta que el archivo original esté en ninguna carpeta especial.
- **`share_plus` como dependencia nueva:** Flutter no tiene una API nativa para abrir la hoja de "compartir" del sistema — misma excepción ya aceptada antes para `file_picker`/`open_filex`/`flutter_svg`/`table_calendar`. No requirió tocar `AndroidManifest.xml` a mano: el paquete declara su propio `FileProvider` en su manifiesto, que Gradle fusiona automáticamente al compilar.
- **`_compartiendo`:** mientras se genera y comparte la imagen, el ícono del `AppBar` se reemplaza por un `CircularProgressIndicator` chico y se deshabilita (`onPressed: null`) — evita que un segundo toque dispare una segunda exportación mientras la primera sigue en curso.

### 6. Watermark "Patas al Día" al pie de la tarjeta (2026-08-17)

Logo chico (`assets/images/logo_patas_al_dia.png`, el mismo PNG rasterizado que usa `LogoBarraSuperior`) + texto "Patas al Día", centrados, al final del `Column` de la tarjeta — *dentro* del `RepaintBoundary`, no agregado aparte sobre la imagen ya exportada. Al capturarse como parte del mismo widget que se ve en pantalla, la imagen compartida siempre lleva la marca sin necesidad de dibujarla por separado con `Canvas`/`ui.PictureRecorder` después de exportar — y el usuario ve exactamente lo mismo que va a compartir, sin sorpresas. Sugerido para que, si la credencial se comparte fuera de la app (con un veterinario, por ejemplo), quede claro de dónde viene.
