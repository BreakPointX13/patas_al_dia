# Nota de Obsidian: `DetalleMascotaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/detalle_mascota_screen.dart`

Se abre al tocar una mascota en la lista de `HomeScreen`. Desde acá se llega a `FormularioMascotaScreen` (modo editar), a `AgendaScreen` filtrada por esta mascota, y a `DocumentosScreen` filtrada por esta mascota.

## 🎯 Propósito del Archivo

Muestra todos los datos de una mascota puntual (foto, especie, raza, sexo, fecha de nacimiento o edad estimada, peso, esterilizado, rut, colores, número de chip) y da acceso a tres acciones, las tres funcionales desde el 2026-08-16: "Editar datos", "Agenda" y "Documentos".

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

### 0. Guarda contra mascota inexistente (2026-08-15)

`build()` ya no usa `firstWhere` sin `orElse` (podía lanzar `StateError` si la mascota ya no estaba en `mascotasProvider` — ej. justo después de cerrar sesión, ver `decisiones_arquitectura.md`). Ahora busca a mano con un `for`, y si no la encuentra, muestra un `CircularProgressIndicator` momentáneo y hace `Navigator.pop()` en el siguiente frame en vez de crashear.

### 1. `ConsumerWidget` (no `ConsumerStatefulWidget`)

A diferencia de `HomeScreen` y `FormularioMascotaScreen`, esta pantalla no maneja campos de formulario ni necesita ningún método de ciclo de vida propio (`initState`, `dispose`) — solo lee datos y navega. Por eso alcanza con `ConsumerWidget`, la versión "sin estado propio" (como `LoginScreen`).

### 2. `firstWhere`

```dart
ref.watch(mascotasProvider).firstWhere((m) => m.id == mascotaId)
```

Método de lista de Dart: recorre los elementos y devuelve el primero que cumpla la condición. Si ninguno cumple, lanza una excepción (acá no se contempla ese caso porque, mientras no exista una función de "eliminar mascota", el id siempre debería estar en la lista).

### 3. `ListTile` dentro de `Card` — cada dato en su propia tarjeta (2026-08-16)

Cada dato de la mascota (especie, raza, etc.) sigue siendo un `ListTile` (`title` = etiqueta, `subtitle` = valor), pero ahora cada uno va envuelto en un `Card` (`for (final tile in datosTiles) Card(child: tile)`) en vez de quedar pegados uno debajo del otro. Usa el mismo `CardTheme` global de `main.dart` (fondo Durazno, bordes redondeados) que ya aplican las listas de `HomeScreen`/`AgendaScreen`/`DocumentosScreen` — es la tercera iteración de este espaciado: primero se probó sin separación (se veía "pegado"), después con líneas divisorias en Durazno entre cada dato (el usuario las encontró poco prolijas al verlas en pantalla), y finalmente esta versión con tarjetas, que el usuario prefirió por quedar visualmente coherente con el resto de las listas de la app en vez de introducir un tratamiento nuevo solo para esta pantalla.

`datosTiles` se arma como una lista local de `ListTile` *antes* del `return Scaffold(...)`, en vez de escribir cada `Card(child: ListTile(...))` inline — quedó de cuando existía un `Divider` grueso separando el bloque de datos del bloque de acciones (una iteración intermedia de este mismo cambio); con las tarjetas propias ese divisor grueso dejó de hacer falta (el corte visual ya lo dan las tarjetas mismas) y se sacó, quedando solo un `SizedBox(height: 16)` entre ambos bloques — pero la lista se conservó como variable aparte igual, ya no por necesidad sino porque no había motivo para volver a inlinearla.

**Orden de los datos (2026-08-17, primera pasada):** Especie, Raza, Sexo, Edad/Fecha de nacimiento, Peso, Colores, Esterilizado, RUT de la mascota, Número de chip — pedido explícito del usuario sobre el orden original (que tenía Esterilizado y RUT antes que Colores). "Esterilizado" no estaba en la lista que dio el usuario al pedir el cambio; se confirmó con él dónde ubicarlo (quedó después de Colores, en vez de al final o sacarlo del todo).

### 3b. Tres grupos con `SeparadorSeccionFicha` (2026-08-17, segunda pasada)

`datosTiles` (una sola lista) se dividió en tres: `grupoMascota` (Especie, Raza), `grupoIdentificacion` (RUT de la mascota, Número de chip) y `grupoDatos` (Sexo, Colores, Peso, Esterilizado, Edad/Fecha de nacimiento) — mismo agrupamiento que se le dio a `FormularioMascotaScreen` en la misma sesión (ver `formularioMascotaScreen.md`), para que la ficha de detalle y el formulario de edición se lean igual. Entre cada grupo (y antes del primero, justo debajo de la foto) va un `SeparadorSeccionFicha` (`lib/presentation/widgets/separador_seccion_ficha.dart`) — línea Durazno a cada lado con un ícono centrado: `Icons.pets` (el mismo del navbar) para "Mascota", y dos SVG nuevos (`identificacion.svg`/`datos.svg`) para las otras dos secciones.

