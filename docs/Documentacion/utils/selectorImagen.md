# Nota de Obsidian: `elegirImagenConPermiso`

## 📁 Ubicación en el Proyecto

`lib/presentation/utils/selector_imagen.dart`

Usado por `FormularioMascotaScreen`, `FormularioDocumentoScreen`, `FormularioAgendaEventoScreen`, `FormularioReporteMascotaExtraviadaScreen` y `ReportarBugScreen` — cualquier pantalla que llame a `ImagePicker.pickImage`.

## 🎯 Propósito del Archivo

Envuelve `ImagePicker.pickImage` pidiendo el permiso de cámara de forma explícita antes de abrir el selector (2026-08-25). Antes de esto, un tester tocaba "Tomar foto" y no pasaba nada, sin ningún mensaje — el permiso ya había quedado denegado para siempre (Android no vuelve a mostrar su propio diálogo en ese estado), y la app no tenía ninguna forma de detectarlo ni de explicarle al usuario qué hacer.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Reemplaza la llamada directa `_picker.pickImage(...)` en los 7 puntos del proyecto donde se abre la cámara o la galería — mismo `ImagePicker`, mismos parámetros (`source`, `maxWidth`, `imageQuality`), solo con el permiso ya resuelto antes de llegar al picker.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `elegirImagenConPermiso(BuildContext, ImagePicker, {required ImageSource source, double? maxWidth, int? imageQuality})`

Cámara y galería se tratan distinto a propósito:

- **Cámara:** siempre pide el permiso (`Permission.camera`) antes de abrir el picker. Si Android ya lo denegó para siempre (`isPermanentlyDenied`), no vuelve a intentar pedirlo — en ese estado el sistema nunca muestra su diálogo, así que en vez de fallar en silencio se muestra un diálogo propio con un botón "Abrir ajustes" (`openAppSettings()`, de `permission_handler`).
- **Galería:** **no** se gestiona con `permission_handler`. En Android 13+, el selector de fotos del sistema no pide ningún permiso — pedirlo igual (aunque fuera solo para revisar el estado) bloquearía sin necesidad a cualquiera que lo negara, aun cuando el picker hubiera funcionado bien sin él. Acá solo se atrapa la `PlatformException` que tira `pickImage` si el selector "clásico" (Android 12 o anterior, que sí necesita `READ_EXTERNAL_STORAGE`/`READ_MEDIA_IMAGES` — ver `AndroidManifest.xml`) falla igual.

### 2. Por qué `permission_handler` y no otra cosa

`image_picker` ya pide sus propios permisos por dentro (incluida la cámara) — el problema real no era la falta de un pedido, sino la falta de una forma de **saber si ya quedó denegado para siempre** y de **abrir Ajustes** para que el usuario lo arregle a mano. Ninguna de esas dos cosas la resuelve `image_picker` por sí solo, así que se sumó `permission_handler` (única excepción a "dependencias mínimas" en este cambio — ver regla 6 de `CLAUDE.md`) puntualmente para eso.

### 3. iOS

`permission_handler` necesita macros de preprocesador activadas por permiso en el `Podfile` de iOS (`PERMISSION_CAMERA=1`) — este proyecto todavía no tiene un `ios/Podfile` generado (nunca se corrió `pod install`), así que queda pendiente para cuando se retome trabajo real de iOS. Ver `pendientes_ios.md`, punto 3.
