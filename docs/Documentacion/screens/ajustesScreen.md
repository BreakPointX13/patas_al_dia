# Nota de Obsidian: `AjustesScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/ajustes_screen.dart`

Se accede desde `MenuUsuarioAvatar` (ver `menuUsuarioAvatar.md`), presente en el `AppBar` de las tres pestañas de `NavegacionPrincipalScreen` — antes se accedía solo desde un ícono de engranaje propio de `HomeScreen`.

## 🎯 Propósito del Archivo

Pantalla de ajustes de la app. Tiene diez opciones, agrupadas en cinco secciones desde el 2026-08-22 (ver punto 11): **Apoyo** ("Aportes voluntarios", 2026-08-17, punto 3), **Apariencia** ("Tema", punto 5; "Tamaño de letra", punto 4; "Idioma", punto 6 — las tres del 2026-08-18), **Cuenta** ("Cuenta", 2026-08-19, punto 7 — solo para invitados, es el punto de entrada para registrarse; "Cambiar contraseña", 2026-08-21, punto 10; "Sincronizar ahora", 2026-08-21, punto 9 — las dos últimas solo para usuarios registrados), **Ayuda** ("Reportar un bug", 2026-08-22, punto 12) y **Sesión** ("Cerrar sesión" y "Eliminar cuenta", 2026-08-19, punto 8). Desde esta pasada, todos sus textos salen de `AppLocalizations` (ver `sistemaIdiomas.md`) en vez de estar escritos fijo en español.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

`ConsumerWidget` (no necesita estado propio ni ciclo de vida, igual que `LoginScreen`). Usa `ListView` con un único `ListTile` en vez de una lista de botones sueltos, para que agregar más opciones a futuro sea directo (un `ListTile` más).

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `_confirmarCerrarSesion` (2026-08-15, mensaje condicional desde 2026-08-19)

Antes de llamar a `_cerrarSesion`, pide confirmación con `confirmarAccion` (ver `dialogoConfirmacion.md` — un `AlertDialog` manual hasta el 2026-08-22, extraído a función compartida al encontrarse la misma construcción repetida en 7 lugares del proyecto). Se agregó porque, como invitado, no existe forma de "volver a entrar" a la misma sesión después de cerrarla (no hay credencial que recordar) — cerrar sesión es, en la práctica, irreversible desde la UI, aunque los datos no se borren literalmente de SQLite (ver el punto 3). El texto del diálogo se lo dice explícitamente al usuario antes de que lo haga sin querer.

**Con Login real (2026-08-19), ese texto dejó de ser cierto para un usuario registrado** — al tener email y contraseña, sí puede volver a entrar a la misma sesión (ver `iniciarSesionScreen.md`), con todos sus datos intactos si es el mismo dispositivo. `_confirmarCerrarSesion` ahora recibe un tercer parámetro `esInvitado` (`usuario?.esInvitado ?? true`) y elige entre `cerrarSesionContenido` (advertencia de "esto es irreversible", solo para invitados) y `cerrarSesionContenidoRegistrado` (mensaje neutro, sin advertencia) según corresponda.

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

- **`cerrarSesion()`** (en `UsuarioNotifier`) marca `sesionActiva = false` en SQLite sin borrar al usuario, y desde 2026-08-19 también cierra la sesión de Supabase Auth si el usuario es registrado — ver `usuarioNotifier.md`.
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

### 6. "Idioma" — Auto / ES / EN / PT (2026-08-18, corregido 2026-08-19)

```dart
const _idiomas = ['sistema', 'es', 'en', 'pt'];
// en build(): final etiquetasIdioma = [l10n.idiomaSistemaLabel, 'ES', 'EN', 'PT'];
```

Tercera pieza del pedido de accesibilidad del usuario, ver `sistemaIdiomas.md` para el sistema completo (`.arb`, `AppLocalizations`, etc.) — acá solo el control en sí, mismo patrón que "Tema" (`SegmentedButton<String>`, `'sistema'` por defecto).

