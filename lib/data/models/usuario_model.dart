class UsuarioModel {
  final String id;
  final String? email;
  final bool esInvitado;
  final DateTime? fechaRegistro;
  final DateTime? ultimaSincronizacion;
  final String? dispositivoId;
  final bool sesionActiva;
  final double escalaTexto;
  // 'sistema' (sigue el modo oscuro/claro del sistema operativo), 'claro' o
  // 'oscuro' — preferencia explícita del usuario, ver ajustesScreen.md.
  final String tema;
  // 'sistema' (sigue el idioma del sistema operativo, si está entre los
  // soportados), 'es', 'en' o 'pt' — ver ajustesScreen.md.
  final String idioma;

  UsuarioModel({
    required this.id,
    this.email,
    this.esInvitado = true,
    this.fechaRegistro,
    this.ultimaSincronizacion,
    this.dispositivoId,
    this.sesionActiva = true,
    this.escalaTexto = 1.0,
    this.tema = 'sistema',
    this.idioma = 'sistema',
  });

  // ADUANA DE ENTRADA: De mapas de SQLite a objetos de Flutter
  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'] as String,
      email: map['email'] as String?,
      esInvitado: (map['es_invitado'] as int?) == 1,
      fechaRegistro: map['fecha_registro'] != null
          ? DateTime.parse(map['fecha_registro'] as String)
          : null,
      ultimaSincronizacion: map['ultima_sincronizacion'] != null
          ? DateTime.parse(map['ultima_sincronizacion'] as String)
          : null,
      dispositivoId: map['dispositivo_id'] as String?,
      sesionActiva: (map['sesion_activa'] as int?) == 1,
      escalaTexto: map['escala_texto'] != null
          ? (map['escala_texto'] as num).toDouble()
          : 1.0,
      tema: map['tema'] as String? ?? 'sistema',
      idioma: map['idioma'] as String? ?? 'sistema',
    );
  }

  // ADUANA DE SALIDA: De objetos de Flutter a mapas listos para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'es_invitado': esInvitado ? 1 : 0,
      'fecha_registro': fechaRegistro?.toIso8601String(),
      'ultima_sincronizacion': ultimaSincronizacion?.toIso8601String(),
      'dispositivo_id': dispositivoId,
      'sesion_activa': sesionActiva ? 1 : 0,
      'escala_texto': escalaTexto,
      'tema': tema,
      'idioma': idioma,
    };
  }

  // Crea una copia de este objeto reemplazando solo los campos que se pasen
  UsuarioModel copyWith({
    String? id,
    String? email,
    bool? esInvitado,
    DateTime? fechaRegistro,
    DateTime? ultimaSincronizacion,
    String? dispositivoId,
    bool? sesionActiva,
    double? escalaTexto,
    String? tema,
    String? idioma,
  }) {
    return UsuarioModel(
      id: id ?? this.id,
      email: email ?? this.email,
      esInvitado: esInvitado ?? this.esInvitado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      ultimaSincronizacion: ultimaSincronizacion ?? this.ultimaSincronizacion,
      dispositivoId: dispositivoId ?? this.dispositivoId,
      sesionActiva: sesionActiva ?? this.sesionActiva,
      escalaTexto: escalaTexto ?? this.escalaTexto,
      tema: tema ?? this.tema,
      idioma: idioma ?? this.idioma,
    );
  }
}
