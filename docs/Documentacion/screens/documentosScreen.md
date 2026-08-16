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

`_tileDocumento` devuelve `Card(child: ListTile(...))`, no un `ListTile` suelto — mismo `CardTheme` global (fondo Durazno, bordes redondeados) que las listas de `HomeScreen` y `AgendaScreen`, parte de la misma pasada de colores.

### 2. Botón flotante centrado

Mismo patrón que `AgendaScreen`/`HomeScreen` (ver `decisiones_arquitectura.md`, entrada del 2026-08-12): `FloatingActionButton.extended` con ícono + texto, centrado abajo.
