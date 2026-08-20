# Nota de Obsidian: `DocumentosScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/documentos_screen.dart`

Se abre desde "Documentos" en `DetalleMascotaScreen` — reemplaza el placeholder "próximamente" que existía hasta el 2026-08-16.

## 🎯 Propósito del Archivo

Lista **todos** los documentos de una mascota (carnets, exámenes, recetas, boletas...), estén o no vinculados a un evento de agenda puntual — a diferencia de la sección "Documentos adjuntos" dentro de un evento de `FormularioAgendaEventoScreen`/`DetalleAgendaEventoScreen`, que solo muestra los documentos de ESE evento.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Reutiliza el mismo `documentosProvider` que ya usaba la Agenda — no hace falta un provider nuevo, solo un método distinto para cargar el estado: `cargarDocumentos(mascotaId)` en vez de `cargarDocumentosDeEvento(eventoId)` (ver `documentoNotifier.md`). Como es el mismo provider compartido, entrar a esta pantalla reemplaza el `state` que tuviera cargado — mismo patrón que ya usa el resto de los providers de lista del proyecto (`mascotasProvider`, `agendaEventosProvider`).

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. Ícono de enlace (`Icons.link`) para documentos vinculados a un evento

```dart
trailing: documento.eventoId == null ? null : const Icon(Icons.link, size: 18),
```

Si el documento se adjuntó desde un evento de agenda (`eventoId != null`), aparece un ícono chico de enlace en la fila — para que se note, sin abrir el documento, que viene de una consulta puntual. No se busca el título del evento acá (eso sería una consulta extra por cada fila de la lista); ese detalle sí se muestra en `DetalleDocumentoScreen`, donde solo hace falta una consulta para el documento que se está viendo.

### 1b. Cada fila en su propia `Card` (2026-08-16)

`_tileDocumento` devuelve `TarjetaClara(child: ListTile(...))` (antes `Card(...)` directo — ver `tarjetaClara.md`, cambio del 2026-08-18 al implementar modo oscuro), no un `ListTile` suelto — mismo `CardTheme` global (fondo Durazno, bordes redondeados) que las listas de `HomeScreen` y `AgendaScreen`, parte de la misma pasada de colores.

### 2. Botón flotante centrado

Mismo patrón que `AgendaScreen`/`HomeScreen` (ver `decisiones_arquitectura.md`, entrada del 2026-08-12): `FloatingActionButton.extended` con ícono + texto, centrado abajo.

### 3. Traducido (2026-08-18, pasada de Documentos)

Título de AppBar, estado vacío y el tipo mostrado en cada fila (vía `tipoDocumentoMostrar`) pasan a `AppLocalizations` — cierra la pasada de i18n de Agenda/Documentos (ver `sistemaIdiomas.md`, punto 6).

### 4. Agrupado por tipo, con `SeparadorSeccionFicha` (2026-08-18)

```dart
for (final tipo in tiposDocumentoDisponibles)
  ..._seccionTipo(context, l10n, tipo, documentos.where((d) => d.tipoDocumento == tipo).toList()),
```

La lista ya no es plana — se agrupa por `tipoDocumento`, en el mismo orden fijo de `tiposDocumentoDisponibles` (la constante que antes era privada de `FormularioDocumentoScreen`, ver `formularioDocumentoScreen.md`, punto 5). `_seccionTipo` arma, por cada tipo con al menos un documento, un separador (`SeparadorSeccionFicha`, ver `separadorSeccionFicha.md`, punto 4) seguido de sus tarjetas; los tipos sin documentos no generan sección (`if (documentosDelTipo.isEmpty) return const []`). Mismo mecanismo visual que ya usan `FormularioMascotaScreen`/`DetalleMascotaScreen`, pedido explícitamente por el usuario para "ordenar por tipo de documento y facilitar la vista".

