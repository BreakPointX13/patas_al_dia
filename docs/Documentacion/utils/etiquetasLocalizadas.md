# Nota de Obsidian: `etiquetas_localizadas.dart`

## 📁 Ubicación en el Proyecto

`lib/presentation/utils/etiquetas_localizadas.dart`

Primer archivo de una carpeta `utils/` nueva, hermana de `screens/`/`widgets/`/`theme/` dentro de `presentation/`. Usado por `HomeScreen`, `DetalleMascotaScreen` y `CredencialMascotaScreen`.

## 🎯 Propósito del Archivo

Traduce para mostrar en pantalla los valores de especie y sexo de una mascota — que se guardan fijos en español en la base de datos, sin importar el idioma de la app (ver `sistemaIdiomas.md`, punto 3, para el porqué de esta separación).

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `especieMostrar(BuildContext context, MascotaModel mascota)`

```dart
String especieMostrar(BuildContext context, MascotaModel mascota) {
  final l10n = AppLocalizations.of(context);
  if (mascota.especie == 'Otro' && mascota.especiePersonalizada != null) {
    return mascota.especiePersonalizada!;
  }
  final etiquetas = {
    'Perro': l10n.especiePerro,
    'Gato': l10n.especieGato,
    ...
  };
  return etiquetas[mascota.especie] ?? l10n.noEspecificada;
}
```

Reemplaza al getter `especieTexto` que tenía `MascotaModel` (borrado en esta misma pasada — ver `mascota.model.md`) — un getter no puede recibir `BuildContext`, así que no podía traducir nada, solo devolver el texto en español guardado tal cual.

- **El texto libre de "Otro" nunca se traduce:** si el usuario escribió una especie personalizada (ej. "Iguana"), ese texto es lo que el usuario tipeó — no hay forma de traducirlo automáticamente, así que se muestra igual sin importar el idioma de la app.
- **`etiquetas[mascota.especie] ?? l10n.noEspecificada`:** si `especie` es `null` (mascota sin especie cargada) o, en teoría, algún valor que no esté en el mapa (no debería pasar con datos nuevos, pero es una salvaguarda barata), cae al texto de "no especificada" en vez de mostrar `null` o crashear.

### 2. `sexoMostrar(BuildContext context, String? sexo)`

Mismo patrón que `especieMostrar`, mucho más simple al ser solo dos valores posibles (`'Macho'`/`'Hembra'`). Reemplaza los usos directos de `mascota.sexo` en pantalla (que antes mostraban el string en español crudo, o `'No especificado'` si era `null`).

### 3. Por qué funciones sueltas, no getters en `MascotaModel`

A diferencia de `especieTexto` (que sí vivía como getter en el modelo antes de esta pasada), estas dos funciones **no** pueden ser parte de `MascotaModel` — necesitan `BuildContext` para llegar a `AppLocalizations.of(context)`, y los modelos de datos de este proyecto no dependen de Flutter/widgets (separación deliberada entre `data/` y `presentation/`). Por eso viven en `presentation/utils/`, no en `data/models/`.

### 4. `tipoEventoMostrar`/`tipoDocumentoMostrar`/`tipoPresentacionMostrar` (2026-08-18, pasada de Agenda)

```dart
String tipoEventoMostrar(AppLocalizations l10n, String? tipoEvento) { ... }
String tipoDocumentoMostrar(AppLocalizations l10n, String? tipoDocumento) { ... }
String tipoPresentacionMostrar(AppLocalizations l10n, String tipoPresentacion) { ... }
```

Mismo patrón exacto que `especieMostrar`/`sexoMostrar`, para los otros tres valores guardados fijos en español que aparecen en el módulo Agenda. Una diferencia de firma: estas tres reciben `AppLocalizations l10n` ya resuelto en vez de `BuildContext context` — a diferencia de `especieMostrar`/`sexoMostrar` (que se llaman una sola vez por pantalla, directo con el `context` a mano), estas se usan varias veces dentro del mismo `build()` (una por cada medicamento/documento de una lista), así que conviene resolver `AppLocalizations.of(context)` una sola vez arriba y pasarlo, en vez de repetir la búsqueda en cada llamada.

`tipoDocumentoMostrar` es compartida entre los documentos adjuntos a un evento de agenda (`FormularioAgendaEventoScreen`/`DetalleAgendaEventoScreen`) y la pantalla general de Documentos (`DocumentosScreen`/`FormularioDocumentoScreen`/`DetalleDocumentoScreen`, traducida en la pasada del 2026-08-18) — mismo tipo de dato, mismo criterio de traducción, sin importar desde qué pantalla se llama.

**`'Carnet de vacunación': l10n.tipoDocumentoCarnetVacunacion`** — única entrada del mapa que solo existe en la lista `_tiposDocumento` de `FormularioDocumentoScreen` (no en la versión reducida de Agenda). Vive en el mismo mapa igual que las demás porque `tipoDocumentoMostrar` es compartida entre ambos contextos — no hay problema en que el mapa tenga una clave que un solo llamador use.
