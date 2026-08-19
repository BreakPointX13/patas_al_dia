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
final String mascotaNombre;
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

### 4. `estado` — `'perdido'`/`'encontrado'`, validado en la base, no en el modelo

El modelo no valida que `estado` sea uno de esos dos valores — esa validación vive en la base (`check (estado in ('perdido', 'encontrado'))` en el `.sql`), mismo criterio que el resto de las listas fijas del proyecto (especie, tipo de evento, etc., ver `sistemaIdiomas.md`), donde el modelo confía en que quien construye el objeto ya eligió un valor válido (típicamente desde un `DropdownButtonFormField`).
