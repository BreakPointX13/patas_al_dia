# Nota de Obsidian: `AgendaEventoModel`

## 📁 Ubicación en el Proyecto

`lib/data/models/agenda_evento_model.dart`

## 🎯 Propósito del Archivo

Este archivo define la clase de mapeo para los eventos de la agenda veterinaria (vacunas, controles, desparasitaciones, etc.). Traduce las filas de la tabla `agenda_eventos` de SQLite en objetos `AgendaEventoModel` fuertemente tipados, siguiendo exactamente el mismo patrón de traducción que `MascotaModel`.

---

## 🗺️ Mapa de Conexión Conceptual (Traducción de Datos)

### 🏛️ En un Proyecto Estándar de la Industria

Los sistemas de agenda o calendario en producción (Google Calendar, apps de salud, sistemas veterinarios profesionales) separan siempre dos conceptos: el **evento planificado** (cuándo debería pasar) y el **evento realizado** (cuándo pasó realmente, si es que pasó). Modelar esto como dos campos de fecha independientes, en vez de sobrescribir uno solo, es el estándar para no perder el historial de cumplimiento.

### 🐾 En Nuestro Proyecto "Patas al día"

`AgendaEventoModel` refleja esa separación con `fechaProgramada` (obligatoria, el evento siempre se agenda a futuro) y `fechaRealizada` (opcional, se llena recién cuando el dueño marca la vacuna o control como completado). Esto permite, por ejemplo, mostrar en la UI eventos "atrasados" comparando `fechaProgramada` con la fecha actual mientras `fechaRealizada` siga en `null`.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** Muchos sistemas de agenda usan un solo campo `fecha` y un booleano `completado`, perdiendo el dato de cuándo se cumplió realmente el evento.
- **Nuestro Enfoque:** Al tener `fechaProgramada` y `fechaRealizada` por separado, conservamos ambos datos, lo que habilita features futuras como "tu perro se vacunó 3 días después de lo programado" sin cambiar el esquema.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `fechaProgramada` no nullable vs `fechaRealizada` nullable

- **Definición Estándar:** No todos los campos de fecha tienen el mismo nivel de certeza. Un dato planificado a futuro es conocido de antemano; un dato de cumplimiento solo existe una vez que el hecho ocurrió.
- **En Nuestro Proyecto:** `fechaProgramada` se declara `DateTime` (obligatorio, sin `?`) porque un evento de agenda no existe sin fecha planificada — así lo exige también la columna SQL (`NOT NULL`). `fechaRealizada` se declara `DateTime?` porque al crear el evento todavía no se cumplió.
- **Comparativa:** Si ambos campos fueran nullable, tendríamos que validar en cada pantalla si el evento "existe" comprobando que `fechaProgramada != null`. Al forzarlo como obligatorio desde el modelo, esa validación es innecesaria: si el objeto existe, tiene fecha programada.

### 2. Constructor de Fábrica (`factory AgendaEventoModel.fromMap`)

- **En Nuestro Proyecto:** Igual que en `MascotaModel`, toma la fila cruda de SQLite (`Map<String, dynamic>`) y arma el objeto tipado.
- **Lógicas Complejas:**
    - **Conversión de Booleano (`notificacionesActivas`):** Misma técnica que `esterilizado` en `MascotaModel`: `map['notificaciones_activas'] == 1 || map['notificaciones_activas'] == true`, para tolerar tanto el `INTEGER` de SQLite como un futuro `bool` real desde Supabase.
    - **Conversión de Fechas Dobles:** `fechaProgramada` siempre se parsea con `DateTime.parse()` sin verificación de nulos (porque nunca es nula). `fechaRealizada` sí se verifica antes de parsear, ya que la mayoría de los eventos recién creados no tienen fecha de cumplimiento aún.
    - **`repetirCadaMeses` opcional:** Se castea a `int?` solo si el dato existe. Representa la recurrencia del evento (ej. `3` para un control cada 3 meses); si es `null`, el evento no se repite automáticamente.

### 3. Método de Serialización (`toMap()`)

- **En Nuestro Proyecto:** Empaqueta el objeto de vuelta a las columnas exactas de `agenda_eventos`, incluyendo el truco `fechaRealizada?.toIso8601String()` — el operador `?.` evita lanzar un error si el evento aún no fue realizado, guardando `null` directamente en la columna.
