c# Nota de Obsidian: `MascotaModel`

## 📁 Ubicación en el Proyecto

`lib/data/models/mascota_model.dart`

## 🎯 Propósito del Archivo

En este archivo creamos la clase de mapeo para el objeto `Mascota` en Flutter (Dart). Funciona como un traductor que transforma los datos planos e inestructurados de la base de datos SQLite en objetos fuertemente tipados con Null Safety en la memoria de la aplicación.

---

## 🗺️ Mapa de Conexión Conceptual (Traducción de Datos)

### 🏛️ En un Proyecto Estándar de la Industria

En el desarrollo de software profesional, las aplicaciones nunca interactúan directamente con las bases de datos utilizando los formatos nativos del motor. En su lugar, se implementa una capa llamada **Mapeo de Datos (Data Mapping)** o un **ORM/ODM (Object-Relational Mapping)**. El estándar dicta que los datos viajan en estructuras genéricas (como archivos JSON o mapas clave-valor) para desacoplar el almacenamiento de la interfaz. Si no se tipan estos datos inmediatamente, cualquier error de escritura en el nombre de una columna (ej. escribir `nombree` en vez de `nombre`) causará que la aplicación se caiga en tiempo de ejecución sin previo aviso.

### 🐾 En Nuestro Proyecto "Patas al día"

Para evitar la sobrecarga que un ORM pesado implicaría en un dispositivo móvil, implementamos un mapeo manual pero estructurado. Como SQLite nos entrega la información de tus gatos o perros en un mapa rústico (`Map<String, dynamic>`), creamos este archivo para que actúe como un puesto de control aduanero. El código captura ese mapa y lo transforma de inmediato en una clase de Dart fuertemente tipada.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** Suele depender de librerías externas de generación de código (como `json_serializable` o `freezed`), lo que añade complejidad al compilador y archivos adicionales (`.g.dart`).
    
- **Nuestro Enfoque:** Al escribir los métodos de conversión de forma explícita y nativa, mantenemos el proyecto ligero, eliminamos dependencias que ralenticen tu MSI y mantienes el control total sobre cómo se procesa cada dato (ideal para un portafolio donde debes explicar cada línea).
    

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. Variables de Instancia con Null Safety (`final` y `?`)

- **Definición Estándar:** En lenguajes de programación modernos, el estándar es el _Null Safety_ (Seguridad contra Nulos). Evita el clásico error de la industria: el `NullPointerException` (cuando una app intenta leer un dato que no existe y se cierra inesperadamente). Las propiedades inmutables (`final`) aseguran que el estado del objeto no cambie de forma caótica en la memoria.
    
- **En Nuestro Proyecto:** Campos mandatorios como el `id` o el `nombre` se declaran estrictamente requeridos. Campos como `numero_chip` o `rut_mascota` se definen como opcionales usando el signo de interrogación (`String?`).
    
- **Comparativa:** A diferencia de esquemas de bases de datos tradicionales donde un valor nulo puede romper la consistencia si no se valida en cada consulta, nuestro modelo absorbe la opcionalidad desde el origen. Si el gato no tiene chip, la app lo sabe de manera segura y no genera excepciones al renderizar la interfaz en tu S24 Ultra.
    

### 2. Constructor de Fábrica (`factory MascotaModel.fromMap`)

- **Definición Estándar:** El patrón de diseño _Factory_ (Fábrica) se utiliza en la arquitectura de software cuando la creación de un objeto requiere una lógica previa o un procesamiento de datos antes de entregar la instancia lista. En un desarrollo estándar, se usa para instanciar clases abstractas o procesar respuestas de APIs.
    
- **En Nuestro Proyecto:** Este constructor toma la fila que devuelve SQLite (`Map<String, dynamic>`) y procesa sus tipos primitivos para transformarlos en tipos complejos de Dart.
    
- **Lógicas Complejas y Comparativa:**
    
    - **Conversión de Booleanos:** * _Estándar:_ Los motores de base de datos modernos tienen el tipo `BOOLEAN`.
        
        - _SQLite:_ No lo tiene, usa enteros `0` (falso) o `1` (verdadero).
            
        - _Nuestra Solución:_ Evaluamos `map['esterilizado'] == 1 || map['esterilizado'] == true`. Esto unifica ambos mundos: si el dato viene de SQLite local como entero o si en el futuro viene de la nube como booleano real, el modelo no se romperá y siempre entregará un `bool` limpio a tus pantallas.
            
    - **Conversión de Fechas:**
        
        - _Estándar:_ Las fechas se manejan como marcas de tiempo Unix o estructuras complejas nativas.
            
        - _Nuestra Solución:_ SQLite nos entrega un texto plano (`String`). Usamos `DateTime.parse()` para reconstruir el objeto cronológico en Dart, permitiéndote usar funciones de tiempo nativas más adelante (como calcular cuántos meses le faltan a la mascota para su próxima vacuna).
            
    - **Conversión Numérica Precisa:**
        
        - _Estándar:_ Los subtipos numéricos pueden colisionar si el procesador del teléfono interpreta un entero cuando esperaba un decimal.
            
        - _Nuestra Solución:_ Forzamos el casteo con `(map['peso_actual'] as num).toDouble()`. Esto previene caídas si el usuario ingresa un peso exacto como `5` en lugar de `5.0`.
            

### 3. Método de Serialización (`toMap()`)

- **Definición Estándar:** Es el proceso inverso a la deserialización. En la industria, antes de enviar datos a través de una red (API REST) o guardarlos en un disco, el objeto en memoria debe convertirse en un flujo de bytes estructurado o en un formato relacional simple.
    
