class MascotaModel {
  final String id;
  final String usuarioId;
  final String nombre;
  final String? rutMascota;
  final String? especie;
  final String? sexo;
  final String? raza;
  final bool esterilizado;
  final String? colores;
  final String? numeroChip;
  final DateTime? fechaNacimiento;
  final double? pesoActual;
  final String? fotoUrl;

  MascotaModel({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    this.rutMascota,
    this.especie,
    this.sexo,
    this.raza,
    this.esterilizado = false,
    this.colores,
    this.numeroChip,
    this.fechaNacimiento,
    this.pesoActual,
    this.fotoUrl,
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
    };
  }
}
