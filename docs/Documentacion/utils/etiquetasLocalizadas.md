# Nota de Obsidian: `etiquetas_localizadas.dart`

## 📁 Ubicación en el Proyecto

`lib/presentation/utils/etiquetas_localizadas.dart`

Primer archivo de una carpeta `utils/` nueva, hermana de `screens/`/`widgets/`/`theme/` dentro de `presentation/`. Usado por `HomeScreen`, `DetalleMascotaScreen` y `CredencialMascotaScreen`.

## 🎯 Propósito del Archivo

Traduce para mostrar en pantalla los valores de especie y sexo de una mascota — que se guardan fijos en español en la base de datos, sin importar el idioma de la app (ver `sistemaIdiomas.md`, punto 3, para el porqué de esta separación).

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `especieValorMostrar(AppLocalizations l10n, String? especie, [String? especiePersonalizada])` y `especieMostrar(BuildContext context, MascotaModel mascota)`

```dart
String especieValorMostrar(AppLocalizations l10n, String? especie, [String? especiePersonalizada]) {
  if (especie == 'Otro' && especiePersonalizada != null) return especiePersonalizada;
  final etiquetas = {'Perro': l10n.especiePerro, 'Gato': l10n.especieGato, ...};
  if (especie == null) return l10n.noEspecificada;
  return etiquetas[especie] ?? especie;
}

String especieMostrar(BuildContext context, MascotaModel mascota) {
  return especieValorMostrar(AppLocalizations.of(context), mascota.especie, mascota.especiePersonalizada);
}
```

`especieMostrar` reemplaza al getter `especieTexto` que tenía `MascotaModel` (borrado en la pasada de idiomas — ver `mascota.model.md`) — un getter no puede recibir `BuildContext`, así que no podía traducir nada, solo devolver el texto en español guardado tal cual. `especieValorMostrar` (2026-08-19) es el núcleo real de la lógica, separado para que también pueda usarse sin una `MascotaModel` de por medio — ver punto 5.

- **El texto libre de "Otro" (con `especiePersonalizada` presente) nunca se traduce:** si el usuario escribió una especie personalizada (ej. "Iguana"), ese texto es lo que el usuario tipeó — no hay forma de traducirlo automáticamente, así que se muestra igual sin importar el idioma de la app.
- **Fallback de `especie == null` vs. un valor no reconocido, distintos (2026-08-19):** `especie == null` (mascota sin especie cargada) cae a `l10n.noEspecificada`. Un valor **no nulo** que no está en el mapa de traducciones ya no cae ahí — se muestra tal cual (`etiquetas[especie] ?? especie`). Antes de este cambio, ambos casos caían al mismo "no especificada", lo cual era un bug latente para cualquier llamador que guardara texto libre directo en el campo `especie` sin el par `especie`/`especiePersonalizada` de `MascotaModel` — ver punto 5, el caso real que lo destapó.

### 2. `sexoMostrar(BuildContext context, String? sexo)`

Mismo patrón que `especieMostrar`, mucho más simple al ser solo dos valores posibles (`'Macho'`/`'Hembra'`). Reemplaza los usos directos de `mascota.sexo` en pantalla (que antes mostraban el string en español crudo, o `'No especificado'` si era `null`).

### 3. Por qué funciones sueltas, no getters en `MascotaModel`

A diferencia de `especieTexto` (que sí vivía como getter en el modelo antes de esta pasada), estas dos funciones **no** pueden ser parte de `MascotaModel` — necesitan `BuildContext` para llegar a `AppLocalizations.of(context)`, y los modelos de datos de este proyecto no dependen de Flutter/widgets (separación deliberada entre `data/` y `presentation/`). Por eso viven en `presentation/utils/`, no en `data/models/`.

### 4. `tipoEventoMostrar`/`tipoDocumentoMostrar`/`tipoPresentacionMostrar` (2026-08-18, pasada de Agenda)

```dart
String tipoEventoMostrar(AppLocalizations l10n, String? tipoEvento, [String? tipoEventoPersonalizado]) { ... }
String tipoDocumentoMostrar(AppLocalizations l10n, String? tipoDocumento) { ... }
String tipoPresentacionMostrar(AppLocalizations l10n, String tipoPresentacion) { ... }
```

