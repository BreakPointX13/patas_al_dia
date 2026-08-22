// Un documento adjunto a una mascota (carnet, examen, receta, etc.).
class DocumentoModel {
  final String id;
  final String mascotaId;
  final String? eventoId;
  final String titulo;
  final String tipoDocumento;
  final String? tipoDocumentoPersonalizado;
  // Ruta LOCAL del dispositivo — nunca viaja por Sync. Nullable desde
  // 2026-08-20 (Sync): una fila recién traída de otro dispositivo no tiene
  // archivo local todavía, hasta que se descarga (ver archivoRutaNube).
  final String? filePath;
  final String? fileExtension;
  // Ruta dentro del bucket de Storage `archivos_documentos`, una vez
  // subido el archivo (2026-08-20, Sync — ver sync_service.dart).
  // Reemplaza a `sincronizadoNube` (campo viejo, nunca usado en el código).
  final String? archivoRutaNube;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;
  final bool recordatorioVencimiento;
  final DateTime? fechaSubida;
  final String? notasAsociadas;
  // Sync (2026-08-20) — ver mascota_model.dart para el porqué de estos tres.
  final DateTime? actualizadoEn;
  final bool eliminado;
  final DateTime? eliminadoEn;

  DocumentoModel({
    required this.id,
    required this.mascotaId,
    this.eventoId,
    required this.titulo,
    required this.tipoDocumento,
    this.tipoDocumentoPersonalizado,
    this.filePath,
    this.fileExtension,
    this.archivoRutaNube,
    this.fechaEmision,
    this.fechaVencimiento,
    this.recordatorioVencimiento = false,
    this.fechaSubida,
    this.notasAsociadas,
    this.actualizadoEn,
    this.eliminado = false,
    this.eliminadoEn,
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
      filePath: map['file_path'] != null ? map['file_path'] as String : null,
      fileExtension: map['file_extension'] != null
          ? map['file_extension'] as String
          : null,
      archivoRutaNube: map['archivo_ruta_nube'] != null
          ? map['archivo_ruta_nube'] as String
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
      'evento_id': eventoId,
      'titulo': titulo,
      'tipo_documento': tipoDocumento,
      'tipo_documento_personalizado': tipoDocumentoPersonalizado,
      'file_path': filePath,
      'file_extension': fileExtension,
      'archivo_ruta_nube': archivoRutaNube,
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
      'actualizado_en': actualizadoEn?.toIso8601String(),
      'eliminado': eliminado ? 1 : 0,
      'eliminado_en': eliminadoEn?.toIso8601String(),
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
    String? archivoRutaNube,
    DateTime? fechaEmision,
    DateTime? fechaVencimiento,
    bool? recordatorioVencimiento,
    DateTime? fechaSubida,
    String? notasAsociadas,
    DateTime? actualizadoEn,
    bool? eliminado,
    DateTime? eliminadoEn,
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
      archivoRutaNube: archivoRutaNube ?? this.archivoRutaNube,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      recordatorioVencimiento:
          recordatorioVencimiento ?? this.recordatorioVencimiento,
      fechaSubida: fechaSubida ?? this.fechaSubida,
      notasAsociadas: notasAsociadas ?? this.notasAsociadas,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      eliminado: eliminado ?? this.eliminado,
      eliminadoEn: eliminadoEn ?? this.eliminadoEn,
    );
  }
}
