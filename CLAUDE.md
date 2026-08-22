# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Patas al Día** — aplicación móvil Flutter para dueños de mascotas. Permite registrar mascotas, gestionar agenda de eventos veterinarios (con medicamentos y recordatorios), almacenar documentos, reportar y ver mascotas extraviadas en un mapa, y — para quien se registre — sincronizar todo eso entre dispositivos. Arquitectura local-first: 100% funcional sin conexión y sin cuenta (modo invitado), con Supabase como backend cloud opcional (Auth, Postgres, Storage y Edge Functions) para usuarios registrados.

**Estado: v1 completa y probada de punta a punta.** Las cuatro entidades del core (mascotas, agenda, documentos, medicamentos), el módulo Mapa, el login real y la sincronización en dos sentidos ya están implementados, documentados y en producción (`main`). Ver `docs/Documentacion/decisiones_arquitectura.md` para la bitácora completa de decisiones, y `docs/Planificaciones/PublicacionPlayStore.md` para lo que falta (no es código) antes de publicar en Google Play.

## Commands

```bash
flutter pub get          # instalar dependencias
flutter run               # correr en dispositivo/emulador conectado
flutter test               # correr todos los tests
flutter test test/widget_test.dart  # correr un test específico
flutter analyze            # lint estático
flutter build apk --debug  # build Android debug, para instalar y probar
flutter build appbundle --release  # build Android release firmado, para subir a Play Console
flutter gen-l10n            # regenerar lib/l10n/*.dart después de tocar los .arb
```

## Architecture

El proyecto sigue una arquitectura por capas, todas completas para el alcance de v1: `lib/data/` (models + repositories), `lib/providers/` (Riverpod), `lib/services/` (Supabase Auth/Storage/Edge Functions, notificaciones locales, almacenamiento de archivos), y `lib/presentation/` (screens + widgets + utils compartidos).

### Estructura de `lib/`

```
lib/
├── main.dart                          # Entry point — ProviderScope, listeners globales (recuperación de contraseña, disparadores de Sync)
├── data/
│   ├── database/
│   │   └── database_helper.dart       # Singleton SQLite — 6 tablas (ver más abajo)
│   ├── models/                        # usuario, mascota, agenda_evento, medicamento_evento, documento, mascota_extraviada
│   └── repositories/                  # uno por modelo (menos medicamento_evento/mascota_extraviada que no tienen provider propio de estado — ver providers/)
├── providers/                          # Riverpod: un xRepositoryProvider + un xNotifier/xProvider por entidad, más sync_provider.dart
├── services/
│   ├── supabase_config.dart            # URL/publishable key, constantes de redirect (recuperar contraseña, confirmar correo)
│   ├── sync_service.dart               # Motor de sincronización en dos sentidos (ver más abajo)
│   ├── almacenamiento_local_service.dart  # Rutas persistentes para fotos/documentos (Sync)
│   ├── notificacion_service.dart       # Recordatorios locales de agenda (flutter_local_notifications)
│   └── reportar_bug_service.dart       # Llama a la Edge Function reportar-bug
└── presentation/
    ├── screens/                        # ~30 pantallas — login/registro/recuperación, home, ficha de mascota, agenda, documentos, mapa, ajustes, reportar bug
    ├── widgets/                        # SeparadorSeccionFicha, TarjetaClara, dialogo_confirmacion (confirmarAccion), IconoTipoReporte, etc. — compartidos entre pantallas
    ├── utils/                          # etiquetas_localizadas (traduce valores guardados fijos en español), validador_contrasena, errores_autenticacion, mapa_tiles
    └── theme/
        └── tema_app.dart                # Paleta Crema/Naranja/Durazno/Café, con variantes de modo oscuro
```

`supabase/functions/` (fuera de `lib/`, corre en el servidor de Supabase, no en la app): `eliminar-cuenta` y `reportar-bug` — ver "Backend cloud" más abajo.

### Capa de datos

**`DatabaseHelper`** es un Singleton con Lazy Initialization (`DatabaseHelper.instance`). Crea 6 tablas en `_onCreate`:

```
usuarios
└── mascotas (CASCADE)
      ├── agenda_eventos (CASCADE)
      │     └── medicamentos_evento (CASCADE)
      ├── documentos (CASCADE; evento_id → agenda_eventos con SET NULL, no CASCADE)
      └── mascotas_extraviadas (CASCADE)
```

