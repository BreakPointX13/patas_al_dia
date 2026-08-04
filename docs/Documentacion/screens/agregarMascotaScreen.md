# Nota de Obsidian: `AgregarMascotaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/agregar_mascota_screen.dart`

Se abre desde el botón flotante (`+`) de `HomeScreen`, con `Navigator.push` (no `pushReplacement`, porque acá sí se puede volver atrás sin guardar).

## 🎯 Propósito del Archivo

Formulario para registrar una mascota nueva: nombre (obligatorio), especie, raza, sexo, fecha de nacimiento y peso. Al guardar, crea un `MascotaModel` y lo pasa a `mascotasProvider.notifier.agregarMascota`, que inserta en SQLite y actualiza el estado en memoria. `HomeScreen` se refresca solo al volver, porque ya escucha ese mismo estado con `ref.watch`.

Campos que el modelo soporta pero que este primer formulario no pide todavía (se pueden sumar después sin romper nada): `rutMascota`, `esterilizado`, `colores`, `numeroChip`, `fotoUrl`.

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Un formulario con validación y múltiples tipos de campo (texto, selección, fecha) es el caso de uso típico de `Form` + `GlobalKey<FormState>` en Flutter — el mecanismo estándar para validar varios campos a la vez antes de enviar datos.

### 🐾 En Nuestro Proyecto "Patas al día"

Es la primera pantalla del proyecto que escribe datos nuevos (antes solo leíamos con `cargarMascotas` o creábamos un usuario invitado con un solo campo). Por eso es también la primera que necesita `TextEditingController` y limpieza en `dispose()`.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** proyectos grandes suelen usar paquetes de formularios más sofisticados (`reactive_forms`, `flutter_form_builder`) para formularios muy largos o reutilizables.
- **Nuestro Enfoque:** usamos el `Form` nativo de Flutter, sin dependencias extra — suficiente para un formulario de este tamaño y consistente con la regla de dependencias mínimas del proyecto.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `GlobalKey<FormState>` + `Form`

```dart
final _formKey = GlobalKey<FormState>();
...
Form(key: _formKey, child: ListView(children: [...]))
```

El `Form` agrupa todos los campos hijos. El `GlobalKey` es la forma de "agarrar" ese estado desde código (`_formKey.currentState!.validate()`) para pedirle que valide todos los campos a la vez antes de guardar.

### 2. `TextEditingController` y `dispose()`

Cada `TextFormField` de texto libre (nombre, especie, raza, peso) tiene su propio controller para poder leer `.text` al momento de guardar. Los controllers ocupan memoria mientras existen, por eso hay que liberarlos explícitamente en `dispose()` — si no, quedan "vivos" después de cerrar la pantalla.

### 3. `validator`

```dart
validator: (valor) {
  if (valor == null || valor.trim().isEmpty) {
    return 'El nombre es obligatorio';
  }
  return null;
}
```

Función que corre cuando se llama `validate()` sobre el `Form`. Si devuelve un `String`, ese texto se muestra como error bajo el campo; si devuelve `null`, el campo pasa la validación. Solo el campo "nombre" lo usa, porque es el único obligatorio.

### 4. `DropdownButtonFormField`

El campo "Sexo" no usa `TextEditingController`: al ser una lista fija de opciones (`Macho`/`Hembra`), el valor elegido se guarda directo en una variable de estado (`_sexo`) dentro de `onChanged`, y se le pasa de vuelta al widget vía `initialValue`.

### 5. `showDatePicker`

```dart
final fecha = await showDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime(2000),
  lastDate: DateTime.now(),
);
```

Abre el selector de fecha nativo de Flutter y devuelve un `DateTime?` — `null` si el usuario cancela. Por eso el chequeo `if (fecha != null)` antes de guardar el resultado con `setState`.

### 6. `mounted` vs. `context.mounted`

En `LoginScreen` (un `ConsumerWidget`, sin estado propio) se usa `context.mounted` tras un `await`. Acá, al ser un `ConsumerState` (tiene estado propio), existe la propiedad `mounted` directamente en el `State` — es la forma preferida por el analizador cuando está disponible, en vez de `context.mounted`.
