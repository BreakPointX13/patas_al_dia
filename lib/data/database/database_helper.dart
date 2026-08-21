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

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  // SQLite no aplica ningún `ON DELETE CASCADE` declarado en el schema (los
  // de este archivo, ver `_onCreate`) salvo que se active esta pragma —
  // hallazgo pendiente desde Login real (2026-08-19, ver
  // decisiones_arquitectura.md), corregido acá: sin esto, borrar una
  // mascota (o un usuario) dejaba huérfanas sus filas hijas en vez de
  // borrarlas en cascada como parecía. `onConfigure` corre siempre que se
  // abre la conexión (no solo la primera vez, a diferencia de `onCreate`),
  // así que la pragma queda activa en cada arranque de la app.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
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
    //
    // actualizado_en/eliminado/eliminado_en (2026-08-20, Sync — ver
    // decisiones_arquitectura.md): "eliminar" una mascota ya no es un
    // DELETE real, es soft-delete — un DELETE no deja ningún rastro que
    // Sync pueda empujar a otro dispositivo. actualizado_en se usa tanto
    // para saber qué empujar (todo lo más nuevo que la última sync) como
    // para resolver conflictos (gana el cambio más reciente). Los
    // repositories son responsables de mantener estas columnas, no las
    // pantallas — ver mascota_repository.dart.
    //
    // foto_ruta_nube: a diferencia de foto_url (una ruta LOCAL del
    // dispositivo, nunca se sincroniza), esta columna guarda la ruta del
    // archivo dentro del bucket de Storage una vez subido — es la que sí
    // viaja por Sync. Ver sync_service.dart.
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
        foto_ruta_nube TEXT,
        fecha_estimada INTEGER DEFAULT 0,
        actualizado_en TEXT,
        eliminado INTEGER DEFAULT 0,
        eliminado_en TEXT,
        pendiente_push INTEGER DEFAULT 0,
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
        actualizado_en TEXT,
        eliminado INTEGER DEFAULT 0,
        eliminado_en TEXT,
        pendiente_push INTEGER DEFAULT 0,
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
        actualizado_en TEXT,
        eliminado INTEGER DEFAULT 0,
        eliminado_en TEXT,
        pendiente_push INTEGER DEFAULT 0,
        FOREIGN KEY (agenda_evento_id) REFERENCES agenda_eventos (id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabla Documentos (Lógica de Doble Entrada)
    //
    // archivo_ruta_nube reemplaza a sincronizado_nube (2026-08-20, Sync) —
    // ese campo llevaba desde el schema original sin usarse en ningún lado
    // del código (confirmado, código muerto); con Sync ya hace falta una
    // columna real para esto, mismo criterio que foto_ruta_nube arriba:
    // file_path es local-only, archivo_ruta_nube es la ruta en el bucket.
    await db.execute('''
      CREATE TABLE documentos (
        id TEXT PRIMARY KEY,
        mascota_id TEXT NOT NULL,
        evento_id TEXT,
        titulo TEXT NOT NULL,
        tipo_documento TEXT NOT NULL,
        tipo_documento_personalizado TEXT,
        file_path TEXT,
        file_extension TEXT,
        archivo_ruta_nube TEXT,
        fecha_emision TEXT,
        fecha_vencimiento TEXT,
        recordatorio_vencimiento INTEGER DEFAULT 0,
        fecha_subida TEXT DEFAULT CURRENT_TIMESTAMP,
        notas_asociadas TEXT,
        actualizado_en TEXT,
        eliminado INTEGER DEFAULT 0,
        eliminado_en TEXT,
        pendiente_push INTEGER DEFAULT 0,
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