**Models** implementan mapeo manual SQLite↔Dart sin ORM externo (`fromMap`/`toMap`/`copyWith`). Booleanos `bool` ↔ `INTEGER` (0/1); fechas `DateTime` ↔ `TEXT` ISO 8601, siempre en **UTC** para las 4 entidades que sincronizan (ver Sync, más abajo — un bug real de zona horaria costó encontrar esto).

**IDs**: todos los registros usan `String` UUID (paquete `uuid`). Las PKs son `TEXT` en SQLite, compatibles con el UUID de PostgreSQL en Supabase.

**Soft-delete**: las 4 entidades que sincronizan (`mascotas`, `agenda_eventos`, `medicamentos_evento`, `documentos`) no usan `DELETE` real — cada `eliminarX` de su repository hace un `UPDATE` (`eliminado`/`eliminado_en`), respetando la cascada real del schema a mano (soft-delete no dispara `ON DELETE CASCADE`). `mascotas_extraviadas` es la excepción: no sincroniza entre dispositivos (vive solo en Supabase, no en SQLite local), así que sí usa borrado real.

### Login real y usuarios

`UsuarioModel` soporta dos estados:
- `esInvitado = true` → datos solo locales en SQLite, sin cuenta, sin conexión a Supabase Auth.
- `esInvitado = false` → usuario registrado con `email` y `id` igual al `auth.uid()` de Supabase — decisión deliberada para que Sync no tenga que traducir entre dos sistemas de ids.

Implementado: registro, iniciar sesión, "olvidé mi contraseña" (enlace por correo, con deep link `patasaldia://reset-password`), cambiar contraseña (desde Ajustes, con la contraseña actual), eliminar cuenta (borra Supabase Auth de verdad vía la Edge Function `eliminar-cuenta`, más los datos locales). Un invitado con datos ya cargados que se registra los conserva todos — no arranca de cero.

### Sync (sincronización en dos sentidos)

`lib/services/sync_service.dart` — solo para usuarios registrados. Automático pero no instantáneo (tres disparadores en `main.dart`: al detectar sesión activa, cada 5 minutos en primer plano, al pasar a segundo plano — sin cola persistente aparte, la "cola" es la tabla misma filtrada por `pendiente_push`). Push + pull por entidad, en el orden `Mascota → AgendaEvento → MedicamentoEvento → Documento` (el orden seguro para los `FOREIGN KEY`). Conflictos: gana el cambio más reciente por `actualizado_en`. Fotos/documentos se suben/bajan de buckets privados de Storage (`fotos_mascotas`, `archivos_documentos`), con compresión (`maxWidth`/`imageQuality`) en las fotos que salen del dispositivo.

Documentación completa: `docs/Documentacion/services/syncService.md`. Bitácora de los bugs reales encontrados durante el desarrollo (zona horaria, `pendiente_push`, `INSERT OR REPLACE` disparando cascadas, conflictos de medicamentos): `decisiones_arquitectura.md`, entradas del 2026-08-20 al 22.

### Mapa (mascotas extraviadas)

Implementado como parte de v1, no v2 (a diferencia de lo que decía una versión anterior de este archivo). `MascotaExtraviadaRepository` habla directo con Supabase (Postgres, no SQLite — es la única entidad que no vive local, porque su razón de ser es que *otros* usuarios la vean). Reportar mascota perdida/encontrada con ubicación, foto (bucket público `fotos_reportes`), contacto de emergencia y descripción; mapa con `flutter_map` mostrando los reportes activos; denuncia y borrado con limpieza de la foto en Storage. Un invitado puede publicar un reporte sin registrarse (usa una sesión anónima de Supabase Auth, no relacionada con su `usuarioId` local).

### Backend cloud

**Supabase** (PostgreSQL + Auth + Storage + Edge Functions). El esquema completo (6 tablas + Storage, con Row Level Security) vive en `docs/Planificaciones/TablaMaestraAppVetMovil1.sql` — es el que está corriendo en producción, no un borrador.

**Edge Functions** (`supabase/functions/`, Deno/TypeScript, no Dart — corren en el servidor):
- `eliminar-cuenta` — borra la cuenta de Supabase Auth (requiere `SUPABASE_SERVICE_ROLE_KEY`, un secreto que no puede vivir en el cliente). Exige JWT válido, identifica a quién borrar por la sesión que llama, nunca por un parámetro.
- `reportar-bug` — arma y manda un correo real (vía Resend, `RESEND_API_KEY` como secreto de Supabase) con la descripción y una imagen opcional. Sin JWT — un invitado también puede reportar un bug.

