# Nota de Obsidian: `ReportarBugService`

## 📁 Ubicación en el Proyecto

`lib/services/reportar_bug_service.dart`

Usado por `ReportarBugScreen` (ver `reportarBugScreen.md`).

## 🎯 Propósito del Archivo

Envuelve la llamada a la Edge Function `reportar-bug` (ver `reportarBugFunction.md`) — un único método, `enviarReporte`, sin estado propio.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Servicio, no repository — no hay ninguna tabla ni modelo de datos detrás de un reporte de bug (no se guarda nada, ni local ni en Supabase, el reporte *es* el correo). Mismo criterio que `NotificacionService`/`AlmacenamientoLocalService`: una clase chica para una responsabilidad puntual que no encaja en la capa de datos. Aun así, sigue la misma convención del resto del proyecto de no llamar a `Supabase.instance.client` directo desde una pantalla — las pantallas hablan con repositories o servicios, nunca con Supabase en persona.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `enviarReporte({required descripcion, imagenBase64, imagenNombre})`

```dart
Future<void> enviarReporte({
  required String descripcion,
  String? imagenBase64,
  String? imagenNombre,
}) async {
  await Supabase.instance.client.functions.invoke(
    'reportar-bug',
    body: {
      'descripcion': descripcion,
      'imagenBase64': ?imagenBase64,
      'imagenNombre': ?imagenNombre,
    },
  );
}
```

- **`'imagenBase64': ?imagenBase64`** — elementos null-aware de mapa (Dart 3.11+, `use_null_aware_elements`): la clave `'imagenBase64'` solo se incluye en el mapa si `imagenBase64` no es `null`. Evita mandar `imagenBase64: null` explícito en el body cuando no hay imagen — equivalente a `if (imagenBase64 != null) 'imagenBase64': imagenBase64`, pero es la forma que sugiere el linter del proyecto para este caso.
- **Sin `try/catch` acá** — mismo criterio que `UsuarioRepository.eliminarCuentaSupabase()` (ver `usuario.repository.md`): la excepción se deja propagar tal cual hasta quien llama (`ReportarBugScreen`), que decide qué mensaje mostrar.
- **No requiere sesión activa** — `functions.invoke` adjunta el JWT de la sesión si existe, pero la Edge Function no lo exige (ver `reportarBugFunction.md`, punto 1); un usuario invitado también puede llamar este método sin que falle.
