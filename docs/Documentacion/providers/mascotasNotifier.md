# Nota de Obsidian: `MascotasNotifier` y `mascotasProvider`

## 📁 Ubicación en el Proyecto

`lib/providers/mascota_provider.dart` (parte inferior del archivo, después de `mascotaRepositoryProvider`)

## 🎯 Propósito del Archivo

Es la "pizarra" de las mascotas: mantiene en memoria la lista actual de mascotas y se actualiza a sí misma cada vez que se crea, edita o elimina una, notificando automáticamente a cualquier pantalla que la esté mirando. Es la pieza que conecta las acciones del usuario (tocar "Guardar" en un formulario) con la base de datos (`MascotaRepository`) y con la interfaz visual (que se refresca sola).

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Este patrón se conoce como **estado inmutable**: en vez de modificar los datos "in situ" (mutarlos), cada cambio genera una copia nueva de la estructura de datos con la diferencia aplicada, y se reemplaza la referencia vieja por la nueva. Frameworks de estado como Redux, MobX o el propio Riverpod usan esto porque simplifica muchísimo cómo se detectan los cambios: en vez de revisar campo por campo si algo cambió, alcanza con preguntar "¿esta referencia es la misma que antes o es otra?".

### 🐾 En Nuestro Proyecto "Patas al día"

`MascotasNotifier` extiende `Notifier<List<MascotaModel>>` — un tipo de Riverpod diseñado justamente para mantener un estado (acá, una lista) que cambia con el tiempo. Cada uno de sus métodos sigue la misma estructura de tres pasos:
1. Pedir el repository (`ref.read(mascotaRepositoryProvider)`).
2. Ejecutar la operación real contra la base de datos (`await repo.algo(...)`).
3. Recalcular `state` con el resultado, **siempre creando una lista nueva**, nunca modificando la existente.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** Algunos frameworks (BLoC) fuerzan explícitamente esta inmutabilidad mediante clases de "evento" y "estado" separadas, con mucho código de por medio.
- **Nuestro Enfoque:** Riverpod no obliga nada por sintaxis — la inmutabilidad acá es una **disciplina que debemos mantener nosotros mismos** al escribir cada método. Si algún día se usa `state.add(...)` o `state.removeWhere(...)` en vez de reasignar `state = [...]`, el código va a compilar igual, pero la UI **no se va a actualizar**, porque Riverpod no detecta el cambio.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `class MascotasNotifier extends Notifier<List<MascotaModel>>` y `build()`

```dart
class MascotasNotifier extends Notifier<List<MascotaModel>> {
  @override
  List<MascotaModel> build() {
    return [];
  }
}
```

- El `<List<MascotaModel>>` le dice a Riverpod: "el estado que voy a manejar es una lista de mascotas".
- `build()` es obligatorio y define el **estado inicial** — acá, una lista vacía (todavía no se cargó nada de la base de datos).
- Dentro de cualquier método de esta clase, `ref` está disponible automáticamente (heredado de `Notifier`) — no hace falta declararlo.

### 2. `cargarMascotas(String usuarioId)` — leer y reemplazar todo

```dart
Future<void> cargarMascotas(String usuarioId) async {
  final repo = ref.read(mascotaRepositoryProvider);
  state = await repo.obtenerMascotasPorUsuario(usuarioId);
}
```

El más simple de los cuatro: no hay que combinar nada con lo que ya había en `state`, directamente se reemplaza entero por lo que devuelve la base de datos.

### 3. `agregarMascota(MascotaModel mascota)` — el operador *spread* (`...`)

```dart
state = [...state, mascota];
```

**¿Qué hace `...`?** "Desparrama" los elementos de una lista existente dentro de una lista nueva que se está construyendo. Es como fotocopiar una lista de invitados entera y, en la copia nueva, agregar un nombre más al final — la lista original queda intacta, y la copia (con el nombre nuevo) es la que se usa de ahora en más.

`[...state, mascota]` se lee: "una lista nueva que contiene todo lo que había en `state`, más `mascota` al final".

### 4. `actualizarMascota(MascotaModel mascota)` — `.map()` + operador ternario (`? :`)

```dart
state = state.map((m) => m.id == mascota.id ? mascota : m).toList();
```

Dos piezas para desarmar por separado:

**a) `.map((m) => ...)`** — recorre la lista actual elemento por elemento (cada elemento se llama `m` acá), y por cada uno **decide qué poner en su lugar** en la lista nueva. No filtra nada ni agrega nada: la lista resultante tiene exactamente la misma cantidad de elementos que la original, solo que cada uno puede haber sido transformado.

**b) El operador ternario `condición ? valorSiVerdadero : valorSiFalso`** — es un `if/else` escrito en una sola línea, como una pregunta con dos respuestas posibles:

```
m.id == mascota.id   ?   mascota   :   m
   (la pregunta)      (si sí)   (si no)
```

Se lee: "¿el id de esta mascota (`m`) es igual al id de la mascota que estoy actualizando? Si la respuesta es sí, pon la versión nueva (`mascota`) en su lugar. Si la respuesta es no, deja esta mascota (`m`) tal como estaba."

**Truco para no marearse con el orden:** el operador ternario siempre tiene la misma forma —`pregunta ? respuesta_si_sí : respuesta_si_no`— igual que el orden de un semáforo: primero la condición (¿verde o rojo?), después qué pasa si es una cosa, después qué pasa si es la otra.

Por último, `.map()` devuelve algo "perezoso" (un `Iterable`, no una `List` de verdad todavía) — por eso siempre se cierra con `.toList()`, igual que veníamos haciendo en los repositories al convertir filas de SQLite.

### 5. `eliminarMascota(String id)` — el operador `.where()`

```dart
state = state.where((m) => m.id != id).toList();
```

**¿Qué hace `.where()`?** A diferencia de `.map()` (que transforma cada elemento pero mantiene la cantidad), `.where()` **filtra**: se queda solo con los elementos donde la condición da `true`, y descarta el resto. Acá, la condición es `m.id != id` — "quédate con esta mascota únicamente si su id es *distinto* al que estoy eliminando". La única mascota que no cumple esa condición (la que sí tiene ese id) queda afuera de la lista nueva.

---

## 🧾 Chuleta rápida de operadores usados en este archivo

| Operador / método | Qué hace | Ejemplo acá |
|---|---|---|
| `...` (spread) | Copia los elementos de una lista existente dentro de una lista nueva | `[...state, mascota]` |
| `? :` (ternario) | `if/else` en una línea: `pregunta ? si_sí : si_no` | `m.id == mascota.id ? mascota : m` |
| `.map(fn)` | Transforma cada elemento de una lista en otro valor (misma cantidad de elementos al final) | `.map((m) => ...)` |
| `.where(fn)` | Filtra una lista, quedándose solo con los elementos donde `fn` da `true` (puede reducir la cantidad) | `.where((m) => m.id != id)` |
| `.toList()` | Convierte el resultado "perezoso" de `.map()`/`.where()` en una lista real y utilizable | `.map(...).toList()` |

**Regla de oro para recordar todo esto:** cualquier método de `MascotasNotifier` que modifique la lista de mascotas **siempre termina reasignando `state = ...` con una lista construida desde cero** (con `[...]`, `.map()` o `.where()`), nunca llamando a `.add()`, `.remove()` u otro método que modifique la lista existente en el lugar.
