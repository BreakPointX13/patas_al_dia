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