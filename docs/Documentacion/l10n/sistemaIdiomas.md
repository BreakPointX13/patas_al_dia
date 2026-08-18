# Nota de Obsidian: Sistema de idiomas (i18n)

## 📁 Ubicación en el Proyecto

- `l10n.yaml` (raíz del proyecto) — configuración del generador.
- `lib/l10n/app_es.arb`, `app_en.arb`, `app_pt.arb` — los textos, uno por idioma.
- `lib/l10n/app_localizations*.dart` — generados automáticamente, no se editan a mano (ver punto 2).
- `lib/presentation/utils/etiquetas_localizadas.dart` — ver `etiquetasLocalizadas.md`.

## 🎯 Propósito

Tercera pieza del pedido de accesibilidad del usuario (modo oscuro, tamaño de letra, idiomas — ver `decisiones_arquitectura.md`), y la más grande de las tres: la app pasa de tener todo el texto de interfaz escrito literal en español dentro de cada pantalla, a sacarlo de tres archivos de traducción (español, inglés, portugués), elegidos por el usuario o siguiendo el idioma del sistema operativo.

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Internacionalizar una app significa separar **qué dice la interfaz** de **en qué idioma lo dice** — cada texto pasa a ser una clave (`accionGuardar`) con una traducción por idioma, en vez de un string fijo (`'Guardar'`) escrito directo en el widget.

### 🐾 En Nuestro Proyecto "Patas al día"

Se usa el sistema oficial de Flutter (`flutter_localizations`, incluido en el SDK — no es un paquete de pub.dev nuevo) en vez de un paquete de terceros: genera una clase `AppLocalizations` tipada a partir de los `.arb`, así que pedir una clave que no existe es un error de compilación, no algo que se descubre recién en producción. Sigue coherente con la regla de dependencias mínimas — `intl` (para dar soporte a `flutter_localizations`) ya era dependencia del proyecto desde antes, solo se bajó de `^0.20.3` a `^0.20.2` porque `flutter_localizations` fija esa versión exacta.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `l10n.yaml` — configuración del generador

```yaml
arb-dir: lib/l10n
template-arb-file: app_es.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
```

- **`template-arb-file: app_es.arb`**: español es el idioma "molde" — cualquier clave nueva se agrega primero acá, con su descripción/placeholders, y los otros dos `.arb` la copian. Tiene sentido siendo español el idioma base del proyecto (regla 4 de `CLAUDE.md`).
- **`nullable-getter: false`**: hace que `AppLocalizations.of(context)` devuelva `AppLocalizations` (no `AppLocalizations?`) — sin este ajuste, cada uso necesitaría `AppLocalizations.of(context)!`. Es seguro dejarlo así porque `AppLocalizations.delegate` siempre está registrado en `MaterialApp` (ver punto 4), así que `of(context)` nunca es null en la práctica dentro de esta app.
- **Comando para regenerar tras editar un `.arb`**: `flutter gen-l10n` (o simplemente `flutter run`/`flutter pub get`, que lo disparan solo gracias a `generate: true` en `pubspec.yaml`).

### 2. Los `.arb` — formato y placeholders

```json
{
  "@@locale": "es",
  "eliminarMascotaContenido": "¿Eliminar a {nombre}? Se van a borrar también su agenda y sus documentos. Esta acción no se puede deshacer.",
  "@eliminarMascotaContenido": {
    "placeholders": { "nombre": {} }
  }
}
```

Cada clave normal (`"clave": "texto"`) puede tener una entrada hermana `"@clave": {...}` con metadata — acá solo se usa para declarar `placeholders` (variables dentro del texto, `{nombre}`), que el generador convierte en un parámetro de función: `l10n.eliminarMascotaContenido(mascota.nombre)` en vez de un getter simple.

**Los tres `.arb` deben tener exactamente las mismas claves** — si a `app_en.arb` o `app_pt.arb` le falta una clave que sí está en el `app_es.arb` (molde), el build falla con un error claro señalando cuál falta. Es una red de seguridad: no hay forma de "olvidarse" de traducir algo a un idioma sin que el proyecto deje de compilar.

### 3. Datos guardados en la base de datos vs. texto de interfaz

Antes de escribir código, se resolvió una pregunta con el usuario: especie, sexo, tipo de evento y tipo de documento no son solo texto de interfaz — son **valores guardados** en SQLite (ej. `mascota.especie == 'Perro'`), elegidos desde listas fijas. La decisión (explícita, consultada) fue traducirlos para mostrar, sin cambiar cómo se guardan: la base de datos siempre tiene `'Perro'` en español, sin importar el idioma de la app, y una función se encarga de traducirlo solo al momento de mostrarlo en pantalla. Ver `etiquetasLocalizadas.md` para el mecanismo.

**Consecuencia importante:** comparaciones de código contra estos valores (`if (mascota.sexo == 'Macho')`, `if (_especie == 'Otro')`) siguen comparando contra el string en español siempre — nunca contra la traducción mostrada en pantalla. Esto no cambió con el idioma; solo cambió qué se le muestra al usuario.

### 4. Cómo se aplica en `main.dart`

```dart
final locale = switch (usuario?.idioma) {
  'es' => const Locale('es'),
  'en' => const Locale('en'),
  'pt' => const Locale('pt'),
  _ => null, // 'sistema' — sigue el del sistema operativo
};
return MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  ...
);
```

