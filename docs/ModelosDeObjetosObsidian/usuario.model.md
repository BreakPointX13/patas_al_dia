# Nota de Obsidian: `UsuarioModel` (Estructura de Datos Híbrida)

## 📁 Ubicación en el Proyecto
`docs_obsidian/usuario_model.md` (Espejo de `lib/data/models/usuario_model.dart`)

## 🎯 Propósito del Archivo
Este modelo actúa como la **Aduana de Datos** para el manejo de usuarios en "Patas al día". Está diseñado específicamente bajo una arquitectura híbrida para soportar tanto a usuarios locales anónimos (invitados) como a usuarios sincronizados en la nube, garantizando que el paso de datos entre las consultas crudas de SQLite (`Map<String, dynamic>`) y las pantallas de Flutter sea tipado, seguro e inmutable.

---

## 🏗️ Nivel 1: Concepto Estándar de la Industria (Serialización y Mapeo)

En la programación orientada a objetos moderna, las bases de datos relacionales o almacenes de persistencia local no entienden qué es una "Clase de Flutter" o un "Objeto". Solo entienden estructuras primitivas (filas, columnas, texto, enteros). 

La **Serialización** es el proceso de transformar un objeto vivo en memoria a un formato almacenable (como un Mapa o un JSON). La **Deserialización** es el proceso inverso. En la industria, delegar esta responsabilidad a constructores `factory .fromMap` y métodos `.toMap` evita el acoplamiento y asegura que si la base de datos cambia de motor en el futuro, tus pantallas e interfaces no sufran ninguna rotura de código.

---

## ⚙️ Nivel 2: Implementación en Patas al día

El modelo de usuario implementa conversiones estrictas debido a las limitaciones físicas de SQLite:

### 1. Manejo del Estado de Invitado (`bool` vs `int`)
* **El Problema:** SQLite no tiene un tipo de dato nativo para Booleanos (`true`/`false`).
* **La Solución:** 
  * Al guardar (`toMap`), evaluamos de manera ternaria: `esInvitado ? 1 : 0`.
  * Al recuperar (`fromMap`), realizamos una comparación lógica directa: `(map['es_invitado'] as int?) == 1`. Si es igual a 1, Flutter recibe un `true` real.

### 2. Parseo de Estampas de Tiempo (`DateTime` vs `String`)
* **El Problema:** Las fechas en SQLite se almacenan como cadenas de texto plano (`TEXT`).
* **La Solución:** Utilizar el estándar industrial **ISO 8601** (`YYYY-MM-DDTHH:MM:SS.mmmmmm`). 
  * En la salida, el operador de navegación segura `fechaRegistro?.toIso8601String()` previene errores si la fecha es nula.
  * En la entrada, controlamos la existencia del dato antes de forzar el parseo dinámico mediante `DateTime.parse()`.

---

## 🔄 Nivel 3: Comparativa Visual y Ventajas Técnicas

| Tipo de Dato en Flutter | Tipo de Almacenamiento SQLite | Método de Transformación | Ventaja en el Negocio |
| :--- | :--- | :--- | :--- |
| `String id` | `TEXT PRIMARY KEY` | Directo (`as String`) | Soporta UUIDs autogenerados para evitar colisiones al sincronizar online |
| `String? email` | `TEXT` | Directo (`as String?`) | Permite opcionalidad completa para cuentas no registradas de forma local |
| `bool esInvitado` | `INTEGER` (0 o 1) | Evaluación lógica binaria | Permite al usuario usar la app de inmediato sin barreras de registro obligatorio |
| `DateTime? fechaRegistro`| `TEXT` (ISO 8601) | `DateTime.parse()` / `.toIso8601String()` | Mantiene la precisión milimétrica del registro local para auditorías de datos |

### Ventaja de la Inmutabilidad (`final`)
Al declarar todas las variables como `final`, aseguramos que una vez que el usuario inicia sesión o abre la app, sus datos no puedan ser modificados de forma accidental por procesos en segundo plano. Si el usuario se registra y deja de ser invitado, la arquitectura nos obliga a generar un nuevo estado limpio, cumpliendo con los principios de **Código Limpio y Reactivo**.