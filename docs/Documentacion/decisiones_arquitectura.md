# Bitácora de Decisiones de Arquitectura — Patas al Día

Registro de las decisiones de arquitectura tomadas en el proyecto, con el contexto y el porqué de cada una. Se actualiza cada vez que se toma una decisión nueva de este tipo (no cambios de código en sí, sino elecciones de enfoque, tecnología o estructura).

---

## 2026-05-24 — SQLite local-first, sin ORM

**Decisión:** persistencia local con `sqflite` (SQLite), sin ningún ORM — mapeo manual `fromMap`/`toMap` en cada modelo.

**Por qué:** mantener el proyecto liviano y sin generación de código (`.g.dart`), acorde a la regla de dependencias mínimas. La app debe ser 100% funcional offline antes de cualquier feature de sync cloud.

---

## 2026-05-24 — IDs como `String` UUID en vez de autoincrementales

**Decisión:** todas las tablas usan `TEXT` (UUID vía el paquete `uuid`) como clave primaria, en vez de enteros autoincrementales.

**Por qué:** compatibilidad futura con Supabase/PostgreSQL, donde los UUID son el estándar para IDs generados en el cliente (permite crear registros offline sin esperar un ID del servidor).

---

## 2026-05-24 — Supabase como backend cloud (sobre Firebase)

**Decisión:** cuando se implemente sync cloud, será con Supabase (PostgreSQL + Auth + Storage), no Firebase.

**Por qué:** compatibilidad directa con el esquema SQL ya definido (PostgreSQL, no una base NoSQL), costos operativos menores, y Storage integrado para fotos/documentos sin agregar un proveedor aparte.

---

## 2026-05-24 — Login híbrido: invitado sin cuenta obligatoria

**Decisión:** `UsuarioModel` soporta dos estados (`esInvitado = true/false`); ninguna funcionalidad core requiere registro.

**Por qué:** prioridad de UX — la barrera de entrada más baja posible. Un usuario invitado nunca debe ver errores por falta de conexión ni por falta de cuenta.

---

## 2026-07-25/26 — Riverpod como única solución de estado

**Decisión:** gestión de estado con `flutter_riverpod` (sin generación de código), sin mezclar con otros enfoques (Provider clásico, BLoC).

**Por qué:** consistencia en todo el proyecto — un solo patrón que aprender y mantener, en línea con la regla de dependencias mínimas.

---

## 2026-08-06 — `FormularioMascotaScreen` reutilizable para crear y editar

**Decisión:** una sola pantalla (`FormularioMascotaScreen(mascotaExistente: MascotaModel?)`) maneja tanto la creación como la edición de una mascota, en vez de dos pantallas separadas.

**Por qué:** decisión del usuario — "reutilizar sería una buena opción en tema de recursos". Evita duplicar la UI de un formulario grande a medida que crece en campos.

---

## 2026-08-06 — `image_picker` como dependencia nueva, sin alternativa

**Decisión:** se agrega `image_picker` para elegir la foto de la mascota desde galería/cámara.

**Por qué:** decisión del usuario — "es algo vital y no negociable". Es la excepción justificada a la regla de dependencias mínimas: no existe forma de acceder a la galería/cámara nativa con Dart puro.

---

## 2026-08-06 — Navegación lista → detalle → acciones (en vez de acciones inline en la lista)

**Decisión:** tocar una mascota en `HomeScreen` abre `DetalleMascotaScreen`, que a su vez da acceso a Editar, Agenda y Documentos — en vez de exponer esas acciones directo en la lista.

**Por qué:** decisión del usuario — quería poder "pinchar en la mascota desde la lista... y ya dentro de esa mascota se desplegarán más opciones". Patrón estándar de la industria (lista liviana + detalle completo).

---

## 2026-08-06 — `DetalleMascotaScreen` recibe `mascotaId`, no el objeto `MascotaModel` completo

**Decisión:** la pantalla de detalle recibe un `String mascotaId` y busca la mascota actualizada en `mascotasProvider` en cada `build()`, en vez de recibir una copia fija del objeto.

**Por qué:** si se pasara el objeto completo, quedaría "congelado" en el momento de abrir la pantalla — si el usuario edita la mascota y vuelve al detalle, vería datos viejos. Con el id, la pantalla siempre refleja el estado actual sin refrescar nada a mano.

---

## 2026-08-06 — Edad estimada: reutilizar `fechaNacimiento` calculada + flag, en vez de un campo de edad aparte

**Decisión:** cuando el usuario no sabe la fecha exacta de nacimiento, se activa un switch que pide la edad en años; al guardar, se calcula `fechaNacimiento` como "hoy menos esos años" y se guarda un flag `fechaEstimada: bool` nuevo en `MascotaModel`, en vez de agregar un campo de "edad" paralelo y independiente.

**Por qué:** mantiene `fechaNacimiento` como única fuente de verdad para toda la lógica futura (agenda, cálculo de edad), evitando que dos campos puedan quedar inconsistentes entre sí.

**Alternativa considerada:** granularidad de años y meses (más precisa para cachorros/gatitos). Se descartó por ahora a favor de solo años, por simplicidad — decisión explícita del usuario.

---

## 2026-08-06 — RUT y número de chip sin validación de formato estricto

**Decisión:** estos dos campos se dejan como texto libre, sin aplicar el algoritmo de dígito verificador del RUT chileno ni exigir una cantidad exacta de dígitos para el chip. Sí se validan **peso** (número positivo) y **edad estimada** (entero entre 1 y 30), por ser universales.

**Por qué:** decisión explícita del usuario — aunque la app está pensada inicialmente para Chile, no se quiere cerrar la puerta a usuarios de otros países cuyos formatos de identificación no calcen con el estándar chileno.

---

## 2026-08-06 — Cambios de esquema SQLite vía reinstalación, no migración, durante desarrollo

**Decisión:** mientras el proyecto esté en fase de desarrollo (sin usuarios reales con datos que preservar), los cambios de esquema (nuevas columnas) se agregan directo en `DatabaseHelper._onCreate`, y se aplican reinstalando la app — no se implementa `onUpgrade` con `ALTER TABLE` todavía.

**Por qué:** `_onCreate` solo corre una vez (la primera vez que la app crea la base de datos); sin datos reales que perder, reinstalar es más simple que mantener migraciones. El usuario confirmó entender que esto **no** sería válido en producción, donde sí haría falta una migración real.

---

## De aquí en adelante

Cada vez que se tome una decisión de arquitectura nueva (enfoque, tecnología, estructura — no un simple fix o ajuste de código), se agrega una entrada acá con: fecha, la decisión, el porqué, y alternativas consideradas si las hubo.
