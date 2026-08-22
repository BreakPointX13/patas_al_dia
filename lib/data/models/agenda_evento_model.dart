// Un evento de la agenda veterinaria (vacuna, control, etc.) de una mascota.
class AgendaEventoModel {
  final String id;
  final String mascotaId;
  final String? tipoEvento;
  final String? tipoEventoPersonalizado;
  final String titulo;
  final String? observaciones;
  final DateTime fechaProgramada;
  final DateTime? fechaRealizada;
  // Horas antes del evento en que avisar (ej: [24, 1]); se guarda como texto separado por comas.
  final List<int> recordatorioHorasAntes;
  // Sync (2026-08-20) — ver mascota_model.dart para el porqué de estos tres.
  final DateTime? actualizadoEn;
  final bool eliminado;
  final DateTime? eliminadoEn;

  AgendaEventoModel({
    required this.id,
    required this.mascotaId,
    this.tipoEvento,
    this.tipoEventoPersonalizado,
    required this.titulo,
    this.observaciones,
    required this.fechaProgramada,
    this.fechaRealizada,
    this.recordatorioHorasAntes = const [],
    this.actualizadoEn,
    this.eliminado = false,
    this.eliminadoEn,
  });

  // Convierte un Mapa (fila de la BDD) a un objeto AgendaEventoModel
  factory AgendaEventoModel.fromMap(Map<String, dynamic> map) {
    return AgendaEventoModel(
      id: map['id'] as String,
      mascotaId: map['mascota_id'] as String,
      tipoEvento: map['tipo_evento'] != null
          ? map['tipo_evento'] as String
          : null,
      tipoEventoPersonalizado: map['tipo_evento_personalizado'] != null
          ? map['tipo_evento_personalizado'] as String
          : null,
      titulo: map['titulo'] as String,
      observaciones: map['observaciones'] != null
          ? map['observaciones'] as String
          : null,
      fechaProgramada: DateTime.parse(map['fecha_programada'] as String),
      fechaRealizada: map['fecha_realizada'] != null
          ? DateTime.parse(map['fecha_realizada'] as String)
          : null,
      recordatorioHorasAntes:
          map['recordatorio_horas_antes'] == null ||
              (map['recordatorio_horas_antes'] as String).isEmpty
          ? const []
          : (map['recordatorio_horas_antes'] as String)
                .split(',')
                .map(int.parse)
                .toList(),
      actualizadoEn: map['actualizado_en'] != null
          ? DateTime.parse(map['actualizado_en'] as String)
          : null,
      eliminado: map['eliminado'] == 1 || map['eliminado'] == true,
      eliminadoEn: map['eliminado_en'] != null
          ? DateTime.parse(map['eliminado_en'] as String)
          : null,
    );
  }

  // Convierte este objeto a un Mapa listo para insertarse en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mascota_id': mascotaId,
      'tipo_evento': tipoEvento,
      'tipo_evento_personalizado': tipoEventoPersonalizado,
      'titulo': titulo,
      'observaciones': observaciones,
      'fecha_programada': fechaProgramada.toIso8601String(),
      'fecha_realizada': fechaRealizada?.toIso8601String(),
      'recordatorio_horas_antes': recordatorioHorasAntes.isEmpty
          ? null
          : recordatorioHorasAntes.join(','),
      'actualizado_en': actualizadoEn?.toIso8601String(),
      'eliminado': eliminado ? 1 : 0,
      'eliminado_en': eliminadoEn?.toIso8601String(),
    };
  }

  // Crea una copia de este objeto reemplazando solo los campos que se pasen
  AgendaEventoModel copyWith({
    String? id,
    String? mascotaId,
    String? tipoEvento,
    String? tipoEventoPersonalizado,
    String? titulo,
    String? observaciones,
    DateTime? fechaProgramada,
    DateTime? fechaRealizada,
    List<int>? recordatorioHorasAntes,
    DateTime? actualizadoEn,
    bool? eliminado,
    DateTime? eliminadoEn,
  }) {
    return AgendaEventoModel(
      id: id ?? this.id,
      mascotaId: mascotaId ?? this.mascotaId,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      tipoEventoPersonalizado:
          tipoEventoPersonalizado ?? this.tipoEventoPersonalizado,
      titulo: titulo ?? this.titulo,
      observaciones: observaciones ?? this.observaciones,
      fechaProgramada: fechaProgramada ?? this.fechaProgramada,
      fechaRealizada: fechaRealizada ?? this.fechaRealizada,
      recordatorioHorasAntes:
          recordatorioHorasAntes ?? this.recordatorioHorasAntes,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      eliminado: eliminado ?? this.eliminado,
      eliminadoEn: eliminadoEn ?? this.eliminadoEn,
    );
  }
}
