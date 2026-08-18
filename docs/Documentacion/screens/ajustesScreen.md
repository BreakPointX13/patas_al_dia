# Nota de Obsidian: `AjustesScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/ajustes_screen.dart`

Se accede desde `MenuUsuarioAvatar` (ver `menuUsuarioAvatar.md`), presente en el `AppBar` de las tres pestañas de `NavegacionPrincipalScreen` — antes se accedía solo desde un ícono de engranaje propio de `HomeScreen`.

## 🎯 Propósito del Archivo

Pantalla de ajustes de la app. Tiene cuatro opciones: "Tema" (2026-08-18, ver punto 5), "Tamaño de letra" (2026-08-18, ver punto 4), "Aportes voluntarios" (2026-08-17, ver punto 3) y "Cerrar sesión"; es el lugar natural donde agregar más adelante otras preferencias (notificaciones, cuenta, etc.) sin volver a tocar `HomeScreen`.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

`ConsumerWidget` (no necesita estado propio ni ciclo de vida, igual que `LoginScreen`). Usa `ListView` con un único `ListTile` en vez de una lista de botones sueltos, para que agregar más opciones a futuro sea directo (un `ListTile` más).

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `_confirmarCerrarSesion` (2026-08-15)

Antes de llamar a `_cerrarSesion`, pide confirmación con un `AlertDialog`. Se agregó porque, como invitado, no existe forma de "volver a entrar" a la misma sesión después de cerrarla (no hay credencial que recordar) — cerrar sesión es, en la práctica, irreversible desde la UI, aunque los datos no se borren literalmente de SQLite (ver el punto 3). El texto del diálogo se lo dice explícitamente al usuario antes de que lo haga sin querer.

### 2. `_cerrarSesion(BuildContext context, WidgetRef ref)`

```dart
Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
  await ref.read(usuarioProvider.notifier).cerrarSesion();

  ref.invalidate(mascotasProvider);
  ref.invalidate(agendaEventosProvider);
  ref.invalidate(medicamentoEventoProvider);
  ref.invalidate(documentosProvider);

  if (!context.mounted) {
    return;
  }

  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginScreen()),
    (route) => false,
  );
}
```

- **`cerrarSesion()`** (en `UsuarioNotifier`) marca `sesionActiva = false` en SQLite sin borrar al usuario — ver `usuarioNotifier.md`.
- **`ref.invalidate(...)`** (agregado el 2026-08-15, ver el bug correspondiente en `decisiones_arquitectura.md`): fuerza a que cada provider vuelva a su estado inicial (`build()` devuelve `[]`) la próxima vez que algo lo lea. Sin esto, un invitado nuevo (creado después de cerrar sesión) podía ver por un momento — o de forma persistente en `AgendaScreen`, por una condición de carrera con `mascotasProvider` — datos del invitado anterior, porque estos providers son globales y no se "resetean" solos solo por navegar a otra pantalla.
- **`pushAndRemoveUntil(..., (route) => false)`**: a diferencia del `pushReplacement` que usan `LoginScreen` y `SesionInicialScreen` (que reemplazan solo la pantalla actual), acá hace falta vaciar **todo** el stack de navegación — si solo se reemplazara `AjustesScreen`, `NavegacionPrincipalScreen` seguiría debajo y el botón "atrás" desde `LoginScreen` volvería a una sesión que ya se cerró. El callback `(route) => false` le dice "no conserves ninguna ruta anterior".
- **`rootNavigator: true`**: desde el 2026-08-12, `AjustesScreen` se abre empujada dentro del `Navigator` propio de la pestaña activa (ver `navegacionPrincipalScreen.md`), no en el `Navigator` de toda la app. Sin este parámetro, `Navigator.of(context)` resolvería al `Navigator` de esa pestaña, y `pushAndRemoveUntil` solo vaciaría la pila de esa pestaña — `LoginScreen` quedaría empujado ahí adentro, con la barra inferior del shell todavía visible alrededor. `rootNavigator: true` fuerza a que apunte siempre al `Navigator` más externo (el de `MaterialApp`), sin importar desde qué pestaña se haya abierto esta pantalla.

### 3. "Aportes voluntarios" — `url_launcher` (2026-08-17)

