<div align="center">

<img src="assets/images/logo_patas_al_dia.png" alt="Patas al Día logo" width="120"/>

# Patas al Día

**Una app de cuidado de mascotas local-first para Flutter — funciona completamente sin conexión, con sincronización en la nube opcional.**

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%5E3.11.5-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-3DDC84)](#)
[![Backend](https://img.shields.io/badge/backend-Supabase-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Languages](https://img.shields.io/badge/i18n-es%20%7C%20en%20%7C%20pt-orange)](#)
[![Status](https://img.shields.io/badge/status-v1%20feature%20complete-success)](#)

[Español](#español) · [English](#english)

</div>

---

<a id="español"></a>
## Español

### Sobre el proyecto

**Patas al Día** ayuda a dueños de mascotas a organizar todo lo importante sobre su salud: fichas de cada mascota, agenda veterinaria con recordatorios de medicamentos, documentos, y un mapa comunitario de mascotas perdidas/encontradas.

La app está construida **local-first**: cada función anda completamente sin conexión, sin necesitar cuenta. Crear una cuenta es totalmente opcional y solo desbloquea la sincronización entre dispositivos — ninguna funcionalidad central queda detrás de un login.

### Funcionalidades

- 🐾 **Mascotas** — registra cada mascota con especie, raza, peso, número de chip, esterilización y una foto.
- 📅 **Agenda veterinaria** — vacunas, controles, desparasitaciones y cualquier evento, con medicamentos y recordatorios locales.
- 📄 **Documentos** — carnet de vacunación, exámenes, recetas y certificados, con seguimiento de vencimiento.
- 🗺️ **Mapa de mascotas perdidas** — reporta una mascota perdida o encontrada con foto, ubicación y contacto de emergencia; revisa los reportes activos en un mapa en vivo. Un invitado puede publicar sin crear cuenta.
- 👤 **Modo invitado real** — funcionalidad completa sin registrarse. Registrarse después conserva todo lo que ya cargaste.
- ☁️ **Sincronización en dos sentidos** — para usuarios registrados, los datos (incluidas fotos y documentos) se sincronizan solos entre dispositivos, con soft-delete y "gana el cambio más reciente" en los conflictos.
- 🌐 **Multi-idioma** — español, inglés y portugués, cambiable desde la app.

### Stack técnico

| Capa | Elección |
|---|---|
| Framework | Flutter (Dart, sin generación de código) |
| Gestión de estado | [Riverpod](https://riverpod.dev) |
| Almacenamiento local | SQLite vía `sqflite` |
| Backend | [Supabase](https://supabase.com) — Postgres, Auth, Storage, Edge Functions |
| Funciones serverless | Deno/TypeScript (borrado de cuenta, correo de reportar bug vía Resend) |
| Mapas | `flutter_map` + `geolocator` |
| Notificaciones | `flutter_local_notifications` |
| Idiomas | `flutter_localizations` + archivos ARB (es/en/pt) |

### Arquitectura

El código sigue una estructura por capas:

```
lib/
├── data/            # Schema SQLite, models (fromMap/toMap manual, sin ORM), repositories
├── providers/        # Gestión de estado con Riverpod
├── services/          # Auth/Storage de Supabase, motor de sync, notificaciones locales, archivos
└── presentation/       # Pantallas, widgets compartidos, tema visual, utils conscientes del idioma
```

Cada entidad que sincroniza (mascotas, eventos de agenda, medicamentos, documentos) usa **soft-delete** en vez de un `DELETE` real, para que un borrado se pueda propagar a otro dispositivo. Los conflictos se resuelven por "gana el cambio más reciente", comparado con un timestamp `actualizado_en` guardado siempre en UTC.

El razonamiento completo de arquitectura y la bitácora de bugs reales encontrados en el camino viven en [`docs/Documentacion/decisiones_arquitectura.md`](docs/Documentacion/decisiones_arquitectura.md). Un mapa visual de cómo se conecta cada pantalla está en [`docs/Documentacion/mapaNavegacion.md`](docs/Documentacion/mapaNavegacion.md) (versión interactiva: `mapaNavegacion.html`). Cada archivo significativo tiene documentación companion en `docs/Documentacion/`, con la misma ubicación relativa que en `lib/`.

### Cómo correrlo

```bash
flutter pub get                     # instalar dependencias
flutter run                          # correr en dispositivo/emulador conectado
flutter test                          # correr los tests
flutter analyze                        # lint estático
flutter build apk --debug               # build de Android debug
flutter build appbundle --release        # build de release firmado (Play Store)
flutter gen-l10n                          # regenerar lib/l10n/*.dart después de tocar los .arb
```

El modo invitado no necesita ninguna configuración. Sincronización en la nube requiere un proyecto de Supabase — el schema completo está en `docs/Planificaciones/TablaMaestraAppVetMovil1.sql`.

### Estado del proyecto

La v1 está completa y probada de punta a punta: mascotas, agenda, documentos, el módulo Mapa, login real y sincronización en dos sentidos están todos implementados y corriendo en producción (`main`). Lo que falta antes de publicar es enteramente administrativo (configuración de Play Console, assets de la ficha, testing cerrado) — seguimiento en `docs/Planificaciones/PublicacionPlayStore.md`.

### Apoyo

Patas al Día es gratuita, sin publicidad ni rastreo de terceros. Si te resulta útil, hay una forma opcional de apoyar el desarrollo: [ko-fi.com/breakpointx](https://ko-fi.com/breakpointx).

---

<a id="english"></a>
## English

### About

**Patas al Día** ("Paws Up to Date") helps pet owners keep track of everything that matters for their animal's health: profiles, a vet schedule with medication reminders, health documents, and a community map for lost/found pets.

The app is built **local-first**: every feature works completely offline, with no account required. Creating an account is entirely optional and only unlocks cross-device sync — nothing about the core experience is gated behind a login.

### Features

- 🐾 **Pets** — register each pet with species, breed, weight, microchip number, spay/neuter status and a photo.
- 📅 **Vet schedule** — vaccines, check-ups, deworming and any other event, with medications and local push reminders.
- 📄 **Documents** — vaccination records, test results, prescriptions and certificates, with expiration tracking.
- 🗺️ **Lost & found map** — report a missing or found pet with photo, location and emergency contact; browse active reports on a live map. Guests can post without creating an account.
- 👤 **Guest mode by design** — full functionality with zero sign-up. Registering later keeps everything you already created.
- ☁️ **Two-way sync** — for registered users, data (including photos and documents) syncs automatically across devices, with soft-delete and last-write-wins conflict resolution.
- 🌐 **Localized** — Spanish, English and Portuguese, switchable in-app.

### Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart, no code generation) |
| State management | [Riverpod](https://riverpod.dev) |
| Local storage | SQLite via `sqflite` |
| Backend | [Supabase](https://supabase.com) — Postgres, Auth, Storage, Edge Functions |
| Serverless functions | Deno/TypeScript (account deletion, bug-report emails via Resend) |
| Maps | `flutter_map` + `geolocator` |
| Notifications | `flutter_local_notifications` |
| Localization | `flutter_localizations` + ARB files (es/en/pt) |

### Architecture

The codebase follows a layered structure:

```
lib/
├── data/            # SQLite schema, models (manual fromMap/toMap, no ORM), repositories
├── providers/        # Riverpod state management
├── services/          # Supabase Auth/Storage, sync engine, local notifications, file storage
└── presentation/       # Screens, shared widgets, theming, i18n-aware utils
```

Every syncable entity (pets, schedule events, medications, documents) uses **soft-delete** instead of real `DELETE`s, so a deletion can propagate to other devices. Conflicts resolve by "most recent change wins," compared by an `actualizado_en` timestamp kept in UTC.

Full architectural reasoning and the log of real bugs found along the way live in [`docs/Documentacion/decisiones_arquitectura.md`](docs/Documentacion/decisiones_arquitectura.md). A visual map of how every screen connects to the next is in [`docs/Documentacion/mapaNavegacion.md`](docs/Documentacion/mapaNavegacion.md) (interactive version: `mapaNavegacion.html`). Every significant file has a companion doc under `docs/Documentacion/`, mirroring its location in `lib/`.

### Getting started

```bash
flutter pub get                     # install dependencies
flutter run                          # run on a connected device/emulator
flutter test                          # run the test suite
flutter analyze                        # static analysis
flutter build apk --debug               # debug Android build
flutter build appbundle --release        # signed release build (Play Store)
flutter gen-l10n                          # regenerate lib/l10n/*.dart after editing the .arb files
```

Guest mode needs no setup at all. Cloud sync requires a Supabase project — the schema lives in `docs/Planificaciones/TablaMaestraAppVetMovil1.sql`.

### Project status

v1 is feature-complete and tested end-to-end: pets, schedule, documents, the map module, real authentication and two-way sync are all implemented and running in production (`main`). What's left before publishing is entirely administrative (Play Console setup, store listing assets, closed testing) — tracked in `docs/Planificaciones/PublicacionPlayStore.md`.

### Support

Patas al Día is free, with no ads and no third-party tracking. If it's useful to you, there's an optional way to support development: [ko-fi.com/breakpointx](https://ko-fi.com/breakpointx).
