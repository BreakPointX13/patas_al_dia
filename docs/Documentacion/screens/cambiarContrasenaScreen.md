# Nota de Obsidian: `CambiarContrasenaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/cambiar_contrasena_screen.dart`

Se accede desde `AjustesScreen` (ver `ajustesScreen.md`, punto 10), solo para usuarios registrados con sesión iniciada.

## 🎯 Propósito del Archivo

Retoque post-Sync (2026-08-21, ver `decisiones_arquitectura.md`): permite a un usuario registrado cambiar su contraseña sin tener que pasar por el flujo de "olvidé mi contraseña" (que exige salir de la app y volver por un enlace de correo).

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Comparte estructura con `RegistroScreen`/`NuevaContrasenaScreen` (mismo patrón de formulario con `validarContrasena`, mismo manejo de `AuthException`), pero es una pantalla nueva y no una reutilización de `NuevaContrasenaScreen` — la diferencia importante entre las dos es **qué prueba de identidad existe antes de aceptar el cambio**:

- **`NuevaContrasenaScreen`** se llega solo después de que un enlace de recuperación por correo ya estableció una sesión de recuperación válida — la identidad ya está probada por haber accedido al correo de la cuenta, así que solo pide la contraseña nueva.
- **`CambiarContrasenaScreen`** se llega con una sesión normal ya iniciada, sin ninguna prueba adicional de que quien tiene el teléfono en la mano sea realmente el dueño de la cuenta (podría ser alguien que encontró el teléfono desbloqueado) — por eso pide la contraseña **actual** además de la nueva, y la usa para reautenticar contra Supabase antes de aceptar el cambio.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** algunos backends exponen un endpoint dedicado tipo "verificar contraseña actual" separado de la reautenticación completa.
- **Nuestro Enfoque:** Supabase Auth no tiene un endpoint así — se reutiliza `iniciarSesionConEmail` (el mismo método que usa `IniciarSesionScreen`) como mecanismo de verificación: si la contraseña actual está mal, ese intento de login falla con `invalid_credentials` y nunca se llega a llamar a `actualizarContrasena`.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `_cambiar()` y `UsuarioNotifier.cambiarContrasena`

```dart
// usuario_provider.dart
Future<void> cambiarContrasena({
  required String contrasenaActual,
  required String nuevaContrasena,
}) async {
  final repo = ref.read(usuarioRepositoryProvider);
  await repo.iniciarSesionConEmail(email: state!.email!, password: contrasenaActual);
  await repo.actualizarContrasena(nuevaContrasena);
}
```

Dos llamadas encadenadas, sin `try/catch` interno — si la primera (`iniciarSesionConEmail`) falla, la segunda nunca se ejecuta, y la excepción sube tal cual hasta la pantalla (mismo criterio que el resto de los métodos de autenticación del proyecto, ver `usuario.repository.md`). `state!.email!` — el email de la cuenta ya activa, nunca se le vuelve a pedir al usuario (a diferencia de `IniciarSesionScreen`, donde sí hace falta porque todavía no hay ninguna sesión).

### 2. Mapeo de errores — `invalid_credentials` con mensaje propio, no el genérico compartido

```dart
final esCredencialInvalida = e is AuthApiException && e.code == 'invalid_credentials';
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(
    esCredencialInvalida ? l10n.errorContrasenaActualIncorrecta : mensajeErrorAutenticacion(l10n, e),
  )),
);
```

`mensajeErrorAutenticacion` (ver `erroresAutenticacion.md`) ya traduce `invalid_credentials` a `errorCredencialesInvalidas` ("Correo o contraseña incorrectos") — pero ese mensaje menciona el correo, que no es un campo de este formulario (el correo ya se conoce, no se vuelve a pedir). Se usa un mensaje propio (`errorContrasenaActualIncorrecta`, "La contraseña actual es incorrecta") solo para ese código puntual; cualquier otro error (sin conexión, error genérico del servidor) sigue cayendo en el helper compartido.

### 3. Aviso de requisitos, siempre visible — `helperText`, no solo el error de validación

```dart
TextFormField(
  controller: _nuevaController,
  decoration: InputDecoration(
    labelText: l10n.campoNuevaContrasena,
    helperText: l10n.avisoRequisitosContrasena,
    helperMaxLines: 2,
  ),
  validator: (valor) => validarContrasena(l10n, valor),
),
```

A diferencia de `RegistroScreen`/`NuevaContrasenaScreen` (donde el requisito de contraseña solo aparece como mensaje de error después de un intento fallido), acá el aviso queda visible todo el tiempo debajo del campo, vía `helperText` — decisión explícita del usuario al pedir esta pantalla. `helperMaxLines: 2` evita que Flutter trunque el texto con `...` si no entra en una sola línea (pasa con pantallas angostas o tamaño de letra "Grande", ver `ajustesScreen.md`, punto 4).

### 4. Logo centrado (2026-08-21, decisión explícita del usuario)

A diferencia del resto de las pantallas de formulario del proyecto (`RegistroScreen`, `NuevaContrasenaScreen`, sin logo, solo el título del `AppBar`), esta pantalla suma `Image.asset('assets/images/logo_patas_al_dia.png', width: 80, height: 80)` centrado arriba del formulario — a pedido explícito del usuario al definir cómo quería esta pantalla, junto con el subtítulo (`cambiarContrasenaSubtitulo`) y el aviso de requisitos del punto 3.

### 5. Al terminar — `pop()` + `SnackBar`, no navegar a otra pantalla

```dart
Navigator.of(context).pop();
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.avisoContrasenaActualizada)));
```

A diferencia de `RegistroScreen`/`NuevaContrasenaScreen` (que navegan hacia adentro de la app, porque antes de esa pantalla no había ninguna sesión "de verdad" todavía), acá el usuario ya estaba usando la app con normalidad — cambiar la contraseña no cambia nada de lo que ve, así que alcanza con volver a `AjustesScreen` y confirmar con un mensaje breve.