```dart
final _urlKoFi = Uri.parse('https://ko-fi.com/breakpointx');

Future<void> _abrirKoFi(BuildContext context) async {
  final abierto = await launchUrl(_urlKoFi, mode: LaunchMode.externalApplication);
  if (!abierto && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace')));
  }
}
```

**Contexto de la decisión:** el plan de monetización original (ver `decisiones_arquitectura.md` y la memoria de sesión "Lanzamiento y monetización") era publicidad mínima para cubrir costos de Play Store. El usuario descartó esa idea y la reemplazó por una sección discreta de aportes voluntarios vía Ko-fi — sin publicidad en la app.

- **`url_launcher` como dependencia nueva:** Flutter no tiene forma nativa de abrir una URL en el navegador del sistema — misma excepción a la regla de dependencias mínimas ya aceptada para `file_picker`/`open_filex`/`flutter_svg`/`table_calendar`/`share_plus`.
- **`LaunchMode.externalApplication`**: abre el link en el navegador del sistema (o la app de Ko-fi si el usuario la tiene instalada), no en un WebView embebido dentro de la propia app — más simple y consistente con que esta es una salida a un servicio externo, no una función de la app en sí.
- **`launchUrl` devuelve `bool`, no lanza excepción si falla:** a diferencia de otras integraciones (`OpenFilex.open`, por ejemplo), acá se chequea el resultado y se muestra un `SnackBar` de error si no se pudo abrir (ej. sin navegador disponible) — sin este chequeo, un fallo pasaría completamente desapercibido, sin ningún feedback al usuario.
- **`android:queries` en `AndroidManifest.xml`:** Android 11+ restringe qué paquetes puede "ver" una app por defecto (*package visibility*). Sin declarar `<intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>` dentro de `<queries>`, `launchUrl` puede fallar en dispositivos con Android 11+ aunque el navegador esté instalado — no es un requisito específico de este proyecto, es el comportamiento documentado del propio paquete `url_launcher`.
- **Ubicación discreta, dentro de `AjustesScreen`:** decisión explícita del usuario — no un ítem en el menú desplegable del perfil (`MenuUsuarioAvatar`), que se mantiene con una sola opción ("Ajustes"), sino un `ListTile` más dentro de la pantalla de ajustes, dos pasos de distancia en vez de estar a la vista todo el tiempo.

### 4. "Tamaño de letra" — primer paso de accesibilidad (2026-08-18)

```dart
const _escalasTexto = [0.85, 1.0, 1.2];
const _etiquetasEscalaTexto = ['Pequeño', 'Normal', 'Grande'];

final escalaActual = ref.watch(usuarioProvider)?.escalaTexto ?? 1.0;
var indiceActual = _escalasTexto.indexOf(escalaActual);
if (indiceActual == -1) indiceActual = 1;

Slider(
  value: indiceActual.toDouble(),
  min: 0, max: 2, divisions: 2,
  label: _etiquetasEscalaTexto[indiceActual],
  onChanged: (valor) => ref.read(usuarioProvider.notifier).actualizarEscalaTexto(_escalasTexto[valor.round()]),
)
```

Primera pieza de un pedido más grande del usuario sobre accesibilidad (modo oscuro, tamaño de letra e idiomas — ver `decisiones_arquitectura.md`, entrada del 2026-08-18). Se empezó por tamaño de letra por ser, de las tres, la más chica y la de mayor impacto real de accesibilidad.

