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
    - **Conversión de Fechas Dobles:** `fechaProgramada` siempre se parsea con `DateTime.parse()` sin verificación de nulos (porque nunca es nula). `fechaRealizada` sí se verifica antes de parsear, ya que la mayoría de los eventos recién creados no tienen fecha de cumplimiento aún.
    - **`recordatorioHorasAntes`:** `List<int>` (no nullable, `[]` por defecto) — cuántas horas antes de `fechaProgramada` se dispara una notificación local; un evento puede tener varios recordatorios a la vez (ej. `[24, 1]` avisa un día antes y también una hora antes). Lista vacía = sin recordatorios. En SQLite se guarda como texto separado por comas (`"24,1"`, columna `TEXT`) en vez de una tabla hija aparte — es un conjunto chico y cerrado de enteros sin identidad propia, no ameritaba el mismo tratamiento que `medicamentos_evento`.

**Cambios del 2026-08-14:** se sacaron `notificacionesActivas` (bool) y `repetirCadaMeses` (int?), que existían en la primera versión de este modelo.
- `notificacionesActivas` quedó redundante en cuanto se agregó `recordatorioHorasAntes`: tener un booleano *y* un valor nullable para lo mismo ("¿hay recordatorio?") podía quedar en estados contradictorios (`notificacionesActivas = true` pero `recordatorioHorasAntes = null`, por ejemplo). Ahora `recordatorioHorasAntes == null` es la única fuente de verdad para "sin recordatorio".
- `repetirCadaMeses` se sacó por pedido explícito del usuario: quedaba redundante con la función "Programar próxima consulta" del formulario (ver `formularioAgendaEventoScreen.md`), que resuelve la misma necesidad (agendar un evento de seguimiento) de forma más flexible — el usuario elige el día exacto en vez de depender de una cadencia fija en meses.

### 3. Método de Serialización (`toMap()`)

- **En Nuestro Proyecto:** Empaqueta el objeto de vuelta a las columnas exactas de `agenda_eventos`, incluyendo el truco `fechaRealizada?.toIso8601String()` — el operador `?.` evita lanzar un error si el evento aún no fue realizado, guardando `null` directamente en la columna.

### 4. Copia Inmutable (`copyWith()`)

- **En Nuestro Proyecto:** Como todos los campos son `final`, "completar" un evento (pasar de agendado a realizado) no se puede hacer mutando el objeto — se genera uno nuevo con `evento.copyWith(fechaRealizada: DateTime.now())`. El resto de los campos (`titulo`, `fechaProgramada`, `recordatorioHorasAntes`, etc.) se conservan automáticamente gracias al operador `??` dentro del método, que solo reemplaza el campo que se le pasa explícitamente.
- **Caso de uso típico:** `DetalleAgendaEventoScreen` usa exactamente este patrón para el switch "Marcar como realizado" — ver `detalleAgendaEventoScreen.md`.
