class AgendaEventoModel {
  final String id;
  final String mascotaId;
  final String? tipoEvento;
  final String titulo;
  final String? observaciones;
  final DateTime fechaProgramada;
  final DateTime? fechaRealizada;
  final List<int> recordatorioHorasAntes;

  AgendaEventoModel({
    required this.id,
    required this.mascotaId,
    this.tipoEvento,
    required this.titulo,
    this.observaciones,
    required this.fechaProgramada,
    this.fechaRealizada,
    this.recordatorioHorasAntes = const [],
  });

  // Convierte un Mapa (fila de la BDD) a un objeto AgendaEventoModel
  factory AgendaEventoModel.fromMap(Map<String, dynamic> map) {
    return AgendaEventoModel(
      id: map['id'] as String,
      mascotaId: map['mascota_id'] as String,
      tipoEvento: map['tipo_evento'] != null
          ? map['tipo_evento'] as String
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
    );
  }

  // Convierte este objeto a un Mapa listo para insertarse en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mascota_id': mascotaId,
      'tipo_evento': tipoEvento,
      'titulo': titulo,
      'observaciones': observaciones,
      'fecha_programada': fechaProgramada.toIso8601String(),
      'fecha_realizada': fechaRealizada?.toIso8601String(),
      'recordatorio_horas_antes': recordatorioHorasAntes.isEmpty
          ? null
          : recordatorioHorasAntes.join(','),
    };
  }

  // Crea una copia de este objeto reemplazando solo los campos que se pasen
  AgendaEventoModel copyWith({
    String? id,
    String? mascotaId,
    String? tipoEvento,
    String? titulo,
    String? observaciones,
    DateTime? fechaProgramada,
    DateTime? fechaRealizada,
    List<int>? recordatorioHorasAntes,
  }) {
    return AgendaEventoModel(
      id: id ?? this.id,
      mascotaId: mascotaId ?? this.mascotaId,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      titulo: titulo ?? this.titulo,
      observaciones: observaciones ?? this.observaciones,
      fechaProgramada: fechaProgramada ?? this.fechaProgramada,
      fechaRealizada: fechaRealizada ?? this.fechaRealizada,
      recordatorioHorasAntes:
          recordatorioHorasAntes ?? this.recordatorioHorasAntes,
    );
  }
}
