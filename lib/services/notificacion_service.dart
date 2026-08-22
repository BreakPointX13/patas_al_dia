import 'package:flutter/material.dart' show Color;
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

  // Ícono monocromático (blanco sobre transparente, como exige Android para
  // la barra de estado) + color de marca como tinte — ver
  // assets/images/icono_notificacion_patas.svg para el diseño original.
  static const _iconoNotificacion = 'ic_stat_patas';
  static const _colorNotificacion = Color(0xFFE0812F);

  // Todas las horas-antes posibles que ofrece el formulario — se usa acá
  // para poder cancelar cualquier recordatorio que un evento haya tenido
  // alguna vez, sin necesidad de saber cuáles tenía programados antes.
  static const horasPosibles = [24, 12, 6, 1];

  // La app está pensada inicialmente para Chile (ver decisiones_arquitectura.md),
  // así que se fija esa zona horaria en vez de sumar un paquete aparte solo
  // para detectar la zona horaria real del dispositivo.
  static const _zonaHoraria = 'America/Santiago';

  // Prepara el plugin y pide permisos de notificación y alarma exacta.
  Future<void> inicializar() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_zonaHoraria));

    const configuracion = InitializationSettings(
      android: AndroidInitializationSettings(_iconoNotificacion),
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

  // flutter_local_notifications necesita un id numérico por notificación.
  // Como ahora un mismo evento puede tener varios recordatorios (uno por
  // cada "horas antes" elegido), el id combina el evento y esa cantidad de
  // horas, para que cada recordatorio del mismo evento tenga su propio id.
  int _idParaRecordatorio(String eventoId, int horasAntes) =>
      ('$eventoId-$horasAntes').hashCode & 0x7fffffff;

  String _tituloRecordatorio(int horasAntes) {
    switch (horasAntes) {
      case 24:
        return '🐾 Mañana tienes una cita';
      case 12:
        return '🐾 En 12 horas tienes una cita';
      case 6:
        return '🐾 En 6 horas tienes una cita';
      case 1:
        return '🐾 En 1 hora tienes una cita';
      default:
        return '🐾 Tienes una cita próximamente';
    }
  }

  String _cuerpoRecordatorio(AgendaEventoModel evento) {
    return evento.tipoEvento == null
        ? evento.titulo
        : '${evento.titulo}, ${evento.tipoEvento}';
  }

  // Programa un recordatorio por cada "horas antes" elegido en el evento.
  Future<void> programarRecordatorio(AgendaEventoModel evento) async {
    for (final horasAntes in evento.recordatorioHorasAntes) {
      await _programarUnRecordatorio(evento, horasAntes);
    }
  }

  Future<void> _programarUnRecordatorio(
    AgendaEventoModel evento,
    int horasAntes,
  ) async {
    final momento = evento.fechaProgramada.subtract(
      Duration(hours: horasAntes),
    );
    if (momento.isBefore(DateTime.now())) {
      return;
    }

    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        _canalId,
        _canalNombre,
        icon: _iconoNotificacion,
        color: _colorNotificacion,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final fechaProgramada = tz.TZDateTime.from(momento, tz.local);
    final id = _idParaRecordatorio(evento.id, horasAntes);
    final titulo = _tituloRecordatorio(horasAntes);
    final cuerpo = _cuerpoRecordatorio(evento);

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: titulo,
        body: cuerpo,
        scheduledDate: fechaProgramada,
        notificationDetails: detalles,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Si el sistema niega la alarma exacta (ej. permiso no otorgado),
      // se agenda de todos modos, solo que sin precisión exacta.
      await _plugin.zonedSchedule(
        id: id,
        title: titulo,
        body: cuerpo,
        scheduledDate: fechaProgramada,
        notificationDetails: detalles,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  // Cancela todos los recordatorios posibles de un evento, tenga o no cada uno.
  Future<void> cancelarRecordatorio(String eventoId) async {
    for (final horasAntes in horasPosibles) {
      await _plugin.cancel(id: _idParaRecordatorio(eventoId, horasAntes));
    }
  }
}
