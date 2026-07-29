# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Patas al Día** — aplicación móvil Flutter para dueños de mascotas. Permite registrar mascotas, gestionar agenda de eventos veterinarios, almacenar documentos y reportar mascotas extraviadas. Diseñada con arquitectura local-first (SQLite en dispositivo) y sincronización cloud pendiente de implementar vía Supabase.

## Commands

```bash
flutter pub get          # instalar dependencias
flutter run              # correr en dispositivo/emulador conectado
flutter test             # correr todos los tests
flutter test test/widget_test.dart  # correr un test específico
flutter analyze          # lint estático
flutter build apk        # build Android release
```

## Architecture
El proyecto sigue una arquitectura por capas. Las capas de datos (`lib/data/`) y de gestión de estado (`lib/providers/`) están completas; la UI (`lib/presentation/`) está en construcción — primera pantalla (`LoginScreen`) implementada.

### Estructura objetivo de `lib/`

```
lib/
├── main.dart                        # Entry point — lanza LoginScreen dentro de ProviderScope
├── presentation/
│   └── screens/
│       ├── login_screen.dart        # Bienvenida: iniciar sesión (no disponible aún) o continuar como invitado
│       └── home_screen.dart         # "Mis Mascotas" — lista real conectada a mascotasProvider, estado vacío, FAB (agregar mascota pendiente)
├── data/
│   ├── database/
│   │   └── database_helper.dart     # Singleton SQLite — punto de acceso único a la DB
│   ├── models/
│   │   ├── usuario_model.dart        # Modelo Usuario con soporte híbrido invitado/registrado
│   │   ├── mascota_model.dart        # Modelo Mascota con conversiones SQLite↔Dart
│   │   ├── agenda_evento_model.dart  # Modelo de eventos de agenda veterinaria (vacunas, controles)
│   │   └── documento_model.dart      # Modelo de documentos adjuntos (carnet, exámenes, recetas)
│   └── repositories/
│       ├── mascota_repository.dart        # CRUD de Mascota sobre DatabaseHelper
│       ├── usuario_repository.dart        # CRUD de Usuario sobre DatabaseHelper
│       ├── agenda_evento_repository.dart  # CRUD de AgendaEvento sobre DatabaseHelper
│       └── documento_repository.dart      # CRUD de Documento sobre DatabaseHelper
└── providers/                          # Gestión de estado con Riverpod (capa propia, hermana de data/)
    ├── mascota_provider.dart           # mascotaRepositoryProvider + MascotasNotifier/mascotasProvider (estado de la lista)
    ├── usuario_provider.dart           # usuarioRepositoryProvider + UsuarioNotifier/usuarioProvider (estado de un único usuario)
    ├── agenda_evento_provider.dart     # agendaEventoRepositoryProvider + AgendaEventoNotifier/agendaEventosProvider
    └── documento_provider.dart         # documentoRepositoryProvider + DocumentoNotifier/documentosProvider
```

Estado de las capas:
- `lib/data/repositories/` — completa; los 4 repositories del core (`mascota_repository.dart`, `usuario_repository.dart`, `agenda_evento_repository.dart`, `documento_repository.dart`) tienen el CRUD completo (crear, leer, actualizar, eliminar)
- `lib/providers/` — completa; los 4 repositories están expuestos (DI simple vía `Provider`), y `mascota_provider.dart`/`agenda_evento_provider.dart`/`documento_provider.dart`/`usuario_provider.dart` ya tienen su `NotifierProvider` con CRUD completo sobre el estado
- `lib/presentation/` — en construcción; `LoginScreen` completa (crea usuario invitado y navega, o avisa que el login real no está disponible aún) y `HomeScreen` completa (lista real de mascotas vía `mascotasProvider`, estado vacío). Pendiente: formulario de agregar/editar mascota (el FAB de `HomeScreen` hoy solo avisa "próximamente"), y pantallas de detalle (agenda, documentos)

### Capa de datos

**`DatabaseHelper`** es un Singleton con Lazy Initialization. Se accede siempre como `DatabaseHelper.instance`. Crea 5 tablas en `_onCreate` (se ejecuta una sola vez en el primer arranque):

```
usuarios
└── mascotas (CASCADE)
      ├── agenda_eventos (CASCADE)
      ├── documentos (CASCADE)
      └── mascotas_extraviadas (CASCADE)
```

