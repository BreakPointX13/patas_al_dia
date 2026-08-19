import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Constructor privado necesario para el patrón Singleton
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  // Propiedad asíncrona que expone la base de datos de forma segura
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializa la conexión física con el almacenamiento del teléfono
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'patas_al_dia.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // Se ejecuta únicamente la primera vez que la app corre en el dispositivo
  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabla Usuarios (Soporte Híbrido)
    await db.execute('''
      CREATE TABLE usuarios (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        es_invitado INTEGER DEFAULT 1,
        fecha_registro TEXT DEFAULT CURRENT_TIMESTAMP,
        ultima_sincronizacion TEXT,
        dispositivo_id TEXT,
        sesion_activa INTEGER DEFAULT 1,
        escala_texto REAL DEFAULT 1.0,
        tema TEXT DEFAULT 'sistema',
        idioma TEXT DEFAULT 'sistema',
        aviso_mapa_visto INTEGER DEFAULT 0
      )
    ''');

    // 2. Tabla Mascotas
    await db.execute('''
      CREATE TABLE mascotas (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        nombre TEXT NOT NULL,
        rut_mascota TEXT,
        especie TEXT,
        especie_personalizada TEXT,
        sexo TEXT,
        raza TEXT,
        esterilizado INTEGER DEFAULT 0,
        colores TEXT,
        numero_chip TEXT,
        fecha_nacimiento TEXT,
        peso_actual REAL,
        foto_url TEXT,
        fecha_estimada INTEGER DEFAULT 0,
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabla Agenda de Eventos
    await db.execute('''
      CREATE TABLE agenda_eventos (
        id TEXT PRIMARY KEY,
        mascota_id TEXT NOT NULL,
        tipo_evento TEXT,
        tipo_evento_personalizado TEXT,
        titulo TEXT NOT NULL,
        observaciones TEXT,
        fecha_programada TEXT NOT NULL,
        fecha_realizada TEXT,
        recordatorio_horas_antes TEXT,
        FOREIGN KEY (mascota_id) REFERENCES mascotas (id) ON DELETE CASCADE
      )
    ''');

    // 3b. Tabla Medicamentos de Evento
    await db.execute('''
      CREATE TABLE medicamentos_evento (
        id TEXT PRIMARY KEY,
        agenda_evento_id TEXT NOT NULL,
        tipo_presentacion TEXT NOT NULL,
        nombre TEXT NOT NULL,
        observaciones TEXT,
        FOREIGN KEY (agenda_evento_id) REFERENCES agenda_eventos (id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabla Documentos (Lógica de Doble Entrada)
    await db.execute('''
      CREATE TABLE documentos (
        id TEXT PRIMARY KEY,
        mascota_id TEXT NOT NULL,
        evento_id TEXT,
        titulo TEXT NOT NULL,
        tipo_documento TEXT NOT NULL,
        tipo_documento_personalizado TEXT,
        file_path TEXT NOT NULL,
        file_extension TEXT,
        fecha_emision TEXT,
        fecha_vencimiento TEXT,
        recordatorio_vencimiento INTEGER DEFAULT 0,
        fecha_subida TEXT DEFAULT CURRENT_TIMESTAMP,
        notas_asociadas TEXT,
        sincronizado_nube INTEGER DEFAULT 0,
        FOREIGN KEY (mascota_id) REFERENCES mascotas (id) ON DELETE CASCADE,
        FOREIGN KEY (evento_id) REFERENCES agenda_eventos (id) ON DELETE SET NULL
      )
    ''');

    // 5. Tabla Mascotas Extraviadas (Mapa)
    await db.execute('''
      CREATE TABLE mascotas_extraviadas (
        id TEXT PRIMARY KEY,
        mascota_id TEXT NOT NULL,
        ubicacion_lat REAL,
        ubicacion_lng REAL,
        recompensa REAL DEFAULT 0.0,
        estado TEXT DEFAULT 'perdido',
        contacto_emergencia TEXT,
        descripcion TEXT,
        FOREIGN KEY (mascota_id) REFERENCES mascotas (id) ON DELETE CASCADE
      )
    ''');
  }
}
