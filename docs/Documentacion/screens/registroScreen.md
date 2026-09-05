# Nota de Obsidian: `RegistroScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/registro_screen.dart`

Dos puntos de entrada: `IniciarSesionScreen` (link "¿No tenés cuenta? Registrate", flujo desde `LoginScreen`) y `AjustesScreen` ("Cuenta", solo para invitados ya usando la app — ver `ajustesScreen.md`, punto 7).

## 🎯 Propósito del Archivo

Formulario de registro (email + contraseña + confirmar) contra Supabase Auth. Parte de Login real (2026-08-19, ver `decisiones_arquitectura.md`). Si ya había un invitado con datos locales, lo convierte en registrado conservándolos; si no, crea un usuario nuevo desde cero.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

`ConsumerStatefulWidget` con `Form`/`GlobalKey<FormState>`, mismo patrón que `FormularioMascotaScreen`/`FormularioReporteMascotaExtraviadaScreen`: validación de campos vía `TextFormField.validator`, estado `_guardando` para deshabilitar el botón mientras la operación async está en curso.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `entrarComoApp` — el mismo formulario sirve para dos flujos distintos

```dart
class RegistroScreen extends ConsumerStatefulWidget {
  final bool entrarComoApp; // true por defecto
  const RegistroScreen({super.key, this.entrarComoApp = true});
}
```

- **`entrarComoApp: true`** (default, desde `LoginScreen` → `IniciarSesionScreen`): no hay ningún shell de la app montado todavía — al registrarse con éxito, navega adentro con `pushAndRemoveUntil` hacia `NavegacionPrincipalScreen` (vacía todo el stack, mismo criterio que `_continuarComoInvitado` en `LoginScreen`).
- **`entrarComoApp: false`** (desde `AjustesScreen`, invitado ya usando la app): `NavegacionPrincipalScreen` ya está montado por debajo — al registrarse con éxito, alcanza con `Navigator.of(context).pop()` para volver a Ajustes. Navegar "hacia adentro" en este caso duplicaría el shell de la app.

El link "¿Ya tenés cuenta? Iniciá sesión" (al fondo del formulario) también está condicionado a `entrarComoApp` — solo tiene sentido en el flujo de `LoginScreen`, no cuando un invitado ya dentro de la app decide registrarse.

### 2. `_registrar()` — validación, error handling y el aviso de confirmación

```dart
await ref.read(usuarioProvider.notifier).registrarUsuario(email: ..., password: ...);
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.avisoRevisaCorreo)));
```

Con "Confirm email" activado en el proyecto de Supabase (decisión existente del usuario, no de esta pantalla), `signUp()` no deja una sesión activa hasta que el usuario confirma por correo — pero sí devuelve el `auth.uid()` definitivo de inmediato, así que la conversión/creación local (`registrarUsuario`, ver `usuarioNotifier.md`, punto 9) ocurre igual, sin esperar la confirmación. La app queda usable de inmediato (local-first, igual que un invitado) — la confirmación por correo solo importa más adelante, para poder iniciar sesión en otro dispositivo.

**Manejo de errores**, mismo patrón que `formulario_reporte_mascota_extraviada_screen.dart` (`debugPrint` marcado `// TEMPORAL` + mensaje traducido según el error real):

```dart
} on AuthException catch (e) {
  debugPrint('DEBUG registrarUsuario AuthException: code=${...} message=${e.message}');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensajeErrorAutenticacion(l10n, e))));
}
```

`mensajeErrorAutenticacion` (ver `errorAutenticacion.md`) traduce los códigos conocidos de Supabase Auth (contraseña débil, correo ya registrado, etc.) a un mensaje ya localizado — compartido con `IniciarSesionScreen`, no duplicado.

### 3. Validadores de los tres campos

- **Email:** obligatorio + regex simple (`^[^@\s]+@[^@\s]+\.[^@\s]+$`) — sin restringir a ningún dominio o país, mismo criterio que el resto de los campos de la app (ver memoria de sesión "Validación de campos: no cerrar puertas a extranjeros").
- **Contraseña:** `validarContrasena` (ver `validadorContrasena.md`) — mínimo 8 caracteres, una mayúscula y un número (2026-08-20, reemplaza al "mínimo 6 caracteres" original). Configurado también del lado de Supabase, no solo acá. **`helperText: l10n.ayudaRequisitosContrasena`** (2026-09-05) muestra estos requisitos siempre, bajo el campo — antes solo aparecían como mensaje de error después de fallar la validación; un tester señaló que, para cumplir con la regla 2 de `CLAUDE.md` (facilidad de uso), convenía mostrarlos de entrada.
- **Confirmar contraseña:** debe ser igual a `_passwordController.text`.

### 4. Bug arreglado (2026-09-05): "correo ya registrado" mostraba el mensaje genérico

El `throw const AuthException('...', code: 'user_already_exists')` del punto 2 (ver `usuarioNotifier.md`, punto 9) siempre llegaba acá con su código intacto, pero `mensajeErrorAutenticacion` (ver `erroresAutenticacion.md`) lo descartaba por un chequeo de tipo de más (`e is AuthApiException`) — esa excepción es un `AuthException` simple, no un `AuthApiException`. El resultado visible en esta pantalla: registrarse con un correo ya usado mostraba `l10n.errorAutenticacionGenerico` ("Hubo un error...") en vez de `l10n.errorEmailYaRegistrado`. El arreglo fue en `erroresAutenticacion.md`, no en este archivo — `RegistroScreen` ya llamaba a `mensajeErrorAutenticacion` correctamente.
