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
    - **Conversión de Booleanos:** `recordatorioVencimiento` y `sincronizadoNube` usan la misma técnica tolerante que el resto de los modelos: `map['campo'] == 1 || map['campo'] == true`.
    - **`sincronizadoNube`:** Este campo es clave para la futura sincronización con Supabase — permite saber qué documentos ya se subieron a Storage y cuáles siguen pendientes, sin necesitar una tabla de cola aparte.

### 5. Copia Inmutable (`copyWith()`)

- **En Nuestro Proyecto:** Como todos los campos son `final`, actualizar el estado de sincronización de un documento (por ejemplo, después de subirlo exitosamente a Supabase Storage) se hace con `documento.copyWith(sincronizadoNube: true)`, generando un objeto nuevo con ese único campo cambiado y el resto (`filePath`, `titulo`, `tipoDocumento`, etc.) igual al original.
- **Caso de uso típico:** Además de `sincronizadoNube`, este método sirve para activar `recordatorioVencimiento` sobre un documento ya existente sin tener que reconstruir manualmente los 14 campos del modelo.
