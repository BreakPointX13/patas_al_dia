# Nota de Obsidian: `FormularioMascotaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/formulario_mascota_screen.dart`

Se abre de dos formas: desde el botón flotante (`+`) de `HomeScreen` (modo **crear**, sin argumentos), o desde "Editar datos" en `DetalleMascotaScreen` (modo **editar**, pasando la mascota existente). Siempre con `Navigator.push` (no `pushReplacement`, porque acá sí se puede volver atrás sin guardar).

## 🎯 Propósito del Archivo

Formulario único que sirve tanto para **crear** una mascota nueva como para **editar** una existente — evita duplicar el formulario cuando crece. Campos, en este orden (2026-08-17, pedido explícito del usuario): foto, nombre (obligatorio), especie, raza, RUT de la mascota, número de chip, sexo, colores, peso, esterilizado y fecha de nacimiento (o edad estimada) al final. Al guardar, crea o actualiza un `MascotaModel` según corresponda y lo pasa a `mascotasProvider.notifier` (`agregarMascota` o `actualizarMascota`), que escribe en SQLite y actualiza el estado en memoria. Las pantallas que escuchan ese estado (`HomeScreen`, `DetalleMascotaScreen`) se refrescan solas, porque ya usan `ref.watch`.

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Un formulario con validación y múltiples tipos de campo (texto, selección, fecha, imagen) es el caso de uso típico de `Form` + `GlobalKey<FormState>` en Flutter. Reutilizar la misma pantalla para "crear" y "editar" (recibiendo el objeto existente como parámetro opcional) es un patrón común para no duplicar la UI de un formulario grande.

### 🐾 En Nuestro Proyecto "Patas al día"

Es la primera pantalla del proyecto que escribe datos nuevos, y la primera que necesita `TextEditingController` y limpieza en `dispose()`. También es la primera que usa una dependencia externa para una funcionalidad que Dart puro no puede resolver: elegir una foto de la galería requiere el paquete `image_picker` (acceso a APIs nativas de la plataforma).

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** proyectos grandes suelen usar paquetes de formularios más sofisticados (`reactive_forms`, `flutter_form_builder`) para formularios muy largos o reutilizables.
- **Nuestro Enfoque:** usamos el `Form` nativo de Flutter, sin dependencias extra — suficiente para un formulario de este tamaño y consistente con la regla de dependencias mínimas del proyecto. La única dependencia nueva (`image_picker`) es la excepción justificada: no hay forma de acceder a la galería/cámara con Dart puro.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `mascotaExistente` — el parámetro que define el modo

```dart
final MascotaModel? mascotaExistente;
const FormularioMascotaScreen({super.key, this.mascotaExistente});
```

`null` → estamos creando. Con datos → estamos editando. Esta única variable controla tres cosas distintas en la pantalla: si `initState()` precarga los campos, si `_guardar()` llama `agregarMascota` o `actualizarMascota`, y qué título muestra el `AppBar`.

### 2. `GlobalKey<FormState>` + `Form`

```dart
final _formKey = GlobalKey<FormState>();
...
Form(key: _formKey, child: ListView(children: [...]))
```

El `Form` agrupa todos los campos hijos. El `GlobalKey` es la forma de "agarrar" ese estado desde código (`_formKey.currentState!.validate()`) para pedirle que valide todos los campos a la vez antes de guardar.

### 3. `TextEditingController` y `dispose()`

Cada `TextFormField` de texto libre (nombre, especie, raza, peso, rut, colores, número de chip) tiene su propio controller para poder leer `.text` al momento de guardar. Los controllers ocupan memoria mientras existen, por eso hay que liberarlos explícitamente en `dispose()` — si no, quedan "vivos" después de cerrar la pantalla.

### 4. `initState()` — precargar datos si es edición

```dart
@override
void initState() {
  super.initState();
  final mascota = widget.mascotaExistente;
  if (mascota != null) {
    _nombreController.text = mascota.nombre;
    ...
  }
}
```

Si `widget.mascotaExistente` no es `null`, copia cada dato del modelo a su controller o variable de estado correspondiente, para que el formulario aparezca ya lleno en modo edición.

### 5. `validator`

```dart
validator: (valor) {
  if (valor == null || valor.trim().isEmpty) {
    return 'El nombre es obligatorio';
  }
  return null;
}
```

Función que corre cuando se llama `validate()` sobre el `Form`. Si devuelve un `String`, ese texto se muestra como error bajo el campo; si devuelve `null`, el campo pasa la validación. Además del "nombre" (obligatorio), también validan **peso** (si se llena, debe ser un número positivo) y **edad estimada** (obligatoria mientras el switch de fecha estimada esté activo, entero entre 1 y 30). El resto de los campos (raza, rut, colores, número de chip) quedan como texto libre a propósito: RUT y número de chip no tienen un formato validado porque, aunque la app está pensada inicialmente para Chile, no se quiere cerrar la puerta a formatos de identificación de otros países.

