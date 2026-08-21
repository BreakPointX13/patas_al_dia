# Nota de Obsidian: `DatabaseHelper` (El Motor de SQLite)

## 📁 Ubicación en el Proyecto

`lib/data/database/database_helper.dart`

## 🎯 Propósito del Archivo

Este archivo centraliza el acceso a la base de datos local SQLite (`sqflite`). Su objetivo es inicializar el archivo físico de la base de datos dentro del dispositivo móvil, ejecutar el script de creación de las 5 tablas que estructuramos y proveer un punto de acceso único y seguro para que cualquier pantalla o repositorio de la app pueda realizar consultas sin corromper los archivos internos.

---

## 🏗️ Concepto Avanzado de Dart: Entendiendo `static`

### 🏛️ En un Proyecto Estándar de la Industria

En la programación orientada a objetos (POO), cuando creas una variable o un método dentro de una clase, estos le pertenecen a las **instancias** (los objetos creados con `new` o mediante constructores). Si creas 100 objetos, la memoria del sistema creará 100 copias independientes de esas variables.

Sin embargo, hay escenarios donde necesitas que un dato o función le pertenezca a **la clase en sí misma** y no a sus hijos. Para esto sirve la palabra clave `static`.

### 🐾 En Nuestro Proyecto "Patas al día"

En el `DatabaseHelper` combinamos `static` con un patrón de diseño llamado **Singleton**. Analicemos esta sección de tu código:

Dart

```
class DatabaseHelper {
  // 1. Un constructor privado que nadie fuera de esta clase puede usar
  DatabaseHelper._internal();

  // 2. Una variable estática que almacena la ÚNICA instancia de la clase
  static final DatabaseHelper instance = DatabaseHelper._internal();

  // 3. Una variable estática para controlar la base de datos en memoria
  static Database? _database;
}
```

### 🔄 Comparativa: ¿Por qué es vital usar `static` aquí?

- **Sin `static` (Código erróneo o ineficiente):** Cada vez que quisieras guardar una mascota o ver la agenda, tendrías que hacer `var helper = DatabaseHelper();`. Esto intentaría abrir un canal de comunicación nuevo con el archivo físico `.db` del teléfono. En dispositivos móviles, abrir múltiples conexiones simultáneas al mismo archivo genera un bloqueo de lectura/escritura (Database Locked), lo que colapsaría tu app en el S24 Ultra.
    
- **Con `static` (Nuestro Enfoque):** Al declarar `instance` y `_database` como estáticos, estas variables se alojan en una zona de memoria global y permanente de la app. No importa cuántas pantallas tenga la app, todas llamarán a `DatabaseHelper.instance`. Existe **una sola conexión** compartida, protegiendo la integridad del almacenamiento local.
    

---

## 🗺️ Mapa de Conexión Conceptual (El Patrón Singleton)

- **Restricción de Acceso:** El constructor privado (`._internal()`) bloquea la creación libre de objetos.
    
- **Canal Único:** La propiedad `static` actúa como una aduana centralizada. Si la base de datos ya está abierta, te devuelve la conexión existente; si no, la abre por primera vez de forma asíncrona.
    

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. Propiedad Asíncrona `Future<Database> get database`

- **Definición Estándar:** Un método de tipo _Getter_ expone una propiedad de manera controlada. Al combinarlo con un proceso asíncrono (`Future`), le indica al procesador del teléfono que la operación puede demorar milisegundos en leer el hardware de almacenamiento y que no debe "congelar" la interfaz de usuario mientras lo hace.
    
- **En Nuestro Proyecto:** Evalúa si la variable interna `_database` ya tiene una conexión activa. Si existe, la retorna de inmediato (`return _database!`); si está vacía, manda a llamar al inicializador.
    
- **Comparativa:** En sistemas de escritorio pesados, las conexiones suelen abrirse al iniciar la app y se dejan abiertas permanentemente. En entornos móviles (Flutter), aplicamos una técnica llamada **Lazy Initialization** (Inicialización Perezosa): la base de datos solo consume memoria del teléfono en el momento exacto en que el usuario interactúa con un dato por primera vez, optimizando el rendimiento general del sistema.
    