- **Solo texto, no toda la UI:** deliberadamente escala únicamente las fuentes (vía `MediaQuery.textScaler`, ver más abajo), no íconos/paddings/tamaños de tarjetas. Es el mismo criterio que usan los ajustes de tamaño de letra del sistema operativo (Android/iOS) o apps como Gmail/WhatsApp — más robusto que intentar escalar "todo" a mano multiplicando decenas de valores fijos por archivo, que además rompería layouts con más facilidad.
- **3 pasos fijos, no un slider continuo:** decisión explícita del usuario. `_escalasTexto`/`_etiquetasEscalaTexto` son dos listas paralelas (índice 0 = "Pequeño"/0.85, etc.) — el `Slider` en sí no conoce las etiquetas ni los valores reales, solo mueve un índice entre 0 y 2 (`divisions: 2` lo fuerza a saltar en pasos enteros, sin valores intermedios).
- **`indexOf` con salvaguarda a "Normal" (índice 1):** si `escalaTexto` guardada no calza con ninguno de los 3 valores exactos de `_escalasTexto` (no debería pasar en uso normal, pero es una salvaguarda barata), el slider no se rompe — cae a "Normal" en vez de a `indexOf` devolviendo `-1` y crashear al indexar `_etiquetasEscalaTexto[-1]`.
- **`escalaTexto` vive en `UsuarioModel`, no en un paquete de preferencias nuevo** (`shared_preferences` u otro): se guarda junto al resto de los datos del usuario en SQLite, con el mismo comportamiento que "sesión activa" — es una preferencia atada al usuario invitado actual, que se pierde si se desinstala la app (igual que todos sus demás datos), decisión explícita del usuario para no sumar una dependencia nueva. Ver `usuario.model.md` y `usuarioNotifier.md`.
- **Aplicado una sola vez, en `main.dart`, no pantalla por pantalla:** `MyApp` pasó de `StatelessWidget` a `ConsumerWidget`, y el `builder` de `MaterialApp` envuelve el árbol completo en un `MediaQuery` con `textScaler: TextScaler.linear(escalaTexto)` leído de `usuarioProvider`. Como todas las pantallas de la app cuelgan de ese mismo árbol, el cambio de tamaño de letra se aplica a toda la app de una sola vez — no hace falta tocar cada `Text` ni cada pantalla individualmente. Si `usuarioProvider` todavía es `null` (por ejemplo, mientras `SesionInicialScreen` está cargando al usuario), se usa `1.0` como valor por defecto.
- **Pendiente de revisión:** pantallas con alturas fijas o layouts ajustados (por ejemplo `CredencialMascotaScreen`) podrían verse mal con el tamaño "Grande" — no se auditó cada pantalla todavía, queda como tarea de revisión visual pantalla por pantalla, tal como se conversó con el usuario antes de implementar.

### 5. "Tema" — Sistema / Claro / Oscuro (2026-08-18)

```dart
const _temas = ['sistema', 'claro', 'oscuro'];
const _etiquetasTema = ['Sistema', 'Claro', 'Oscuro'];
const _iconosTema = [Icons.brightness_auto, Icons.light_mode, Icons.dark_mode];

SegmentedButton<String>(
  segments: [for (var i = 0; i < _temas.length; i++) ButtonSegment(value: _temas[i], label: Text(_etiquetasTema[i]), icon: Icon(_iconosTema[i]))],
  selected: {_temas[indiceTema]},
  onSelectionChanged: (seleccion) => ref.read(usuarioProvider.notifier).actualizarTema(seleccion.first),
)
```

Segunda pieza del pedido de accesibilidad del usuario (modo oscuro, tamaño de letra, idiomas — ver `decisiones_arquitectura.md`), después de tamaño de letra.

- **`SegmentedButton<String>`, no `Slider`:** a diferencia de "Tamaño de letra", acá las tres opciones no tienen un orden natural de "menos a más" — es una elección categórica (Sistema/Claro/Oscuro), no una escala. `SegmentedButton` es el widget de Material 3 pensado justo para este caso: 2 a 4 opciones excluyentes entre sí, todas visibles al mismo tiempo.
- **`selected: {_temas[indiceTema]}` — un `Set`, no un valor suelto:** `SegmentedButton` soporta selección múltiple por diseño (`multiSelectionEnabled`, no usado acá), así que su API pide un `Set` incluso cuando solo se permite una selección a la vez (comportamiento por defecto, `multiSelectionEnabled: false`).
- **`'sistema'` como valor por defecto, no `'claro'`:** decisión explícita del usuario — la preferencia se guarda en el usuario (igual que `escalaTexto`), pero por defecto la app debe seguir lo que diga el sistema operativo, no forzar claro. Ver cómo se traduce a `ThemeMode` en `main.dart` (`'claro'` → `ThemeMode.light`, `'oscuro'` → `ThemeMode.dark`, cualquier otro valor incluido `'sistema'` → `ThemeMode.system`).
- **Colores de la app en modo oscuro:** ver `temaApp.md` para el detalle completo — en resumen, toda la paleta de acento (Naranja, Naranja marca, Durazno, Amarillo cálido) se mantiene igual en los dos modos; solo cambia el fondo del `Scaffold` (Crema → gris oscuro cálido) y el "café texto" que aparece directo sobre ese fondo (sin tarjeta detrás), que se invierte a un tono claro para seguir siendo legible.
