# Nota de Obsidian: `DetalleAgendaEventoScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/detalle_agenda_evento_screen.dart`

Se abre al tocar un evento en `AgendaScreen`.

## 🎯 Propósito del Archivo

Muestra todos los datos de un evento de agenda (incluidos medicamentos y documentos adjuntos), permite marcarlo como realizado y da acceso a editarlo. Reescrita el 2026-08-14 para incorporar los campos nuevos (recordatorio, medicamentos, documentos) — la primera versión solo mostraba los campos básicos del evento.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

`ConsumerStatefulWidget` (no `ConsumerWidget`): necesita `initState` para disparar la carga de medicamentos y documentos del evento apenas se abre la pantalla, igual razón que `HomeScreen`.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 0. Guarda contra evento/mascota inexistente (2026-08-15)

`build()` ya no asume que `widget.eventoId` (o la mascota del evento) siga existiendo en los providers — busca a mano con un `for` en vez de `firstWhere` sin `orElse`, y si no lo encuentra, muestra un `CircularProgressIndicator` momentáneo y hace `Navigator.pop()` en el siguiente frame. Puede pasar si el evento se borra (o se cierra sesión, ver `decisiones_arquitectura.md`) mientras esta pantalla sigue abierta.

### 1. `initState()` — carga de medicamentos y documentos

```dart
ref.read(medicamentoEventoProvider.notifier).cargarMedicamentosDeEvento(widget.eventoId);
ref.read(documentosProvider.notifier).cargarDocumentosDeEvento(widget.eventoId);
```

A diferencia de `FormularioAgendaEventoScreen` (que mantiene copias locales editables), esta pantalla es de solo lectura + una acción (marcar realizado), así que sí usa directo el `state` de los providers vía `ref.watch`, sin necesidad de listas locales.

### 2. `_marcarRealizado(AgendaEventoModel evento)` — solo se ve si todavía no está realizado

```dart
if (evento.fechaRealizada != null)
  ListTile(..., title: const Text('Realizado'), subtitle: Text('.../.../...'))
else
  SwitchListTile(title: const Text('Marcar como realizado'), value: false, onChanged: (_) => _marcarRealizado(evento)),
```

**Corregido el 2026-08-15** (antes había un solo `SwitchListTile` togglable en ambos sentidos): un evento pasado, al crearse, ya trae `fechaRealizada` puesta automáticamente (ver `formularioAgendaEventoScreen.md`) — no tenía sentido mostrar un switch pidiendo confirmar algo que el usuario ya declaró que ocurrió al elegir "Evento pasado". Ahora, si `fechaRealizada` ya tiene valor, se muestra como texto fijo ("Realizado", sin interacción); el switch solo aparece cuando todavía está pendiente (eventos futuros no marcados), y una vez que se activa, pasa a mostrarse como texto fijo también — no hay forma de "desmarcar" desde acá (si fue un error, se corrige editando el evento).

### 3. `_eliminarEvento(AgendaEventoModel evento)`

Pide confirmación (`AlertDialog`) antes de borrar — es una acción destructiva. Antes de eliminar el evento, cancela su recordatorio pendiente (`NotificacionService.instance.cancelarRecordatorio`) para no dejar una notificación programada apuntando a un evento que ya no existe. El borrado en sí (`agendaEventosProvider.notifier.eliminarAgendaEvento`) dispara en cascada, a nivel de SQLite, el borrado de sus medicamentos (`ON DELETE CASCADE`) y desvincula sus documentos sin borrarlos (`ON DELETE SET NULL`, ver `documento.model.md`) — la pantalla no necesita borrar esas filas a mano.

**Botón "Eliminar" en rojo, y disparador movido del `AppBar` a la lista de acciones (2026-08-17):** originalmente el ícono de basurero vivía en `actions` del `AppBar`, y el botón "Eliminar" del diálogo usaba el `ElevatedButtonTheme` por defecto de la app (sin color de advertencia). Se igualó al mismo patrón que "Eliminar mascota" en `DetalleMascotaScreen` (ver `detalleMascotaScreen.md`, punto 6), agregado ese mismo día: un `ListTile` en rojo (`Icons.delete_outline` + texto, ambos `Colors.red`) al final de la lista de acciones, debajo de "Editar evento", y el botón "Eliminar" del diálogo en rojo — para que las dos pantallas de eliminación de la app se vean y se comporten igual. Desde el 2026-08-22 el diálogo en sí se arma con `confirmarAccion(destructivo: true)` en vez de un `AlertDialog` manual — ver `dialogoConfirmacion.md`.

### 4. Miniatura de documentos según tipo de archivo

```dart
leading: documento.fileExtension == 'pdf'
    ? const Icon(Icons.picture_as_pdf)
    : ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(File(documento.filePath), width: 40, height: 40, fit: BoxFit.cover),
      ),
```

Para imágenes, se muestra una vista previa real leyendo el archivo del dispositivo (`Image.file`); para PDF, solo un ícono.

### 5. `_abrirDocumento(DocumentoModel documento)` — ver imágenes y documentos (2026-08-15)

```dart
if (documento.fileExtension == 'pdf') {
  await OpenFilex.open(documento.filePath);
  return;
}
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => VisorImagenScreen(...)),
);
```

Dos caminos según el tipo de archivo:

- **Imagen:** se abre `VisorImagenScreen` (nueva, `lib/presentation/screens/visor_imagen_screen.dart`) — pantalla completa negra con la imagen dentro de un `InteractiveViewer` (zoom con pellizcar), sin ningún paquete nuevo, es un widget nativo de Flutter.
- **PDF:** no hay visor de PDF embebido en la app — se le pide al sistema operativo que lo abra con la app que el usuario ya tenga instalada para eso (`OpenFilex.open`, paquete nuevo `open_filex`). Es la misma lógica que "descargar y abrir con la app que corresponda" que usa cualquier gestor de archivos.