- **En Nuestro Proyecto:** Desarma las propiedades del objeto Dart y las empaqueta de vuelta en las columnas exactas que definimos en tu script SQL.
    
- **Lógicas Complejas y Comparativa:**
    
    - **Truncado de Fechas:** Al guardar la fecha de nacimiento, ejecutamos `fechaNacimiento?.toIso8601String().split('T')[0]`. El estándar ISO8601 genera una cadena completa con hora y zona horaria (ej. `2023-05-17T06:41:00Z`). Como para el nacimiento de un animal solo nos importa el día, nuestra lógica divide el texto en la letra `T` y se queda solo con la primera parte (`YYYY-MM-DD`). Esto optimiza el espacio de almacenamiento en el móvil y estandariza las búsquedas por fecha en la base de datos.

### 4. Copia Inmutable (`copyWith()`)

- **Definición Estándar:** Como todas las propiedades son `final`, una vez creado el objeto no se puede modificar (ver punto 1). El patrón `copyWith` es el estándar de la industria para "actualizar" un objeto inmutable: en vez de mutarlo, se construye uno nuevo idéntico salvo por los campos que se le indiquen explícitamente.
- **En Nuestro Proyecto:** `copyWith()` recibe los mismos campos que el constructor pero todos opcionales. Cada campo usa el operador `??` para decidir: si se pasó un valor nuevo, lo usa; si no, conserva el valor del objeto original (`this.campo`).
- **Comparativa:** Sin este método, un repository que necesite actualizar solo el `pesoActual` de una mascota (por ejemplo, tras pesarla en un control) tendría que reconstruir manualmente los 13 campos del objeto cada vez. Con `copyWith`, esa actualización se reduce a `mascota.copyWith(pesoActual: 6.5)`, manteniendo la inmutabilidad y evitando errores de copiado manual.

### 5. `especiePersonalizada` (2026-08-17)

Igual que `tipoEventoPersonalizado` en `AgendaEventoModel`, este campo nuevo (`String?`, columna `especie_personalizada`) guarda el texto libre solo cuando `especie == 'Otro'` — `especie` en sí dejó de ser texto libre para pasar a una lista fija de opciones, elegida desde un `DropdownButtonFormField` en `FormularioMascotaScreen` (ver `formularioMascotaScreen.md`).

### 6. `especieTexto` — getter borrado al llegar los idiomas (2026-08-17 → eliminado 2026-08-18)

Este modelo tuvo, por un día, un getter `especieTexto` que resolvía si mostrar `especie` o `especiePersonalizada`. Al implementar idiomas (ver `sistemaIdiomas.md`), dejó de alcanzar: mostrar la especie ahora requiere *traducirla* según el idioma activo, y un getter no puede recibir el `BuildContext` que hace falta para eso. Se borró por completo (no se dejó como alias ni se mantuvo por compatibilidad) y se reemplazó por la función `especieMostrar(context, mascota)` en `presentation/utils/etiquetas_localizadas.dart` (ver `etiquetasLocalizadas.md`), que sí puede traducir porque vive en la capa de presentación, no en el modelo de datos.

### 7. Sync (2026-08-20) — `actualizadoEn`, `eliminado`/`eliminadoEn`, `fotoRutaNube`

Tres campos nuevos, compartidos (mismo nombre y mismo criterio) entre `MascotaModel`, `AgendaEventoModel`, `MedicamentoEventoModel` y `DocumentoModel` — se documentan acá una sola vez.

- **`actualizadoEn` (`DateTime?`, columna `actualizado_en`):** la marca de "última modificación" que usa el motor de sync (ver `syncService.md`) tanto para decidir qué traer de Supabase (`WHERE actualizado_en > última_sincronización`) como para resolver conflictos (gana el cambio más reciente). Los repositories la estampan en cada `crear`/`actualizar`/`eliminar` — nunca la arma la UI ni el formulario.
  - **Siempre en UTC, sin excepción (`DateTime.now().toUtc()`, no `DateTime.now()`).** Bug real encontrado probando el checkpoint de Fase 3: los timestamps escritos localmente usaban la hora del dispositivo (sin zona horaria) mientras que los traídos por pull ya venían en UTC (con "Z", tal cual los entrega Postgres) — comparar ambos formatos como texto plano en SQLite (`WHERE actualizado_en > ?`) daba resultados incorrectos según la zona horaria del dispositivo, causando que filas recién traídas por pull se consideraran "más nuevas" de lo que realmente eran. Ver `decisiones_arquitectura.md`.
- **`eliminado`/`eliminadoEn` (`bool`/`DateTime?`):** soporte de soft-delete — ver `mascota.repository.md`, punto 5, para el porqué (un `DELETE` real no deja rastro que sincronizar).
- **`fotoRutaNube` (`String?`, solo en `MascotaModel`; su equivalente en `DocumentoModel` es `archivoRutaNube`, ver `documento.model.md`):** la ruta del archivo dentro del bucket privado de Storage, no una URL — un bucket privado no tiene URL pública estable. `fotoUrl` (la ruta local, ya existente) y `fotoRutaNube` son campos independientes a propósito: `fotoUrl` nunca viaja a Supabase ni se sobreescribe con un pull, así el dispositivo de origen sigue mostrando la foto al instante sin depender de la red; `fotoRutaNube` es lo que efectivamente sincroniza, y es lo que otro dispositivo usa para descargar el archivo la primera vez que ve esta mascota.