- **`locale: null` para "sistema":** si no se especifica `locale`, Flutter resuelve automáticamente el idioma según el sistema operativo, filtrado contra `supportedLocales` — si el teléfono está en francés (no soportado), cae al primero de la lista (español, por ser el `template-arb-file`). Mismo patrón exacto que `themeMode: ThemeMode.system` para el tema (ver `temaApp.md`).
- **Los tres `GlobalXxxLocalizations.delegate`:** no son de esta app — son los que traducen los textos internos de Flutter/Material (ej. el botón "Cancelar" del selector de fecha nativo, `showDatePicker`, que no pasa por nuestros `.arb`). Sin ellos, esos textos quedarían en inglés (su default) sin importar el idioma elegido.
- **`usuario.idioma`, mismo patrón que `escalaTexto`/`tema`:** guardado en `UsuarioModel` (columna `idioma TEXT DEFAULT 'sistema'`), se pierde si el invitado desinstala la app — igual que el resto de sus preferencias. Ver `usuario.model.md`.

### 5. Selector de idioma en `AjustesScreen`

```dart
const _idiomas = ['sistema', 'es', 'en', 'pt'];
const _etiquetasIdioma = ['Sistema', 'Español', 'English', 'Português'];
```

A diferencia de `_etiquetasTema`/`_etiquetasEscalaTexto` (que sí se traducen según el idioma activo), `_etiquetasIdioma` queda **fija**, siempre en el idioma nativo de cada opción — el nombre de un idioma no se traduce al idioma actualmente seleccionado, para que el usuario siempre pueda reconocer su propio idioma en la lista aunque la app esté puesta en uno que no entienda. Es el mismo criterio que usan Android/iOS/la mayoría de las apps grandes en su selector de idioma.

### 6. Alcance por pasadas

- **Pasada 1 (Mascotas):** Login, navbar, `HomeScreen`, `FormularioMascotaScreen`, `DetalleMascotaScreen`, `CredencialMascotaScreen`, `MenuUsuarioAvatar`, `AjustesScreen` completo (incluido el selector de idioma en sí).
- **Pasada 2 (Agenda):** `AgendaScreen`, `DetalleAgendaEventoScreen`, `FormularioAgendaEventoScreen` — ver punto 7 para los detalles específicos de este módulo (tipos de evento/documento/presentación, fechas con locale dinámico).

Documentos (la pantalla general, fuera del contexto de un evento) y el resto quedan para las siguientes pasadas — hasta que se traduzcan, esas pantallas siguen mostrando su texto en español fijo sin importar el idioma elegido.

### 7. Particularidades del módulo Agenda

**Tres tipos más de valores guardados que se traducen para mostrar** (mismo criterio que especie/sexo, ver punto 3): tipo de evento (`tipoEventoMostrar`), tipo de documento (`tipoDocumentoMostrar`, compartida entre los documentos adjuntos a un evento y la futura pantalla general de Documentos) y tipo de presentación de un medicamento (`tipoPresentacionMostrar`) — las tres funciones viven en `etiquetas_localizadas.dart` junto a `especieMostrar`/`sexoMostrar` (ver `etiquetasLocalizadas.md`).

**`valorOtro` como clave compartida:** las cuatro listas fijas (especie, tipo de evento, tipo de documento, tipo de presentación) tienen una opción "Otro"/"Other"/"Outro" — mismo texto exacto en los tres idiomas para las cuatro. En vez de cuatro claves distintas con el mismo contenido, se usa una sola (`valorOtro`) para las tres funciones nuevas de este módulo. La única excepción es `especieOtro` (Mascotas, pasada 1) — se dejó como estaba, sin renombrar, para no tocar código ya probado y funcionando solo por consistencia de nombres.

**Recordatorios: `Map<int, String>` se convierte en función** (`_opcionesRecordatorio(AppLocalizations l10n)` en vez de una constante `const _opcionesRecordatorio = {...}`) — antes era un mapa fijo de horas→texto en español; como el texto ahora depende del idioma activo, tiene que recalcularse en cada `build()` en vez de vivir como constante de módulo. El texto genérico "`{h} horas antes`" que se usa en `DetalleAgendaEventoScreen` para *cualquier* cantidad de horas guardadas (no solo las 4 opciones fijas del formulario) usa un placeholder simple sin plural ICU (`recordatorioHorasGenerico`), preservando a propósito el mismo comportamiento gramatical que ya tenía el código (`'$h horas antes'` sin ajustar "hora"/"horas" según cantidad).

**Fechas con locale dinámico — `_localeIntl(context)`:** el código ya usaba `DateFormat(..., 'es_ES')` en varios lugares (tarjetas de eventos, agrupación por mes, encabezado del calendario) — todos hardcodeados a español, sin importar el idioma de la app. Se agregó `_localeIntl(context)`, que mapea `AppLocalizations.of(context).localeName` ('es'/'en'/'pt', el código corto que usa `AppLocalizations`) al identificador completo que espera `intl` ('es_ES'/'en_US'/'pt_BR', ya inicializados en `main.dart` vía `initializeDateFormatting`). Sin este cambio, las fechas de Agenda habrían quedado en español fijo aunque el resto de la pantalla ya estuviera traducido — sería fácil no notarlo al revisar solo el código de texto plano, porque `DateFormat` no aparece en ninguna búsqueda de `Text('...')`.
