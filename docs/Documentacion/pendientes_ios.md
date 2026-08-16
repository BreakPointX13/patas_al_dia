# Pendientes y temas a revisar en iOS

Este documento junta todo lo que quedó sin confirmar o sin resolver específicamente para iOS — no porque se haya decidido ignorarlo, sino porque el lanzamiento en App Store está postergado por ahora (cuota anual de desarrollador de Apple, US$100, no viable económicamente por el momento — ver la entrada "Lanzamiento y monetización" en `decisiones_arquitectura.md`) y, en consecuencia, nada de esto se probó todavía en un dispositivo o simulador real.

**Por qué existe este documento aparte:** para no perder de vista estos temas ni mezclarlos con la bitácora de decisiones ya tomadas (`decisiones_arquitectura.md`) — acá van cosas pendientes de confirmar o construir, no decisiones cerradas.

---

## 1. Posible pérdida de fotos de mascotas (`image_picker`)

**Detectado:** revisión de código del 2026-08-06.

**El problema:** `_elegirFoto()` en `FormularioMascotaScreen` guarda `imagen.path` (la ruta que devuelve `image_picker`) directo como `fotoUrl`. En iOS, esa ruta a veces apunta a un archivo temporal que el sistema operativo puede limpiar solo, por lo que la foto podría "desaparecer" con el tiempo — a diferencia de Android, donde la ruta suele ser más estable.

**Cómo confirmarlo:** hace falta un dispositivo o simulador iOS real para reproducirlo — no se pudo verificar todavía.

**Solución probable si se confirma:** copiar el archivo a un directorio persistente de la app usando el paquete `path_provider` (ya varias veces considerado en el proyecto, todavía no agregado) en vez de guardar la ruta temporal tal cual. Esto probablemente convenga resolverlo junto con el punto 2 (exclusión de backups), ya que ambos tocan el mismo código de manejo de archivos.

## 2. Exclusión de backups de iCloud/iTunes para la base de datos local

**Contexto:** en Android ya se deshabilitó `allowBackup` (ver la entrada "deshabilitar allowBackup" en `decisiones_arquitectura.md`, 2026-08-14) para que la base SQLite no se pueda extraer vía `adb backup`. En iOS no existe un flag global equivalente — hay que marcar archivos puntuales con `NSURLIsExcludedFromBackupKey` para excluirlos de los backups de iCloud/iTunes.

**Por qué no se hizo todavía:** requiere tocar código nativo específico de iOS (o un paquete como `path_provider`, que sí lo soporta), y no se pudo probar sin un dispositivo real. Queda pendiente para cuando se retome el trabajo de iOS.

## 3. Nada del proyecto se probó en iOS todavía

Todo lo construido hasta ahora (Agenda, notificaciones locales con `flutter_local_notifications`, selección de archivos con `file_picker`, apertura de archivos con `open_filex`, calendario con `table_calendar`) se escribió con soporte multiplataforma (regla #1 de `CLAUDE.md`), pero **cero probado en iOS real** — todas las pruebas de esta etapa del proyecto fueron en un Samsung Android físico. Antes de siquiera evaluar el lanzamiento en App Store, hace falta una pasada completa de pruebas en iOS (simulador como mínimo, dispositivo real idealmente) para encontrar lo que seguro no se ve desde acá.
