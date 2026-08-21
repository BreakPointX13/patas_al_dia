class MascotaModel {
  final String id;
  final String usuarioId;
  final String nombre;
  final String? rutMascota;
  final String? especie;
  final String? especiePersonalizada;
  final String? sexo;
  final String? raza;
  final bool esterilizado;
  final String? colores;
  final String? numeroChip;
  final DateTime? fechaNacimiento;
  final double? pesoActual;
  // Ruta LOCAL del dispositivo (nunca viaja por Sync) — ver fotoRutaNube.
  final String? fotoUrl;
  // Ruta dentro del bucket de Storage `fotos_mascotas`, una vez subida la
  // foto (2026-08-20, Sync — ver sync_service.dart). null hasta la primera
  // sincronización con foto.
  final String? fotoRutaNube;
  final bool fechaEstimada;
  // Sync (2026-08-20): última modificación (para saber qué empujar y para
  // resolver conflictos — gana el cambio más reciente) y soft-delete (un
  // DELETE real no deja rastro que sincronizar a otro dispositivo). Los
  // repositories son responsables de mantenerlas, no quien llama.
  final DateTime? actualizadoEn;
  final bool eliminado;
  final DateTime? eliminadoEn;

  MascotaModel({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    this.rutMascota,
    this.especie,
    this.especiePersonalizada,
    this.sexo,
    this.raza,
    this.esterilizado = false,
    this.colores,
    this.numeroChip,
    this.fechaNacimiento,
    this.pesoActual,
    this.fotoUrl,
    this.fotoRutaNube,
    this.fechaEstimada = false,
    this.actualizadoEn,
    this.eliminado = false,
    this.eliminadoEn,
  });

  // Convierte un Mapa (fila de la BDD) a un objeto MascotaModel
  factory MascotaModel.fromMap(Map<String, dynamic> map) {
    return MascotaModel(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      nombre: map['nombre'] as String,
      rutMascota: map['rut_mascota'] != null
          ? map['rut_mascota'] as String
          : null,
      especie: map['especie'] != null ? map['especie'] as String : null,
      especiePersonalizada: map['especie_personalizada'] != null
          ? map['especie_personalizada'] as String
          : null,
      sexo: map['sexo'] != null ? map['sexo'] as String : null,
      raza: map['raza'] != null ? map['raza'] as String : null,
      esterilizado: map['esterilizado'] == 1 || map['esterilizado'] == true,
      colores: map['colores'] != null ? map['colores'] as String : null,
      numeroChip: map['numero_chip'] != null
          ? map['numero_chip'] as String
          : null,
      fechaNacimiento: map['fecha_nacimiento'] != null
          ? DateTime.parse(map['fecha_nacimiento'] as String)
          : null,
      pesoActual: map['peso_actual'] != null
          ? (map['peso_actual'] as num).toDouble()
          : null,
      fotoUrl: map['foto_url'] != null ? map['foto_url'] as String : null,
      fotoRutaNube: map['foto_ruta_nube'] != null
          ? map['foto_ruta_nube'] as String
          : null,
      fechaEstimada:
          map['fecha_estimada'] == 1 || map['fecha_estimada'] == true,
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
      'usuario_id': usuarioId,
      'nombre': nombre,
      'rut_mascota': rutMascota,
      'especie': especie,
      'especie_personalizada': especiePersonalizada,
      'sexo': sexo,
      'raza': raza,
      'esterilizado': esterilizado
          ? 1
          : 0, // SQLite almacena booleanos como 0 o 1
      'colores': colores,
      'numero_chip': numeroChip,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String().split(
        'T',
      )[0], // Guarda solo YYYY-MM-DD
      'peso_actual': pesoActual,
      'foto_url': fotoUrl,
      'foto_ruta_nube': fotoRutaNube,
      'fecha_estimada': fechaEstimada ? 1 : 0,
      'actualizado_en': actualizadoEn?.toIso8601String(),
      'eliminado': eliminado ? 1 : 0,
      'eliminado_en': eliminadoEn?.toIso8601String(),
    };
  }

  // Crea una copia de este objeto reemplazando solo los campos que se pasen
  MascotaModel copyWith({
    String? id,
    String? usuarioId,
    String? nombre,
    String? rutMascota,
    String? especie,
    String? especiePersonalizada,
    String? sexo,
    String? raza,
    bool? esterilizado,
    String? colores,
    String? numeroChip,
    DateTime? fechaNacimiento,
    double? pesoActual,
    String? fotoUrl,
    String? fotoRutaNube,
    bool? fechaEstimada,
    DateTime? actualizadoEn,
    bool? eliminado,
    DateTime? eliminadoEn,
  }) {
    return MascotaModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nombre: nombre ?? this.nombre,
      rutMascota: rutMascota ?? this.rutMascota,
      especie: especie ?? this.especie,
      especiePersonalizada: especiePersonalizada ?? this.especiePersonalizada,
      sexo: sexo ?? this.sexo,
      raza: raza ?? this.raza,
      esterilizado: esterilizado ?? this.esterilizado,
      colores: colores ?? this.colores,
      numeroChip: numeroChip ?? this.numeroChip,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      pesoActual: pesoActual ?? this.pesoActual,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      fotoRutaNube: fotoRutaNube ?? this.fotoRutaNube,
      fechaEstimada: fechaEstimada ?? this.fechaEstimada,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      eliminado: eliminado ?? this.eliminado,
      eliminadoEn: eliminadoEn ?? this.eliminadoEn,
    );
  }
}
