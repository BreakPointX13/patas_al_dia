# Nota de Obsidian: `DocumentoModel`

## 📁 Ubicación en el Proyecto

`lib/data/models/documento_model.dart`

## 🎯 Propósito del Archivo

Este archivo define la clase de mapeo para los documentos adjuntos de cada mascota (carnet de vacunación, exámenes, recetas, etc.). Traduce las filas de la tabla `documentos` de SQLite en objetos `DocumentoModel` fuertemente tipados, siguiendo el mismo patrón de traducción que `MascotaModel` y `AgendaEventoModel`.

---

## 🗺️ Mapa de Conexión Conceptual (Traducción de Datos)

### 🏛️ En un Proyecto Estándar de la Industria

Los sistemas que gestionan archivos adjuntos (gestores documentales, historiales clínicos digitales) casi nunca guardan el archivo binario directo en la base de datos relacional: guardan una **referencia** (ruta o URL) y metadatos sobre ese archivo (tipo, fecha, vencimiento). Esto mantiene la base de datos liviana y delega el almacenamiento pesado a un sistema de archivos o storage especializado.

### 🐾 En Nuestro Proyecto "Patas al día"

`DocumentoModel` no guarda el PDF o la foto del examen dentro de SQLite: guarda `filePath`, la ruta local del archivo en el dispositivo (y a futuro, la URL de Supabase Storage cuando el usuario deje de ser invitado). Además modela una **relación opcional** con `agenda_eventos` a través de `eventoId` — un documento puede nacer suelto (ej. subís una foto vieja de una cirugía) o puede estar asociado a un evento puntual de la agenda (ej. el certificado que te entregan tras aplicar una vacuna).

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** Muchos sistemas usan categorías de documento fijas y cerradas (un enum rígido), obligando a rediseñar el esquema cada vez que aparece un tipo de documento nuevo.
- **Nuestro Enfoque:** `tipoDocumento` es un `String` abierto, respaldado por `tipoDocumentoPersonalizado` como campo de escape: si el usuario elige la opción "otro" en la UI, describe libremente el tipo de documento sin que el desarrollador tenga que tocar el esquema SQL.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. Relación Opcional con la Agenda (`eventoId`)

- **Definición Estándar:** Una **Foreign Key opcional** (nullable) modela una relación de "cero o uno", a diferencia de una FK obligatoria que siempre exige un padre.
- **En Nuestro Proyecto:** `eventoId` es `String?` y en SQL usa `ON DELETE SET NULL` (a diferencia de las demás relaciones del proyecto que usan `CASCADE`). Esto es intencional: si se borra un evento de la agenda, el documento asociado **no se borra**, solo pierde su vínculo. El dueño no debería perder el PDF de un examen solo porque eliminó el recordatorio de agenda que lo generó.

### 2. Patrón "Tipo + Personalizado" (`tipoDocumento` / `tipoDocumentoPersonalizado`)

- **En Nuestro Proyecto:** `tipoDocumento` es obligatorio (`NOT NULL` en SQL) y contiene la categoría elegida (ej. `"vacuna"`, `"examen"`, `"otro"`). `tipoDocumentoPersonalizado` es opcional y solo se llena cuando `tipoDocumento == "otro"`.
- **Ventaja:** La UI puede seguir mostrando una lista corta y ordenada de categorías predefinidas sin bloquear al usuario que tiene un caso raro (ej. "certificado de esterilización internacional").

### 3. Doble Fecha con Truncado (`fechaEmision` / `fechaVencimiento`) vs Fecha Completa (`fechaSubida`)

- **Definición Estándar:** No todas las fechas de un sistema necesitan la misma precisión. Una fecha de emisión de documento solo importa a nivel de día; una marca de auditoría de subida sí importa a nivel de segundo.
- **En Nuestro Proyecto:**
    - `fechaEmision` y `fechaVencimiento` se truncan con `.toIso8601String().split('T')[0]`, igual que `fechaNacimiento` en `MascotaModel`, porque en SQL son columnas `DATE`.
    - `fechaSubida` se guarda completa con `.toIso8601String()` (incluye hora), porque en SQL es `TIMESTAMP` y sirve como marca de auditoría de cuándo se subió el archivo al dispositivo.

### 4. Constructor de Fábrica (`factory DocumentoModel.fromMap`) y `toMap()`

- **Lógicas Complejas:**
    - **Conversión de Booleanos:** `recordatorioVencimiento` y `eliminado` (ver punto 6) usan la misma técnica tolerante que el resto de los modelos: `map['campo'] == 1 || map['campo'] == true`.

### 5. Copia Inmutable (`copyWith()`)

- **En Nuestro Proyecto:** Como todos los campos son `final`, actualizar un documento (por ejemplo, después de subirlo exitosamente a Supabase Storage) se hace con `documento.copyWith(archivoRutaNube: ruta)`, generando un objeto nuevo con ese único campo cambiado y el resto (`filePath`, `titulo`, `tipoDocumento`, etc.) igual al original.
- **Caso de uso típico:** Además de `archivoRutaNube`, este método sirve para activar `recordatorioVencimiento` sobre un documento ya existente sin tener que reconstruir manualmente todos los campos del modelo.

### 6. Sync (2026-08-20) — `actualizadoEn`/`eliminado`/`eliminadoEn`, `archivoRutaNube` reemplaza a `sincronizadoNube`, `filePath` pasa a nullable

- **`sincronizadoNube` (booleano) se borró** — quedó desde el esquema original sin usarse en ningún lado del código (confirmado, código muerto). En su lugar, `archivoRutaNube` (`String?`) guarda la ruta real del archivo dentro del bucket de Storage una vez subido — no un booleano suelto, la ruta en sí (necesaria para poder descargarlo desde otro dispositivo). Ver `documento.repository.md`, puntos 7-8.
- **`filePath` pasó de `String` obligatorio a `String?`** — es **local-only** (nunca viaja a Supabase, nunca se sobreescribe con un pull). Un documento traído de otro dispositivo por sync puede no tener el archivo descargado todavía (solo `archivoRutaNube`, apuntando a Storage) — esa es la razón real del cambio: antes de Sync, todo documento visible ya tenía su archivo local por definición (se creaba junto con el archivo elegido en el formulario); con Sync, "existe la fila" y "el archivo ya está en este dispositivo" pasaron a ser dos cosas distintas en el tiempo. `DetalleDocumentoScreen`/`DetalleAgendaEventoScreen` muestran un ícono de "descarga pendiente" (`Icons.cloud_download_outlined`) cuando `filePath` es `null`.
- **`actualizadoEn`/`eliminado`/`eliminadoEn`**: mismo patrón que el resto de las entidades sincronizadas — ver `mascota.model.md`, punto 7, para el detalle completo (soft-delete, conflictos por timestamp, por qué `actualizadoEn` se guarda siempre en UTC).
