# Nota de Obsidian: `DetalleDocumentoScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/detalle_documento_screen.dart`

Se abre al tocar un documento en `DocumentosScreen`.

## 🎯 Propósito del Archivo

Muestra todos los datos de un documento, da acceso a ver el archivo (imagen a pantalla completa o abrir PDF con la app del sistema — mismo mecanismo que `DetalleAgendaEventoScreen`, ver `visor_imagen_screen.dart`), editar y eliminar.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 0. Vista previa con zoom, embebida en la pantalla (2026-08-16)

```dart
if (documento.fileExtension != 'pdf')
  InteractiveViewer(child: Image.file(File(documento.filePath), ...)),
```

Para documentos que son imagen, se muestra una vista previa grande (320 de alto) arriba de los datos, ya con zoom funcional (`InteractiveViewer`, mismo widget que usa `VisorImagenScreen` a pantalla completa) — no hacía falta nada nuevo, la pantalla ya tenía espacio de sobra debajo de una lista corta de `ListTile`. Tocar la vista previa (o el ítem "Ver a pantalla completa" más abajo) igual lleva al visor completo, para los casos en que 320 de alto se queda corto. Los PDF no tienen vista previa embebida — no hay renderizador de PDF en el proyecto (ver la decisión del 2026-08-14) — así que solo tienen el ítem "Abrir documento", que delega en la app del sistema.

### 1. `_cargarEventoVinculado()` — nombre del evento, solo si corresponde

```dart
final eventoId = documento?.eventoId;
if (eventoId == null) return;
final evento = await ref.read(agendaEventoRepositoryProvider).obtenerAgendaEventoPorId(eventoId);
```

Si el documento viene de un evento de agenda (`eventoId != null`), se busca el evento **directo por repository** (no por `agendaEventosProvider`) — porque ese provider solo tiene cargados los eventos que la pantalla de Agenda haya filtrado en su momento, no necesariamente este documento en particular. Es una sola consulta puntual (por id), igual de barata que cualquier otra búsqueda por id ya usada en el proyecto (`obtenerMascotaPorId`, etc.).

### 2. Guarda contra documento inexistente

Mismo patrón que `DetalleAgendaEventoScreen`/`DetalleMascotaScreen` (ver `decisiones_arquitectura.md`, entrada del 2026-08-15): si el documento ya no está en `documentosProvider` (se borró, o se cerró sesión mientras la pantalla seguía abierta), se vuelve atrás en vez de crashear con un `firstWhere` sin red de seguridad.

### 3. Traducido (2026-08-18, pasada de Documentos)

Todo el texto pasa a `AppLocalizations`, incluido el tipo de documento (vía `tipoDocumentoMostrar`).

**El botón de eliminar se movió del `AppBar` a un `ListTile` rojo al final del cuerpo (2026-08-22)** — a pedido explícito del usuario, para que quedara igual al patrón que ya usan `DetalleAgendaEventoScreen`/`DetalleMascotaScreen`/`DetalleReporteMascotaExtraviadaScreen` (esta pantalla era la única que todavía tenía el botón arriba, con un `IconButton` sin color propio, desde la pasada de traducción — ver la nota anterior). Ver `decisiones_arquitectura.md`.
