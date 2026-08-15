# Nota de Obsidian: `AgendaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/agenda_screen.dart`

Pantalla raíz de la pestaña "Agenda" dentro de `NavegacionPrincipalScreen`.

## 🎯 Propósito del Archivo

Lista los eventos de agenda (vacunas, controles, consultas) de las mascotas del usuario, con un filtro para elegir todas/una/algunas mascotas, y un botón para agregar un evento nuevo. Implementada el 2026-08-14.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

`ConsumerStatefulWidget`: necesita estado propio (`_mascotaIdsFiltro`) y ejecutar código en `initState` para la carga inicial, igual que `HomeScreen`.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `_mascotaIdsFiltro` (`Set<String>?`)

`null` significa "todas las mascotas" (el estado por defecto); un `Set` con ids específicos significa "solo estas". Se eligió `null` como "todas" en vez de un `Set` con todos los ids ya armado, para no tener que mantenerlo sincronizado cada vez que se agrega o borra una mascota.

### 2. `_cargarEventos()`

```dart
void _cargarEventos() {
  final mascotas = ref.read(mascotasProvider);
  final ids = _mascotaIdsFiltro?.toList() ?? mascotas.map((m) => m.id).toList();
  ref.read(agendaEventosProvider.notifier).cargarAgendaEventosDeMascotas(ids);
}
```

Traduce el filtro actual a una lista de ids y se la pasa al provider. Se llama en tres momentos distintos (ver siguiente punto) porque hay una carrera real entre "la pestaña Agenda ya se montó" y "la lista de mascotas del usuario ya se cargó".

### 3. `ref.listen` + `WidgetsBinding.instance.addPostFrameCallback` — cubrir la carrera de datos

Como `NavegacionPrincipalScreen` mete las tres pestañas en un `IndexedStack` (ver `navegacionPrincipalScreen.md`), `AgendaScreen` se monta y corre su `initState` al mismo tiempo que `HomeScreen`, sin garantía de quién termina primero:

- `initState` dispara `_cargarEventos()` una vez, después del primer frame (`addPostFrameCallback`) — cubre el caso en que `mascotasProvider` ya tenía datos al montarse (ej. el usuario ya había visitado la pestaña Mascotas antes).
- `ref.listen<List<MascotaModel>>(mascotasProvider, (previous, next) => _cargarEventos())` dentro de `build()` — cubre el caso en que `mascotasProvider` todavía estaba vacío al montarse y se llena después (ej. primera vez que se abre la app, `HomeScreen.initState()` todavía no terminó su `cargarMascotas`).

Sin el segundo mecanismo, la Agenda podría quedar cargada con una lista de mascotas vacía y nunca refrescarse sola.

### 4. `_abrirFiltro(List<MascotaModel> mascotas)`

Diálogo con `CheckboxListTile` por mascota más un checkbox "Todas" que sincroniza con las selecciones individuales (marcarlo selecciona todas; desmarcar cualquiera lo desmarca). Usa una selección temporal (`seleccionTemporal`) que solo se aplica al estado real si el usuario confirma con "Aplicar" — si cancela, el filtro anterior queda intacto.

### 5. `_irAAgregarEvento()`

Antes de abrir `FormularioAgendaEventoScreen`, muestra un `showModalBottomSheet` con dos opciones — "Evento futuro" y "Evento pasado" — que se traducen en el parámetro `esEventoPasado` del formulario. Ver `formularioAgendaEventoScreen.md` para cómo ese parámetro cambia el comportamiento del formulario. Si el filtro tiene exactamente una mascota seleccionada, se la pasa como `mascotaIdInicial` para no obligar a elegirla de nuevo.

### 6. Vista Calendario (`table_calendar`, 2026-08-14)

`_vistaCalendario` (bool, `true` por defecto — el usuario pidió explícitamente que el calendario sea la vista inicial) alterna entre `_vistaLista` (la original) y `_vistaCalendarioWidget`, con un ícono en el `AppBar` para cambiar entre ambas.

- **`eventLoader: (dia) => _eventosDelDia(eventos, dia)`**: le dice a `TableCalendar` qué días marcar con un punto — se recalcula sobre la misma lista `eventos` ya filtrada por mascota, no hace una consulta aparte.
- **`isSameDay`** (utilidad que exporta el propio paquete): compara solo año/mes/día, ignorando la hora — necesario porque `fechaProgramada` incluye hora y `DateTime ==` compararía también eso.
- **Debajo del calendario**, un `Expanded` con la lista de eventos del día tocado (`_diaSeleccionado`, `DateTime?`) — texto "Sin eventos este día" si no hay ninguno, o "Toca un día para ver sus eventos" si no hay ningún día seleccionado. Tocar un evento (en cualquiera de las dos vistas) usa el mismo `_abrirDetalle`, factorizado para no duplicar la navegación.
- **`onPageChanged` limpia la selección** (`_diaSeleccionado = null`): corrige un detalle de UX que notó el usuario probando la app — si seleccionabas un día con eventos y después cambiabas de mes, la lista de abajo seguía mostrando los eventos de ese día aunque ya no estuviera visible en la grilla. Ahora, cambiar de mes deja la sección de abajo pidiendo elegir un día de nuevo, en vez de arrastrar una selección que ya no tiene sentido visualmente.
- **`headerStyle: HeaderStyle(formatButtonVisible: false)`** + `calendarFormat: CalendarFormat.month` fijo: el paquete trae por defecto un botón para alternar entre vista mes/2 semanas/semana (con texto en inglés, "2 weeks"), que no se necesita para este caso de uso — se ocultó en vez de traducirlo.
- **`locale: 'es_ES'`**: requiere que `intl` tenga los datos de esa configuración regional cargados antes de construir el widget — ver `initializeDateFormatting('es_ES')` en `main.dart`. Sin esa llamada, el calendario lanza una excepción (`LocaleDataException`) apenas se intenta mostrar el nombre del mes.

### 7. `_nombreMascota` — resolución segura, sin crashear (2026-08-15)

Reemplaza un `mascotas.firstWhere(..., orElse: () => mascotas.first)` que asumía que `mascotas` nunca podía estar vacía si había eventos — supuesto que se rompía justo después de cerrar sesión (ver la entrada del 2026-08-15 en `decisiones_arquitectura.md`). Ahora, si no encuentra la mascota, devuelve el texto genérico `'Mascota'` en vez de crashear con `StateError` (`.first` sobre una lista vacía).

### 8. Botón flotante centrado

```dart
floatingActionButton: FloatingActionButton.extended(
  onPressed: mascotas.isEmpty ? null : _irAAgregarEvento,
  icon: const Icon(Icons.add),
  label: const Text('Agregar evento'),
),
floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
```

A diferencia del FAB circular de `HomeScreen` (esquina inferior derecha), acá se usa la variante `.extended` (ícono + texto) centrada — decisión de diseño explícita del usuario, ver la entrada correspondiente en `decisiones_arquitectura.md`.
