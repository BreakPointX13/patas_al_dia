# Nota de Obsidian: `DetalleMascotaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/detalle_mascota_screen.dart`

Se abre al tocar una mascota en la lista de `HomeScreen`. Desde acá se llega a `FormularioMascotaScreen` (modo editar) y, más adelante, a las pantallas de agenda y documentos.

## 🎯 Propósito del Archivo

Muestra todos los datos de una mascota puntual (foto, especie, raza, sexo, fecha de nacimiento o edad estimada, peso, esterilizado, rut, colores, número de chip) y da acceso a tres acciones: "Editar datos" (funcional), "Agenda" y "Documentos" (placeholder "próximamente" hasta que existan esas pantallas).

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Es el patrón "lista → detalle" clásico: una pantalla de lista liviana (solo lo esencial para reconocer cada ítem) y una de detalle con toda la información, alcanzable tocando un ítem de la lista.

### 🐾 En Nuestro Proyecto "Patas al día"

**Decisión clave: esta pantalla recibe un `mascotaId` (`String`), no una `MascotaModel` completa.**

Podría parecer más simple pasar el objeto `mascota` completo desde `HomeScreen` (ya está en memoria, no hace falta buscarlo de nuevo). El problema es que ese objeto quedaría "congelado" en el momento en que se abrió la pantalla: si el usuario edita la mascota (cambia el peso, por ejemplo) y vuelve al detalle, seguiría viendo el dato viejo, porque tendría una copia fija, no una referencia a los datos actuales.

Por eso la pantalla busca la mascota actualizada en cada `build()`:

```dart
final mascota = ref
    .watch(mascotasProvider)
    .firstWhere((m) => m.id == mascotaId);
```

`ref.watch(mascotasProvider)` hace que la pantalla se redibuje sola cada vez que cambia la lista de mascotas en el estado — y `actualizarMascota` (que llama `FormularioMascotaScreen` al guardar una edición) modifica esa lista. Resultado: guardás una edición → el estado cambia → `DetalleMascotaScreen` se actualiza sola, sin refrescar nada a mano. Mismo patrón reactivo que ya se usa en `HomeScreen`.

`.firstWhere((m) => m.id == mascotaId)` recorre la lista en memoria y devuelve el primer elemento cuyo `id` coincide — un "buscar por id" hecho a mano, sin consultar la base de datos de nuevo (la lista ya está completa en memoria gracias a `cargarMascotas`).

Nota: cuando esta pantalla navega a "Editar", ahí sí le pasa la `MascotaModel` completa (`FormularioMascotaScreen(mascotaExistente: mascota)`) — porque el formulario la usa una sola vez, al precargar los campos en `initState()`, y no se queda escuchando cambios después. No hay problema de "dato viejo" en ese caso.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** pasar solo el id (o una clave) a una pantalla de detalle, en vez del objeto completo, es una práctica común quando el detalle necesita reflejar cambios posteriores.
- **Nuestro Enfoque:** aprovechamos que Riverpod ya mantiene la lista completa en memoria (`mascotasProvider`) — no hace falta una consulta nueva a SQLite para "refrescar", alcanza con volver a filtrar la lista que ya tenemos.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `ConsumerWidget` (no `ConsumerStatefulWidget`)

A diferencia de `HomeScreen` y `FormularioMascotaScreen`, esta pantalla no maneja campos de formulario ni necesita ningún método de ciclo de vida propio (`initState`, `dispose`) — solo lee datos y navega. Por eso alcanza con `ConsumerWidget`, la versión "sin estado propio" (como `LoginScreen`).

### 2. `firstWhere`

```dart
ref.watch(mascotasProvider).firstWhere((m) => m.id == mascotaId)
```

Método de lista de Dart: recorre los elementos y devuelve el primero que cumpla la condición. Si ninguno cumple, lanza una excepción (acá no se contempla ese caso porque, mientras no exista una función de "eliminar mascota", el id siempre debería estar en la lista).

### 3. `ListTile` reutilizado como fila de dato

Cada dato de la mascota (especie, raza, etc.) se muestra con un `ListTile` donde `title` es la etiqueta y `subtitle` es el valor — mismo widget que ya se usa en otras partes del proyecto (la fila de "Elegir fecha" en el formulario), reutilizado acá como una forma simple de mostrar pares etiqueta/valor en una lista.

### 4. `fechaEstimada` — mostrar edad en vez de fecha

```dart
ListTile(
  title: Text(mascota.fechaEstimada ? 'Edad estimada' : 'Fecha de nacimiento'),
  subtitle: Text(
    mascota.fechaEstimada
        ? '${DateTime.now().year - mascota.fechaNacimiento!.year} años'
        : '.../.../...',
  ),
),
```

Cuando la mascota se registró con el switch "No sé la fecha exacta de nacimiento" activo (ver `formularioMascotaScreen.md`), `mascota.fechaNacimiento` guarda una fecha aproximada (hoy menos X años), no la fecha real. Por eso acá no se muestra esa fecha tal cual: se recalculan los años a partir de ella y se etiqueta la fila como "Edad estimada" en vez de "Fecha de nacimiento", para que quede claro que es un dato aproximado.

### 5. Las tres acciones al final

"Editar datos" navega con `Navigator.push` a `FormularioMascotaScreen(mascotaExistente: mascota)` — abre el mismo formulario que "Agregar mascota", pero en modo edición. "Agenda" y "Documentos" llaman a `_mostrarProximamente`, el mismo patrón de aviso ("próximamente") que ya se usa en `LoginScreen` para "Iniciar sesión".
