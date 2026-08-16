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
Future<void> _cargarEventos() async {
  final mascotas = ref.read(mascotasProvider);
  final ids = _mascotaIdsFiltro?.toList() ?? mascotas.map((m) => m.id).toList();
  await ref.read(agendaEventosProvider.notifier).cargarAgendaEventosDeMascotas(ids);
  if (!mounted) return;
  final eventoIds = ref.read(agendaEventosProvider).map((e) => e.id).toList();
  final idsConDocumento = await ref.read(documentoRepositoryProvider)
      .obtenerEventoIdsConDocumento(eventoIds);
  if (!mounted) return;
  setState(() => _eventoIdsConDocumento = idsConDocumento);
}
```

Traduce el filtro actual a una lista de ids y se la pasa al provider. Se llama en tres momentos distintos (ver siguiente punto) porque hay una carrera real entre "la pestaña Agenda ya se montó" y "la lista de mascotas del usuario ya se cargó". Desde el 2026-08-16 también resuelve, una vez cargados los eventos, qué eventos tienen al menos un documento adjunto (`_eventoIdsConDocumento`) — se usa para el chip "Documento adjunto" del timeline (punto 10). Se consulta con `DocumentoRepository.obtenerEventoIdsConDocumento` directo, sin pasar por `documentosProvider`, porque ese provider guarda un único listado plano que ya se pisa entre "documentos de una mascota" y "documentos de un evento" — mezclarlo acá lo hubiera roto.

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
- **Debajo del calendario**, un `Expanded` con la lista de eventos del día tocado (`_diaSeleccionado`, `DateTime?`) — texto "Toca un día para ver sus eventos" si no hay ningún día seleccionado. Tocar un evento (en cualquiera de las dos vistas) usa el mismo `_abrirDetalle`, factorizado para no duplicar la navegación. Si el día tocado no tiene eventos, ver el punto 10 (`_sinEventosDelDia`) — desde el 2026-08-16 ya no queda una pantalla vacía.
- **`onPageChanged` limpia la selección** (`_diaSeleccionado = null`): corrige un detalle de UX que notó el usuario probando la app — si seleccionabas un día con eventos y después cambiabas de mes, la lista de abajo seguía mostrando los eventos de ese día aunque ya no estuviera visible en la grilla. Ahora, cambiar de mes deja la sección de abajo pidiendo elegir un día de nuevo, en vez de arrastrar una selección que ya no tiene sentido visualmente.
- **`headerStyle: HeaderStyle(formatButtonVisible: false)`** + `calendarFormat: CalendarFormat.month` fijo: el paquete trae por defecto un botón para alternar entre vista mes/2 semanas/semana (con texto en inglés, "2 weeks"), que no se necesita para este caso de uso — se ocultó en vez de traducirlo.
- **`locale: 'es_ES'`**: requiere que `intl` tenga los datos de esa configuración regional cargados antes de construir el widget — ver `initializeDateFormatting('es_ES')` en `main.dart`. Sin esa llamada, el calendario lanza una excepción (`LocaleDataException`) apenas se intenta mostrar el nombre del mes.

### 7. `_nombreMascota` — resolución segura, sin crashear (2026-08-15)

Reemplaza un `mascotas.firstWhere(..., orElse: () => mascotas.first)` que asumía que `mascotas` nunca podía estar vacía si había eventos — supuesto que se rompía justo después de cerrar sesión (ver la entrada del 2026-08-15 en `decisiones_arquitectura.md`). Ahora, si no encuentra la mascota, devuelve el texto genérico `'Mascota'` en vez de crashear con `StateError` (`.first` sobre una lista vacía).

### 8. Aviso "No hay mascotas creadas" (2026-08-16)

Junto al texto "Mostrando: ...", si `mascotas.isEmpty`, aparece un recuadro rojo avisándolo — solo cuando corresponde (ej. justo después de crear un invitado nuevo, o de cerrar sesión, ver `decisiones_arquitectura.md`). Detalle de UX pedido explícitamente por el usuario, para que quede claro por qué la Agenda está vacía en vez de dejarlo ambiguo (¿no hay eventos, o no hay ni siquiera mascotas?).

### 9. Botón flotante centrado

```dart
floatingActionButton: FloatingActionButton.extended(
  onPressed: mascotas.isEmpty ? null : _irAAgregarEvento,
  icon: const Icon(Icons.add),
  label: const Text('Agregar evento'),
),
floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
```

A diferencia del FAB circular de `HomeScreen` (esquina inferior derecha), acá se usa la variante `.extended` (ícono + texto) centrada — decisión de diseño explícita del usuario, ver la entrada correspondiente en `decisiones_arquitectura.md`.

### 10. Vista de lista como timeline, con íconos por tipo de evento (2026-08-16)

`_vistaLista` dejó de ser una lista plana de `ListTile` para pasarse a un diseño de "historial" (timeline), a partir de una maqueta HTML que trajo el usuario. Piezas clave:

- **`_iconosPorTipoEvento`** (constante a nivel de archivo): mapea cada uno de los 7 tipos fijos de evento (ver `formularioAgendaEventoScreen.md`, punto de "Tipo de evento") a su ícono SVG en `assets/icons/eventos/` (`vacuna.svg`, `desparasitacion.svg`, `peluqueria.svg`, `operacion.svg`, `control.svg`, `examen.svg`, `otro.svg` — diseñados por el usuario). `_iconoEvento(tipoEvento)` cae en `otro.svg` si el tipo es `null` o no está en el mapa (dato viejo, previo a la lista fija). Se renderizan con el paquete `flutter_svg` (`SvgPicture.asset`), agregado específicamente para esto — no hay forma nativa de pintar SVG en Flutter.
- **`_tipoEventoTexto(evento)`**: si `tipoEvento == 'Otro'` y hay `tipoEventoPersonalizado`, muestra ese texto libre; si no, el tipo tal cual. Mismo patrón que `DocumentoModel`/`documentos_screen.dart` con `tipoDocumentoPersonalizado`.
- **Tarjeta "Próximo evento"** (`_tarjetaProximoEvento`): se elige recorriendo la lista de eventos y quedándose con el de `fechaRealizada == null` con `fechaProgramada` más cercana (puede ser pasada y estar atrasado — en ese caso la etiqueta dice "Atrasado" en vez de "En N días"). Es la única tarjeta con borde naranja y fondo de ícono propio; el resto de los eventos no la incluye (se descarta por **identidad de objeto**, `e != proximo`, no por id — funciona porque `proximo` es literalmente uno de los elementos de la misma lista `eventos`, no una copia).
- **Agrupación por mes** (`grupos`, `Map<String, List<AgendaEventoModel>>`): la clave es `DateFormat('MMMM y', 'es_ES').format(...)` capitalizada a mano con `_capitalizar` (`intl` devuelve el mes en minúscula). El resto de los eventos (todo menos el destacado) se ordena **ascendente** por `fechaProgramada` antes de agruparse — decisión explícita del usuario tras ver la primera versión (descendente, como en la maqueta) y pedir que quedara en orden cronológico ascendente en su lugar.
- **Chip "Documento adjunto"**: aparece en la tarjeta de un evento si su id está en `_eventoIdsConDocumento` (ver punto 2). Es solo un aviso genérico — no muestra el nombre del archivo, para no tener que cargar los `DocumentoModel` completos solo para pintar la lista.
- **`mostrarNombreMascota`**: si el filtro (`_mascotaIdsFiltro`) tiene más de una mascota (o es `null`, "todas"), cada tarjeta antepone el nombre de la mascota al subtítulo; si el filtro deja exactamente una mascota seleccionada, se omite (ya es obvio por el contexto — decisión del usuario tras preguntarle explícitamente cómo adaptar la maqueta, pensada para una sola mascota, al caso de "todas las mascotas").
- **`_tarjetaEventoTimeline`** se reutiliza igual en la lista del día seleccionado del calendario (`_vistaCalendarioWidget`) y en `_sinEventosDelDia` (punto 11) — reemplazó por completo al viejo `_tileEvento` (`ListTile` simple), que se borró por quedar sin uso.

### 11. Día seleccionado sin eventos → "Próximos eventos" (2026-08-16)

Antes, tocar un día del calendario sin eventos dejaba toda la sección de abajo con un único texto centrado ("Sin eventos este día") y nada más. Ahora `_sinEventosDelDia(dia, eventos, mascotas)`:

1. Muestra la fecha tocada en chico + "Sin eventos este día" debajo, ambos compactos arriba (no centrados, no ocupan toda la sección).
2. Debajo, si hay eventos futuros sin realizar (`fechaRealizada == null && fechaProgramada.isAfter(DateTime.now())`) en cualquier fecha, los lista bajo el título "Próximos eventos" (ascendente, con `_tarjetaEventoTimeline`) — para que la pantalla no quede "muerta" solo porque el día puntual elegido no tiene nada agendado.
3. Si tampoco hay ningún evento futuro en general, cae a un texto centrado "No hay más eventos programados".

Pedido explícito del usuario tras notar que la Agenda se sentía "vacía" al tocar cualquier día sin eventos, en vez de aprovechar el espacio para mostrar qué es lo próximo que viene.

### 12. `esPantallaRaiz` — logo/filtro solo en la pestaña, no al llegar desde una mascota (2026-08-16)

```dart
final esPantallaRaiz = widget.mascotaIdInicial == null;
```

`AgendaScreen` se usa en dos contextos distintos: como pestaña raíz del navbar (`AgendaScreen()`, sin `mascotaIdInicial`) y empujada desde `DetalleMascotaScreen` (`AgendaScreen(mascotaIdInicial: mascotaId)`, ver `detalleMascotaScreen.md`). Antes, el `AppBar` no distinguía entre ambos casos: siempre mostraba `LogoBarraSuperior` como `leading` (tapando el espacio donde Flutter pondría la flecha de "atrás" automática al haber sido empujada) y siempre mostraba el ícono de filtro por mascota (sin sentido si ya se llegó con el filtro fijo a una sola mascota). `esPantallaRaiz` controla ambos: `leading: esPantallaRaiz ? const LogoBarraSuperior() : null` (con `null`, Flutter pone la flecha sola) y el `IconButton` de filtro se envuelve en `if (esPantallaRaiz)`.
