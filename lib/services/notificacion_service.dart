import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:patas_al_dia/data/models/agenda_evento_model.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Singleton que administra las notificaciones locales de los recordatorios
/// de la agenda, siguiendo el mismo patrón que DatabaseHelper.
class NotificacionService {
  NotificacionService._internal();
  static final NotificacionService instance = NotificacionService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _canalId = 'agenda_recordatorios';
  static const _canalNombre = 'Recordatorios de agenda';

  // La app está pensada inicialmente para Chile (ver decisiones_arquitectura.md),
  // así que se fija esa zona horaria en vez de sumar un paquete aparte solo
  // para detectar la zona horaria real del dispositivo.
  static const _zonaHoraria = 'America/Santiago';

  Future<void> inicializar() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_zonaHoraria));

    const configuracion = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: configuracion);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  // flutter_local_notifications necesita un id numérico por notificación;
  // se deriva del id (UUID) del evento para no tener que guardar uno aparte.
  int _idParaEvento(String eventoId) => eventoId.hashCode & 0x7fffffff;

  Future<void> programarRecordatorio(AgendaEventoModel evento) async {
    final horasAntes = evento.recordatorioHorasAntes;
    if (horasAntes == null) {
      return;
    }

    final momento = evento.fechaProgramada.subtract(
      Duration(hours: horasAntes),
    );
    if (momento.isBefore(DateTime.now())) {
      return;
    }

    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(_canalId, _canalNombre),
      iOS: DarwinNotificationDetails(),
    );
    final fechaProgramada = tz.TZDateTime.from(momento, tz.local);

    try {
      await _plugin.zonedSchedule(
        id: _idParaEvento(evento.id),
        title: evento.titulo,
        body: 'Recordatorio de tu mascota',
        scheduledDate: fechaProgramada,
        notificationDetails: detalles,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Si el sistema niega la alarma exacta (ej. permiso no otorgado),
      // se agenda de todos modos, solo que sin precisión exacta.
      await _plugin.zonedSchedule(
        id: _idParaEvento(evento.id),
        title: evento.titulo,
        body: 'Recordatorio de tu mascota',
        scheduledDate: fechaProgramada,
        notificationDetails: detalles,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelarRecordatorio(String eventoId) async {
    await _plugin.cancel(id: _idParaEvento(eventoId));
  }
}