### 2. Función `_initDatabase()` y la Directiva `join()`

- **Definición Estándar:** La inicialización de persistencia requiere mapear rutas físicas del sistema operativo anfitrión. La función `join()` del paquete `path` resuelve las discrepancias de sintaxis de directorios entre plataformas.
    
- **En Nuestro Proyecto:** Recupera la ruta segura de la app en Android mediante `getDatabasesPath()` y concatena de forma nativa el nombre de tu archivo: `'patas_al_dia.db'`.
    
- **Comparativa:** Al usar `join(dbPath, 'patas_al_dia.db')` en lugar de concatenar texto plano con operadores como `+ '/' +`, el código cumple con los principios de código limpio de multiplataforma. Si el día de mañana pruebas la app en Windows, iOS o Linux, el código no sufrirá roturas por culpa de los separadores de carpetas (`/` frente a `\`).
    

### 3. Método de Callback `_onCreate(Database db, int version)`

- **Definición Estándar:** Las librerías de persistencia móvil utilizan eventos de ciclo de vida (_Callbacks_) para estructurar el almacenamiento inicial. `onCreate` es un disparador condicional controlado por el framework.
    
- **En Nuestro Proyecto:** Ejecuta de manera secuencial los bloques `db.execute(...)` que contienen las 5 tablas estructuradas de tu esquema normalizado.
    
- **Lógicas Complejas y Comparativa:**
    
    - **Ejecución Única:** Este método no se ejecuta cada vez que se abre la app; la librería `sqflite` detecta de forma inteligente si el archivo `.db` ya existe en el almacenamiento. Si existe, se salta este paso, acelerando el tiempo de carga de la aplicación.
        
    - **Traducción SQL a SQLite:** Como SQLite almacena datos de forma compacta en el dispositivo, tus restricciones complejas de PostgreSQL o SQL Server se adaptaron automáticamente en este bloque: las llaves primarias universales se definieron como `TEXT` (para soportar tus `UUID`), y las relaciones de borrado automatizado (`ON DELETE CASCADE`) se delegaron directamente a las llaves foráneas (`FOREIGN KEY`), garantizando que si se elimina un registro de usuario o mascota en el teléfono, no queden datos huérfanos ocupando almacenamiento de forma innecesaria.

### 4. Columna `sesion_activa` en `usuarios`

- **El Problema:** al reabrir la app, no había ninguna forma de saber si ya existía un usuario (invitado o registrado) en este dispositivo — cada arranque mostraba `LoginScreen` de nuevo y creaba un usuario invitado *nuevo*, dejando huérfanas (a nivel de sesión, no de base de datos) las mascotas del usuario anterior.
- **La Solución:** columna `sesion_activa INTEGER DEFAULT 1`. `SesionInicialScreen` consulta `WHERE sesion_activa = 1` al arrancar; si encuentra una fila, la app entra directo a `HomeScreen` con ese usuario. "Cerrar sesión" (desde `AjustesScreen`) no borra la fila — solo pone `sesion_activa = 0`, para que los datos del invitado sigan intactos si vuelve a entrar más adelante.
- **Nota de esquema:** este cambio se aplicó directo en `_onCreate` sin migración (`onUpgrade`), siguiendo la decisión ya registrada en `decisiones_arquitectura.md` de que, durante desarrollo sin usuarios reales, los cambios de esquema se resuelven reinstalando la app.

### 5. Tabla `medicamentos_evento` (nueva, 2026-08-14)

- **El problema:** un evento de agenda puede tener más de un medicamento recetado (ej. una consulta donde se recetan dos tratamientos distintos), cada uno con su propia presentación (comprimido, líquido, inyectable...) y observaciones. Guardar eso en un solo campo de texto en `agenda_eventos` (como existía antes, `medicamento_prescrito`) no alcanza para varios medicamentos estructurados.
- **La solución:** tabla hija nueva, mismo patrón que `agenda_eventos` colgando de `mascotas`: `medicamentos_evento` tiene `agenda_evento_id` como FOREIGN KEY hacia `agenda_eventos.id`, con `ON DELETE CASCADE` (si se borra el evento, sus medicamentos se borran con él — a diferencia de `documentos`, acá no hay razón para conservar un medicamento sin su evento). Ver `medicamentoEvento.model.md`.
- **De paso:** se sacó la columna `medicamento_prescrito` de `agenda_eventos` (reemplazada por esta tabla) y se agregó `recordatorio_horas_antes` (reemplaza a `notificaciones_activas`, ver `agendaEvento.model.md` para el porqué).
- **`recordatorio_horas_antes` cambió de `INTEGER` a `TEXT` (2026-08-16):** un evento pasó a poder tener varios recordatorios a la vez (ej. avisar 1 día y también 1 hora antes) — se guardan como texto separado por comas (`"24,1"`), no una tabla hija aparte (ver `agendaEvento.model.md` para el porqué).
- **Columna `tipo_evento_personalizado` agregada a `agenda_eventos` (2026-08-16):** `tipo_evento` dejó de ser texto libre para pasar a una lista fija de 7 valores (ver `agendaEvento.model.md`); esta columna nueva guarda el texto libre solo para la opción "Otro", mismo patrón que `tipo_documento_personalizado` en `documentos`. Igual que el resto de los cambios de esquema en esta etapa, se aplicó reinstalando la app en vez de con una migración.

### 6. Columna `especie_personalizada` agregada a `mascotas` (2026-08-17)

Mismo patrón que `tipo_evento_personalizado`: `especie` en `MascotaModel` pasó de texto libre a una lista fija (ver `mascota.model.md`), y esta columna nueva guarda el texto libre solo para la opción "Otro". Aplicado reinstalando la app, siguiendo la misma política de esquema en desarrollo (ver `decisiones_arquitectura.md`).

### 7. Columnas `escala_texto`, `tema` e `idioma` agregadas a `usuarios` (2026-08-17/18)

Tres preferencias de accesibilidad nuevas, guardadas junto al usuario con el mismo criterio que `sesion_activa` (punto 4): `escala_texto REAL DEFAULT 1.0` (tamaño de letra), `tema TEXT DEFAULT 'sistema'` (claro/oscuro/sistema) e `idioma TEXT DEFAULT 'sistema'` (es/en/pt/sistema, ver `sistemaIdiomas.md`). Ver `usuario.model.md` y `ajustesScreen.md`. Las tres se pierden si el invitado desinstala la app — comportamiento esperado, coherente con que el resto de sus datos tampoco sobrevive a una desinstalación.

### 8b. `onConfigure: _onConfigure` — `PRAGMA foreign_keys = ON` (2026-08-19, corrige el punto 3)

```dart
return await openDatabase(path, version: 1, onConfigure: _onConfigure, onCreate: _onCreate);

Future<void> _onConfigure(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
}
```

**El punto 3 de esta nota decía algo que no era del todo cierto:** declarar `ON DELETE CASCADE` en el `FOREIGN KEY` de una tabla no alcanza por sí solo en SQLite — el motor **no aplica ningún cascade** (ni ninguna otra restricción de clave foránea) salvo que la conexión tenga `PRAGMA foreign_keys = ON` activado explícitamente. Este proyecto nunca lo activaba, así que borrar una mascota (o un usuario) dejaba huérfanas sus filas hijas en la base local en vez de borrarlas en cascada, aunque el schema "dijera" lo contrario. Hallazgo pendiente desde Login real (2026-08-19), corregido acá al implementar "Eliminar cuenta" (ver `decisiones_arquitectura.md` y `usuario.repository.md`) — necesitaba el cascade real para que borrar la cuenta de un invitado limpie de verdad sus mascotas/agenda/documentos, no solo la fila de `usuarios`.

**`onConfigure`, no `onCreate`, para esto:** `onCreate` corre una sola vez, la primera vez que el archivo `.db` se crea (ver punto 3) — pero `PRAGMA foreign_keys` es una configuración **de la conexión**, no del archivo: hay que reactivarla cada vez que la app abre la base, no solo la primera. `onConfigure` corre siempre, antes que `onCreate`/`onUpgrade`, exactamente para este tipo de configuración.

### 8. Columna `aviso_mapa_visto` agregada a `usuarios` (2026-08-19)

`aviso_mapa_visto INTEGER DEFAULT 0` — mismo criterio que `sesion_activa`/`escala_texto`/`tema`/`idioma`: marca si el usuario ya vio el aviso de política de uso del módulo Mapa, para no mostrarlo de nuevo en cada visita a esa pestaña. Ver `usuario.model.md` y `mapaScreen.md`. Aplicado reinstalando la app, siguiendo la misma política de esquema en desarrollo (ver `decisiones_arquitectura.md`) — no existe en la tabla `usuarios` de Supabase, es un estado puramente local.

### 9. Sync (2026-08-20/21) — `actualizado_en`, `eliminado`/`eliminado_en`, `foto_ruta_nube`/`archivo_ruta_nube`, `pendiente_push`, `documentos.file_path` pasa a nullable

Columnas nuevas en las 4 tablas que participan del sync (`mascotas`, `agenda_eventos`, `medicamentos_evento`, `documentos` — **no** `mascotas_extraviadas`, que tiene su propio mecanismo, ver `mascotaExtraviada.repository.md`). Ver `syncService.md` para el motor completo y `mascota.model.md`/`mascota.repository.md` para el detalle de cada campo.

- **`actualizado_en TEXT`**: marca de última modificación, siempre en UTC (ver `mascota.model.md`, punto 7, para el bug real que costó encontrar esto).
- **`eliminado INTEGER DEFAULT 0` / `eliminado_en TEXT`**: soporte de soft-delete — un `DELETE` real no deja rastro que sincronizar a otro dispositivo.
- **`pendiente_push INTEGER DEFAULT 0`** (2026-08-21, agregado un día después que las otras — ver el hallazgo abajo): marca "esto lo tocó este dispositivo y todavía no se subió". Es una columna **puramente local** — no existe su equivalente en Supabase (no hace falta que el servidor sepa qué dispositivo tiene pendiente empujar qué).
  - **El problema que resuelve:** la primera versión del motor de sync decidía qué empujar mirando si `actualizado_en` era más reciente que la última sincronización exitosa. Eso no distingue "lo edité yo en este dispositivo" de "esta fila tiene una fecha reciente porque la acabo de traer por pull" — una fila recién traída se volvía a empujar en la corrida siguiente, pisando sin darse cuenta cualquier cambio más nuevo que hubiera llegado de otro dispositivo mientras tanto. Encontrado probando el checkpoint de la Fase 3 del plan de Sync. Ver `decisiones_arquitectura.md`.
- **`foto_ruta_nube TEXT` en `mascotas` / `archivo_ruta_nube TEXT` en `documentos`** (reemplaza a la columna `sincronizado_nube INTEGER`, que existía desde el esquema original sin usarse en ningún lado del código — confirmado, código muerto): la ruta del archivo dentro del bucket privado de Storage correspondiente, no una URL — un bucket privado no tiene URL pública estable.
- **`documentos.file_path` pasó de `TEXT NOT NULL` a `TEXT`** (2026-08-21, corrige un bug real, no solo un ajuste): un documento traído de otro dispositivo por pull puede no tener el archivo descargado todavía (o la descarga puede fallar por red) — intentar guardar esa fila con `file_path` obligatorio hacía que `guardarDesdeSync` reventara con `NOT NULL constraint failed` a mitad de la sincronización, cortando el resto de la corrida. El lado de Postgres (`TablaMaestraAppVetMovil1.sql`) ya era nullable desde que se diseñó el schema completo; esta columna local se había dejado `NOT NULL` a propósito, bajo el supuesto (incorrecto) de que "toda fila activa localmente siempre tiene un archivo" — cierto antes de Sync, falso apenas existe la posibilidad de traer una fila sin haber descargado su archivo todavía.
- **Aplicado reinstalando la app**, misma política de esquema en desarrollo que el resto de los cambios de esta lista (ver `decisiones_arquitectura.md`).