### 6. `DropdownButtonFormField` y `SwitchListTile`

El campo "Sexo" no usa `TextEditingController`: al ser una lista fija de opciones (`Macho`/`Hembra`), el valor elegido se guarda directo en una variable de estado (`_sexo`) dentro de `onChanged`. "Esterilizado" usa el mismo principio con un `SwitchListTile` y una variable `bool`.

### 6b. `_especies` — lista fija (2026-08-17)

```dart
const _especies = [
  'Perro', 'Gato', 'Conejo', 'Hamster', 'Cobaya', 'Jerbo', 'Rata',
  'Chinchilla', 'Erizo', 'Pez', 'Tortuga', 'Hurón', 'Ave', 'Otro',
];
```

Igual que `tipoEvento` en `FormularioAgendaEventoScreen`, "Especie" dejó de ser texto libre y pasó a un `DropdownButtonFormField<String>` con esta lista fija (las especies más comunes como mascota en Chile, incluida Chinchilla por ser nativa). Si se elige "Otro", aparece un `TextFormField` adicional (`_especiePersonalizadaController`) para especificarla — mismo patrón exacto que `tipoEvento`/`tipoEventoPersonalizado`, incluida la nueva columna `especie_personalizada` en `mascotas` (ver `mascota.model.md` y `database.helper.md`). En `initState()`, si se edita una mascota con una especie que ya no está en la lista fija (dato viejo de texto libre), se mapea automáticamente a "Otro" con ese texto precargado en el campo personalizado.

### 6c. `SeparadorSeccionFicha` — tres grupos de campos (2026-08-17)

Los campos del formulario están agrupados en tres secciones, separadas visualmente por `SeparadorSeccionFicha` (`lib/presentation/widgets/separador_seccion_ficha.dart`, widget nuevo, compartido con `DetalleMascotaScreen`): una línea Durazno a cada lado con un ícono centrado (`Icons.pets` para "Mascota" — el mismo del navbar inferior — y dos SVG nuevos, `identificacion.svg`/`datos.svg`, para las otras dos, diseñados a medida por el usuario). Los tres factory constructors (`.mascota()`, `.identificacion()`, `.datos()`) evitan repetir la configuración de ícono+línea en cada pantalla que lo usa.

- **`SeparadorSeccionFicha.mascota()`** antes de "Nombre" → agrupa Nombre, Especie, Raza.
- **`SeparadorSeccionFicha.identificacion()`** antes de "Rut de la mascota" → agrupa Rut, Número de chip.
- **`SeparadorSeccionFicha.datos()`** antes de "Sexo" → agrupa Sexo, Colores, Peso, Esterilizado, Fecha de nacimiento/Edad estimada.

El orden de campos coincide exactamente con el pedido por el usuario en la misma sesión (ver `decisiones_arquitectura.md`), así que los tres grupos quedaron alineados de forma natural con los límites de cada sección — no fue necesario reordenar nada aparte para que la agrupación tuviera sentido.

**Tamaño parejo entre íconos — ajustado en el SVG, no en Flutter:** al probarlo, el ícono de "Identificación" se veía notablemente más chico que "Datos" y que la pata, aunque los tres usaban el mismo `width`/`height` en `SvgPicture.asset`. La causa real no era el tamaño en Flutter, sino que el dibujo dentro del `viewBox` original (`0 0 48 48`, igual en los dos SVG) ocupaba mucho menos espacio en "Identificación" que en "Datos" — cada ícono traía su propio margen interno, distinto entre sí. La primera solución (subir el `width`/`height` solo de ese ícono en el widget) funcionaba pero era un parche a ojo, específico a este par de SVG: si se reemplaza el archivo por un diseño distinto, el tamaño ajustado deja de calzar. La solución de raíz fue recortar el `viewBox` de cada SVG (`identificacion.svg` → `9 9 30 35`, `datos.svg` → `6 4 36 40`) al rectángulo real del dibujo (con un margen calculado a partir del ancho de línea), para que el "peso visual" del ícono ocupe una proporción similar de su propio lienzo en ambos casos. Con eso, los tres íconos vuelven a usar el mismo `width`/`height` (26) en el widget — la regla para cualquier ícono SVG nuevo que se agregue a este set es la misma: recortar el `viewBox` al dibujo real antes de usarlo, no ajustar el tamaño en el código Dart.

### 7. `showDatePicker`

```dart
final fecha = await showDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime(2000),
  lastDate: DateTime.now(),
);
```