**`PatasAlDiaWeb`** (`https://github.com/BreakPointX13/PatasAlDiaWeb`, repo público aparte, GitHub Pages) — política de privacidad y borrado de cuenta accesible sin la app instalada (es/en/pt), más la página de confirmación de correo. Existe aparte porque Supabase Storage no puede servir HTML real (`Content-Type: text/plain` forzado) y el repo principal es privado.

## Roadmap — pendiente, fuera de esta versión

Nada bloquea publicar v1. Backlog explícito, en orden de qué tan disponible está para retomarse:

- **Backup/exportación manual** para usuarios invitados — Sync ya resuelve esto para registrados; para invitados (que nunca sincronizan por diseño) seguiría siendo la única forma de resguardar datos. Pospuesto, no descartado.
- **Notificaciones de reportes cercanos** (~1km) en el módulo Mapa — bloqueado por costo de infraestructura de push (Firebase).
- **iOS**: el proyecto compila para iOS (regla 1, sigue vigente) pero no se probó en un dispositivo real — bloqueado por el costo de la cuenta de desarrollador de Apple (US$100/año). Se re-evaluará según demanda, una vez publicada en Play Store.

## Development Rules

1. **Cross-platform iOS + Android**: La app debe compilar y funcionar en ambas plataformas. No usar código o paquetes exclusivos de una plataforma sin alternativa para la otra.
2. **UX y facilidad de uso como prioridad**: Todas las decisiones de diseño priorizan la simplicidad para el usuario final. Ninguna funcionalidad core debe requerir registro obligatorio — el login híbrido (invitado sin cuenta) es la expresión de este principio.
3. **Documentación companion por módulo**: Todo archivo Dart significativo (models, repositories, providers, screens complejas, services) debe tener un `.md` en `docs/Documentacion/`, en la subcarpeta que espeja su ubicación en `lib/` (`models/`, `repositories/`, `database/`, `services/`, etc.), siguiendo el patrón existente: ubicación en el proyecto, propósito, mapa conceptual y glosario de funciones complejas. Las Edge Functions (fuera de `lib/`) también, en `docs/Documentacion/functions/`.
4. **Idioma español en todo el código**: Variables, funciones, clases, comentarios y textos de UI en español **neutro** (sin voseo ni modismos regionales — usar "tú"/"puedes", no "vos"/"podés"). El estándar actual lo refleja: `usuarioId`, `fechaNacimiento`, `esterilizado`, `esInvitado`. Los textos visibles para el usuario final salen de `AppLocalizations` (es/en/pt, ver `docs/Documentacion/l10n/sistemaIdiomas.md`), no están escritos fijos en el código.
5. **Local-first siempre**: La app debe ser 100% funcional offline antes de cualquier feature de sync cloud, y lo sigue siendo — un usuario invitado nunca debe ver errores por falta de conexión, y Sync nunca debe bloquear el uso normal de la app si falla (reintenta solo en la próxima corrida).
6. **Dependencias mínimas**: No añadir paquetes externos si la funcionalidad puede cubrirse con los ya presentes o con código nativo de Dart/Flutter.
7. **Gestión de estado consistente**: **Riverpod** (sin generación de código) en todos los módulos, sin mezclar con otros enfoques (Provider, BLoC).

## Key decisions

- **Sin ORM**: mapeo manual en los models para mantener el proyecto liviano y sin generación de código (no hay archivos `.g.dart`).
- **Supabase sobre Firebase**: elegido por compatibilidad con el esquema SQL, costos operativos menores y Storage integrado.
- **Local-first**: la app funciona completamente offline; la nube es opcional y solo para usuarios registrados.
- **Sync: gana el cambio más reciente**, sin merge manual — decisión explícita del usuario, mismo criterio simple en las 4 entidades. Soft-delete (no `DELETE` real) para que un borrado se pueda propagar a otro dispositivo.
- **Resend para correo transaccional** (`reportar-bug`) — API HTTP simple desde Deno, sin SDK, nivel gratis suficiente para el volumen esperado.
- **`applicationId`: `dev.breakpointx.patasaldia`** (Android/iOS/macOS) — cambiado desde el placeholder `com.example.patas_al_dia` de Flutter antes de la primera publicación, porque Google Play rechaza `com.example.*` y no se puede cambiar después sin perder el historial de la app.