**Diferencia clave con "Tema", y un matiz importante en "Idioma": no todo el array es lo mismo.** Los tres nombres de idioma (`'ES'`/`'EN'`/`'PT'`) siguen siendo una constante fija, **no** traducida — cada opción se muestra siempre en su propio idioma nativo, para que el usuario reconozca su idioma sin importar cuál esté puesto en ese momento (traducir el nombre de un idioma según el idioma activo sería contraproducente: alguien que puso la app en portugués sin querer necesita poder encontrar la opción de español en la lista, no una versión traducida al portugués). Pero **"Sistema" no es el nombre de un idioma** — es un concepto de interfaz ("seguir el idioma del sistema operativo"), así que sí debería traducirse como cualquier otro texto de la app. La primera versión lo trataba igual que los otros tres (`_etiquetasIdioma` con `'Sistema'` fijo, string de código) — bug encontrado por el usuario al probar: quedaba siempre en español sin importar el idioma activo. Se corrigió sacándolo del array constante y armándolo en `build()` como `l10n.idiomaSistemaLabel`.

**De nombre completo a sigla (2026-08-18), con "Sistema" corregido después (2026-08-19):** con el tamaño de letra en "Normal" o "Grande", los cuatro segmentos no entraban en una sola línea dentro del `SegmentedButton`. Se acortaron los tres idiomas a su sigla de dos letras (`ES`/`EN`/`PT`) en la primera pasada — pero "Sistema" (7 letras) se dejó igual por error, y seguía desbordando a una segunda línea con el mismo problema que ya se había resuelto para los otros tres. Se corrigió junto con el bug de traducción: `idiomaSistemaLabel` = "Auto" en los tres idiomas (mismo préstamo reconocible en español/inglés/portugués, ya corto por sí solo, sin necesitar acortarlo más). Se descartó usar banderas de países (alternativa que el usuario propuso en su momento): una bandera representa un país, no un idioma, y el portugués en particular no tiene una bandera única sin ambigüedad (Brasil vs. Portugal) — las siglas evitan esa confusión y son un estándar ya reconocido (mismo criterio que usan selectores de idioma de sistemas operativos y navegadores).

### 7. "Cuenta" — punto de entrada para que un invitado se registre (2026-08-19)

```dart
if (usuario != null && usuario.esInvitado)
  ListTile(
    leading: const Icon(Icons.person_outline),
    title: Text(l10n.cuentaInvitadoLabel),
    subtitle: Text(l10n.registrarmeSubtitulo),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegistroScreen(entrarComoApp: false)),
    ),
  )
else if (usuario != null)
  ListTile(
    leading: const Icon(Icons.verified_user_outlined),
    title: Text(usuario.email ?? ''),
  ),
```

Parte de Login real (ver `decisiones_arquitectura.md`, entrada del 2026-08-19, y `registroScreen.md`). Es el único lugar de la app donde un invitado que **ya está usando la app**, con datos cargados, puede llegar a `RegistroScreen` — `LoginScreen` (el otro camino hacia esa pantalla, vía `IniciarSesionScreen`) solo se ve antes de crear ningún usuario, así que no sirve para este caso.

**`entrarComoApp: false`** es la señal que le dice a `RegistroScreen` que ya hay un shell de la app montado alrededor (`NavegacionPrincipalScreen`, con `AjustesScreen` empujada adentro) — al registrarse con éxito, alcanza con un `Navigator.of(context).pop()` para volver a Ajustes, en vez de navegar "hacia adentro" de la app como si fuera la primera vez (que es lo que sí hace el mismo formulario cuando se llega desde `LoginScreen`, con `entrarComoApp: true` por defecto). Ver `registroScreen.md`, punto sobre `entrarComoApp`.

**Un usuario ya registrado ve su email en texto plano, sin flecha ni acción** — no tiene sentido "registrarse" dos veces, así que ese `ListTile` no navega a ningún lado, es puramente informativo (para que sea visible con qué cuenta está conectado).

### 8. "Eliminar cuenta" (2026-08-19)

```dart
Future<void> _confirmarEliminarCuenta(BuildContext context, WidgetRef ref, bool esInvitado) async {
  ...
  content: Text(esInvitado ? l10n.eliminarCuentaContenido : l10n.eliminarCuentaContenidoRegistrado),
  actions: [
    TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.accionCancelar)),
    ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      onPressed: () => Navigator.of(context).pop(true),
      child: Text(l10n.accionEliminar),
    ),
  ],
  ...
}
```