**Ícono + texto, no solo ícono:** a diferencia de las tres secciones fijas de Mascota (que no llevan texto, el usuario ya sabe de memoria qué sección es cada una), acá las secciones son dinámicas — cambian según qué documentos existan — así que se agregó el nombre del tipo al lado del ícono, decisión consultada explícitamente con el usuario. El ícono (`_iconoTipoDocumento`, un `Icons.xxx` de Material por tipo — no hay SVG a medida para esto) queda fijo entre modo claro/oscuro igual que el resto de `SeparadorSeccionFicha`; el texto sí necesita variante oscura (`_colorTextoSeparador`, mismo patrón que `_colorTextoSobreFondo` de `agenda_screen.dart`) porque va directo sobre el fondo de la pantalla, sin tarjeta clara detrás.

### 5. Fecha del documento en la tarjeta, y toggle "por tipo"/"cronológico" (2026-08-19)

```dart
String _fechaMostrar(DocumentoModel documento) {
  final fecha = documento.fechaEmision ?? documento.fechaSubida;
  if (fecha == null) return '';
  return '${fecha.day}/${fecha.month}/${fecha.year}';
}
// subtitle: Text(fecha.isEmpty ? tipo : '$tipo · $fecha'),
```

Pedido del usuario, sin necesitar mucho debate ("creo que debería ir sí o sí"): cada tarjeta ahora muestra la fecha del documento junto al tipo (`Tipo · DD/MM/AAAA`), no solo el tipo. Usa `fechaEmision` (la fecha del documento en sí, ej. cuándo se hizo un examen) si se cargó, y si no cae a `fechaSubida` (la fecha en que se subió a la app, que siempre existe) — mismo criterio de fallback para datos opcionales que el resto del proyecto. Si ninguna de las dos existe (no debería pasar en la práctica), no se agrega el separador `·` y solo se muestra el tipo, sin dejar un guion o fecha vacía colgando.

**`_vistaCronologica` — toggle en el AppBar, mismo patrón que `AgendaScreen`:**

```dart
bool _vistaCronologica = false; // false = agrupado por tipo, true = una lista por fecha

IconButton(
  icon: Icon(_vistaCronologica ? Icons.category : Icons.timeline),
  tooltip: _vistaCronologica ? l10n.verPorTipo : l10n.verCronologico,
  onPressed: () => setState(() => _vistaCronologica = !_vistaCronologica),
)
```

El agrupado por tipo (punto 4) y una línea de tiempo cronológica son dos formas de mirar los mismos documentos que no conviven bien en una sola lista a la vez — se resolvió con el mismo mecanismo de alternar vista que ya usa `AgendaScreen` para calendario/lista (`_vistaCalendario`), en vez de forzar una sola vista o mezclar ambos criterios de orden en una sola pantalla. `_vistaCronologicaWidget` ordena una copia de la lista completa (`[...documentos]..sort(...)`, sin `Sección`/separadores) por `fechaEmision ?? fechaSubida`, más reciente primero — mismo orden descendente que ya usa `obtenerReportesActivos()` en el módulo Mapa. El botón de alternar solo aparece si hay al menos un documento (`if (documentos.isNotEmpty)`) — no tiene sentido con la lista vacía.

**Encabezado propio para la vista cronológica (2026-08-19, mismo día):** el usuario notó que la vista cronológica se veía "pelada" al lado de la vista por tipo, que sí tiene un título+ícono por sección (`SeparadorSeccionFicha`). Se agregó el mismo componente una sola vez al principio de `_vistaCronologicaWidget` (ícono `Icons.timeline`, mismo que el del botón de alternar en el AppBar, + texto `l10n.vistaCronologicaTitulo`) para igualar la visual entre las dos vistas. **Elección de texto:** se usó "Orden cronológico" en vez de "Vista temporal" (la frase textual que pidió el usuario) — en español, "temporal" es ambiguo entre "por tiempo/cronológico" y "provisorio, no permanente"; se prefirió una palabra sin ese doble sentido para evitar confundir a un usuario nuevo, aunque cambia el texto exacto pedido.
