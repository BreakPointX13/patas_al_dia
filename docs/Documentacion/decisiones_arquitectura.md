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

## 2026-08-06 — Persistencia de sesión vía flag `sesion_activa`, no vía la sola existencia de la fila en `usuarios`

**Decisión:** para que la app recuerde al usuario invitado entre reaperturas (bug: antes se creaba un usuario invitado nuevo en cada arranque porque `LoginScreen` era el `home` fijo), se agrega una columna `sesion_activa INTEGER DEFAULT 1` a `usuarios`, en vez de asumir que "la primera fila que exista" es la sesión activa. `SesionInicialScreen`, nueva pantalla, es ahora el `home` de la app: consulta `WHERE sesion_activa = 1` y decide si ir a `HomeScreen` o a `LoginScreen`. "Cerrar sesión" (nueva `AjustesScreen`, accesible desde `HomeScreen`) pone el flag en `0` sin borrar la fila ni sus datos.

**Por qué:** decisión del usuario tras comparar dos opciones — usar la fila existente directamente (más simple, pero "cerrar sesión" quedaría ambiguo: solo se podría lograr borrando al usuario invitado, perdiendo sus mascotas por el `ON DELETE CASCADE`) vs. un flag explícito (mismo costo de dependencias — sigue siendo solo `sqflite` — pero separa "existe un usuario" de "es la sesión activa", permitiendo cerrar sesión sin destruir datos y dejando la puerta abierta a soportar más de un usuario guardado por dispositivo en el futuro).

**Alternativa considerada:** guardar el id de la sesión activa fuera de SQLite (ej. `shared_preferences`). Descartada por chocar con la regla de dependencias mínimas — la tabla `usuarios` ya podía resolverlo sin paquetes nuevos.

---

## 2026-08-10 — Identidad visual: fuentes y logo empaquetados manualmente, sin paquetes nuevos

**Decisión:** se incorporó la identidad visual de la app (logo, paleta de color, tipografía Nunito/Source Sans 3, generada aparte por el usuario y ya aprobada) sin agregar ningún paquete nuevo:

- **Fuentes:** en vez de `google_fonts` (que puede descargar los `.ttf` de la red la primera vez que se usan si no se configura para assets empaquetados), se bajaron los `.ttf` de Nunito (600/700/800) y Source Sans 3 (400/600) una sola vez y se declararon como assets locales en `pubspec.yaml`, referenciados por `fontFamily` en el `ThemeData` de `main.dart`.
- **Logo dentro de la app:** el SVG original se rasterizó una vez a PNG (`assets/images/logo_patas_al_dia.png`, vía ImageMagick) en vez de sumar `flutter_svg` para renderizarlo como vector — el logo es prácticamente estático (no se redimensiona dinámicamente en runtime), así que no se justifica la dependencia.
- **Ícono de launcher:** se generaron manualmente con ImageMagick los 5 tamaños de `mipmap-*` (Android) y los 14 de `AppIcon.appiconset` (iOS) a partir de un segundo SVG (versión sin transparencia, pensada para ícono), en vez de usar el paquete `flutter_launcher_icons`.
- De paso, se corrigió el nombre visible de la app (`android:label` y `CFBundleDisplayName`, que quedaban en `patas_al_dia`/`Patas Al Dia`) a "Patas al Día".

**Por qué:** las tres alternativas de paquete (`google_fonts`, `flutter_svg`, `flutter_launcher_icons`) resuelven problemas que ya cubren herramientas existentes en el entorno de desarrollo (ImageMagick) o el propio Flutter (`pubspec.yaml` assets/fonts) — chocan con la regla de dependencias mínimas sin traer una ventaja real para el tamaño actual de la app. Además, `google_fonts` en su modo por defecto podría violar la regla de local-first (usuario invitado sin errores por falta de conexión) si las fuentes no llegan a estar cacheadas.

**Alternativa considerada:** usar los tres paquetes mencionados, que es el camino "por defecto" que sugiere la propia guía de identidad entregada por el usuario. Se descartó por las razones de arriba.

---

## 2026-08-12 — Navegación principal: barra inferior con `Navigator` independiente por pestaña, en vez de uno solo compartido

**Decisión:** se agrega `NavegacionPrincipalScreen` como nuevo destino de `SesionInicialScreen` (reemplaza a `HomeScreen` en ese rol). Es el "marco" de la app: una barra de navegación inferior con 3 pestañas — Mascotas (`HomeScreen`, sin cambios de contenido), Agenda y Mapa (`AgendaScreen`/`MapaScreen`, placeholders "Próximamente" por ahora) — construidas con widgets nativos de Flutter (`NavigationBar`, `IndexedStack`), sin paquetes nuevos.

Cada pestaña tiene su propio `Navigator` independiente (uno por `GlobalKey<NavigatorState>`), en vez de compartir el único `Navigator` de toda la app. Esto significa que la pila de pantallas de cada pestaña vive por separado: si se abre `DetalleMascotaScreen` desde la pestaña Mascotas y se cambia a otra pestaña, al volver se sigue viendo ese detalle en vez de la lista, y la barra inferior permanece visible en todo momento (no se tapa al navegar dentro de una pestaña). El botón "atrás" del dispositivo se resuelve con `PopScope`: primero intenta retroceder dentro del `Navigator` de la pestaña activa, y solo cierra la app cuando esa pestaña ya está en su raíz.

**Por qué:** decisión explícita del usuario, sopesando dos alternativas con el mismo costo de dependencias (ambas nativas de Flutter):

- **Un solo `Navigator` compartido** (lo que ya existía): más simple de construir y entender, pero al abrir una pantalla desde cualquier pestaña, la barra inferior desaparece tapada por esa pantalla.
- **Un `Navigator` por pestaña** (la elegida): más código nuevo y conceptos más avanzados (`Navigator` anidados, `GlobalKey` por pestaña), pero el resultado se comporta como apps de referencia (Instagram, YouTube) — se consideró que valía la pena priorizando el valor del proyecto como portafolio, aun sabiendo que la app todavía no tiene tantas funciones como para necesitarlo por complejidad real.

Como consecuencia de mover `AjustesScreen` a una posición común a las tres pestañas, el ícono de engranaje de `HomeScreen` se reemplazó por `MenuUsuarioAvatar` (`lib/presentation/widgets/menu_usuario_avatar.dart`, primer archivo de una carpeta `widgets/` nueva, hermana de `screens/`): un ícono de avatar con menú desplegable, reutilizado en las tres pantallas raíz. No es una foto real de usuario — `UsuarioModel` todavía no tiene ese campo — así que por ahora es un ícono genérico de persona.

**Alternativa considerada (para "Cerrar sesión"):** al mover `AjustesScreen` detrás de un `Navigator` anidado, `Navigator.of(context)` dentro de `_cerrarSesion` pasó a resolver al `Navigator` de la pestaña activa en vez del de toda la app — sin corregirlo, cerrar sesión hubiera dejado `LoginScreen` empujado dentro de una pestaña, con la barra inferior del shell todavía visible alrededor. Se corrigió usando `Navigator.of(context, rootNavigator: true)`, que apunta siempre al `Navigator` raíz sin importar desde qué pestaña se abrió `AjustesScreen`.

---

## De aquí en adelante

Cada vez que se tome una decisión de arquitectura nueva (enfoque, tecnología, estructura — no un simple fix o ajuste de código), se agrega una entrada acá con: fecha, la decisión, el porqué, y alternativas consideradas si las hubo.
