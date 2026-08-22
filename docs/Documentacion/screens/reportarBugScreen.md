# Nota de Obsidian: `ReportarBugScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/reportar_bug_screen.dart`

Se accede desde `AjustesScreen`, sección "Ayuda" (ver `ajustesScreen.md`, punto 12).

## 🎯 Propósito del Archivo

Formulario para reportar un bug: descripción obligatoria + foto/captura opcional, enviado al correo del desarrollador vía `ReportarBugService` (ver `reportarBugService.md`). Pedido pendiente desde el 2026-08-18, implementado ahora que Sync (y con él, toda la infraestructura de Supabase) ya está en pie — ver `decisiones_arquitectura.md`.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Formulario chico, mismo esqueleto que el resto de los formularios de la app (`Form` + `GlobalKey<FormState>`, `_enviando`/`ElevatedButton` con `CircularProgressIndicator`, selector de imagen con hoja inferior cámara/galería) — no introduce ningún patrón nuevo, reutiliza los ya establecidos en `FormularioDocumentoScreen`/`FormularioReporteMascotaExtraviadaScreen`.

**Sin requerir sesión ni datos de la mascota** — a diferencia de casi todos los demás formularios de la app (que siempre cuelgan de una mascota o de una cuenta), este es completamente independiente: ni pide login, ni pasa por ningún provider de datos. Coherente con la regla 2 de `CLAUDE.md`.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `_elegirImagen()` — mismo patrón que `FormularioDocumentoScreen`, sin PDF

Hoja inferior con "Tomar foto"/"Elegir de galería" (reutiliza `l10n.tomarFoto`/`l10n.elegirImagenGaleria`, ya existentes) — sin la tercera opción de PDF que sí tiene `FormularioDocumentoScreen`, porque acá la imagen es siempre una captura de pantalla o una foto del problema, nunca un documento. Comprimida con `maxWidth: 1600, imageQuality: 75` — mismo preset que las demás fotos que viajan a la nube (foto de mascota, foto de reporte de mascota perdida), ver `decisiones_arquitectura.md`, entrada de Sync, punto 4.

### 2. `_enviar()` — codificación a base64 recién al momento de enviar

```dart
if (_imagenPath != null) {
  final bytes = await File(_imagenPath!).readAsBytes();
  imagenBase64 = base64Encode(bytes);
  imagenNombre = 'captura.${_imagenPath!.split('.').last}';
}
```

A diferencia de `FormularioMascotaScreen`/`FormularioDocumentoScreen` (que copian el archivo elegido a un directorio persistente apenas se guarda, para que Sync lo suba más adelante), acá no hace falta ningún paso intermedio — el archivo elegido por `image_picker` ya vive en una ruta de caché, y como se lee y se descarta en el mismo momento (nunca se vuelve a necesitar después de armar el `base64`), no hay ningún riesgo de que iOS limpie esa ruta de caché antes de tiempo (ver `pendientes_ios.md`, punto 1 — ese riesgo aplica a archivos que necesitan sobrevivir hasta una sincronización futura, no a uno que se consume al instante).

- **No hay ningún registro local del reporte** — a diferencia de todo lo demás en la app (local-first, todo pasa primero por SQLite), un reporte de bug no se guarda en ningún lado del dispositivo ni de Supabase: es un correo, y una vez enviado, se termina. Decisión implícita en el pedido original del usuario ("que llegue al correo"), no algo que haya hecho falta discutir aparte.
- **Manejo de errores simple:** `try/catch` con `debugPrint` (mismo patrón `// TEMPORAL` que el resto del proyecto con Supabase) y `l10n.errorAutenticacionGenerico` como mensaje genérico si falla — reutilizado a pesar del nombre (pensado originalmente para errores de autenticación), porque el texto en sí ("No se pudo completar la operación. Intenta de nuevo.") es lo bastante genérico como para servir acá también, sin necesitar una clave de traducción nueva solo para este caso.

### 3. Sin persistencia si se cierra la pantalla a mitad de camino

Si el usuario escribe una descripción, elige una foto, y sale de la pantalla sin tocar "Enviar", todo se pierde — no hay ningún borrador guardado. Comportamiento aceptado por simplicidad: es un formulario chico y de un solo uso, no vale la pena la complejidad de un borrador persistente para este caso.
