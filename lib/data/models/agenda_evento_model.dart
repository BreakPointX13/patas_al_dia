class AgendaEventoModel {
  final String id;
  final String mascotaId;
  final String? tipoEvento;
  final String titulo;
  final String? medicamentoPrescrito;
  final String? observaciones;
  final DateTime fechaProgramada;
  final DateTime? fechaRealizada;
  final int? repetirCadaMeses;
  final bool notificacionesActivas;

  AgendaEventoModel({
    required this.id,
    required this.mascotaId,
    this.tipoEvento,
    required this.titulo,
    this.medicamentoPrescrito,
    this.observaciones,
    required this.fechaProgramada,
    this.fechaRealizada,
    this.repetirCadaMeses,
    this.notificacionesActivas = true,
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
      medicamentoPrescrito: map['medicamento_prescrito'] != null
          ? map['medicamento_prescrito'] as String
          : null,
      observaciones: map['observaciones'] != null
          ? map['observaciones'] as String
          : null,
      fechaProgramada: DateTime.parse(map['fecha_programada'] as String),
      fechaRealizada: map['fecha_realizada'] != null
          ? DateTime.parse(map['fecha_realizada'] as String)
          : null,
      repetirCadaMeses: map['repetir_cada_meses'] != null
          ? map['repetir_cada_meses'] as int
          : null,
      notificacionesActivas:
          map['notificaciones_activas'] == 1 ||
          map['notificaciones_activas'] == true,
    );
  }

  // Convierte este objeto a un Mapa listo para insertarse en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mascota_id': mascotaId,
      'tipo_evento': tipoEvento,
      'titulo': titulo,
      'medicamento_prescrito': medicamentoPrescrito,
      'observaciones': observaciones,
      'fecha_programada': fechaProgramada.toIso8601String(),
      'fecha_realizada': fechaRealizada?.toIso8601String(),
      'repetir_cada_meses': repetirCadaMeses,
      'notificaciones_activas': notificacionesActivas
          ? 1
          : 0, // SQLite almacena booleanos como 0 o 1
    };
  }

  // Crea una copia de este objeto reemplazando solo los campos que se pasen
  AgendaEventoModel copyWith({
    String? id,
    String? mascotaId,
    String? tipoEvento,
    String? titulo,
    String? medicamentoPrescrito,
    String? observaciones,
    DateTime? fechaProgramada,
    DateTime? fechaRealizada,
    int? repetirCadaMeses,
    bool? notificacionesActivas,
  }) {
    return AgendaEventoModel(
      id: id ?? this.id,
      mascotaId: mascotaId ?? this.mascotaId,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      titulo: titulo ?? this.titulo,
      medicamentoPrescrito: medicamentoPrescrito ?? this.medicamentoPrescrito,
      observaciones: observaciones ?? this.observaciones,
      fechaProgramada: fechaProgramada ?? this.fechaProgramada,
      fechaRealizada: fechaRealizada ?? this.fechaRealizada,
      repetirCadaMeses: repetirCadaMeses ?? this.repetirCadaMeses,
      notificacionesActivas:
          notificacionesActivas ?? this.notificacionesActivas,
    );
  }
}
