# Nota de Obsidian: `validarContrasena`

## 📁 Ubicación en el Proyecto

`lib/presentation/utils/validador_contrasena.dart`

Usado por `RegistroScreen` y `NuevaContrasenaScreen` (ver sus respectivos `.md`) — `IniciarSesionScreen` no lo usa (ver `iniciarSesionScreen.md`, punto 2, sobre por qué no hace falta validar formato ahí).

## 🎯 Propósito del Archivo

Requisitos de contraseña (2026-08-20, decisión del usuario, ver `decisiones_arquitectura.md`): mínimo 8 caracteres, una mayúscula y un número — reemplaza el validador anterior ("mínimo 6 caracteres", uno por pantalla).

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `validarContrasena(AppLocalizations l10n, String? valor)`

```dart
String? validarContrasena(AppLocalizations l10n, String? valor) {
  if (valor == null || valor.isEmpty) {
    return l10n.errorContrasenaObligatoria;
  }
  final cumpleRequisitos = valor.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(valor) &&
      RegExp(r'[0-9]').hasMatch(valor);
  if (!cumpleRequisitos) {
    return l10n.errorContrasenaCorta;
  }
  return null;
}
```

Función pura (sin `BuildContext`, sin estado) — se usa directo como `TextFormField.validator` (`validator: (valor) => validarContrasena(l10n, valor)`), mismo patrón que `mensajeErrorAutenticacion` (ver `errorAutenticacion.md`).

**Extraída de las dos pantallas, no duplicada:** antes cada pantalla (`RegistroScreen`, `NuevaContrasenaScreen`) tenía su propio validador de una sola línea ("mínimo 6 caracteres") — con tres reglas a la vez, duplicar esa lógica en dos lugares hubiera violado el mismo criterio de "sin código repetido" que ya sigue el resto del proyecto.

**Sin símbolo obligatorio, a propósito.** El usuario definió los requisitos él mismo (mínimo 8 + mayúscula + número), explícitamente sin exigir un símbolo — el razonamiento: el largo mínimo aporta más seguridad real que la complejidad de caracteres, y un símbolo obligatorio es la regla que más fricción genera para el usuario a cambio de la menor ganancia (coherente con la regla 2 de `CLAUDE.md`, UX como prioridad).

**Un solo mensaje de error para las tres reglas** (`errorContrasenaCorta`, con el texto completo "al menos 8 caracteres, una mayúscula y un número") en vez de un mensaje distinto por regla incumplida — más simple de mantener, y evita que el usuario tenga que corregir de a un requisito por vez, re-enviando el formulario para descubrir el siguiente.

### 2. Reforzado también del lado de Supabase (2026-08-20)

Mismo criterio que otras validaciones del proyecto que también viven en el servidor, no solo en la app (ver el `check` constraint de ubicación obligatoria en `mascotas_extraviadas`, o el trigger de límite de reportes activos) — una validación solo del lado del cliente se puede saltar llamando a la API directo. El usuario configuró el mismo mínimo en el panel de Supabase (Authentication → Sign In / Providers → Email → "Minimum password length" = 8, "Password Requirements" = dígitos + mayúscula/minúscula), así que Supabase Auth también rechaza una contraseña que no cumpla, incluso si algo se saltara el validador de la app.
