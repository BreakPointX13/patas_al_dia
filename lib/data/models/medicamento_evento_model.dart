// Un medicamento recetado dentro de un evento de agenda (ej: una consulta).
class MedicamentoEventoModel {
  final String id;
  final String agendaEventoId;
  final String tipoPresentacion;
  final String nombre;
  final String? observaciones;
  // Sync (2026-08-20) — ver mascota_model.dart para el porqué de estos tres.
  final DateTime? actualizadoEn;
  final bool eliminado;
  final DateTime? eliminadoEn;

  MedicamentoEventoModel({
    required this.id,
    required this.agendaEventoId,
    required this.tipoPresentacion,
    required this.nombre,
    this.observaciones,
    this.actualizadoEn,
    this.eliminado = false,
    this.eliminadoEn,
  });

  // Convierte un Mapa (fila de la BDD) a un objeto MedicamentoEventoModel
  factory MedicamentoEventoModel.fromMap(Map<String, dynamic> map) {
    return MedicamentoEventoModel(
      id: map['id'] as String,
      agendaEventoId: map['agenda_evento_id'] as String,
      tipoPresentacion: map['tipo_presentacion'] as String,
      nombre: map['nombre'] as String,
      observaciones: map['observaciones'] != null
          ? map['observaciones'] as String
          : null,
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
      'agenda_evento_id': agendaEventoId,
      'tipo_presentacion': tipoPresentacion,
      'nombre': nombre,
      'observaciones': observaciones,
      'actualizado_en': actualizadoEn?.toIso8601String(),
      'eliminado': eliminado ? 1 : 0,
      'eliminado_en': eliminadoEn?.toIso8601String(),
    };
  }

  // Crea una copia de este objeto reemplazando solo los campos que se pasen
  MedicamentoEventoModel copyWith({
    String? id,
    String? agendaEventoId,
    String? tipoPresentacion,
    String? nombre,
    String? observaciones,
    DateTime? actualizadoEn,
    bool? eliminado,
    DateTime? eliminadoEn,
  }) {
    return MedicamentoEventoModel(
      id: id ?? this.id,
      agendaEventoId: agendaEventoId ?? this.agendaEventoId,
      tipoPresentacion: tipoPresentacion ?? this.tipoPresentacion,
      nombre: nombre ?? this.nombre,
      observaciones: observaciones ?? this.observaciones,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      eliminado: eliminado ?? this.eliminado,
      eliminadoEn: eliminadoEn ?? this.eliminadoEn,
    );
  }
}