Mismo patrón de confirmación que `_confirmarCerrarSesion` (punto 1) — `AlertDialog` con contenido condicionado a `esInvitado`, más el `ListTile` rojo (`Icons.delete_forever`, texto rojo) que ya usan otras acciones destructivas del proyecto (ej. "Eliminar reporte" en `DetalleReporteMascotaExtraviadaScreen`).

**A diferencia de `_cerrarSesion`, acá sí hace falta manejar errores.** Cerrar sesión no puede fallar de una forma que valga la pena mostrarle al usuario — pero eliminar cuenta sí: para un usuario registrado, `UsuarioNotifier.eliminarUsuario()` (ver `usuarioNotifier.md`, punto 4) llama primero a una Edge Function remota (`eliminarCuentaSupabase`), que puede fallar por falta de conexión o un error del servidor. `_eliminarCuenta` envuelve esa llamada en un `try/catch` (mismo patrón `debugPrint` marcado `// TEMPORAL` que el resto del proyecto con Supabase) y muestra `errorAutenticacionGenerico` si falla, **sin** navegar a `LoginScreen` ni invalidar los providers — el usuario sigue viendo Ajustes tal cual, con su cuenta intacta, para poder reintentar.

**El método que llama, `UsuarioNotifier.eliminarUsuario()`, ya existía desde el CRUD base** (ver `usuarioNotifier.md`) pero nunca había estado conectado a ningún botón — esta es su primera vez en uso real.

### 9. "Sincronizar ahora" + "Última sincronización: hace X" (2026-08-21)

```dart
if (usuario != null && !usuario.esInvitado)
  ListTile(
    leading: sincronizando
        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.sync),
    title: Text(l10n.sincronizarAhoraLabel),
    subtitle: Text(_tiempoRelativo(l10n, usuario.ultimaSincronizacion)),
    onTap: sincronizando ? null : () => ref.read(syncServiceProvider).sincronizar(),
  ),
```

- **Solo visible para usuarios registrados** (`!usuario.esInvitado`) — mismo criterio que Sync en general (ver `syncService.md`): un invitado no tiene con qué sincronizar.
- **Respaldo manual, no el disparador principal.** La sincronización real pasa sola, en tres momentos (arranque con sesión activa, cada 5 minutos en primer plano, al pasar a segundo plano — ver `main.dart` y `syncService.md`). Este `ListTile` es la vía manual para forzarla al toque, y a la vez la única señal visible en toda la app de que Sync existe y está funcionando.
- **`_tiempoRelativo(l10n, DateTime? momento)`** — función privada del archivo, no un paquete nuevo (`intl` no trae un helper de tiempo relativo listo). Cuatro escalones nada más (recién ahora / hace X min / hace X h / hace X día(s)), sin necesitar semanas ni meses para este uso — calcula `DateTime.now().difference(momento)` y elige el primer escalón que corresponda. No se actualiza sola mientras la pantalla queda abierta (sin `Timer` propio) — se recalcula la próxima vez que `AjustesScreen` se reconstruya, que en la práctica coincide con cada sync exitoso (`usuarioProvider` cambia, y esta pantalla lo escucha vía `ref.watch`).
- **`sincronizando` (de `sincronizandoProvider`, ver `syncProvider.md`) deshabilita el `onTap` y cambia el ícono por un `CircularProgressIndicator`** mientras hay una corrida en curso — mismo patrón `_guardando` ya usado en los formularios del proyecto, aplicado acá a un botón en vez de a un formulario completo.
- **Reemplaza a un botón temporal de depuración** (`[TEMPORAL] Sincronizar ahora`, sin el texto de última sincronización) que existió durante las Fases 1 y 2 del plan de Sync, mientras no había disparadores automáticos todavía.

### 10. "Cambiar contraseña" (2026-08-21)

```dart
if (usuario != null && !usuario.esInvitado)
  ListTile(
    leading: const Icon(Icons.lock_outline),
    title: Text(l10n.tituloCambiarContrasena),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CambiarContrasenaScreen()),
    ),
  ),
```

Retoque post-Sync (ver `decisiones_arquitectura.md`) — abre `CambiarContrasenaScreen` (ver `cambiarContrasenaScreen.md`), un formulario nuevo que pide la contraseña actual además de la nueva. Ubicado justo después del `ListTile` de "Cuenta" (email en texto plano) — mismo criterio de visibilidad "solo para registrados" que ese ítem y que "Sincronizar ahora" (punto 9), sin sentido para un invitado (no tiene contraseña que cambiar).

