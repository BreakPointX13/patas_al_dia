// Un reporte de mascota perdida o encontrada, visible en el mapa. Vive solo
// en Supabase (no en SQLite local) porque otros usuarios necesitan verlo.
class MascotaExtraviadaModel {
  final String id;
  final String usuarioId;
  final String? mascotaId;
  final String? mascotaNombre;
  final String? mascotaEspecie;
  final String? mascotaFotoUrl;
  final double? ubicacionLat;
  final double? ubicacionLng;
  final double recompensa;
  // 'perdido' o 'encontrado' — qué clase de reporte es. No cambia nunca
  // después de creado (a diferencia de `resuelto`).
  final String tipo;
  final bool resuelto;
  final String contactoEmergencia;
  final String? descripcion;
  final DateTime? fechaPublicacion;

  MascotaExtraviadaModel({
    required this.id,
    required this.usuarioId,
    this.mascotaId,
    this.mascotaNombre,
    this.mascotaEspecie,
    this.mascotaFotoUrl,
    this.ubicacionLat,
    this.ubicacionLng,
    this.recompensa = 0,
    required this.tipo,
    this.resuelto = false,
    required this.contactoEmergencia,
    this.descripcion,
    this.fechaPublicacion,
  });

  // Convierte una fila de Supabase (Map<String, dynamic>) a un objeto Dart
  factory MascotaExtraviadaModel.fromMap(Map<String, dynamic> map) {
    return MascotaExtraviadaModel(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      mascotaId: map['mascota_id'] as String?,
      mascotaNombre: map['mascota_nombre'] as String?,
      mascotaEspecie: map['mascota_especie'] as String?,
      mascotaFotoUrl: map['mascota_foto_url'] as String?,
      ubicacionLat: map['ubicacion_lat'] != null
          ? (map['ubicacion_lat'] as num).toDouble()
          : null,
      ubicacionLng: map['ubicacion_lng'] != null
          ? (map['ubicacion_lng'] as num).toDouble()
          : null,
      recompensa: map['recompensa'] != null
          ? (map['recompensa'] as num).toDouble()
          : 0,
      tipo: map['tipo'] as String,
      resuelto: map['resuelto'] == 1 || map['resuelto'] == true,
      contactoEmergencia: map['contacto_emergencia'] as String,
      descripcion: map['descripcion'] as String?,
      fechaPublicacion: map['fecha_publicacion'] != null
          ? DateTime.parse(map['fecha_publicacion'] as String)
          : null,
    );
  }

  // Convierte este objeto a un Mapa listo para insertar/actualizar en Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'mascota_id': mascotaId,
      'mascota_nombre': mascotaNombre,
      'mascota_especie': mascotaEspecie,
      'mascota_foto_url': mascotaFotoUrl,
      'ubicacion_lat': ubicacionLat,
      'ubicacion_lng': ubicacionLng,
      'recompensa': recompensa,
      'tipo': tipo,
      'resuelto': resuelto,
      'contacto_emergencia': contactoEmergencia,
      'descripcion': descripcion,
      'fecha_publicacion': fechaPublicacion?.toIso8601String(),
    };
  }

  // Crea una copia de este objeto reemplazando solo los campos que se pasen
  MascotaExtraviadaModel copyWith({
    String? id,
    String? usuarioId,
    String? mascotaId,
    String? mascotaNombre,
    String? mascotaEspecie,
    String? mascotaFotoUrl,
    double? ubicacionLat,
    double? ubicacionLng,
    double? recompensa,
    String? tipo,
    bool? resuelto,
    String? contactoEmergencia,
    String? descripcion,
    DateTime? fechaPublicacion,
  }) {
    return MascotaExtraviadaModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      mascotaId: mascotaId ?? this.mascotaId,
      mascotaNombre: mascotaNombre ?? this.mascotaNombre,
      mascotaEspecie: mascotaEspecie ?? this.mascotaEspecie,
      mascotaFotoUrl: mascotaFotoUrl ?? this.mascotaFotoUrl,
      ubicacionLat: ubicacionLat ?? this.ubicacionLat,
      ubicacionLng: ubicacionLng ?? this.ubicacionLng,
      recompensa: recompensa ?? this.recompensa,
      tipo: tipo ?? this.tipo,
      resuelto: resuelto ?? this.resuelto,
      contactoEmergencia: contactoEmergencia ?? this.contactoEmergencia,
      descripcion: descripcion ?? this.descripcion,
      fechaPublicacion: fechaPublicacion ?? this.fechaPublicacion,
    );
  }
}
