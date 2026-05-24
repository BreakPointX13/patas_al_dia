# Nota de Obsidian: `MascotaModel`

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