# Nota de Obsidian: `LoginScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/login_screen.dart`

Ya no es el `home` directo de `MaterialApp` — `main.dart` arranca con `SesionInicialScreen`, que decide si mostrar esta pantalla (no hay usuario con sesión activa en el dispositivo) o saltar directo a `NavegacionPrincipalScreen` (sí lo hay). Ver `sesionInicialScreen.md`.

## 🎯 Propósito del Archivo

Pantalla de bienvenida con dos caminos, coherente con el login híbrido que `UsuarioModel` ya soporta (regla 2 de `CLAUDE.md`: ninguna funcionalidad core debe requerir registro obligatorio):

- **"Continuar como invitado"** (botón principal, relleno): crea un `UsuarioModel` con `esInvitado = true` vía `UsuarioNotifier.crearUsuario`, y navega a `NavegacionPrincipalScreen` reemplazando esta pantalla (no se puede volver atrás).
- **"Iniciar sesión"** (botón secundario, con borde): desde Login real (2026-08-19, ver `decisiones_arquitectura.md`) abre `IniciarSesionScreen`, un formulario real de email/contraseña contra Supabase Auth — ver `iniciarSesionScreen.md`. Antes de esa fecha solo mostraba un aviso ("no disponible todavía").

El logo ya no es el `Icon(Icons.pets)` de placeholder original: usa `Image.asset('assets/images/logo_patas_al_dia.png')`, el logo real de la identidad visual (ver la entrada "Identidad visual" en `decisiones_arquitectura.md`). El título "Patas al Día" hereda `textTheme.headlineMedium` del `ThemeData` global (`main.dart`), que ahora usa la tipografía Nunito de la marca en vez de la fuente por defecto de Material.

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Es común que apps con backend opcional muestren primero una pantalla de decisión (login vs. modo invitado/demo) en vez de forzar un formulario de credenciales antes de dejar entrar al usuario — reduce fricción de onboarding.

### 🐾 En Nuestro Proyecto "Patas al día"

`LoginScreen` es un `ConsumerWidget`: no maneja su propio estado interno, pero necesita `ref` para hablar con `usuarioProvider` (crear el usuario invitado). Es la primera pantalla de la app que consume un provider.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** muchas apps usan paquetes de routing dedicados (`go_router`, `auto_route`) desde el día uno.
- **Nuestro Enfoque:** usamos el `Navigator` incluido en Flutter (`Navigator.of(context).pushReplacement(...)`) — coherente con la regla 6 de dependencias mínimas. Para el tamaño actual de la app alcanza sin problema.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `ConsumerWidget` en vez de `StatelessWidget`

```dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

Es la versión de un widget sin estado propio que Riverpod provee para poder leer/llamar providers desde la UI — `build` recibe un `WidgetRef ref` extra, el mismo tipo de `ref` que ya se usa dentro de los Notifiers.

### 2. `_continuarComoInvitado`

```dart
Future<void> _continuarComoInvitado(BuildContext context, WidgetRef ref) async {
  final usuarioInvitado = UsuarioModel(id: const Uuid().v4());
  await ref.read(usuarioProvider.notifier).crearUsuario(usuarioInvitado);

  if (!context.mounted) {
    return;
  }

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => const NavegacionPrincipalScreen()),
  );
}
```

- **`Uuid().v4()`**: genera el id único del nuevo usuario. Primer uso real del paquete `uuid` en el proyecto.
- **`ref.read(usuarioProvider.notifier)`**: `.notifier` da acceso a la clase `UsuarioNotifier` en sí (sus métodos), no solo a su estado actual.
- **`if (!context.mounted) return;`**: guarda de seguridad obligatoria después de un `await` que usa `context` — la pantalla pudo haberse cerrado mientras se esperaba la operación asíncrona; usar `context` en ese caso puede crashear la app.
- **`pushReplacement` en vez de `push`**: reemplaza la pantalla actual en vez de apilarla, para que no se pueda volver a la bienvenida con el botón "atrás" una vez que ya se entró.

### 3. `_irAIniciarSesion` (2026-08-19, reemplaza a `_mostrarLoginNoDisponible`)

```dart
void _irAIniciarSesion(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => const IniciarSesionScreen()),
  );
}
```

`push` normal (no `pushReplacement`) — a diferencia de "Continuar como invitado", acá sí tiene sentido poder volver atrás con el botón nativo si el usuario tocó "Iniciar sesión" por error. La clave `loginNoDisponible` (usada acá hasta esta fecha) se borró de los tres `.arb` junto con este método — código muerto una vez que el login real existe.

### 4. `OutlinedButton` vs. `ElevatedButton`

El botón con borde (`Outlined`) se usa para la acción secundaria ("Iniciar sesión"), el relleno (`Elevated`) para la principal ("Continuar como invitado") — jerarquía visual que prioriza el camino sin fricción, según el wireframe acordado antes de programar la pantalla.

### 5. Textos vía `AppLocalizations` (2026-08-18)

Todos los textos de esta pantalla (eslogan, botones, aviso de "no disponible") salen de `AppLocalizations.of(context)` en vez de estar escritos fijo en español — ver `sistemaIdiomas.md`. El nombre "Patas al Día" (`l10n.appTitulo`) queda igual en los tres idiomas: es el nombre propio de la app, no se traduce.

### 6. `_abrirPoliticaPrivacidad` — link a la política de privacidad (2026-08-21)

```dart
Future<void> _abrirPoliticaPrivacidad(BuildContext context) async {
  final idioma = Localizations.localeOf(context).languageCode;
  final sufijo = ['es', 'en', 'pt'].contains(idioma) ? idioma : 'es';
  final uri = Uri.parse(
    'https://breakpointx13.github.io/PatasAlDiaWeb/privacidad-$sufijo.html',
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
```

- **Retoque post-Sync** (ver `decisiones_arquitectura.md`) — tres páginas HTML estáticas, una por idioma, en el mismo repo de GitHub Pages que ya aloja la página de confirmación de correo (`PatasAlDiaWeb`, público, separado del repo principal privado) — mismo motivo que esa página: Supabase Storage no puede servir HTML real, siempre lo entrega como `text/plain`.
- **`Localizations.localeOf(context)`, no `usuario?.idioma`:** en `LoginScreen` puede no existir ningún `UsuarioModel` todavía (la primerísima vez que se abre la app, antes de "Continuar como invitado" o de iniciar sesión) — `usuarioProvider` sería `null` en ese caso, sin ningún idioma guardado del cual leer. `Localizations.localeOf(context)` en cambio siempre devuelve el idioma **efectivamente activo** en pantalla, resuelto por Flutter (según la preferencia guardada si ya existe un usuario, o según el idioma del sistema operativo si no) — es el mismo idioma que el usuario ya está viendo en el resto de esta pantalla, así que la política de privacidad que se abre siempre coincide.
- **Visible en `LoginScreen`, no solo en `AjustesScreen`:** decisión explícita del usuario — al estar en la primera pantalla de la app, queda al alcance de cualquiera, incluso de alguien que todavía no creó ni una cuenta de invitado (relevante también para el requisito de Play Store de que la política de privacidad sea encontrable sin tener que registrarse primero).
- **`url_launcher`, mismo patrón que "Aportes voluntarios"** (ver `ajustesScreen.md`, punto 3) — `LaunchMode.externalApplication`, abre en el navegador del sistema, no en un WebView embebido.
