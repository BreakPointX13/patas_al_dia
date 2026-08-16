# Nota de Obsidian: `NotificacionService`

## 📁 Ubicación en el Proyecto

`lib/services/notificacion_service.dart`

Primer archivo de la carpeta `services/`, hermana de `data/`, `presentation/` y `providers/` — se creó porque este código (notificaciones locales) no encaja en ninguna de las capas existentes: no es acceso a datos, ni UI, ni estado de Riverpod, es un servicio de plataforma. Creado el 2026-08-14.

## 🎯 Propósito del Archivo

Singleton (mismo patrón que `DatabaseHelper`) que administra las notificaciones locales de los recordatorios de agenda, usando el paquete `flutter_local_notifications`.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

`NotificacionService.instance.inicializar()` se llama una sola vez, en `main()`, antes de `runApp()` — necesita estar listo antes de que cualquier pantalla pueda programar un recordatorio. `programarRecordatorio(AgendaEventoModel evento)` y `cancelarRecordatorio(String eventoId)` los llama `FormularioAgendaEventoScreen` al guardar un evento (siempre cancela primero y reprograma después, para no dejar recordatorios viejos huérfanos al editar).

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** Muchas apps calculan la zona horaria real del dispositivo con un paquete aparte (`flutter_timezone`/`flutter_native_timezone`) para programar notificaciones con precisión en cualquier país.
- **Nuestro Enfoque:** Se fija `America/Santiago` como zona horaria fija en vez de detectarla — la app está pensada inicialmente para Chile (ver `decisiones_arquitectura.md`), así que no se justifica una dependencia nueva solo para esto. Limitación conocida: un usuario viajando fuera de esa zona horaria vería sus recordatorios desfasados. Aceptable por ahora; se reconsideraría si la app se expande a otros países.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `inicializar()`

Tres pasos: inicializa la base de datos de zonas horarias del paquete `timezone` (`tz_data.initializeTimeZones()`), fija la zona local (`tz.setLocalLocation(...)`), e inicializa el plugin nativo con el ícono por defecto (`@mipmap/ic_launcher`, el mismo que usa el launcher de la app). Al final pide los permisos de notificaciones y de alarma exacta — en Android 13+ y 12+ respectivamente, estos no vienen concedidos por defecto.

### 2. `_idParaEvento(String eventoId)`

```dart
int _idParaEvento(String eventoId) => eventoId.hashCode & 0x7fffffff;
```

El plugin necesita un id numérico (`int`) por notificación, pero los eventos de agenda usan UUID (`String`). Se deriva un `int` a partir del hash del UUID; el `& 0x7fffffff` descarta el bit de signo para evitar un `int` negativo. No es 100% libre de colisiones (dos UUIDs distintos podrían, en teoría, generar el mismo id), pero es el mismo id calculado siempre a partir del mismo `eventoId`, así que `cancelarRecordatorio` puede encontrar y cancelar la notificación correcta sin tener que guardar el id numérico en ningún lado.

### 3. `programarRecordatorio(AgendaEventoModel evento)` — un recordatorio por cada "horas antes" (2026-08-16)

Desde que `recordatorioHorasAntes` pasó a ser una lista (un evento puede avisar 1 día antes *y* 1 hora antes, por ejemplo), este método recorre la lista y programa una notificación por cada valor (`_programarUnRecordatorio`), cada una con su propio id (`_idParaRecordatorio`, que combina el id del evento *y* la cantidad de horas — antes el id solo dependía del evento, porque solo podía haber un recordatorio). `cancelarRecordatorio` ya no sabe de antemano cuáles horas tenía programadas ese evento, así que cancela los cuatro ids posibles (`horasPosibles = [24, 12, 6, 1]`) — cancelar un id que nunca se programó no hace nada, así que es seguro cancelar de más.

### 3c. `_programarUnRecordatorio` (antes `programarRecordatorio`)

```dart
final momento = evento.fechaProgramada.subtract(Duration(hours: horasAntes));
if (momento.isBefore(DateTime.now())) return;
```

Si el momento calculado para avisar ya pasó (ej. el evento está a 20 minutos y el recordatorio pedía "1 hora antes"), no se programa nada — el recordatorio ya no tiene sentido. `zonedSchedule` se intenta primero con `AndroidScheduleMode.exactAllowWhileIdle` (precisión exacta, incluso con el dispositivo en reposo); si el sistema lo rechaza (ej. el usuario no otorgó el permiso de alarma exacta), se reintenta con `inexactAllowWhileIdle` como respaldo — el recordatorio igual se programa, solo que sin garantía de precisión al minuto.

### 2b. Ícono y color de marca (2026-08-16)

`AndroidInitializationSettings(_iconoNotificacion)` reemplaza al ícono por defecto que se usaba antes (`@mipmap/ic_launcher`, el mismo del launcher). Android exige que el ícono de la barra de estado sea monocromático — blanco puro sobre transparente, sin colores propios — el sistema lo tiñe él mismo con el color que se le pase (`AndroidNotificationDetails.color`, acá `_colorNotificacion`). El diseño original (SVG editable) vive en `assets/images/icono_notificacion_patas.svg`; los `.png` por densidad están en `android/app/src/main/res/drawable-{m,h,x,xx,xxx}hdpi/ic_stat_patas.png` — son recursos nativos de Android, no `assets` de Flutter, por eso no aparecen en `pubspec.yaml`.

### 3b. `_tituloRecordatorio` / `_cuerpoRecordatorio` — texto de la notificación (2026-08-16)

El título grande de la notificación depende de qué opción de recordatorio se eligió — "🐾 Mañana tienes una cita" para 24 horas antes, "🐾 En 12 horas tienes una cita" / "🐾 En 1 hora tienes una cita" para las otras dos. El texto chico (cuerpo) es `"$titulo, $tipoEvento"` (ej. "Control anual, Control"), o solo el título si el evento no tiene tipo cargado. Decisión explícita del usuario sobre cómo debía verse la notificación — antes decía siempre lo mismo ("Recordatorio de tu mascota"), sin información del evento en sí.

### 4. Bug encontrado y corregido (2026-08-14): receptor de alarmas no declarado en el manifiesto

**Síntoma:** el recordatorio se programaba bien (`AlarmManager` mostraba la alarma programada, y sonaba a la hora exacta), pero nunca aparecía la notificación — ni rastro de que se hubiera intentado mostrar.

**Diagnóstico:** el paquete `flutter_local_notifications` necesita que la app declare manualmente, en su propio `AndroidManifest.xml`, los `<receiver>` que el plugin usa para recibir la alarma del sistema (`ScheduledNotificationReceiver`) y para reprogramar recordatorios tras un reinicio del dispositivo (`ScheduledNotificationBootReceiver`) — el `AndroidManifest.xml` que trae el propio paquete no los incluye. Sin esa declaración, Android reconoce la alarma programada (es un mecanismo del sistema operativo, independiente de la app) pero no tiene a quién entregarle el aviso cuando se dispara: el broadcast se pierde en silencio, sin ninguna excepción ni error visible en los logs.

Se confirmó comparando `adb shell dumpsys package com.example.patas_al_dia | grep Receiver` antes y después del arreglo: antes, la app no tenía ningún receptor de este paquete registrado; después, sí.

**Solución:** se agregaron ambos `<receiver>` a `android/app/src/main/AndroidManifest.xml`, más el permiso `RECEIVE_BOOT_COMPLETED` que pide `ScheduledNotificationBootReceiver`.
