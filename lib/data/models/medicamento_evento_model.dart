class MedicamentoEventoModel {
  final String id;
  final String agendaEventoId;
  final String tipoPresentacion;
  final String nombre;
  final String? observaciones;

  MedicamentoEventoModel({
    required this.id,
    required this.agendaEventoId,
    required this.tipoPresentacion,
    required this.nombre,
    this.observaciones,
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
    };
  }

  // Crea una copia de este objeto reemplazando solo los campos que se pasen
  MedicamentoEventoModel copyWith({
    String? id,
    String? agendaEventoId,
    String? tipoPresentacion,
    String? nombre,
    String? observaciones,
  }) {
    return MedicamentoEventoModel(
      id: id ?? this.id,
      agendaEventoId: agendaEventoId ?? this.agendaEventoId,
      tipoPresentacion: tipoPresentacion ?? this.tipoPresentacion,
      nombre: nombre ?? this.nombre,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}
