class DocumentoModel {
  final String id;
  final String mascotaId;
  final String? eventoId;
  final String titulo;
  final String tipoDocumento;
  final String? tipoDocumentoPersonalizado;
  final String filePath;
  final String? fileExtension;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;
  final bool recordatorioVencimiento;
  final DateTime? fechaSubida;
  final String? notasAsociadas;
  final bool sincronizadoNube;

  DocumentoModel({
    required this.id,
    required this.mascotaId,
    this.eventoId,
    required this.titulo,
    required this.tipoDocumento,
    this.tipoDocumentoPersonalizado,
    required this.filePath,
    this.fileExtension,
    this.fechaEmision,
    this.fechaVencimiento,
    this.recordatorioVencimiento = false,
    this.fechaSubida,
    this.notasAsociadas,
    this.sincronizadoNube = false,
  });

  // Convierte un Mapa (fila de la BDD) a un objeto DocumentoModel
  factory DocumentoModel.fromMap(Map<String, dynamic> map) {
    return DocumentoModel(
      id: map['id'] as String,
      mascotaId: map['mascota_id'] as String,
      eventoId: map['evento_id'] != null ? map['evento_id'] as String : null,
      titulo: map['titulo'] as String,
      tipoDocumento: map['tipo_documento'] as String,
      tipoDocumentoPersonalizado: map['tipo_documento_personalizado'] != null
          ? map['tipo_documento_personalizado'] as String
          : null,
      filePath: map['file_path'] as String,
      fileExtension: map['file_extension'] != null
          ? map['file_extension'] as String
          : null,
      fechaEmision: map['fecha_emision'] != null
          ? DateTime.parse(map['fecha_emision'] as String)
          : null,
      fechaVencimiento: map['fecha_vencimiento'] != null
          ? DateTime.parse(map['fecha_vencimiento'] as String)
          : null,
      recordatorioVencimiento:
          map['recordatorio_vencimiento'] == 1 ||
          map['recordatorio_vencimiento'] == true,
      fechaSubida: map['fecha_subida'] != null
          ? DateTime.parse(map['fecha_subida'] as String)
          : null,
      notasAsociadas: map['notas_asociadas'] != null
          ? map['notas_asociadas'] as String
          : null,
      sincronizadoNube:
          map['sincronizado_nube'] == 1 || map['sincronizado_nube'] == true,
    );
  }

  // Convierte este objeto a un Mapa listo para insertarse en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mascota_id': mascotaId,
      'evento_id': eventoId,
      'titulo': titulo,
      'tipo_documento': tipoDocumento,
      'tipo_documento_personalizado': tipoDocumentoPersonalizado,
      'file_path': filePath,
      'file_extension': fileExtension,
      'fecha_emision': fechaEmision?.toIso8601String().split(
        'T',
      )[0], // Solo YYYY-MM-DD
      'fecha_vencimiento': fechaVencimiento?.toIso8601String().split(
        'T',
      )[0], // Solo YYYY-MM-DD
      'recordatorio_vencimiento': recordatorioVencimiento
          ? 1
          : 0, // SQLite almacena booleanos como 0 o 1
      'fecha_subida': fechaSubida?.toIso8601String(),
      'notas_asociadas': notasAsociadas,
      'sincronizado_nube': sincronizadoNube ? 1 : 0,
    };
  }

  // Crea una copia de este objeto reemplazando solo los campos que se pasen
  DocumentoModel copyWith({
    String? id,
    String? mascotaId,
    String? eventoId,
    String? titulo,
    String? tipoDocumento,
    String? tipoDocumentoPersonalizado,
    String? filePath,
    String? fileExtension,
    DateTime? fechaEmision,
    DateTime? fechaVencimiento,
    bool? recordatorioVencimiento,
    DateTime? fechaSubida,
    String? notasAsociadas,
    bool? sincronizadoNube,
  }) {
    return DocumentoModel(
      id: id ?? this.id,
      mascotaId: mascotaId ?? this.mascotaId,
      eventoId: eventoId ?? this.eventoId,
      titulo: titulo ?? this.titulo,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      tipoDocumentoPersonalizado:
          tipoDocumentoPersonalizado ?? this.tipoDocumentoPersonalizado,
      filePath: filePath ?? this.filePath,
      fileExtension: fileExtension ?? this.fileExtension,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      recordatorioVencimiento:
          recordatorioVencimiento ?? this.recordatorioVencimiento,
      fechaSubida: fechaSubida ?? this.fechaSubida,
      notasAsociadas: notasAsociadas ?? this.notasAsociadas,
      sincronizadoNube: sincronizadoNube ?? this.sincronizadoNube,
    );
  }
}
