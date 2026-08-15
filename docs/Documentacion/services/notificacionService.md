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

### 3. `programarRecordatorio(AgendaEventoModel evento)`

```dart
final momento = evento.fechaProgramada.subtract(Duration(hours: horasAntes));
if (momento.isBefore(DateTime.now())) return;
```

Si el momento calculado para avisar ya pasó (ej. el evento está a 20 minutos y el recordatorio pedía "1 hora antes"), no se programa nada — el recordatorio ya no tiene sentido. `zonedSchedule` se intenta primero con `AndroidScheduleMode.exactAllowWhileIdle` (precisión exacta, incluso con el dispositivo en reposo); si el sistema lo rechaza (ej. el usuario no otorgó el permiso de alarma exacta), se reintenta con `inexactAllowWhileIdle` como respaldo — el recordatorio igual se programa, solo que sin garantía de precisión al minuto.

### 4. Bug encontrado y corregido (2026-08-14): receptor de alarmas no declarado en el manifiesto

**Síntoma:** el recordatorio se programaba bien (`AlarmManager` mostraba la alarma programada, y sonaba a la hora exacta), pero nunca aparecía la notificación — ni rastro de que se hubiera intentado mostrar.

**Diagnóstico:** el paquete `flutter_local_notifications` necesita que la app declare manualmente, en su propio `AndroidManifest.xml`, los `<receiver>` que el plugin usa para recibir la alarma del sistema (`ScheduledNotificationReceiver`) y para reprogramar recordatorios tras un reinicio del dispositivo (`ScheduledNotificationBootReceiver`) — el `AndroidManifest.xml` que trae el propio paquete no los incluye. Sin esa declaración, Android reconoce la alarma programada (es un mecanismo del sistema operativo, independiente de la app) pero no tiene a quién entregarle el aviso cuando se dispara: el broadcast se pierde en silencio, sin ninguna excepción ni error visible en los logs.

Se confirmó comparando `adb shell dumpsys package com.example.patas_al_dia | grep Receiver` antes y después del arreglo: antes, la app no tenía ningún receptor de este paquete registrado; después, sí.

**Solución:** se agregaron ambos `<receiver>` a `android/app/src/main/AndroidManifest.xml`, más el permiso `RECEIVE_BOOT_COMPLETED` que pide `ScheduledNotificationBootReceiver`.