**Models** (`MascotaModel`, `UsuarioModel`) implementan mapeo manual SQLite↔Dart sin ORM externo:
- `factory Model.fromMap(Map<String, dynamic>)` — deserialización desde SQLite
- `toMap()` — serialización hacia SQLite
- Booleanos: `bool` ↔ `INTEGER` (0/1) porque SQLite no tiene tipo `BOOLEAN`
- Fechas: `DateTime` ↔ `TEXT` ISO 8601; `MascotaModel` trunca a `YYYY-MM-DD` para fechas de nacimiento

**IDs**: todos los registros usan `String` UUID generados con el paquete `uuid`. Las PKs son `TEXT` en SQLite para compatibilidad futura con Supabase (PostgreSQL UUID).

### Login híbrido (pendiente de implementar)

`UsuarioModel` ya contempla dos estados de usuario:
- `esInvitado = true` → datos solo locales en SQLite, sin cuenta
- `esInvitado = false` → usuario registrado con `email`, listo para sync cloud

El campo `ultimaSincronizacion` es la marca de tiempo para sync incremental con Supabase. El campo `dispositivoId` identifica el dispositivo origen.

### Backend cloud (pendiente)

Tecnología elegida: **Supabase** (PostgreSQL + Auth + Storage).
- El esquema SQL de Supabase replica las 5 tablas de `TablaMaestraAppVetMovil1.txt` casi sin cambios.
- `foto_url` y `file_path` en los modelos apuntarán a URLs de Supabase Storage.
- La sincronización se activa únicamente cuando `esInvitado = false`.

## Roadmap — Segunda versión (v2)

Funcionalidades y modelos que quedan **fuera del alcance de la v1** y se retoman más adelante:

- **Mascotas extraviadas (reporte y mapa)**: la tabla `mascotas_extraviadas` ya existe en `_onCreate` de `DatabaseHelper` (se creó junto con las otras 4 para no romper el esquema), pero no tiene `MascotaExtraviadaModel`, repository ni pantallas. La feature completa incluye: reportar mascota perdida con geolocalización (`ubicacion_lat`/`ubicacion_lng`), estado (`perdido`/`encontrado`), recompensa, contacto de emergencia y descripción, más la UI de mapa para mostrar reportes. Se implementa después de tener el core (mascotas, agenda, documentos) funcionando end-to-end.

## Development Rules

1. **Cross-platform iOS + Android**: La app debe compilar y funcionar en ambas plataformas. No usar código o paquetes exclusivos de una plataforma sin alternativa para la otra.
2. **UX y facilidad de uso como prioridad**: Todas las decisiones de diseño priorizan la simplicidad para el usuario final. Ninguna funcionalidad core debe requerir registro obligatorio — el login híbrido (invitado sin cuenta) es la expresión de este principio.
3. **Documentación companion por módulo**: Todo archivo Dart significativo (models, repositories, providers, screens complejas) debe tener un `.md` en `docs/Documentacion/`, en la subcarpeta que espeja su ubicación en `lib/` (`models/`, `repositories/`, `database/`, etc.), siguiendo el patrón existente: ubicación en el proyecto, propósito, mapa conceptual y glosario de funciones complejas.
4. **Idioma español en todo el código**: Variables, funciones, clases, comentarios y textos de UI en español. El estándar actual lo refleja: `usuarioId`, `fechaNacimiento`, `esterilizado`, `esInvitado`.
5. **Local-first siempre**: La app debe ser 100% funcional offline antes de implementar cualquier feature de sync cloud. Un usuario invitado nunca debe ver errores por falta de conexión.
6. **Dependencias mínimas**: No añadir paquetes externos si la funcionalidad puede cubrirse con los ya presentes (`sqflite`, `uuid`, `path`) o con código nativo de Dart/Flutter.
7. **Gestión de estado consistente**: Se eligió **Riverpod** (sin generación de código, ver `flutter_riverpod` en `pubspec.yaml`) como solución de estado. Usarla en todos los módulos sin mezclar con otros enfoques (Provider, BLoC).

## Key decisions

- **Sin ORM**: mapeo manual en los models para mantener el proyecto liviano y sin generación de código (no hay archivos `.g.dart`).
- **Supabase sobre Firebase**: elegido por compatibilidad con el esquema SQL existente, costos operativos menores y Storage integrado para fotos/documentos.
- **Local-first**: la app funciona completamente offline; la nube es opcional y solo para usuarios registrados.