Mismo patrón exacto que `especieMostrar`/`sexoMostrar`, para los otros tres valores guardados fijos en español que aparecen en el módulo Agenda. Una diferencia de firma: estas tres reciben `AppLocalizations l10n` ya resuelto en vez de `BuildContext context` — a diferencia de `especieMostrar`/`sexoMostrar` (que se llaman una sola vez por pantalla, directo con el `context` a mano), estas se usan varias veces dentro del mismo `build()` (una por cada medicamento/documento de una lista), así que conviene resolver `AppLocalizations.of(context)` una sola vez arriba y pasarlo, en vez de repetir la búsqueda en cada llamada.

**`tipoEventoMostrar` ganó el parámetro opcional `tipoEventoPersonalizado` (2026-08-22)** — mismo patrón que `especieValorMostrar` (punto 1): si `tipoEvento == 'Otro'` y hay texto personalizado, se muestra ese texto tal cual. Antes de este cambio, `AgendaScreen` (con su propio helper privado `_tipoEventoTexto`) y `DetalleAgendaEventoScreen` (con la misma rama inline) reimplementaban ese chequeo cada una por su lado — encontrado en una revisión completa del código pedida por el usuario (ver `decisiones_arquitectura.md`). Se sumó el parámetro a la función compartida y se borraron las dos copias.

`tipoDocumentoMostrar` es compartida entre los documentos adjuntos a un evento de agenda (`FormularioAgendaEventoScreen`/`DetalleAgendaEventoScreen`) y la pantalla general de Documentos (`DocumentosScreen`/`FormularioDocumentoScreen`/`DetalleDocumentoScreen`, traducida en la pasada del 2026-08-18) — mismo tipo de dato, mismo criterio de traducción, sin importar desde qué pantalla se llama.

**`'Carnet de vacunación': l10n.tipoDocumentoCarnetVacunacion`** — única entrada del mapa que solo existe en la lista `_tiposDocumento` de `FormularioDocumentoScreen` (no en la versión reducida de Agenda). Vive en el mismo mapa igual que las demás porque `tipoDocumentoMostrar` es compartida entre ambos contextos — no hay problema en que el mapa tenga una clave que un solo llamador use.

### 5. `fechaHoraCorta(DateTime fecha)` (2026-08-22)

```dart
String fechaHoraCorta(DateTime fecha) {
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '${fecha.day}/${fecha.month}/${fecha.year} $hora:$minuto';
}
```

No traduce nada (a diferencia del resto de las funciones de este archivo) — vive acá igual porque es del mismo tipo de duplicación que ya resuelven las demás: `DetalleAgendaEventoScreen` y `FormularioAgendaEventoScreen` armaban el mismo string `d/M/y H:mm` con `padLeft` a mano, cada una por su lado, encontrado en la misma revisión de código que el punto 4. Sin `intl`/`DateFormat` a propósito: no hay nombres de mes ni nada que dependa del idioma, un string numérico se lee igual en los tres idiomas de la app — a diferencia de `_localeIntl`/`DateFormat` en `AgendaScreen`, que sí hace falta cuando se muestran nombres de mes.

### 6. `especieValorMostrar` sin `MascotaModel` — el caso que la destapó (2026-08-19)

`FormularioReporteMascotaExtraviadaScreen` y `DetalleReporteMascotaExtraviadaScreen` (módulo Mapa) trabajan con `MascotaExtraviadaModel`, que **no** tiene el par `especie`/`especiePersonalizada` de `MascotaModel` — solo un `mascotaEspecie` único (denormalizado, ver `mascotaExtraviada.model.md`). Cuando alguien reporta una mascota sin registrarla y elige "Otro" con un texto libre (ej. "Iguana"), ese texto se guarda directo en `mascotaEspecie`, sin ningún flag "Otro" aparte. Antes del fix del punto 1, mostrar ese reporte habría dicho "No especificada" en vez del texto real — se detectó al construir estas pantallas, antes de publicarse. La función pública `especieValorMostrar(l10n, especie)` (sin `especiePersonalizada`, ya que no existe acá) resuelve el mismo problema: cualquier texto no reconocido se muestra tal cual, en vez de perderse.