Abre el selector de fecha nativo de Flutter y devuelve un `DateTime?` — `null` si el usuario cancela. Por eso el chequeo `if (fecha != null)` antes de guardar el resultado con `setState`.

### 8. `ImagePicker` — seleccionar una foto

```dart
final ImagePicker _picker = ImagePicker();
String? _fotoPath;

Future<void> _elegirFoto() async {
  final imagen = await _picker.pickImage(source: ImageSource.gallery);
  if (imagen != null) {
    setState(() => _fotoPath = imagen.path);
  }
}
```

`pickImage` abre el selector nativo de galería y devuelve un `XFile?` (`null` si se cancela). Como todavía no existe Supabase Storage, `_fotoPath` guarda la **ruta local** del archivo en el teléfono — más adelante, con sync cloud, ese valor pasaría a ser la URL subida. Para mostrarla en pantalla se usa `FileImage(File(_fotoPath!))`, que necesita `import 'dart:io';` para la clase `File`.

### 9. `_guardar()` — crear o actualizar según el modo

```dart
final mascota = MascotaModel(
  id: widget.mascotaExistente?.id ?? const Uuid().v4(),
  ...
);

if (widget.mascotaExistente == null) {
  await ref.read(mascotasProvider.notifier).agregarMascota(mascota);
} else {
  await ref.read(mascotasProvider.notifier).actualizarMascota(mascota);
}
```

Si estamos editando, reutiliza el `id` de la mascota existente (`widget.mascotaExistente?.id`) en vez de generar uno nuevo con `Uuid()` — así `actualizarMascota` modifica el registro correcto en SQLite en vez de crear uno duplicado.

### 10. `mounted` vs. `context.mounted`

En `LoginScreen` (un `ConsumerWidget`, sin estado propio) se usa `context.mounted` tras un `await`. Acá, al ser un `ConsumerState` (tiene estado propio), existe la propiedad `mounted` directamente en el `State` — es la forma preferida por el analizador cuando está disponible, en vez de `context.mounted`.

### 11. Texto de estado en el selector de foto

```dart
Column(
  children: [
    CircleAvatar(...),
    const SizedBox(height: 8),
    Text(_fotoPath == null ? 'Añadir foto' : 'Cambiar foto'),
  ],
)
```

El `CircleAvatar` original no tenía ninguna etiqueta — quedaba ambiguo si era decorativo o tocable. El texto reutiliza la misma condición (`_fotoPath == null`) que ya decide si mostrar el ícono de pata o la imagen, así los dos estados (icono + "Añadir foto" / imagen + "Cambiar foto") quedan sincronizados sin variables nuevas.

### 12. `_fechaEstimada` — edad aproximada en vez de fecha exacta

```dart
if (_fechaEstimada)
  TextFormField(controller: _edadEstimadaController, ...)
else
  ListTile(..., trailing: TextButton(onPressed: _seleccionarFecha, ...)),
```

No todos los dueños conocen la fecha de nacimiento exacta de su mascota (rescates, adopciones, etc.). El `SwitchListTile` "No sé la fecha exacta de nacimiento" reemplaza el selector de fecha por un campo numérico de años cuando está activo. Al guardar, en vez de duplicar el modelo con un campo de "edad" separado, se sigue usando `fechaNacimiento` como única fuente de verdad: se calcula como `hoy menos esos años` (`DateTime(DateTime.now().year - anios, ...)`), y el flag `fechaEstimada` (bool, nueva columna en SQLite) queda guardado en el `MascotaModel` para que el resto de la app (por ejemplo `DetalleMascotaScreen`) sepa que ese dato es una aproximación y no una fecha real. En `initState()`, si se está editando una mascota con `fechaEstimada == true`, se recalculan los años a partir de esa fecha aproximada para precargar el campo.

### 13. Textos vía `AppLocalizations`, `_etiquetasEspecies` para el dropdown (2026-08-18)

Todos los `labelText`, mensajes de validación y botones de este formulario salen de `AppLocalizations.of(context)` (ver `sistemaIdiomas.md`). El `DropdownButtonFormField` de especie es el caso particular: `_especies` (la lista de `value`, ej. `'Perro'`) sigue igual — es lo que se guarda en la base de datos — pero cada `DropdownMenuItem` ahora muestra `_etiquetasEspecies[e]!(l10n)` como texto, un mapa de `especie en español → función que devuelve la traducción` (`Map<String, String Function(AppLocalizations)>`, no `const` porque una función no es una constante de compilación en Dart). El dropdown de "Sexo" sigue el mismo criterio: `value: 'Macho'`/`'Hembra'` fijos, `child: Text(l10n.sexoMacho)`/`Text(l10n.sexoHembra)` para la etiqueta visible.