### 11. Agrupación en secciones con `SeparadorSeccionFicha` (2026-08-21)

```dart
Widget _encabezadoSeccion(BuildContext context, IconData icono, String texto) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: SeparadorSeccionFicha(
      icono: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: const Color(0xFFD06D1F), size: 24),
          const SizedBox(width: 8),
          Text(texto, style: TextStyle(color: _colorTextoSeparador(context), fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}
```

- **A pedido explícito del usuario**, que pidió reorganizar las nueve opciones "de un estilo parecido a la separación con logos que implementamos en el orden de los documentos" — reutiliza el mismo widget `SeparadorSeccionFicha` (ver `separadorSeccionFicha.md`) con el mismo patrón ícono+texto que ya usa `DocumentosScreen` para agrupar por tipo (ver `documentosScreen.md`, punto 4), en vez de los tres factory constructors originales del widget (pensados para grupos fijos de campos de un formulario, no para secciones de una pantalla de ajustes).
- **`_colorTextoSeparador`** es una copia local de la función homónima de `documentos_screen.dart` — mismo criterio de duplicar en vez de compartir ya usado en el resto del proyecto (repositories, por ejemplo) cuando una función es chica y no vale la pena una nueva capa de abstracción compartida para dos usos.
- **Cinco secciones desde el 2026-08-22 (originalmente cuatro), con "Apoyo" primero** (decisión explícita del usuario — no es el orden en el que se fueron agregando las opciones históricamente): "Apoyo" (Aportes voluntarios), "Apariencia" (Tema, Tamaño de letra, Idioma), "Cuenta" (Cuenta/Cambiar contraseña/Sincronizar ahora), "Ayuda" (Reportar un bug, ver punto 12) y "Sesión" (Cerrar sesión, Eliminar cuenta) — estas dos últimas separadas a propósito, ya que agrupar una acción destructiva ("Eliminar cuenta") junto a acciones rutinarias de cuenta diluye la separación visual que ya tenía (ícono/texto en rojo).
- **Los encabezados de sección son fijos, no condicionales** — aparecen siempre, aunque algún `ListTile` de esa sección esté oculto (ej. "Cuenta" solo con el ítem de invitado/email, sin "Cambiar contraseña" ni "Sincronizar ahora", para un usuario invitado). Mantiene la estructura visual predecible en vez de hacer que la pantalla "salte" secciones según el tipo de usuario.

### 12. "Reportar un bug" — sección "Ayuda" nueva (2026-08-22)

```dart
ListTile(
  leading: const Icon(Icons.bug_report_outlined),
  title: Text(l10n.reportarBugTitulo),
  subtitle: Text(l10n.reportarBugSubtitulo),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => const ReportarBugScreen()),
  ),
),
```

Pedido pendiente desde el 2026-08-18 (ver memoria de sesión `project_reportar_bug_pendiente`, ya resuelta), pospuesto explícitamente hasta tener Sync/Supabase en pie — ver `decisiones_arquitectura.md` y `reportarBugScreen.md`. Visible para **cualquier** usuario, invitado o registrado (a diferencia de "Cambiar contraseña"/"Sincronizar ahora", que son solo para registrados) — no hay ningún `if` de por medio antes de este `ListTile`, es la primera opción de la pantalla que no depende en absoluto de `usuario`.

### 13. "Moderación" — sección visible solo para el admin (2026-08-25)

```dart
if (usuario?.email == correoAdmin) ...[
  _encabezadoSeccion(context, Icons.admin_panel_settings_outlined, l10n.moderacionTitulo),
  ListTile(
    leading: const Icon(Icons.flag_outlined),
    title: Text(l10n.moderacionTitulo),
    subtitle: Text(l10n.moderacionSubtitulo),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdminModeracionScreen()),
    ),
  ),
],
```

Único ítem de toda la pantalla que se filtra por un correo específico (`correoAdmin`, en `supabase_config.dart`), no por `esInvitado`. Lleva a `AdminModeracionScreen` (ver `adminModeracionScreen.md`) — reemplaza el flujo anterior de revisar reportes denunciados a mano desde el panel de Supabase. La protección real no es este `if` (es solo para no mostrarle el ítem a nadie más) sino la política RLS `denuncias_reportes_leer_admin` del lado del servidor, que compara el mismo correo.
