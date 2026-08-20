# Nota de Obsidian: `MascotaExtraviadaModel`

## 📁 Ubicación en el Proyecto

`lib/data/models/mascota_extraviada_model.dart`

Primer modelo del módulo Mapa (v2, ver roadmap en `CLAUDE.md`) y primer modelo del proyecto que **no** habla con SQLite local.

## 🎯 Propósito del Archivo

Mapea un reporte de mascota extraviada, guardado en la tabla `mascotas_extraviadas` de **Supabase** (no de la base local) — ver `docs/Planificaciones/TablaMaestraAppVetMovil1.sql` para el esquema completo y `decisiones_arquitectura.md`, entrada del 2026-08-18, para el porqué de esta decisión.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Los otros tres modelos (`MascotaModel`, `AgendaEventoModel`, `DocumentoModel`) mapean filas de SQLite local — este mapea filas de Supabase (Postgres), directo. La razón es de fondo, no de estilo: el propósito de Mapa es que **otro** usuario, en otro teléfono, vea tu reporte — algo que SQLite local no puede resolver por sí solo. `fromMap`/`toMap` siguen el mismo patrón manual (sin ORM, sin `.g.dart`) que el resto del proyecto, solo que el "mapa" del que hablan es el que devuelve/espera `supabase_flutter`, no `sqflite`.

### 🔄 Por qué es más simple que los otros tres modelos

Postgres tiene tipos nativos que SQLite no tiene — no hace falta la conversión de booleanos `0`/`1` ↔ `bool` que sí necesitan `MascotaModel`/`DocumentoModel` (acá, de hecho, no hay ningún campo booleano). Las fechas siguen viniendo como texto (`timestamptz` serializado a ISO 8601 por Supabase), así que `DateTime.parse()` funciona igual que con SQLite.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. Datos de la mascota denormalizados, no una relación

```dart
final String? mascotaNombre;
final String? mascotaEspecie;
final String? mascotaFotoUrl;
final String? mascotaId; // sin FK — solo referencia local, no se valida contra Supabase
```

El diseño obvio sería que el reporte solo guardara `mascotaId` y fuera a buscar nombre/especie/foto a la tabla `mascotas`. No funciona acá: la tabla `mascotas` de Supabase está vacía (las mascotas hoy solo viven en SQLite local, no hay sync todavía — ver `decisiones_arquitectura.md`). En vez de esa relación, el reporte copia los datos que necesita para mostrarse al momento de publicar. `mascotaId` se mantiene, pero solo como dato informativo local (por ejemplo, para que la app sepa "esta mascota ya tiene un reporte activo") — no es una foreign key real, Postgres no lo valida contra nada.

**Consecuencia a tener presente:** si el usuario edita el nombre de su mascota localmente después de publicar un reporte, el reporte ya publicado no se actualiza solo — sigue mostrando el nombre/foto de cuando se creó. Aceptado a propósito por ser el caso de uso normal (un reporte de mascota perdida es una foto del momento, no algo que deba seguir cambiando).

### 2. `usuarioId` — quién puede editar/borrar el reporte

```dart
final String usuarioId;
```

Como ya no hay relación con `mascotas` para saber el dueño (ver punto 1), el reporte guarda `usuarioId` directo — es el campo que las políticas de Row Level Security de Supabase usan (`usuario_id = auth.uid()`) para permitir editar/borrar solo al dueño, aunque cualquiera pueda *leer* el reporte (lectura pública, ver el `.sql`).

### 3. `id` generado en el cliente, no por Supabase

Igual que el resto de los modelos del proyecto: `id` es un UUID generado con el paquete `uuid` antes de insertar (la tabla no tiene `default gen_random_uuid()`), no algo que Postgres asigne solo. Mantiene el mismo criterio de PKs en todo el proyecto — importante si en el futuro se implementa sync real y hace falta que el mismo id exista en local y en la nube.

### 4. `tipo`/`resuelto` — separados a propósito (2026-08-19, reemplaza al viejo `estado`)

```dart
final String tipo; // 'perdido' o 'encontrado' — no cambia nunca después de creado
final bool resuelto; // false = activo, true = cerrado — lo único que cambia con el tiempo
```

Originalmente había un solo campo `estado` (`'perdido'`/`'encontrado'`) que hacía dos trabajos a la vez: "qué clase de reporte es" y "sigue activo o ya se cerró". Funcionaba mientras solo existía un flujo (reportar una mascota propia perdida — `'perdido'` = activo, `'encontrado'` = resuelto). Se rompió al sumar el flujo "encontré una mascota que no es mía": ese reporte nace con naturaleza *encontrado* pero necesita seguir **activo** (visible en el mapa, para que alguien la reconozca) hasta que se resuelva — algo que el viejo `estado = 'encontrado'` no podía representar, porque ese mismo valor ya significaba "cerrado".

La separación resuelve la ambigüedad: `tipo` clasifica el reporte (se fija al crearlo, nunca se actualiza), `resuelto` es el único campo que cambia al cerrar un reporte — sea cual sea su `tipo`. El mapa/lista de "activos" siempre filtra por `resuelto = false` (ver `MascotaExtraviadaRepository.obtenerReportesActivos`), sin mirar `tipo` para nada. Ninguno de los dos se valida en el modelo — `tipo` tiene su propio `check` en la base (`TablaMaestraAppVetMovil1.sql`), mismo criterio que el resto de las listas fijas del proyecto (especie, tipo de evento, etc., ver `sistemaIdiomas.md`).
