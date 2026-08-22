# Nota de Obsidian: `FormularioDocumentoScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/formulario_documento_screen.dart`

Se abre desde `DocumentosScreen` (crear) o desde `DetalleDocumentoScreen` (editar).

## 🎯 Propósito del Archivo

Formulario único crear/editar de un documento — mismo patrón que `FormularioMascotaScreen`/`FormularioAgendaEventoScreen` — con **todos** los campos de `DocumentoModel`: título, tipo (con "Otro" + texto libre), archivo (foto o PDF), fecha de emisión, fecha de vencimiento + recordatorio de vencimiento, notas. Creada el 2026-08-16 con alcance completo desde el inicio (decisión explícita del usuario, en vez de arrancar reducido como se hizo con Agenda).

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

El selector de archivo (tarjeta de 3 opciones: tomar foto / galería / PDF) es el mismo mecanismo que ya se construyó para adjuntar documentos a un evento de agenda (`FormularioAgendaEventoScreen`) — se reimplementó acá en vez de extraerlo a un widget compartido, porque el flujo alrededor es distinto (acá el archivo es *el* dato principal del formulario, no un ítem dentro de una lista editable).

### 🔄 Comparativa con la versión reducida de Agenda

- **Categorías de tipo:** acá se agrega "Carnet de vacunación" a la lista (Receta/Examen/Certificado/Boleta/Otro que ya existía) — es un tipo de documento común que no tenía sentido en el contexto de "documento adjunto a un evento puntual", pero sí en la vista general de documentos de la mascota.
- **Campos nuevos:** fecha de emisión, fecha de vencimiento, recordatorio de vencimiento, notas — ninguno existía en la versión reducida.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `mascotaId` fijo, no editable

A diferencia de `FormularioAgendaEventoScreen` (donde la mascota se elige de un dropdown, porque el evento puede ser de cualquiera), acá `mascotaId` llega como parámetro fijo desde `DocumentosScreen` — este formulario siempre se abre desde el detalle de una mascota puntual, no tiene sentido pedir que se elija.

### 2. `eventoId` se conserva al editar, nunca se asigna al crear

```dart
eventoId: widget.documentoExistente?.eventoId,
```

Un documento creado desde acá nunca queda vinculado a un evento (`eventoId` siempre `null` al crear) — para vincular un documento a un evento puntual, se sigue haciendo desde la sección "Documentos adjuntos" de `FormularioAgendaEventoScreen`. Al editar, se conserva el vínculo que ya tuviera (si vino de un evento, sigue vinculado después de editarlo acá).

### 3. Recordatorio de vencimiento — solo el dato, todavía sin notificación

```dart
SwitchListTile(
  title: Text(l10n.recordatorioVencimientoLabel),
  subtitle: Text(l10n.recordatorioVencimientoAviso),
  ...
)
```

Decisión explícita del usuario: por ahora `recordatorioVencimiento` (bool) se guarda pero no dispara ninguna notificación real — a diferencia de `recordatorioHorasAntes` en Agenda, que sí programa avisos reales vía `NotificacionService`. El subtítulo del switch se lo aclara al usuario directamente en la UI, para que no espere un aviso que todavía no existe. El campo de fecha de vencimiento también se etiqueta como "(opcional)" cuando no tiene valor, por el mismo motivo: dejar claro que no es obligatorio completarlo.

### 4. Traducido (2026-08-18, pasada de Documentos)

Todo el texto de esta pantalla pasa a `AppLocalizations` (ver `sistemaIdiomas.md`, punto 6). El tipo "Carnet de vacunación" (único de este formulario, no existe en la versión reducida de Agenda) se traduce vía `tipoDocumentoMostrar` igual que el resto de los tipos — se le agregó su propia clave `tipoDocumentoCarnetVacunacion` en los tres `.arb` (ver `etiquetasLocalizadas.md`, punto 4).

### 5. `tiposDocumentoDisponibles` — pasó de privada a pública (2026-08-18)

```dart
const tiposDocumentoDisponibles = ['Carnet de vacunación', 'Receta', 'Examen', 'Certificado', 'Boleta', 'Otro'];
```

Antes `_tiposDocumento`, privada de este archivo. Al agrupar `DocumentosScreen` por tipo (ver `documentosScreen.md`, punto 4), se necesitaba el mismo orden fijo en dos pantallas — se sacó el guion bajo para que `DocumentosScreen` la importe y la reuse tal cual, en vez de duplicar la lista o crear un archivo de constantes nuevo solo para esto.

### 6. `_guardando` — indicador de carga en el botón (2026-08-22)

Mismo hallazgo y mismo arreglo que en `FormularioMascotaScreen` (ver `formularioMascotaScreen.md`, punto 14) — este formulario tampoco tenía la bandera de carga, a pesar de que `_guardar()` hace trabajo asíncrono real (copiar el archivo elegido a un directorio persistente). Encontrado en una revisión de consistencia visual pedida por el usuario. Los dos `return` tempranos por validación (formulario inválido, ningún archivo elegido) quedan **antes** de `setState(() => _guardando = true)` — el botón nunca muestra el spinner por un error de validación, solo mientras hay trabajo real en curso.

### 7. Separadores de sección con `SeparadorSeccionFicha` (2026-08-22)

A pedido explícito del usuario, para que este formulario calzara visualmente con `FormularioMascotaScreen` (el único que ya los tenía). Tres secciones, con el constructor base del widget (`icono: Icon(...)`, no los tres factory constructors de la ficha, que traen íconos fijos de Mascota/Identificación/Datos): **Archivo** (`Icons.attach_file`), **Datos** (`Icons.article_outlined` — título, tipo, tipo personalizado) y **Fechas** (`Icons.event_outlined` — emisión, vencimiento, recordatorio). A diferencia del uso en `DocumentosScreen`/`AjustesScreen` (ícono + texto en un `Row`, porque esas pantallas agrupan contenido dinámico y el texto ayuda a identificar cada grupo), acá se usa solo el ícono — mismo criterio que `FormularioMascotaScreen`, donde las etiquetas de cada campo ya alcanzan para identificar la sección. Ver `separadorSeccionFicha.md`, punto 6.