**Diferencia con el formulario:** en el formulario, el grupo "Mascota" incluye el campo "Nombre" (primer campo del form); acá no hay un tile de "Nombre" (el nombre ya se muestra como título del `AppBar`), así que el grupo "Mascota" de esta pantalla solo tiene Especie y Raza — el separador con el ícono de pata queda igual justo debajo de la foto, marcando el inicio conceptual del mismo grupo.

**Margen superior extra sobre la foto:** el `ListView` que arma la pantalla pasó de `padding: EdgeInsets.all(16)` a `EdgeInsets.fromLTRB(16, 32, 16, 16)` — el usuario notó que la foto de la mascota quedaba "muy pegada" al `AppBar` al entrar a una mascota.

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

### 5. Las cuatro acciones al final

"Editar datos" navega con `Navigator.push` a `FormularioMascotaScreen(mascotaExistente: mascota)` — abre el mismo formulario que "Agregar mascota", pero en modo edición. "Agenda" (desde el 2026-08-14) navega a `AgendaScreen(mascotaIdInicial: mascotaId)` — la misma pantalla que vive en la pestaña Agenda del navbar, pero empujada como pantalla suelta dentro de la pestaña Mascotas, con el filtro ya puesto en esta mascota puntual. Como se llega empujando una pantalla (no cambiando de pestaña), la barra inferior sigue mostrando "Mascotas" como seleccionada mientras se ve la Agenda filtrada — comportamiento aceptado, no es necesario forzar el cambio de pestaña para esto. "Documentos" (desde el 2026-08-16) navega igual a `DocumentosScreen(mascotaId: mascotaId)`, ver `documentosScreen.md`. "Eliminar mascota" (2026-08-17) es la cuarta, ver punto 6.

**Bug encontrado y corregido (2026-08-16):** al llegar a `AgendaScreen` por este camino (`mascotaIdInicial != null`), la pantalla mostraba igual el logo de la app y el ícono de filtro por mascota en el `AppBar` — ambos pensados solo para cuando Agenda es la pestaña raíz del navbar. El logo tapaba el espacio de la flecha de "atrás" (no había forma visual de volver, solo el botón físico/gesto del sistema), y el filtro no tenía sentido si ya se llegó con una mascota fija. Se corrigió en `AgendaScreen` condicionando ambos al mismo chequeo (`mascotaIdInicial == null` = pantalla raíz) — ver `agendaScreen.md`.

### 6. "Eliminar mascota" — primera función de borrado del proyecto (2026-08-17)

```dart
Future<void> _eliminarMascota(BuildContext context, WidgetRef ref, MascotaModel mascota) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar mascota'),
      content: Text('¿Eliminar a ${mascota.nombre}? Se van a borrar también su agenda y sus documentos. Esta acción no se puede deshacer.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (confirmar != true || !context.mounted) return;
  await ref.read(mascotasProvider.notifier).eliminarMascota(mascota.id);
  if (context.mounted) Navigator.of(context).pop();
}
```

Hasta esta versión, el proyecto no tenía ninguna función de "eliminar" expuesta en la UI — `MascotaRepository.eliminarMascota` y `MascotasNotifier.eliminarMascota` ya existían desde que se construyó la capa de datos/providers (CRUD completo desde el inicio, ver `mascota.repository.md`), pero nada en `presentation/` los llamaba todavía.

- **Confirmación con `showDialog<bool>`:** mismo patrón ya usado en `AjustesScreen._cerrarSesion` — un `AlertDialog` que devuelve `true`/`false`/`null` (si se descarta tocando afuera) según el botón tocado, y el código que sigue solo continúa si el resultado fue exactamente `true`.
- **El aviso menciona la cascada:** el mensaje del diálogo advierte explícitamente que se borran también la agenda y los documentos de la mascota — es cierto a nivel de esquema (`ON DELETE CASCADE` en `agenda_eventos`, `documentos` y `mascotas_extraviadas`, todas con `mascota_id` como *foreign key* hacia `mascotas`, ver `database.helper.md`), así que ocultar esa consecuencia sería engañoso para una acción irreversible.
- **Botón "Eliminar" en rojo** (`ElevatedButton.styleFrom(backgroundColor: Colors.red)`), distinto del resto de los `ElevatedButton` de la app (que usan el `ElevatedButtonTheme` por defecto) — es la primera acción destructiva de la app con esta señal visual explícita; "Cerrar sesión" no la tiene porque, a diferencia de borrar una mascota, no destruye datos (ver `decisiones_arquitectura.md`, entrada del 2026-08-06).
- **`Navigator.of(context).pop()` al final, no `pushReplacement` ni nada más elaborado:** como `DetalleMascotaScreen` siempre se llega empujándola sobre `HomeScreen` (ver la nota sobre `mascotaId` más arriba), un simple `pop()` alcanza para volver a la lista — que ya no va a mostrar la mascota eliminada porque `eliminarMascota` del notifier actualiza el `state` en memoria antes de que se ejecute el `pop()`.
