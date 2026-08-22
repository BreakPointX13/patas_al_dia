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

## 2026-08-14 — Formulario de eventos de agenda: futuro vs. pasado, con segunda mitad progresiva

**Decisión:** una sola pantalla (`FormularioAgendaEventoScreen`) para crear/editar eventos de agenda, con dos modos de creación:

- **Evento futuro** (recordatorio): pide solo mascota, título, fecha/hora y recordatorio. El resto del formulario (observaciones, medicamentos, documentos, "programar próxima consulta") aparece pero recién se habilita cuando la fecha programada ya pasó.
- **Evento pasado** (historial): formulario completo desde el principio, sin recordatorio (no tiene sentido avisar de algo ya ocurrido).

La visibilidad de cada sección no depende de un campo guardado que distinga "futuro" de "pasado" — se calcula en vivo comparando la fecha del evento contra el reloj actual (`_esFechaFutura`/`_segundaMitadVisible` en el formulario). Ver `formularioAgendaEventoScreen.md` para el detalle.

**Por qué:** decisión del usuario, iterada en varias rondas — primero se planteó un bloqueo de 2 horas después del evento para habilitar la segunda mitad (se descartó por fricción: alguien que vuelve de la veterinaria a los 30 minutos no podía anotar la receta al toque), después se simplificó a "se habilita en cuanto pasa la hora de la consulta". Mantener todo en una sola pantalla (en vez de dos separadas) evita duplicar la lógica de medicamentos/documentos en dos archivos.

---

## 2026-08-14 — Medicamentos y documentos por evento: tabla nueva + `file_picker` + `flutter_local_notifications`

**Decisión:** un evento de agenda ahora puede tener varios medicamentos (tabla nueva `medicamentos_evento`, con FK obligatoria y `ON DELETE CASCADE` hacia `agenda_eventos`) y varios documentos adjuntos (reutilizando la tabla `documentos` ya existente, que desde su diseño original ya soportaba un `eventoId` opcional). Para adjuntar documentos se suma el paquete `file_picker` (selección de PDF; fotos ya se cubrían con `image_picker`). Para los recordatorios con aviso real del sistema se suma `flutter_local_notifications` + `timezone`.

**Por qué chocan con la regla de dependencias mínimas:** a diferencia de las fuentes/logo/ícono (2026-08-10), donde sí había una alternativa nativa razonable, acá no la hay — Flutter no trae selector de archivos genérico ni notificaciones programadas de fábrica. Excepción consciente a la regla, decidida explícitamente por el usuario: "esta parte es la principal del proyecto, no deberíamos escatimar tanto" en el caso del calendario/agenda en general.

**Gotcha encontrado con `flutter_local_notifications`:** el paquete requiere declarar manualmente, en el `AndroidManifest.xml` de la app, los `<receiver>` que usa para recibir la alarma del sistema — su propio manifiesto no los incluye. Sin esa declaración, las alarmas se programan y suenan bien (es un mecanismo del sistema operativo), pero la notificación nunca llega a mostrarse, sin ningún error visible. Ver el detalle completo en `notificacionService.md`. También requirió habilitar *core library desugaring* en `android/app/build.gradle.kts` (con `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:...")`), otro requisito del paquete no evidente hasta que el build falla pidiéndolo.

---

## 2026-08-14 — Bugs de navegación encontrados al probar Agenda (no decisiones, pero vale dejar registro)

Dos bugs reales en el navbar armado el 2026-08-12, recién visibles al probar con interacción real del usuario (no en el desarrollo inicial):

1. **`LoginScreen` no llevaba al invitado nuevo al navbar.** Al armar `NavegacionPrincipalScreen`, se actualizó `SesionInicialScreen` para que un usuario con sesión activa fuera al navbar — pero `LoginScreen._continuarComoInvitado` (el camino de un invitado *nuevo*) seguía apuntando directo a `HomeScreen`, sin el marco del navbar. Se corrigió el `Navigator.pushReplacement` para que apunte a `NavegacionPrincipalScreen`.
2. **El botón "atrás" del sistema cerraba la app entera** en vez de retroceder dentro de una pestaña, al navegar dentro de una pestaña sin que `NavegacionPrincipalScreen` se reconstruyera (empujar `FormularioAgendaEventoScreen` no dispara un rebuild del widget padre). El detalle completo del arreglo (`PopScope` con `canPop: false` fijo) está en `navegacionPrincipalScreen.md`.

**Por qué importa dejarlo anotado:** ambos bugs solo aparecen con interacción real (tocar el botón atrás del sistema, crear un usuario invitado desde cero) — no los detecta `flutter analyze` ni una revisión de código superficial. Vale la pena probar estos flujos específicos (botón atrás del sistema, no solo el de la `AppBar`; alta de usuario invitado nuevo, no solo sesión ya existente) después de cualquier cambio futuro a la navegación.

---

## 2026-08-14 — Vista Calendario de la Agenda: `table_calendar` como excepción a dependencias mínimas

**Decisión:** `AgendaScreen` tiene dos vistas alternables (lista y calendario, con calendario como vista inicial por defecto, decisión explícita del usuario), usando el paquete `table_calendar` para la vista de calendario.

**Por qué choca con la regla de dependencias mínimas:** igual que con `file_picker` y `flutter_local_notifications` (ver la entrada del mismo día), Flutter no trae de fábrica un widget de calendario con grilla de mes, marcadores de eventos por día y navegación entre meses — construirlo a mano es posible pero no trivial. Excepción consciente, decidida explícitamente por el usuario ("esta parte es la principal del proyecto, no deberíamos escatimar tanto").

**Detalle no evidente:** usar `locale: 'es_ES'` en `TableCalendar` requiere inicializar los datos de esa configuración regional del paquete `intl` antes (`initializeDateFormatting('es_ES')` en `main.dart`) — sin eso, el widget lanza una excepción al intentar mostrar el nombre del mes en español.

---

## 2026-08-15 — Ver documentos adjuntos: `open_filex` para PDF, visor propio para imágenes

**Decisión:** desde `DetalleAgendaEventoScreen`, tocar un documento adjunto ahora lo abre. Las imágenes se muestran dentro de la propia app (`VisorImagenScreen`, pantalla nueva con `InteractiveViewer` para zoom — widget nativo de Flutter, sin dependencias nuevas). Los PDF se delegan al sistema operativo (`OpenFilex.open`, paquete nuevo `open_filex`), que abre el archivo con la app que el usuario ya tenga instalada para eso — no se construyó un visor de PDF propio.

**Por qué:** bug reportado por el usuario ("deberías ser capaz de poder ver las imágenes y los documentos que uno adjunte") — hasta ahora los documentos adjuntos solo se veían como ícono/miniatura, sin poder abrirlos. `open_filex` es la misma clase de excepción a dependencias mínimas ya aceptada para esta parte del proyecto (Agenda/Documentos) — no hay forma nativa de pedirle a Android/iOS que abra un archivo con la app correspondiente sin un paquete así.

---

## 2026-08-15 — Evento pasado: `fechaRealizada` se completa sola al crearlo

**Decisión:** al guardar un evento creado con "Evento pasado", `fechaRealizada` se llena automáticamente con la misma fecha elegida (`fechaProgramada`), en vez de quedar `null` hasta que el usuario active un switch a mano. En `DetalleAgendaEventoScreen`, el switch "Marcar como realizado" ahora solo aparece si `fechaRealizada` sigue sin valor — una vez marcado (a mano o automáticamente al crear), se muestra como texto fijo.

**Por qué:** bug reportado por el usuario — un evento pasado, recién creado, "quedaba como si fuera un evento agendado para futuro", obligando a un paso extra (tocar el switch) para algo que el usuario ya había declarado al elegir "Evento pasado" en el primer paso del formulario.

---

## 2026-08-15 — Bug: datos de la sesión anterior sobrevivían en memoria tras cerrar sesión

**Síntoma reportado por el usuario:** después de cerrar sesión y entrar como un invitado nuevo, `AgendaScreen` seguía mostrando eventos del invitado anterior, y la lista bajo el calendario crasheaba con un error de Flutter en rojo.

**Causa:** `mascotasProvider`, `agendaEventosProvider`, `medicamentoEventoProvider` y `documentosProvider` son providers globales de Riverpod — nada los "vacía" solo por navegar a `LoginScreen` y crear un usuario invitado nuevo. `mascotasProvider` terminaba reflejando al invitado nuevo (vacío) porque `HomeScreen` siempre dispara `cargarMascotas` al montarse, pero `agendaEventosProvider` podía quedar con los eventos viejos por una condición de carrera (su propia recarga podía leer `mascotasProvider` *antes* de que terminara de actualizarse). El resultado: una pantalla con `mascotas` vacío pero `eventos` apuntando a mascotas que ya no estaban en esa lista — y el código asumía (`firstWhere(..., orElse: () => mascotas.first)`) que la lista de mascotas nunca podía estar vacía si había eventos, lo cual dejó de ser cierto.

**Solución (dos partes, no solo una):**
1. **Causa raíz:** `AjustesScreen._cerrarSesion` ahora invalida (`ref.invalidate(...)`) los cuatro providers al cerrar sesión, para que arranquen limpios la próxima vez que algo los lea — no dependen de que cada pantalla se acuerde de recargarlos a tiempo.
2. **Defensivo, igual necesario:** se sacaron todos los `firstWhere(..., orElse: () => lista.first)` que asumían que la lista nunca podía estar vacía (`AgendaScreen`, `DetalleAgendaEventoScreen`, `DetalleMascotaScreen`) — ahora, si no se encuentra el dato, se muestra un texto de reemplazo o se vuelve a la pantalla anterior en vez de crashear. Vale la pena mantener esto aunque la causa raíz ya esté resuelta: es la misma clase de bug (asumir que un dato relacionado siempre existe) que puede reaparecer por otras vías (ej. sincronización futura con Supabase, otro dispositivo borrando algo).

**De paso:** se agregó una confirmación antes de cerrar sesión (`AjustesScreen`) — como invitado no hay forma de volver a esa sesión después, así que es una acción efectivamente irreversible que merecía un aviso, aunque los datos no se borren literalmente de SQLite (siguen la decisión ya registrada del 2026-08-06: "sesión" es un flag, no la existencia de la fila).

---

## 2026-08-16 — Recordatorios múltiples por evento, con checkboxes en vez de un dropdown

**Decisión:** `AgendaEventoModel.recordatorioHorasAntes` pasa de `int?` (un solo valor) a `List<int>` — un evento puede pedir que le avisen en varios momentos a la vez (ej. 1 día antes *y* 1 hora antes), no solo uno. En el formulario, el selector cambia de `DropdownButtonFormField` (una sola opción) a una lista de `CheckboxListTile` (varias a la vez). Se agrega "6 horas antes" como cuarta opción (antes eran solo 24/12/1).

**Cómo se guarda:** como texto separado por comas en la misma columna `recordatorio_horas_antes` (que pasa de `INTEGER` a `TEXT`), no una tabla hija nueva — a diferencia de `medicamentos_evento` (que sí es una tabla propia), acá el conjunto de valores posibles es chico, cerrado y sin identidad propia (no tiene sentido "editar" un recordatorio de 12 horas, o darle observaciones) — no ameritaba el mismo tratamiento relacional.

**Notificaciones:** `NotificacionService` ahora programa un recordatorio por cada valor de la lista, cada uno con su propio id (combinando el id del evento y la cantidad de horas). Al cancelar, como no se sabe de antemano cuáles horas tenía programadas ese evento en particular, se cancelan las cuatro combinaciones posibles — cancelar un id que nunca se programó es un no-op seguro.

---

## 2026-08-16 — Pantalla general de Documentos: alcance completo, sin tocar la capa de datos

**Decisión:** `DocumentosScreen` (lista de todos los documentos de una mascota) + `FormularioDocumentoScreen` (crear/editar con **todos** los campos de `DocumentoModel`: título, tipo, archivo, fecha de emisión, fecha de vencimiento, recordatorio de vencimiento, notas) + `DetalleDocumentoScreen`. Decisión explícita del usuario: alcance completo desde el arranque, no una versión reducida como se hizo primero con Agenda.

**Nada cambió en `data/` ni en `providers/`** — `documentoProvider`/`DocumentoRepository` ya tenían todo lo necesario desde que se construyeron (incluida la relación opcional con `agenda_eventos` vía `eventoId`), semanas antes de que existiera esta pantalla. Es la primera feature grande del proyecto que no requirió ningún cambio de esquema ni de repository — validación de que el diseño original de esas capas (2026-08-06) ya contemplaba este caso de uso.

**Recordatorio de vencimiento — solo dato, sin notificación real (por ahora):** a diferencia del recordatorio de Agenda (que sí programa notificaciones reales), `recordatorioVencimiento` se guarda como preferencia pero no dispara nada todavía — decisión explícita del usuario, con la UI aclarándolo directamente (subtítulo del switch, y la fecha de vencimiento marcada como "(opcional)"). Se deja pendiente para una tarea aparte si se decide implementarlo.

---

## 2026-08-16 — Vista de lista de Agenda como timeline: `flutter_svg`, tipo de evento fijo, esquema nuevo

**Decisión:** la vista de lista de `AgendaScreen` pasa de una lista plana de `ListTile` a un diseño de "historial" (timeline) con tarjeta destacada para el próximo evento y el resto agrupado por mes, a partir de una maqueta HTML que trajo el usuario (`timeline_patas_al_dia.html`) y un set de 7 íconos SVG que diseñó a medida (`vacuna`, `desparasitación`, `peluquería`, `operación`, `control`, `examen`, `otro`).

**Nueva dependencia — `flutter_svg`:** rompe la regla de dependencias mínimas del proyecto de forma consciente, misma excepción ya aceptada antes para `table_calendar`/`file_picker`/`open_filex`: Flutter no trae forma nativa de renderizar SVG, y los íconos ya venían como SVG (no se generaron desde cero para este proyecto).

**`AgendaEventoModel.tipoEvento` pasa de texto libre a lista fija:** para poder mapear cada evento a uno de los 7 íconos de forma confiable, `tipoEvento` deja de ser un `TextField` sin restricciones y pasa a un `DropdownButtonFormField` con esos 7 valores. Se agrega `tipoEventoPersonalizado` (nueva columna `tipo_evento_personalizado` en `agenda_eventos`) para el texto libre de la opción "Otro" — mismo patrón ya usado en `documentos`/`tipoDocumentoPersonalizado`. El usuario decidió no migrar los eventos existentes (los volvió a crear desde cero tras el cambio de esquema) en vez de escribir lógica de migración de datos viejos — coherente con la política ya registrada de reinstalar la app durante esta etapa de desarrollo en vez de mantener migraciones.

**Alcance de la maqueta, adaptado:** el botón "Agendar cita" que traía la maqueta se descartó (ya existe el FAB "Agregar evento" de la pantalla). La tarjeta destacada de "Próximo evento" se decidió mantener también cuando se filtran *todas* las mascotas a la vez (no solo una, como en la maqueta original) — mostrando el nombre de la mascota en la tarjeta y en cada evento del timeline solo cuando hay más de una mascota en el filtro activo, para no ser redundante cuando el filtro ya deja una sola.

**Orden del timeline:** la primera versión agrupaba los meses de más reciente a más antiguo (igual que la maqueta original). El usuario pidió el cambio a orden cronológico ascendente (más antiguo/próximo arriba) después de probarlo — la maqueta era solo un punto de partida visual, no una spec de comportamiento a seguir al pie de la letra.

---

## 2026-08-17 — `MascotaModel.especie` pasa de texto libre a lista fija

**Decisión:** igual que se hizo con `tipoEvento` de `AgendaEventoModel` (2026-08-16), el campo "Especie" de `FormularioMascotaScreen` deja de ser un `TextFormField` sin restricciones y pasa a un `DropdownButtonFormField` con una lista fija de 14 valores: Perro, Gato, Conejo, Hamster, Cobaya, Jerbo, Rata, Chinchilla, Erizo, Pez, Tortuga, Hurón, Ave, Otro. Se agrega `especiePersonalizada` (nueva columna `especie_personalizada` en `mascotas`) para el texto libre de la opción "Otro" — mismo patrón exacto que `tipoEventoPersonalizado`/`tipoDocumentoPersonalizado`.

**Por qué:** propuesta del usuario, con la misma motivación que la lista fija de tipos de evento — ordenar un dato que hasta ahora era texto libre sin restricciones. La lista de especies la definió el usuario a partir de las mascotas más comunes en Chile (Conejo, Chinchilla y Erizo se agregaron sobre la marcha, esta última recordada por el usuario después de haber dado el resto por cerrada).

**Migración de datos viejos:** igual que con `tipoEvento`, no se migran los registros existentes con el algoritmo automático de "texto viejo no reconocido → Otro" en frío — se aplicó el cambio de esquema reinstalando la app, coherente con la política ya registrada de reinstalación durante esta etapa de desarrollo. El mapeo a "Otro" en `initState()` de `FormularioMascotaScreen` queda como salvaguarda para cualquier dato que sí sobreviva (ej. si se restaura un backup viejo), no como mecanismo de migración pensado.

---

## 2026-08-17 — Formulario de mascota: orden de campos y agrupación visual en 3 secciones

**Decisión (orden):** `FormularioMascotaScreen` cambia de orden a: Nombre, Especie, Raza, RUT de la mascota, Número de chip, Sexo, Colores, Peso, Esterilizado, Fecha de nacimiento (o Edad estimada) — pedido explícito del usuario, sin ningún cambio de campos, solo de secuencia.

**Decisión (agrupación visual):** los campos quedan agrupados en 3 secciones separadas por `SeparadorSeccionFicha` (widget nuevo en `lib/presentation/widgets/`, reutilizado también en `DetalleMascotaScreen`): "Mascota" (Nombre, Especie, Raza), "Identificación" (RUT, Número de chip) y "Datos" (Sexo, Colores, Peso, Esterilizado, Fecha de nacimiento). Cada separador es una línea Durazno a cada lado con un ícono centrado: `Icons.pets` (el mismo de la barra inferior) para "Mascota", y dos SVG diseñados a medida por el usuario (`assets/icons/ficha/identificacion.svg`, `assets/icons/ficha/datos.svg`) para las otras dos — misma técnica ya usada para los íconos de tipo de evento de Agenda (`flutter_svg`, ya era dependencia del proyecto).

**Por qué:** el orden nuevo lo pidió el usuario primero, sin mencionar agrupación visual; en un pedido aparte, pidió separar visualmente esos mismos datos en secciones con íconos, y trajo los 2 SVG nuevos. Los límites de cada sección ("el ícono de Identificación va sobre RUT", "el de Datos va sobre Sexo") calzaron exactamente con los límites que ya había entre bloques del reordenamiento recién hecho — no fue coincidencia forzada, el pedido de agrupación reutilizó las mismas fronteras.

**Aplicado también a `DetalleMascotaScreen`:** el usuario confirmó que quería el mismo criterio de agrupación en la ficha de detalle (no solo en el formulario). Ahí no existe un tile de "Nombre" (se muestra como título del `AppBar`, no como dato de la lista), así que el grupo "Mascota" de esa pantalla quedó con solo Especie y Raza — el separador con el ícono de pata se puso igual, justo debajo de la foto.

---

## 2026-08-17 — Credencial digital de mascota: solo vista, sin exportar/compartir por ahora

**Decisión:** `CredencialMascotaScreen` (nueva) muestra un carnet visual de la mascota (foto grande, nombre, especie/raza, RUT, número de chip, esterilizado), accesible desde un ícono de acceso rápido (`trailing`, `Icons.badge_outlined`) en cada fila de `HomeScreen`, independiente del toque normal de la fila (que sigue abriendo `DetalleMascotaScreen`). Primera versión: solo una vista dentro de la app — sin poder exportarla como imagen/PDF ni compartirla fuera de la app.

**Por qué:** decisión explícita del usuario tras plantear dos alcances posibles (solo vista vs. vista + exportar/compartir) — se optó por la versión simple primero, dejando exportar como paso siguiente si hace falta más adelante. Evita sumar de entrada una dependencia nueva (captura de widget a imagen + `share_plus` o similar) para una funcionalidad que todavía no se confirmó que se vaya a necesitar.

**De paso:** la lógica de "qué texto de especie mostrar" (la especie de la lista fija, o el texto libre de `especiePersonalizada` si es "Otro") estaba duplicada como función privada en `home_screen.dart` y `detalle_mascota_screen.dart`. Al necesitarla por tercera vez acá, se subió a `MascotaModel` como getter (`especieTexto`) — ver `mascota.model.md`.

---

## 2026-08-17 — Credencial digital: tarjeta más grande, y exportar/compartir como imagen (`share_plus`)

**Decisión (tamaño):** tras probar la primera versión, se agrandó la tarjeta (`maxWidth` 360→440) y el texto (nombre 24px→32px, resto 16-18px→18-20px, foto radio 64→84) — el usuario la encontró chica y con letra poco legible. También se le agregó fondo circular Naranja marca al ícono de acceso rápido en `HomeScreen` (antes era un ícono suelto sobre la tarjeta Durazno, que no se leía como botón tocable).

**Decisión (exportar/compartir):** se agrega `share_plus` como dependencia nueva y un ícono de compartir en el `AppBar` de `CredencialMascotaScreen`, que captura la tarjeta como imagen PNG (`RepaintBoundary` + `RenderRepaintBoundary.toImage()`) y abre la hoja de "compartir" nativa del sistema con esa imagen.

**Por qué:** decisión explícita del usuario, como siguiente paso ya previsto al construir la primera versión "solo vista" (ver la entrada anterior del mismo día). `share_plus` es la misma clase de excepción a dependencias mínimas ya aceptada para `file_picker`/`open_filex`/`flutter_svg`/`table_calendar` — Flutter no tiene forma nativa de abrir la hoja de "compartir" del sistema operativo. No se agregó `path_provider`: para el archivo PNG temporal alcanza con `Directory.systemTemp` de `dart:io`, ya que `share_plus` copia el archivo a su propia carpeta de caché antes de compartirlo (con su propio `FileProvider`, declarado en su manifiesto y fusionado automático por Gradle — no requirió tocar `AndroidManifest.xml` a mano).

---

## 2026-08-17 — Monetización: se descarta publicidad, se agregan aportes voluntarios vía Ko-fi

**Decisión:** la app no va a mostrar publicidad. En su lugar, `AjustesScreen` suma un ítem discreto "Aportes voluntarios" que abre el Ko-fi del desarrollador (`https://ko-fi.com/breakpointx`) en el navegador del sistema, vía el paquete nuevo `url_launcher`.

**Por qué:** el plan original (registrado en memoria de sesión, no en este archivo hasta ahora) contemplaba publicidad mínima para cubrir costos de mantener la app en Play Store. El usuario lo reconsideró: descartó publicidad por completo — coherente con la prioridad de UX del proyecto (regla 2 de `CLAUDE.md`, "simplicidad para el usuario final") — y la reemplazó por una vía de aporte 100% opcional y fuera del flujo normal de uso, sin fricción ni interrupciones para quien no quiera usarla.

**Ubicación deliberadamente discreta:** no se agregó al menú desplegable del perfil (`MenuUsuarioAvatar`), que sigue mostrando solo "Ajustes" — el acceso queda un paso más adentro, dentro de `AjustesScreen`, para que no compita visualmente con las funciones reales de la app. Ver el detalle técnico (`url_launcher`, `AndroidManifest.xml`) en `ajustesScreen.md`.

---

## 2026-08-18 — Credencial: sexo como símbolo (no fila), fuera de la paleta de marca

**Decisión:** `CredencialMascotaScreen` sumó los datos de sexo y edad que le faltaban. Edad se agregó como una fila más (etiqueta/valor, igual que RUT/Número de chip/Esterilizado). Sexo, en cambio, se muestra como un símbolo (♂/♀) junto al nombre, en `Colors.blue`/`Colors.pink` — colores fuera de la paleta de marca del proyecto (Naranja/Café/Durazno/Crema).

**Por qué:** decisión consultada con el usuario (preguntó explícitamente su opinión sobre ubicación y color antes de implementar). El sexo, a diferencia de la edad, tiene una representación visual corta y universalmente reconocida — mostrarlo como símbolo junto al nombre ahorra una fila entera de la tarjeta y es más "de un vistazo", coherente con el espíritu de carnet. El azul/rosa convencional se prefirió sobre mantener la paleta de marca a rajatabla, porque la reconocibilidad de esa convención pesó más que la consistencia visual en este caso puntual — no se extiende a ningún otro lugar de la app.

---

## 2026-08-18 — Accesibilidad: tres pedidos (modo oscuro, tamaño de letra, idiomas), abordados por separado

**Contexto:** el usuario planteó tres funciones de accesibilidad juntas: modo oscuro, tamaño de letra ajustable e idiomas (español/inglés/portugués). Se evaluaron por separado antes de empezar, porque son de tamaño muy distinto:

- **Modo oscuro:** requiere primero un refactor — casi todos los colores de la app están escritos como `Color(0xFF...)` literal en cada widget, no a través de un `ColorScheme`/tema centralizado. No se puede agregar un modo oscuro real sin antes mover esos colores a un sistema de tokens claro/oscuro.
- **Idiomas (ES/EN/PT):** la más grande de las tres — hay texto en español escrito literal en decenas de pantallas; internacionalizar de verdad implica extraer todos esos strings a un sistema de traducción (`flutter_localizations` + `.arb`) y traducir cada uno a los otros dos idiomas.
- **Tamaño de letra:** la más chica y, según el usuario preguntó explícitamente, la de mayor impacto real de accesibilidad — Flutter la resuelve casi de fábrica con `MediaQuery.textScaler`.

**Decisión:** no implementar las tres en la misma sesión — son tres proyectos separados en la práctica. Se empezó por tamaño de letra (ver `ajustesScreen.md`, punto 4); modo oscuro e idiomas quedan pendientes, cada uno como su propio bloque de trabajo cuando el usuario decida retomarlos.

**De paso, se ajustó el alcance de "tamaño de letra":** el pedido original mencionaba "aumentar o disminuir todos los elementos de la app" (un zoom general de la UI). Se acotó a escalar solo el texto (no íconos/paddings/tamaños fijos) tras compararlo con el usuario — es el estándar real de accesibilidad (así funcionan los ajustes de tamaño de letra de Android/iOS) y muchísimo más robusto de implementar que un escalado general, que en Flutter no tiene una forma nativa de aplicarse de forma consistente sin tocar cada valor fijo a mano.

---

## 2026-08-18 — Modo oscuro: paleta de acento fija, solo el fondo y el "café texto" directo se invierten

**Decisión:** `AjustesScreen` suma un selector Sistema/Claro/Oscuro (`SegmentedButton`, guardado en `UsuarioModel.tema`, mismo criterio que `escalaTexto`). El sistema de temas se separó a `lib/presentation/theme/tema_app.dart` (`temaClaro`/`temaOscuro`, ver `temaApp.md`), aplicados en `main.dart` vía `theme`/`darkTheme`/`themeMode` de `MaterialApp`.

**Paleta:** el usuario definió el criterio antes de implementar — la paleta de acento (Naranja, Naranja marca, Durazno, Amarillo cálido) se mantiene idéntica en los dos modos; solo el fondo del `Scaffold` cambia de Crema (`#FBF0E2`) a un gris oscuro cálido (`#1E1811`, no negro puro, para no perder la calidez de la paleta de marca).

**El hallazgo que amplió el alcance real del cambio:** al auditar el código (grep de `Color(0xFF` en todo `lib/`, solo 7 archivos con colores hardcodeados en total — bastante menos que lo estimado al principio), aparecieron dos problemas de contraste que "solo cambiar el fondo" no resolvía solo:

1. **Texto "café texto" directo sobre el fondo, sin tarjeta detrás:** 3 lugares en `agenda_screen.dart` (etiquetas de sección, fecha/"sin eventos" del día seleccionado) muestran texto café oscuro directo sobre el `Scaffold` — con el fondo nuevo oscuro, ese texto quedaría casi ilegible. Se resolvió con dos funciones (`_colorTextoSobreFondo`/`_colorTextoSecundarioSobreFondo`) que devuelven el color de siempre en claro y una variante clara en oscuro, según `Theme.of(context).brightness`. El resto de los colores hardcodeados de la app (la enorme mayoría) van dentro de tarjetas/paneles de acento (Durazno, Crema clara con borde Naranja) que no cambian de color entre temas, así que no hicieron falta variantes ahí — ver el detalle completo en `agendaScreen.md`.
2. **Tarjetas Durazno con texto que se volvería claro solo:** las `Card` (fondo Durazno fijo en los dos temas) no controlan el color del texto que Flutter les pone adentro por defecto — ese sale de `colorScheme.onSurface`, que en modo oscuro es un color claro. Sin corregirlo, cualquier `ListTile` dentro de una tarjeta Durazno tendría texto claro sobre fondo claro en modo oscuro. Se resolvió con `TarjetaClara` (widget nuevo, ver `tarjetaClara.md`): envuelve el `Card` en un `Theme(data: temaClaro, ...)` anidado, forzando ese subárbol a verse siempre en modo claro sin importar el tema real de la app. Reemplazó los 5 usos de `Card` que había en el proyecto (`HomeScreen`, `DetalleMascotaScreen` ×3, `DocumentosScreen`).

**Por qué importa dejarlo anotado:** el primer diagnóstico ("hay que mover los colores a un sistema de tokens") resultó ser parcialmente cierto pero incompleto — el problema real no era solo "¿de dónde sale cada color?", sino "¿qué widgets dependen implícitamente del tema para su texto, cuando su fondo en realidad no cambia con el tema?". Vale la pena repetir esta pregunta si se agregan más tarjetas o paneles de color fijo en el futuro.

---

## 2026-08-18 — Idiomas: sistema oficial de Flutter, por módulos, datos guardados se traducen para mostrar

**Decisión:** tercera pieza del pedido de accesibilidad (ver la entrada anterior sobre modo oscuro/tamaño de letra), la más grande. Se usa el sistema oficial de Flutter (`flutter_localizations` + `.arb` + `AppLocalizations` generado, ver `sistemaIdiomas.md`) en vez de un paquete de terceros — no rompe la regla de dependencias mínimas porque `flutter_localizations` viene con el SDK. Selector Sistema/Español/English/Português en `AjustesScreen`, guardado en `UsuarioModel.idioma` (mismo criterio que `tema`/`escalaTexto`).

**Pregunta resuelta antes de escribir código:** especie, sexo, tipo de evento y tipo de documento no son solo texto de interfaz — son valores guardados en SQLite desde listas fijas. Se consultó con el usuario y se decidió traducirlos **para mostrar**, sin cambiar cómo se guardan (la base de datos sigue en español siempre) — requiere una capa de traducción aparte (`especieMostrar`/`sexoMostrar` en `etiquetasLocalizadas.md`) que no existe para texto de interfaz normal.

**Por módulos, no todo de una vez:** se empezó por Mascotas (Login, navbar, Home, Formulario/Detalle/Credencial de mascota, `MenuUsuarioAvatar`, `AjustesScreen` completo), seguido de Agenda (`AgendaScreen`, `DetalleAgendaEventoScreen`, `FormularioAgendaEventoScreen`, incluidas las fechas del calendario con locale dinámico — ver `sistemaIdiomas.md`, punto 7) y por último Documentos (`DocumentosScreen`, `FormularioDocumentoScreen`, `DetalleDocumentoScreen`) — con esto, todas las pantallas del core quedan traducidas a los tres idiomas.

**Portugués con revisión extra:** el usuario pidió específicamente que las traducciones al portugués se revisen con cuidado (ni él ni el asistente son hablantes nativos) — se usó portugués brasileño (términos como "Cachorro", "Sair", "Excluir") de forma consistente, con nombres de especies elegidos por uso cotidiano real en Brasil (ej. "Porquinho-da-índia" para cobaya) en vez de traducciones literales.

---

## 2026-08-18 — Arranca Supabase: por fases, esquema manual, y por qué Mapa lo necesita de verdad

**Decisión:** con el core local-first (Mascotas/Agenda/Documentos) más accesibilidad e idiomas ya completos — la precondición de la regla 5 de `CLAUDE.md` ("100% funcional offline antes de sync cloud") — se empieza a implementar Supabase. Se acordó con el usuario avanzar por fases, mismo criterio que ya funcionó bien con idiomas: (1) esquema SQL, (2) cuenta/proyecto en Supabase (lo crea el usuario, no el asistente — requiere sus credenciales), (3) conexión desde la app (`supabase_flutter`), (4) login real, (5) Storage, (6) sync. La versión anterior de este archivo (`TablaMaestraAppVetMovil1.txt`, un esquema genérico sin RLS) había quedado desactualizada respecto al esquema real de `database_helper.dart` (le faltaban `medicamentos_evento`, `especie_personalizada`, `fecha_estimada`, `tipo_evento_personalizado`, `recordatorio_horas_antes`). Se reemplazó por `TablaMaestraAppVetMovil1.sql` (mismo nombre base, extensión `.sql`): el esquema Postgres real, ya con `enable row level security` y las políticas por tabla, listo para pegar directo en el SQL Editor de Supabase — escrito a partir del código real de `database_helper.dart`, no del `.txt` viejo.

**Sin herramientas de migración:** los cambios de esquema entre SQLite (local) y Supabase (nube) no se sincronizan solos — son dos bases de datos independientes. Cada cambio de tabla futuro (agregar/modificar una columna, como se hizo varias veces esta sesión) va a requerir aplicarlo a mano en los dos lados, revisado contra `TablaMaestraAppVetMovil1.sql` como referencia. Coherente con la regla de "sin ORM, sin generación de código" que ya rige el resto del proyecto — sumar una herramienta de migraciones ahora sería una complejidad que 6 tablas con cambios esporádicos todavía no justifican.

**Mapa (`mascotas_extraviadas`) es distinto a los otros tres módulos — depende de Supabase para existir, no solo para respaldo:** Mascotas/Agenda/Documentos son datos privados por usuario, funcionan 100% local y Supabase ahí es sync opcional. Mapa necesita que **otro** usuario, en otro teléfono, vea tu reporte — imposible de resolver con SQLite local solo. Esto afina el motivo real detrás del roadmap de v2 en `CLAUDE.md` ("se implementa después de tener el core funcionando end-to-end"): no es solo orden de prioridades, es una dependencia dura.

Dos implicancias para cuando se diseñe el esquema/políticas de Supabase de esta tabla (`mascotas_extraviadas`):
- **RLS de lectura pública, escritura restringida:** a diferencia de `mascotas`/`agenda_eventos`/`documentos` (cada usuario ve solo lo suyo), acá cualquiera debe poder *leer* los reportes activos — si no, la función no cumple su propósito — pero solo el dueño del reporte puede crear/editar/borrar el suyo.
- **Un invitado sí puede reportar, pero con contacto obligatorio (decisión del usuario):** no hace falta cuenta registrada para publicar en Mapa (mismo espíritu de la regla 2, "ninguna función core debe exigir registro"), pero como un invitado no tiene email ni cuenta a la cual contactarlo, el campo `contacto_emergencia` (ya existe en el esquema) pasa a ser **obligatorio** para poder publicar — es la única forma de que alguien pueda contactar a quien reportó, sin depender de que tenga una cuenta.

**Fase 3 completada — conexión verificada en el dispositivo:** se agregó `supabase_flutter` como dependencia y `lib/services/supabase_config.dart` con las credenciales del proyecto (Project URL + publishable key, ver `supabaseConfig.md` para el detalle de por qué esa clave no es un secreto). `Supabase.initialize(...)` se llama en `main.dart` antes de `runApp`, mismo lugar que el resto de las inicializaciones globales de la app. Se verificó con una consulta temporal a `mascotas_extraviadas` (tabla de lectura pública, no requiere sesión) que se sacó del código una vez confirmada la conexión — el log mostró `Supabase: conexión OK`. `supabaseClientProvider` (en `lib/providers/supabase_provider.dart`) expone el cliente vía Riverpod para que el código de las próximas fases (login real, sync, Mapa) lo use con el mismo patrón de DI que ya usa el resto del proyecto.

**Aparte, un ajuste de configuración que no es específico de Supabase pero que esta fase destapó:** `android/gradle.properties` tenía `-Xmx8G` para Gradle en una máquina con 7.1GB de RAM total — la primera compilación con una dependencia grande como `supabase_flutter` se cortó dos veces (una vez colgó el propio VSCode) porque Gradle pedía más memoria de la que existía físicamente, forzando swap pesado. Se bajó a `-Xmx2G`/`MaxMetaspaceSize=1G`/`ReservedCodeCacheSize=256m`, valores acordes a la RAM real de la máquina de desarrollo — con eso, la build siguiente compiló sin cortes.

**Mapa, punto 1 — `mascota_id` dejó de ser foreign key, datos de la mascota denormalizados en el reporte:** al diseñar `MascotaExtraviadaModel` (ver `mascotaExtraviada.model.md`) apareció un problema real en el esquema de `mascotas_extraviadas` recién escrito: su `mascota_id` referenciaba `mascotas(id)` de Supabase, pero esa tabla está vacía (no hay sync todavía, Fase 6 pendiente) — cualquier intento de publicar un reporte fallaría por violar la foreign key. Se resolvió denormalizando: el reporte ahora guarda copiados `mascota_nombre`/`mascota_especie`/`mascota_foto_url` al momento de publicar, en vez de ir a buscarlos por relación. `mascota_id` se mantuvo pero sin FK, solo como dato informativo local. Como ya no hay relación con `mascotas` para saber el dueño del reporte, se agregó `usuario_id` directo a la tabla (referencia real a `auth.users`), y las políticas de RLS de escritura pasaron a comparar contra ese campo en vez de hacerlo vía subconsulta a `mascotas`. Detalle a tener presente: si el usuario edita su mascota después de publicar un reporte, el reporte ya publicado no se actualiza solo — aceptado a propósito, un reporte de mascota perdida es una foto del momento.

**Nombres de política sin comillas, tras un error real:** al re-ejecutar el `.sql` corregido, los nombres de política originales (`"mascotas_extraviadas: solo el dueño puede crear"`, con espacios/dos puntos/tilde, que exigían comillas dobles) fallaron al pegarse desde el chat — el copiado convierte comillas rectas en tipográficas, y Postgres ya no las reconoce como el mismo carácter de apertura/cierre. Se renombraron a identificadores simples sin espacios ni tildes (`mascotas_extraviadas_lectura_publica`, etc.), que no necesitan comillas y no dependen de que el texto se copie sin alteraciones — evita que el mismo problema vuelva a aparecer en futuros cambios de esquema pegados desde el chat.

**Mapa, punto 3 — `flutter_map` (OpenStreetMap) en vez de `google_maps_flutter`, por costo de configuración:** para mostrar los reportes en un mapa se evaluaron los dos paquetes cross-platform estándar de Flutter. `google_maps_flutter` es visualmente más pulido y con mejor fluidez (vista nativa embebida, no widgets de Flutter dibujando tiles) — pero exige crear un proyecto en Google Cloud, habilitar las Maps SDK de Android/iOS y asociar una tarjeta de crédito con un depósito de USD 25 (reembolsable solo al cerrar la cuenta). El usuario descartó esa opción por chocar con el criterio de costos mínimos ya establecido (ver "Lanzamiento y monetización" en memoria — Ko-fi discreto en vez de ads, justamente para evitar este tipo de gastos). Se optó por `flutter_map` + tiles de OpenStreetMap: sin API key, sin cuenta, sin tarjeta — a cambio de una estética algo más simple por defecto y paneo/zoom levemente menos fluido (renderizado por widgets de Flutter, no por una vista nativa). Para geolocalizar el reporte se suma `geolocator` (estándar de facto en Flutter, sin alternativa real a evaluar) — maneja los permisos de Android/iOS internamente, agregados en `AndroidManifest.xml` (`ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION`) e `Info.plist` (`NSLocationWhenInUseUsageDescription`).

**Límite de reportes activos (anti-abuso) — trigger en Postgres, no solo validación en la app:** el usuario pidió evitar que alguien publique reportes sin límite. Se implementó como trigger `BEFORE INSERT` (`limitar_reportes_activos()`, ver el `.sql`) que rechaza el intento si el usuario ya tiene 3 reportes con `estado = 'perdido'` — los marcados `'encontrado'` no cuentan. Se hizo a nivel de base y no solo en la pantalla porque una validación únicamente del lado de la app se puede saltar llamando a la API de Supabase directo, sin pasar por la app — el límite real tiene que vivir donde no se puede evitar. El mensaje de error del trigger está en español fijo (no puede usar `AppLocalizations`, vive en la base) — la app lo intercepta por `PostgrestException.code == 'P0001'` (código por defecto de un `raise exception` de usuario) y muestra en su lugar un mensaje propio ya traducido a los tres idiomas, en vez del texto crudo que devuelve Postgres.

**Foto del reporte pospuesta para una fase posterior (pendiente, no resuelto):** el modelo (`MascotaExtraviadaModel.mascotaFotoUrl`) y la tabla ya contemplan el campo, pero por ahora la pantalla de reporte **no lo llena** — la foto de una mascota hoy es una ruta de archivo local (`mascota.fotoUrl`), útil solo en el propio teléfono; copiarla tal cual al reporte no le serviría a otro usuario viéndolo desde otro dispositivo. Mostrar la foto real requiere subirla a Supabase Storage, que es trabajo de la Fase 5 (todavía no implementada) — se decidió no adelantar esa pieza solo para esto, mismo criterio que ya se usó con `mascota_id`/sync. **Queda pendiente:** cuando se implemente Storage, conectar la subida de foto al flujo de reporte (subir al publicar, guardar la URL real en `mascotaFotoUrl`) y sumarla también a la UI de detalle de un reporte.

**Ajustes al formulario de reporte tras la primera prueba del usuario (2026-08-19):** recompensa pasó de campo de texto siempre visible a un `SwitchListTile` + campo condicional ("¿Ofreces recompensa?"); se sumó una segunda forma de indicar la ubicación (dirección a mano, geocodificada vía Nominatim de OpenStreetMap — gratis, sin API key, sin restringir a ningún país, mismo criterio que RUT/número de chip); y descripción pasó de opcional a obligatoria — junto con contacto de emergencia (ya obligatorio) y las dos formas de mascota (nombre/especie, ya fijos), quedan como los únicos dos campos realmente opcionales de todo el formulario: recompensa y ubicación, cada uno con una razón real para serlo (no siempre hay premio; no siempre se puede/quiere dar la ubicación exacta). Ver `formularioReporteMascotaExtraviadaScreen.md` para el detalle técnico completo.

**Hallazgo de paso: permiso de Internet faltaba en el manifiesto de release.** Al construir la geocodificación se notó que `android/app/src/main/AndroidManifest.xml` no tenía `INTERNET` — Flutter lo agrega solo, automáticamente, al manifiesto de **debug** (`android/app/src/debug/AndroidManifest.xml`), no al principal. No se había notado porque la app solo se había probado en modo debug hasta ahora; sin este permiso, un build de release no podría hablar ni con Supabase ni con Nominatim. Se agregó al manifiesto principal.

**Moderación de contenido — denuncia manual, no automática (2026-08-19):** el usuario planteó una preocupación real: ¿qué pasa si alguien publica un anuncio no relacionado con mascotas perdidas? Se descartó moderación automática (IA de clasificación de texto/imágenes) por ser una complejidad/costo que el volumen esperado al lanzar no justifica todavía. Se acordó un enfoque en dos partes: (1) el panel de Supabase ya permite al desarrollador ver/borrar cualquier reporte directamente (el Table Editor no pasa por las políticas de RLS, que solo restringen a la app) — disponible hoy, sin código nuevo; (2) un botón "Denunciar este aviso" por reporte, pendiente de construir junto con la UI de Mapa (punto 4), que guarda la denuncia en una tabla aparte para que el desarrollador la revise cuando quiera — sin ocultado automático.

**Aviso de política de uso — una sola vez, con el logo de la app (2026-08-19):** `MapaScreen` muestra, la primera vez que un usuario entra a esa pestaña, un diálogo no descartable (`barrierDismissible: false`) recordando que el módulo es solo para mascotas perdidas/encontradas y motivando a denunciar contenido que no corresponda. Se guarda en `UsuarioModel.avisoMapaVisto` (mismo criterio que `tema`/`idioma`, puramente local, no se replica en Supabase) para no repetirlo en cada visita — decisión explícita del usuario sobre la alternativa de mostrarlo siempre, a cambio de requerir un reinstalar la app por el cambio de esquema. El diálogo incluye el logo de la app (`assets/images/logo_patas_al_dia.png`, mismo asset que `LoginScreen`) — pedido explícito del usuario "para darle más profesionalismo".

**Mapa, punto 4 completado — tres formas de reportar, mapa real, denuncia (2026-08-19):** el usuario pidió expandir el alcance más allá de "reportar una mascota mía ya registrada": (1) mascota propia registrada (flujo original), (2) mascota propia sin registrar (nombre/especie a mano), y (3) "encontré una mascota que no es mía" (sin vínculo con ninguna mascota del usuario, nombre opcional, sin recompensa). Esto obligó a separar el viejo campo `estado` (`'perdido'`/`'encontrado'`) en dos: `tipo` (qué clase de reporte es — fijo desde que se crea) y `resuelto` (si sigue activo — lo único que cambia), porque un reporte "encontré una mascota" nace con naturaleza *encontrado* pero necesita seguir **activo** hasta que se resuelva, algo que el campo único no podía representar sin ambigüedad (ver `mascotaExtraviada.model.md`, punto 4, para el detalle completo). Se tuvo que recrear la tabla `mascotas_extraviadas` en Supabase (estaba vacía, sin costo de datos reales) y ajustar el trigger de límite de reportes para contar por `resuelto = false` en vez de `estado = 'perdido'`.

`MapaScreen` pasó de placeholder a contenido real: `flutter_map` con los reportes activos que tienen ubicación (marcadores rojo/verde según `tipo`), una fila horizontal aparte para los que no tienen ubicación (la ubicación es opcional en el formulario, así que un mapa solo no alcanzaba para no perder ninguno — se evaluó una vista de lista completa tipo toggle como en `AgendaScreen` y se descartó por complejidad), y un FAB que abre las tres variantes de reporte (con un selector de "cuál mascota" si el usuario tiene más de una registrada, más la opción "otra mascota, no registrada").

Se sumó la tabla `denuncias_reportes` (moderación manual acordada antes, ver la entrada anterior): sin motivo de texto libre, solo "quién denunció qué reporte", con una restricción única `(reporte_id, usuario_id)` para que no se pueda denunciar el mismo reporte más de una vez por usuario. `DetalleReporteMascotaExtraviadaScreen` (nueva) muestra el botón de denunciar (visible para cualquiera) y, solo para el dueño (comparando `auth.uid()` contra `reporte.usuarioId`, sin forzar una sesión nueva solo por mirar), marcar como resuelto/eliminar.

Un bug de paso, encontrado al construir estas pantallas: al reportar una mascota sin registrarla con especie "Otro", el texto libre se guarda directo en `mascotaEspecie` (no hay un campo separado como en `MascotaModel`) — `especieValorMostrar` fallaba mostrando "No especificada" en vez del texto real para cualquier valor no reconocido. Se corrigió separando el fallback de `especie == null` (→ "no especificada") del de un valor no nulo mal reconocido (→ se muestra tal cual, es texto libre) — ver `etiquetasLocalizadas.md`, punto 1.

Por requisito de OpenStreetMap, se agregó atribución visible (`RichAttributionWidget`, "© OpenStreetMap contributors") en los dos lugares donde se usa `flutter_map`.

**Ronda de bugs y ajustes tras probar la app completa (2026-08-19):** varios hallazgos del usuario, cada uno con su causa real confirmada antes de arreglar:
- **Navbar sin bordes curvos:** pedido de vuelta a un rectángulo normal — se sacó el `ClipRRect` que envolvía la barra inferior (ver `navegacionPrincipalScreen.md`, punto 4b).
- **"Sistema" del selector de idioma, sin traducir y en dos líneas:** bug real — a diferencia de ES/EN/PT (nombres de idioma, intencionalmente fijos), "Sistema" es un concepto de interfaz que debía traducirse como cualquier otro texto; se armaba desde una constante `'Sistema'` fija en español. Se corrigió con una clave nueva (`idiomaSistemaLabel` = "Auto" en los tres idiomas) armada en `build()` en vez de en el array constante — ver `ajustesScreen.md`, punto 6.
- **Crash "Infinity or NaN toInt" al interactuar mucho con el zoom del mapa:** un primer intento (límites solo en `MapOptions`) no alcanzó — se confirmó la causa real con el log del dispositivo (`TileRangeCalculator.calculate` dentro de `TileLayer`, no de `MapOptions`) y se agregaron los mismos límites (`minZoom: 2, maxZoom: 19`) también en el `TileLayer` — ver `mapaTiles.md`, punto 3.
- **Texto invisible en modo oscuro, en las dos tarjetas nuevas de `MapaScreen`:** mismo bug ya resuelto antes para otras pantallas (`Card` con fondo Durazno fijo + texto que sigue el tema activo) — se envolvieron con `TarjetaClara` en vez de `Card` directo (ver `mapaScreen.md`, punto 10).
- **"No se pudo publicar el reporte, revisa tu conexión" con conexión real:** el mensaje mentía — la causa real (confirmada con `adb logcat` en vivo mientras el usuario reproducía la acción, no a ciegas) era que "Anonymous Sign-ins" había quedado deshabilitado en el proyecto de Supabase. Se agregó un mensaje de error específico para fallas de autenticación (`errorAutenticacionReporte`), distinto del genérico de conexión — ver `formularioReporteMascotaExtraviadaScreen.md`, punto 5b.
- **Segunda línea de dirección, opcional:** se sumó `campoReferenciaDireccion` (depto/esquina/etc.) al bloque de dirección manual, concatenada a la búsqueda de Nominatim.

**Ícono de reporte rediseñado — pata en triángulo, amarillo/azul (2026-08-19):** el usuario pidió reemplazar el pin rojo/verde (`Icons.location_on`) por algo más distintivo: la misma pata del navbar (`Icons.pets`) encerrada en un triángulo de advertencia, amarillo para "perdido" y azul para "encontrado". Se armó componiendo dos íconos de Material en un `Stack` (`IconoTipoReporte`, ver `iconoTipoReporte.md`) en vez de sumar un SVG a medida — reutilizado en los cuatro lugares donde antes se repetía la lógica rojo/verde (marcadores del mapa, burbuja, chips de "sin ubicación", mini-mapa y chip de tipo del detalle). De paso corrigió un bug menor: el marcador del mini-mapa en `DetalleReporteMascotaExtraviadaScreen` estaba fijo en rojo sin mirar el `tipo` real del reporte.

**Tiles CARTO (Positron/Dark Matter) + burbuja al tocar un marcador — feedback del usuario tras probar el mapa (2026-08-19):** dos ajustes pedidos después de la primera prueba. (1) el estilo de tiles crudo de OpenStreetMap se veía "feo" — se cambió a CARTO Basemaps (Positron claro, Dark Matter oscuro), gratis y sin API key igual que antes, elegidos por ser explícitamente la pareja diseñada para verse coherente entre sí — el mapa cambia de estilo solo según `Theme.of(context).brightness`, mismo criterio que ya usa el resto de la app para adaptarse al tema. Centralizado en `lib/presentation/utils/mapa_tiles.dart` (`urlTilesSegunTema`/`atribucionMapa`, con atribución a OpenStreetMap y CARTO), usado por `MapaScreen` y `DetalleReporteMascotaExtraviadaScreen` — ver `mapaTiles.md`. (2) tocar un marcador ahora abre una burbuja flotante con nombre/tipo del reporte (mismo patrón que Google Maps/Apple Maps) en vez de navegar directo al detalle — la burbuja se cierra tocando el mapa vacío o con su propio botón, y solo al tocarla se llega al detalle completo. Sin anclar la burbuja al pixel exacto del marcador (requeriría un paquete adicional) — se usa una posición fija en la parte inferior del mapa. Ver `mapaScreen.md`, puntos 8-9.

---

## 2026-08-19 — Ronda de mejoras tras usar la app completa: ubicación automática, Documentos por fecha/cronológico, reportes sin ubicación en lista

Cinco sugerencias del usuario tras probar el módulo Mapa completo, evaluadas una por una (opinión pedida explícitamente, no la neutralidad por defecto de otras decisiones — ver `feedback_neutralidad_arquitectura` en memoria):

1. **Ubicación automática al abrir el formulario de reporte** — implementada. El switch "usar ubicación actual" ya arrancaba activado; pedir además un toque en "Obtener ubicación" era un paso de más. Ver `formularioReporteMascotaExtraviadaScreen.md`, punto 9b.
2. **Notificación por reportes en un radio (~1 km)** — pospuesta como fase propia, sin fecha. Requiere infraestructura de push real (Firebase Cloud Messaging + lógica server-side), una categoría de trabajo comparable a Login real/Storage/Sync de Supabase — ver memoria `project_notificaciones_radio_pendiente`.
3. **Documentos: alternar entre agrupado por tipo y orden cronológico** — implementada con un `IconButton` en el AppBar, mismo patrón que el toggle calendario/lista de `AgendaScreen`. Ver `documentosScreen.md`, punto 5.
4. **Fecha del documento visible en la tarjeta** — implementada sin necesitar debate, mejora chica y clara. Ver `documentosScreen.md`, punto 5.
5. **Reportes sin ubicación en una lista aparte, no en la fila fija del mapa** — implementada: botón + `showModalBottomSheet`, en vez de una fila horizontal que le restaba espacio al mapa todo el tiempo. Ver `mapaScreen.md`, punto 6.

---

## 2026-08-19 — Ubicación obligatoria en los reportes (revierte la decisión "opcional" del mismo día)

El usuario, después de usar el botón de "reportes sin ubicación" que se acababa de construir (ver la entrada anterior, punto 5), se dio cuenta de que la ubicación debería ser obligatoria: un reporte sin ella no aparece en el mapa, que es el propósito central del módulo — la opcionalidad original (pensada para el caso "reporto desde un lugar distinto al que perdí la mascota") generaba más problemas de los que resolvía.

**Cómo se hizo obligatoria sin volverla imposible de cumplir:** el GPS puede fallar (sin señal, permiso denegado) y la geocodificación de una dirección manual puede no encontrar resultados — así que no se exige "coordenadas sí o sí" a ciegas. En cambio, `_publicarReporte()` bloquea el guardado (con un mensaje y la posibilidad de reintentar) si, después de intentar el camino elegido (GPS o dirección), `ubicacionLat`/`ubicacionLng` siguen sin valor. El campo "Calle" también pasó a tener su propio validador cuando se usa el modo dirección. Ver `formularioReporteMascotaExtraviadaScreen.md`, punto 3.

**Refuerzo en la base:** se agregó un `check` constraint en `mascotas_extraviadas` (`ubicacion_lat is not null and ubicacion_lng is not null`), con `not valid` para no romper por los reportes de prueba que ya existían sin ubicación de antes de este cambio — mismo criterio que el trigger de límite de reportes: una validación solo del lado de la app se puede saltar llamando a la API directo.

**Limpieza pedida explícitamente por el usuario ("no tengamos código basura"):** con la ubicación garantizada, el botón/lista de "reportes sin ubicación" (construido esa misma sesión, ver la entrada anterior) nunca iba a tener nada que mostrar — se eliminó por completo (el método, el `Positioned`, las claves de traducción que solo usaba), en vez de dejarlo como código muerto. `MapaScreen` volvió a depender solo de `reportes`, con un filtro defensivo (`conUbicacion`) que protege únicamente contra los reportes de prueba viejos que puedan quedar sin ubicación en la base — no es una feature, solo evita un crash.

---

## 2026-08-19 — Foto obligatoria en los reportes, con Supabase Storage

Después de dejar la ubicación obligatoria (entrada anterior), el usuario pidió seguir con "el tema de la imagen" — hasta ese momento, `MascotaExtraviadaModel.mascotaFotoUrl` quedaba sin llenar (pendiente, Fase 5 de Supabase). Dos decisiones tomadas explícitamente por el usuario, en contra de mi recomendación en ambos casos:

- **Foto obligatoria, no opcional.** Recomendé opcional (coherente con el resto de los campos verdaderamente opcionales — recompensa — y para no bloquear una publicación rápida si alguien no tiene una foto a mano en el momento). El usuario prefirió obligatoria: un reporte sin foto es mucho menos útil para que alguien reconozca a la mascota.
- **Siempre pedir una foto nueva, incluso con mascota registrada** (que ya tiene `fotoUrl` guardada). Recomendé reutilizar la foto existente como default, con opción de cambiarla. El usuario prefirió pedir siempre una foto nueva — la foto del reporte debe reflejar el estado actual de la mascota (pelaje, collar, etc.), no una foto de perfil que puede ser vieja.

**Primer uso de Supabase Storage en el proyecto** (hasta ahora solo se usaba la base de datos vía PostgREST). Bucket `fotos_reportes`, público para lectura (cualquiera necesita ver la foto en el mapa/detalle, mismo criterio que la lectura pública de `mascotas_extraviadas`), restringido a usuarios autenticados para escritura — sin políticas de update/delete, una foto de reporte no se reemplaza ni se borra sola por ahora. Ver `TablaMaestraAppVetMovil1.sql`, sección 7.

`MascotaExtraviadaRepository.subirFoto()` sube el archivo local y devuelve la URL pública, que se guarda en `mascotaFotoUrl` al armar el reporte — la subida ocurre antes del `insert`, no después, así que un fallo de subida (`StorageException`, con mensaje propio en vez de caer en el genérico de conexión) bloquea la publicación en vez de dejar un reporte a medias. Ver `formularioReporteMascotaExtraviadaScreen.md`, punto 6, y `mascotaExtraviada.repository.md`, punto 5b.

---

## 2026-08-19 — Login real (Fase 4 de Supabase)

Con Storage (Fase 5, adelantada de paso para las fotos de reportes — ver entrada anterior) ya funcionando, se retomó el orden original de fases y se implementó Fase 4: login real con Supabase Auth. Antes de programar, se discutieron tres decisiones con el usuario (ver también memoria `feedback_metodo_aprendizaje` — se le pidió primero cómo lo abordaría él, y se comparó el razonamiento antes de definir):

1. **Email + contraseña, no magic link.** El usuario ya se inclinaba por esto; la razón real (corregida en la discusión) no es necesitar un servidor de correo propio — Supabase ya manda esos correos solo — sino que un magic link exige que la app capture un "deep link" cuando el usuario toca el enlace del correo, lo que implica configurar esquemas de URL nativos en Android e iOS por separado. Email+contraseña es un simple llamado a la API de Supabase, sin nada de eso.
2. **Un invitado con datos ya cargados se convierte en registrado, sin dudarlo** — conserva mascotas/agenda/documentos/preferencias al registrarse, en vez de arrancar de cero.
3. **El `id` local (SQLite) pasa a ser el mismo `auth.uid()` de Supabase al registrarse**, en vez de guardarse como un campo aparte. El propio esquema (`TablaMaestraAppVetMovil1.sql`) ya anticipaba esto — `usuarios.id` está declarado como `references auth.users (id)` desde que se escribió el schema completo (ver entrada del 2026-08-18), aunque en ese momento quedó como "pendiente para la fase de login real". El usuario lo eligió explícitamente después de entender el trade-off: es más trabajo ahora (una migración chica, una sola vez, al registrarse) a cambio de nada de trabajo extra en Sync (la fase siguiente) para siempre — sin esto, cada operación de sync tendría que traducir entre dos sistemas de ids, en vez de hacer un simple "traer/empujar lo que tiene mi id".

**Alcance de esta fase:** solo Supabase Auth (`signUp`/`signInWithPassword`/`signOut`) y el estado local (`usuarios` en SQLite) — no toca la tabla `public.usuarios` de Supabase ni sincroniza mascotas/agenda/documentos todavía, eso es Sync (Fase 6, la que sigue). Un usuario que inicia sesión en un dispositivo nuevo arranca con datos locales vacíos hasta que esa fase exista.

**"Olvidé mi contraseña" quedó fuera de esta tanda** (decisión explícita del usuario, "para después") — la app queda sin forma de recuperar el acceso si alguien olvida su contraseña, ítem pendiente para una vuelta posterior.

**El proyecto de Supabase del usuario ya tenía "Confirm email" activado** — esto determinó el diseño del flujo de registro: `signUp()` no deja una sesión activa hasta que el usuario confirma por correo, pero sí devuelve el `auth.uid()` definitivo de inmediato, así que la conversión/creación local ocurre igual, sin esperar la confirmación (la app queda usable de inmediato, local-first) — la confirmación por correo solo importa para poder iniciar sesión en otro dispositivo más adelante. Ver `registroScreen.md`.

**Bug de Supabase evitado a propósito, no encontrado en producción:** con "Confirm email" activado, registrarse con un correo que ya tiene una cuenta confirmada no devuelve ningún error (comportamiento intencional de Supabase, para no revelar si un correo existe o no) — devuelve éxito sin sesión, con `identities` vacío como única señal real de que no pasó nada nuevo. Sin chequear esto, se habría terminado reasignando los datos locales al `auth.uid()` de una cuenta ajena. Ver `usuarioNotifier.md`, punto 9.

**Hallazgo de paso, sin resolver todavía:** al diseñar cómo reasignar `mascotas.usuario_id` durante la conversión, se notó que `database_helper.dart` nunca activa `PRAGMA foreign_keys = ON` — sin eso, SQLite no aplica ningún `ON DELETE CASCADE` declarado en el schema. En la práctica, borrar una mascota (o un usuario) hoy deja huérfanas las filas hijas en la base local en vez de borrarlas en cascada como parecía. No bloqueaba el trabajo de esta fase (la conversión usa una transacción explícita, no depende del cascade), así que se dejó pendiente — ver `usuario.repository.md`, punto 5.

**"Olvidé mi contraseña" — retomado el mismo día, con enlace por correo (después de un cambio de plan sobre la marcha).** Mismo razonamiento que la elección de email+contraseña sobre magic link: el enlace de recuperación de Supabase también exige deep linking nativo para volver a abrir la app — por eso la primera decisión fue evitarlo, con un código de 6 dígitos que Supabase manda por correo (`resetPasswordForEmail` → `verifyOTP(type: recovery)` → `updateUser`).

Al ir a configurar la plantilla de correo para mostrar ese código (agregar `{{ .Token }}` al texto de "Reset Password" en el panel de Supabase), apareció un bloqueo no anticipado: el panel avisa explícitamente que **las plantillas de correo no se pueden editar sin tener SMTP propio configurado** — con el correo por defecto de Supabase (el que usa el proyecto), el texto queda fijo, solo con el enlace visible, nunca con el código. Se le presentó el trade-off actualizado al usuario ("¿configurar SMTP propio para poder seguir con el código, o volver al enlace con deep linking?") y se optó por el enlace — evita sumar una cuenta/infraestructura de correo nueva, a cambio de aceptar el deep linking que se había querido evitar.

**Implementación del enlace:** esquema propio `patasaldia://reset-password`, registrado en `AndroidManifest.xml` (`intent-filter` con `android:scheme`/`android:host`) e `Info.plist` (`CFBundleURLTypes`) — `supabase_flutter` ya trae `app_links` como dependencia transitiva y lo captura solo, sin sumar ningún paquete nuevo al proyecto (mismo criterio de dependencias mínimas). `main.dart` escucha `Supabase.instance.client.auth.onAuthStateChange` por el evento `AuthChangeEvent.passwordRecovery` y navega a `NuevaContrasenaScreen` usando un `navigatorKey` global (primera vez que el proyecto navega desde fuera del árbol de widgets, sin un `BuildContext` de por medio). Ver `recuperarContrasenaScreen.md` y `nuevaContrasenaScreen.md`.

---

## 2026-08-19 — Eliminar cuenta, con Edge Function para el borrado remoto real

Pedido del usuario tras terminar "olvidé mi contraseña": faltaba una forma de borrar la cuenta, con una advertencia clara de que es irreversible. Dos decisiones tomadas antes de programar:

1. **Arreglar el cascade delete roto (`PRAGMA foreign_keys`) como parte de esto, no después.** Ya estaba anotado como hallazgo pendiente desde la entrada de Login real (arriba) — sin el fix, "eliminar cuenta" en un invitado hubiera dejado mascotas/agenda/documentos huérfanos en la base local, aunque la app dijera "tu cuenta se borró". Corregido en `database_helper.dart` con `onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON')` — ver `database.helper.md`, punto 8b.
2. **Borrado remoto real para usuarios registrados, no solo local.** La app (con la clave pública) no puede borrar una cuenta de Supabase Auth por sí sola — esa operación exige la "service_role key", un secreto que nunca puede vivir en el código del cliente. Se evaluaron dos caminos: dejar el borrado remoto pendiente (solo borrar datos locales, documentando el límite) o sumar una Edge Function (código que corre en el servidor de Supabase, con esa clave disponible de forma segura). El usuario eligió la segunda — la cuenta se borra de verdad, no solo el rastro local.

**Primera pieza de infraestructura de servidor del proyecto** (`supabase/functions/eliminar-cuenta/index.ts`, Deno/TypeScript, no Dart) — ver `eliminarCuentaFunction.md` para el detalle técnico completo. Identifica a quién borrar por el JWT de quien llama, nunca por un id recibido como parámetro (para que nadie pueda pedir borrar una cuenta ajena).

**Fricción real al desplegar, documentada para la próxima vez:** esta máquina no tenía el CLI de Supabase ni Node/npm instalados, y usa Podman en vez de Docker. El flujo estándar de instalación (`.rpm` vía `sudo rpm -i`) y de despliegue (`supabase functions deploy`, que arma un contenedor local) fallaron por eso — se resolvió instalando el binario suelto en `~/.local/bin` (sin `sudo`) y desplegando con `--use-api` (sin Docker/Podman). También se encontró que `supabase login` no funciona en un entorno sin terminal interactiva (esta sesión) — hizo falta un Personal Access Token generado a mano en el panel de Supabase y pasado con `supabase login --token`.

**`UsuarioNotifier.eliminarUsuario()` ya existía** (CRUD base, desde antes de Login real) pero nunca había estado conectado a ningún botón — se extendió en el lugar para sumar el borrado remoto (solo si `!esInvitado`) antes del borrado local, en vez de crear un método nuevo. Si el borrado remoto falla, no se borra nada local — mejor un reintento con todo intacto que un estado a medio borrar. Ver `usuarioNotifier.md`, punto 4, y `ajustesScreen.md`, punto 8.

---

## 2026-08-20 — Requisitos de contraseña, compresión de fotos de reporte y bug de fotos huérfanas en Storage

Tres pendientes/hallazgos resueltos en la misma sesión, todos relacionados con el módulo Mapa y Login real.

**1. Requisitos de contraseña.** Pendiente desde el cierre de Login real (ver memoria de sesión `project_requisitos_contrasena_pendiente`, ya resuelta y borrada). Se le preguntó al usuario cómo lo abordaría antes de proponer nada (ver `feedback_metodo_aprendizaje`) — propuso mínimo 8 caracteres, una mayúscula y un número, explícitamente sin exigir símbolo ("no es algo de vital importancia... la idea es que sea de fácil uso"). Se implementó en `validador_contrasena.dart` (ver `validadorContrasena.md`), compartido entre `RegistroScreen` y `NuevaContrasenaScreen` — antes cada pantalla tenía su propio validador de una sola línea, duplicado; con tres reglas a la vez valía la pena extraerlo. Reforzado también en el panel de Supabase (Authentication → Sign In / Providers → Email → mínimo 8 + dígito/mayúscula) — mismo criterio que el resto de las validaciones del proyecto que también viven del lado del servidor.

**2. Compresión de la foto de reporte.** Surgió de una pregunta del usuario sobre cuánto ocuparía en Supabase el almacenamiento de un usuario promedio. Revisando el código se encontró que `image_picker` subía la foto del reporte (la única foto de todo el proyecto que va a la nube — las de mascota/documentos quedan solo en el dispositivo) sin ningún límite de calidad/resolución: 3 a 8 MB típico en un teléfono moderno. Se agregó `maxWidth: 1600, imageQuality: 75` en `formulario_reporte_mascota_extraviada_screen.dart` — medido en producción, una foto real bajó de varios MB a 117 KB. Se evaluó comprimir también las fotos de mascota/documentos y se descartó: sin costo de Storage de por medio (quedan locales), el ahorro no justifica el riesgo — sobre todo en documentos, donde la legibilidad del texto (dosis, fechas) importa más que el peso del archivo.

**3. Fotos huérfanas en Storage al borrar un reporte (bug real, no solo hallazgo).** Mismo hilo de la pregunta de almacenamiento: se encontró que `eliminarReporte()` solo borraba la fila de `mascotas_extraviadas`, nunca la foto del bucket `fotos_reportes` — cada reporte borrado dejaba su foto ocupando espacio para siempre. Se corrigió pasando el `MascotaExtraviadaModel` completo (no solo el `id`) a `eliminarReporte`, para poder reconstruir la ruta del archivo en Storage y borrarlo antes de la fila (best effort, no bloquea el borrado del reporte si falla). **Segunda vuelta necesaria:** el primer intento no funcionó en la práctica — faltaba una política de `delete` en `storage.objects` para el bucket (solo existían las de lectura e inserción desde que se creó, ver la entrada del 2026-08-19). Se agregó `fotos_reportes_borrar_dueno`, restringida al dueño de la foto vía `(storage.foldername(name))[1] = auth.uid()::text`. Confirmado con pruebas reales contra la API pública de Supabase (antes de la política: la foto seguía respondiendo `200` después de borrar el reporte; después: `400`). Ver `mascotaExtraviada.repository.md`, punto 5, y `TablaMaestraAppVetMovil1.sql`, sección 7.

**De paso, tooling:** se activó `org.gradle.caching` en `android/gradle.properties` para acelerar builds repetidos sin pedir más RAM (a diferencia de `org.gradle.parallel`, descartado — esta máquina ya viene con problemas recurrentes de memoria durante los builds, ver memoria de sesión `project_dispositivo_pruebas_quirks`). También se probó `org.gradle.configuration-cache`, pero se sacó el mismo día: rompía el build (`DebugMinSdkCheck`, un task interno de Flutter, usa tipos que la configuration cache de Gradle 9 no puede serializar) — se detectó de inmediato al primer build siguiente y se revirtió.

---

## 2026-08-20 (continuación) — Página de confirmación de correo, con hosting externo

Retomado el pendiente de la sesión anterior (ver memoria de sesión `project_pagina_confirmacion_correo_rota`, ya resuelta y borrada): el enlace de "confirma tu correo" redirigía a `http://localhost:3000` (Site URL sin configurar), mostrando un error de conexión aunque la confirmación en sí ya hubiera funcionado.

**Primer intento descartado: subir una página propia a Supabase Storage.** Se creó el bucket `paginas_publicas` (con su política de lectura pública, ver `TablaMaestraAppVetMovil1.sql`, sección 8) y se armó una página HTML con el logo y la paleta de la app. Al subirla, Supabase Storage devolvía `Content-Type: text/plain` sin importar qué se le pidiera — probado con tres métodos distintos (CLI `storage cp --experimental`, subida binaria directa con header explícito, `multipart/form-data`), los tres iguales. Es una medida de seguridad de la plataforma (no servir HTML/scripts arbitrarios subidos por cualquiera bajo su propio dominio), no un bug para reportar ni arreglar del lado de la app.

**Se evaluó también deep linking** (mismo patrón que "olvidé mi contraseña") y se descartó: el evento que dispara la confirmación de registro es `AuthChangeEvent.signedIn`, el mismo que dispara cualquier login normal — reabrir la app ahí sería ambiguo sin lógica extra frágil (¿cómo distinguir "recién confirmaste tu correo" de "iniciaste sesión como siempre"?).

**Decisión final:** el usuario, explícitamente, priorizó que se vea profesional ("es prácticamente la primera impresión de la app" para alguien que se acaba de registrar) por sobre dejarlo pendiente. Se creó un repo nuevo y público en GitHub (`PatasAlDiaWeb`, separado del repo principal — que es privado), con una sola página estática (mismo logo y paleta de colores que la app: Naranja/Naranja marca/Durazno/Café texto, tipografías Nunito/Source Sans 3 vía Google Fonts), publicada con GitHub Pages. `signUp()` ahora pasa `emailRedirectTo` apuntando a esa URL (ver `supabase_config.dart`, `supabaseConfig.md` punto 5) — hay que agregarla a la lista de "Redirect URLs" del panel de Supabase, igual que se hizo para la de recuperar contraseña (las dos URLs conviven ahí, una por flujo).

**Bug de comunicación encontrado de paso:** la primera versión de la página tenía voseo rioplatense ("podés" en vez de "puedes") — cuarta vez que se repite este error en la sesión con este usuario, y la primera vez que aparece en un archivo fuera de `lib/` (no pasa por el flujo habitual de revisión de strings de UI en Dart). Corregido y republicado — ver memoria de sesión `feedback_comunicacion_idioma`, actualizada para cubrir explícitamente cualquier texto generado, no solo el código Dart.

**De paso, otro hallazgo de tooling:** `org.gradle.configuration-cache` (activado el mismo día, ver entrada anterior) rompía el build por una incompatibilidad de Gradle 9 con un task interno de Flutter (`DebugMinSdkCheck`) — se detectó en el primer build siguiente y se revirtió, dejando solo `org.gradle.caching`.

---

## 2026-08-20/21 — Sync (Fase 6 de Supabase)

Última fase grande del plan de Supabase. Con Login real, Storage y los retoques ya cerrados, un usuario registrado no tenía ninguna diferencia real frente a un invitado: sus datos vivían solo en el dispositivo donde se cargaron. Antes de programar, se discutieron seis decisiones con el usuario (mismo método que en Login real — se le preguntó primero cómo lo abordaría él):

1. **Dos sentidos** (multi-dispositivo real, no solo respaldo).
2. **Automático pero no instantáneo**: se dispara en momentos naturales (abrir la app, cada 5 minutos mientras está abierta, antes de pasar a segundo plano — ver `main.dart`), agrupando cambios en vez de sincronizar en cada tecla. Sin conexión, los cambios quedan pendientes para la próxima vez que la haya (mismo criterio reactivo ya usado en el módulo Mapa, sin paquete de detección de conectividad).
3. **Sincroniza todo**: las 4 entidades (Mascota, AgendaEvento, MedicamentoEvento, Documento), incluidos sus archivos — no solo las filas de la base.
4. **Compresión de imágenes**: foto de mascota con compresión agresiva (igual que la foto de reporte, `maxWidth: 1600, imageQuality: 75`). Documentos-imagen con compresión suave que preserve legibilidad (`maxWidth: 2000, imageQuality: 90`). PDFs sin comprimir — investigado, no existe un paquete maduro de compresión de PDF para Flutter; se descartó sumar uno.
5. **Conflictos: gana el cambio más reciente** (por timestamp), sin avisos ni merge manual.
6. **Solo usuarios registrados sincronizan** — un invitado no tiene una identidad estable contra la cual sincronizar.

**Plan formal, primera vez en el proyecto.** Dado el tamaño de la fase, se usó por primera vez el flujo de Plan Mode: investigación de la capa de datos existente, un pase de validación técnica que encontró un bug bloqueante real antes de escribir una sola línea (ver el hallazgo del FK, abajo), plan escrito a 5 fases con checkpoints detallados, aprobado por el usuario después de una ronda de ajuste (pidió más detalle en los pasos de prueba y preguntó cómo probar "otro dispositivo" sin tener la app publicada — se resolvió simulándolo con llamadas directas a la API de Supabase con la `service_role key`, sin necesitar una segunda app corriendo, dado que esta máquina ya mostraba problemas de RAM compilando para un solo dispositivo).

### Hallazgo 1 (encontrado en el diseño, antes de programar) — FK real de `public.usuarios`

`mascotas.usuario_id` tiene un `FOREIGN KEY` real hacia `public.usuarios(id)` en Postgres, no solo una política de RLS. Esa tabla nunca se pobló durante Login real (documentado como pendiente en su momento, ver la entrada del 2026-08-19). Sin corregirlo, el primer `push` de cualquier mascota habría fallado por violación de FK. Se resolvió con un `upsert` mínimo a `usuarios` (`id`/`email`/`es_invitado`, sin tocar preferencias) al principio de cada corrida de sync — ver `syncService.md`, punto 2.

### Hallazgo 2 (encontrado en el diseño) — ruta de Storage, no URL

El diseño inicial imaginaba `fotoRutaNube`/`archivoRutaNube` guardando una URL pública. Corregido en la validación: los buckets de Sync (`fotos_mascotas`, `archivos_documentos`) son privados — a diferencia de `fotos_reportes` (público) — y un bucket privado no tiene URL pública estable (`getPublicUrl()` da 403). Esos campos guardan la ruta del objeto dentro del bucket; la descarga usa `.download(ruta)`, no un `Uri` directo.

### Soft-delete, no `DELETE` real

Sincronizar borrados en dos sentidos exige que un borrado deje rastro — un `DELETE` no lo hace. Las 4 tablas suman `eliminado`/`eliminado_en`, y cada `eliminarX` pasó de un `DELETE` a una transacción manual (`db.transaction`) que respeta las cascadas *reales* del schema, no las aplana: `eliminarMascota` propaga a agenda/documentos/medicamentos (mismo alcance que el `ON DELETE CASCADE` real); `eliminarAgendaEvento` sí soft-deletea sus medicamentos, pero solo desvincula (`evento_id = NULL`) sus documentos, preservando el `ON DELETE SET NULL` original — un documento sobrevive al borrado del evento que lo generó. Ver `mascota.repository.md` y `agendaEvento.repository.md`.

### Bug real 1 (encontrado probando el checkpoint de la Fase 3) — timestamps mezclando zona horaria

Probando que un cambio hecho "desde otro dispositivo" (simulado editando la fila directo en Supabase) apareciera solo al reabrir la app, se encontró que la edición manual quedaba pisada de vuelta al valor viejo apenas la app sincronizaba. Causa: `actualizado_en` se escribía con `DateTime.now()` (hora local del dispositivo, sin zona) en las escrituras locales, pero con hora UTC (con "Z") en las filas traídas por pull desde Postgres — comparar ambos formatos como texto plano en una consulta SQL (`WHERE actualizado_en > ?`) daba resultados incorrectos según el desfase horario real del dispositivo (Chile, UTC-3/-4), haciendo que una fila recién traída pareciera "modificada más recientemente" de lo que en verdad estaba. Corregido cambiando los 5 puntos donde el proyecto estampa esta columna (4 repositories + `sync_service.dart`) de `DateTime.now()` a `DateTime.now().toUtc()`. Ver `mascota.model.md`, punto 7.

### Bug real 2 (encontrado en la misma sesión de pruebas, más de fondo) — `pendiente_push`

Corregido el bug de zona horaria, el mismo síntoma volvió a aparecer una corrida después: una edición manual en Supabase se pisaba de vuelta al valor viejo, esta vez con los timestamps ya consistentes. Causa real, más estructural: el motor decidía qué empujar mirando si `actualizado_en` era más nuevo que la última sincronización exitosa — eso no distingue "lo edité yo acá" de "esta fila tiene una fecha reciente porque la acabo de traer por pull". Una fila recién traída volvía a calificar para el `push` en la corrida siguiente, y ese `push` no comparaba contra lo que hubiera en Supabase en ese momento — simplemente sobrescribía, sin importar si mientras tanto había llegado una edición más nueva de otro lado.

**La solución:** columna `pendiente_push`, puramente local (no existe en Postgres), prendida solo por escrituras genuinamente locales y apagada solo después de un `push` exitoso — o implícitamente al recibir una fila por pull (`guardarDesdeSync`, un `INSERT OR REPLACE`, deja cualquier columna no mencionada en su `DEFAULT`, 0). El filtro de "qué empujar" pasó de comparar fechas a `WHERE pendiente_push = 1`, sin ambigüedad posible entre "lo edité" y "tiene fecha reciente". Ver `database.helper.md`, punto 9, `syncService.md`, punto 5, y `mascota.repository.md`, puntos 6-9, para el detalle completo — incluida una segunda corrección de paso (`actualizarFotoRutaNube`/`actualizarArchivoRutaNube` en vez de `guardarDesdeSync` al guardar la ruta de un archivo recién subido, para no apagar `pendiente_push` antes de tiempo si el `push` de la fila completa fallara justo después).

**Verificado con pruebas reales contra Supabase**, no solo revisión de código: simulando "otro dispositivo" con ediciones directas vía `service_role key` (REST API), con la app real corriendo en el teléfono de prueba — el mismo método de verificación que ya se venía usando en las fases anteriores de Sync, sin necesitar una segunda app corriendo en paralelo.

### `documentos.file_path` pasa a nullable (2026-08-21, bug real encontrado en el mismo pase)

Probando el primer login limpio con datos ya existentes en Supabase, la sincronización moría a mitad de camino con `NOT NULL constraint failed: documentos.file_path`. La columna local se había dejado obligatoria bajo el supuesto de que "toda fila activa localmente siempre tiene un archivo" — cierto antes de Sync (un documento nacía siempre junto con su archivo elegido en el formulario), falso apenas existe la posibilidad de traer por pull una fila cuyo archivo todavía no se descargó (o cuya descarga falló). El lado de Postgres ya era nullable desde que se diseñó el schema completo; solo faltaba corregir la columna local. Ver `database.helper.md`, punto 9, y `documento.model.md`, punto 6.

### Disparadores automáticos (Fase 3) — `main.dart`

`MyApp` pasó de `ConsumerWidget` a `ConsumerStatefulWidget` con `WidgetsBindingObserver`. Tres disparadores, los tres llaman a `sincronizar()` sin condición (la guarda de invitado/sin sesión ya vive dentro de `SyncService`):
- `ref.listen<UsuarioModel?>(usuarioProvider, ...)` dentro de `build()`, disparando en la transición exacta de "no elegible" a "elegible para sync" — cubre de una sola vez arranque en frío con sesión ya existente, login recién hecho, registro recién hecho y conversión de invitado a registrado, sin depender de `initState`/`didChangeAppLifecycleState` (que no cubren de forma confiable el arranque en frío). Comparado explícitamente contra el `anterior` de cada cambio (no solo "¿es elegible ahora?"), para no volver a disparar sync en cada edición de preferencias de un usuario que ya estaba sincronizando desde antes.
- `Timer.periodic(Duration(minutes: 5))` mientras la app está en primer plano — arranca en `initState` y se reinicia en cada `resumed`, se cancela en `paused`.
- `didChangeAppLifecycleState(AppLifecycleState.paused)` — un intento más, best-effort, justo antes de pasar a segundo plano.

Los tres confirmados con pruebas reales en el checkpoint de esta fase (edición manual en Supabase con la app cerrada, con la app abierta esperando el timer, y pasando a segundo plano justo después de una edición) — ver `ajustesScreen.md`, punto 9, para el respaldo manual que queda en la UI.

### Bug real 3 (2026-08-21, encontrado en la prueba final combinada) — `INSERT OR REPLACE` borraba hijos de verdad al recibir un pull

El más serio de los tres bugs de esta fase — no era un problema de "vuelve a subir de más", era pérdida real de datos. Probando varias entidades a la vez (mascota + agenda + medicamento + documento, mezclando ediciones locales con ediciones remotas simuladas), el evento de agenda y el documento de una mascota **desaparecieron por completo** de la base local apenas la app trajo por pull una edición remota de esa mascota — no quedaron con `eliminado = 1` (soft-delete), quedaron genuinamente borrados de la tabla.

**Causa:** los 4 `guardarDesdeSync` (uno por repository) usaban `db.insert(..., conflictAlgorithm: ConflictAlgorithm.replace)`. `INSERT OR REPLACE` en SQLite, ante un conflicto de `PRIMARY KEY`, no actualiza la fila existente — la **borra** primero y recién ahí inserta la nueva. Con `PRAGMA foreign_keys = ON` activo (corregido en la entrada de "Eliminar cuenta", arriba), ese borrado oculto disparaba el `ON DELETE CASCADE` real del schema hacia `agenda_eventos`/`documentos`/`medicamentos_evento`, exactamente como si se hubiera ejecutado un `DELETE` a mano. No se detectó en las Fases 1-2 porque casi todas las filas traídas ahí eran nuevas para el dispositivo (`REPLACE` solo borra si hay un conflicto real de PK) — recién al traer la actualización de una mascota que ya tenía hijos locales se dio la condición exacta para disparar el bug.

**El riesgo real:** si un dispositivo hubiera tenido una edición local de un hijo (un evento, un documento) todavía sin subir en el momento exacto de un pull sobre su mascota padre, esa edición se habría perdido para siempre — nunca llegó a Supabase, y la cascada la borró localmente antes de que pudiera subirse. Con datos de prueba se pudo recuperar (todavía existían en Supabase, se volvieron a traer con una reinstalación limpia); con datos reales de un usuario, no habría existido esa red de seguridad.

**La solución:** se reemplazaron los 4 `guardarDesdeSync` por un upsert manual armado con SQL crudo (`INSERT INTO tabla (...) VALUES (...) ON CONFLICT(id) DO UPDATE SET columna = excluded.columna, ...`) — ante una fila existente, esto es un `UPDATE` real, que no dispara ninguna acción de foreign key. Ver `syncService.md`, punto 10, y `mascota.repository.md`, punto 8, para el detalle completo.

---

## 2026-08-21 — Retoques post-Sync: cambiar contraseña y política de privacidad

Primeros dos de los tres "retoques" que quedaron anotados al cerrar Sync (ver memoria de sesión `project_retoques_post_sync`) — falta todavía el borrado de cuenta accesible desde la web (requisito de Play Store 2023+).

**Cambiar contraseña.** Antes de programar, se le preguntó al usuario cómo lo abordaría (mismo método que en decisiones anteriores) — pidió una opción nueva en `AjustesScreen` junto con una pantalla dedicada (no un diálogo) que pida la contraseña actual y la nueva dos veces, más título, logo y el aviso de requisitos de contraseña visible. `CambiarContrasenaScreen` reutiliza `iniciarSesionConEmail` como mecanismo de "verificar contraseña actual" (Supabase Auth no tiene un endpoint dedicado para eso) — ver `cambiarContrasenaScreen.md` y `usuarioNotifier.md`, punto 12. Verificado contra la API de administración de Supabase (`updated_at` del usuario cambió justo después del re-login con la contraseña actual, confirmando que el cambio llegó de verdad al servidor, no solo a la app).

**Política de privacidad.** Decisiones del usuario: en los tres idiomas de la app (es/en/pt), como páginas separadas con selector entre ellas, hosteadas en el mismo repo público `PatasAlDiaWeb` (GitHub Pages) que ya aloja la página de confirmación de correo — mismo motivo de siempre, Supabase Storage no puede servir HTML real. El link vive en `LoginScreen` (no solo en `AjustesScreen`), a pedido explícito del usuario, para que quede al alcance de cualquiera antes incluso de crear una cuenta de invitado. El idioma de la página que se abre se resuelve con `Localizations.localeOf(context)` (el idioma efectivamente activo en la app en ese momento), no con `usuario?.idioma` — en `LoginScreen` puede no existir ningún usuario todavía. Contacto de la política: `breakpointx.dev@gmail.com` (decisión explícita del usuario, el mismo correo que ya usa para el resto del proyecto). Ver `loginScreen.md`, punto 6.

**Borrado de cuenta desde la web (mismo día, tercer y último retoque de esta lista).** Requisito real de Google Play (desde 2023): además del borrado in-app, tiene que existir una forma de pedirlo **sin tener la app instalada**. Se le presentaron al usuario dos caminos — un formulario real (correo + contraseña, self-service e instantáneo) o una página simple de "escribinos y lo procesamos a mano" (mucho menos trabajo, patrón aceptado igual para apps chicas) — y eligió el primero, "es lo más profesional".

Tres páginas nuevas (`eliminar-cuenta-es/en/pt.html`, mismo repo `PatasAlDiaWeb`), con el SDK `@supabase/supabase-js` cargado por CDN: el formulario llama `signInWithPassword` con la "publishable key" (la misma clave pública que ya usa la app, no es un secreto) para comprobar la identidad, y si esa verificación pasa, llama a la Edge Function `eliminar-cuenta` que ya existía desde el borrado in-app (ver `eliminarCuentaFunction.md`) — sin crear ninguna función nueva.

**Hallazgo real, no solo un ajuste:** esa función nunca había sido llamada desde un navegador — solo desde la app Flutter (Dart nativo, donde CORS no aplica). Probar el formulario reveló que la función no respondía el preflight `OPTIONS` ni mandaba encabezados `Access-Control-Allow-Origin`, así que el navegador bloqueaba la respuesta antes de que el JS de la página la viera. Se corrigió sumando el manejo de CORS a la función (ver `eliminarCuentaFunction.md`, punto 5) y se redesplegó. Verificado con una prueba real de punta a punta contra una cuenta descartable creada solo para esto (API de administración de Supabase): login con correo/contraseña → llamada a la función con el token resultante → confirmación de que el usuario ya no existe (`404` al buscarlo después).

---

## 2026-08-21/22 — Revisión total del código: bug real de sync, código muerto

Pedido explícito del usuario: una revisión completa de todo el código (no solo lo último tocado) buscando optimización y código de más. Se lanzaron 4 revisiones en paralelo, una por ángulo — reutilización, simplificación, eficiencia y profundidad de los arreglos ya hechos —, cada una cubriendo todo `lib/`, no un diff puntual.

**Bug real 4 (encontrado por la revisión de "profundidad", no por una prueba puntual) — medicamentos sin resolución de conflictos.** `_sincronizarMedicamentosEvento` era la única de las 4 entidades sincronizadas que guardaba una fila traída por pull directo, sin comparar contra la versión local primero (`_ganaElLocal`, ver `syncService.md`, punto 6) — las otras 3 sí lo hacían desde el diseño original. La justificación original era que "un medicamento no se edita campo a campo desde dos dispositivos en la práctica", una suposición de uso, no una garantía real del schema ni de la UI. Sin esa comparación, una edición local de un medicamento todavía sin subir se podía perder ante un pull con una versión más vieja, y sin ningún reintento después (`guardarDesdeSync` apaga `pendiente_push` sin condición) — la misma clase de bug que el "Bug real 2" de la entrada de Sync, arriba, pero para la única entidad que había quedado afuera de esa corrección. Arreglado agregando `MedicamentoEventoRepository.obtenerMedicamentoEventoPorId` (mismo patrón que las otras 3) y sumando la comparación de conflicto en `sync_service.dart`. Verificado con una prueba real de conflicto en las dos direcciones (local gana, remoto gana) contra Supabase. Ver `syncService.md`, punto 11, y `medicamentoEvento.repository.md`.

**Código muerto encontrado y borrado**, todo verificado con grep (cero llamadores en `lib/`) antes de sacarlo:
- `AgendaEventoNotifier.cargarAgendaEventos` (nunca se usaba, todo pasaba por la versión plural `cargarAgendaEventosDeMascotas`).
- `UsuarioNotifier.cargarUsuario` (nunca se usaba).
- `MascotaExtraviadaRepository.obtenerReportePorId` (nunca se usaba, `DetalleReporteMascotaExtraviadaScreen` lee del provider ya cargado, no vuelve a pedir el reporte).
- Clave de idioma huérfana `editarEventoLabel`, en los tres `.arb`.
- Provider entero sin usar: `lib/providers/supabase_provider.dart` (`supabaseClientProvider`) — todos los repositories que hablan con Supabase llaman `Supabase.instance.client` directo, nunca pasaron por este provider.

**Quedó pendiente, a propósito, para más adelante** (decisión explícita del usuario — no bloquea nada, y tocar el motor de sync ahora que recién quedó estable implicaría volver a probar todo el ciclo):
- Duplicación real encontrada por la revisión de "reutilización": la lógica de "Otro" en tipo de evento repetida en dos pantallas de agenda, el formateo de fecha+hora duplicado en las mismas dos pantallas, el diálogo de "¿confirmar esta acción?" reconstruido a mano en 6+ pantallas, y el patrón subir/bajar archivo duplicado entre mascota y documento dentro de `sync_service.dart`.
- Eficiencia encontrada por esa misma revisión, dentro de `sync_service.dart`: cada `pull` hace una consulta SQLite por fila en vez de una sola con `IN (...)` (N+1), y las subidas/bajadas de archivos corren de a una en vez de en paralelo con `Future.wait`. Impacto real mínimo con el volumen de datos actual — quedaría pendiente si en algún momento hay cuentas con muchos datos/archivos sincronizando a la vez.

---

## 2026-08-22 — Duplicación pendiente resuelta, más consistencia visual en Documentos

Retomando la duplicación que había quedado pendiente de la revisión total del código (entrada anterior) — el usuario pidió seguir con eso.

**Lógica de "Otro" en tipo de evento.** `tipoEventoMostrar` (ver `etiquetasLocalizadas.md`, punto 4) ganó un parámetro opcional `tipoEventoPersonalizado`, mismo patrón que ya tenía `especieValorMostrar`. Se borraron las dos copias manuales de esa rama (`AgendaScreen._tipoEventoTexto`, y el ternario inline en `DetalleAgendaEventoScreen`).

**Formateo de fecha+hora.** Nueva función `fechaHoraCorta(DateTime)` en el mismo archivo (ver `etiquetasLocalizadas.md`, punto 5), reemplazando el `d/M/y H:mm` armado a mano con `padLeft` en `DetalleAgendaEventoScreen` y `FormularioAgendaEventoScreen`.

**Diálogo de confirmación compartido.** Nueva función `confirmarAccion` (`lib/presentation/widgets/dialogo_confirmacion.dart`, ver `dialogoConfirmacion.md`), reemplazando 7 `AlertDialog` construidos a mano en `DetalleMascotaScreen`, `DetalleDocumentoScreen`, `DetalleAgendaEventoScreen`, `DetalleReporteMascotaExtraviadaScreen` (x3) y `AjustesScreen` (x2). Acepta `destructivo: bool` para el botón rojo, en vez de repetir el `ElevatedButton.styleFrom(backgroundColor: Colors.red)` en cada llamador.

**De paso, un pedido de consistencia visual del usuario** (no parte de la revisión de duplicación en sí, pero relacionado): `DetalleDocumentoScreen` era la única pantalla de detalle con el botón de eliminar en el `AppBar` en vez del patrón `ListTile` rojo al final del cuerpo que ya usan las demás (`DetalleMascotaScreen`, `DetalleAgendaEventoScreen`, `DetalleReporteMascotaExtraviadaScreen`) — quedó así desde la pasada de traducción de Documentos, documentado en su momento como fuera de alcance (ver `detalleDocumentoScreen.md`). Se corrigió para que las cuatro pantallas de detalle sean visualmente consistentes.

Los 4 hallazgos de duplicación de la revisión total quedaron así completos — el quinto punto pendiente de esa entrada (el patrón subir/bajar archivo duplicado dentro de `sync_service.dart`) y los dos de eficiencia siguen pospuestos a propósito, por tocar el motor de sync.

---

## 2026-08-22 (continuación) — Revisión de consistencia visual entre pantallas

Pedido explícito del usuario: revisar todas las pantallas/formularios buscando cualquiera que no calzara con el resto en decoración, logos o formato ("que no hayan puntos en blanco"). Se lanzó una revisión completa (fork, con todo el contexto de patrones ya establecidos en la sesión) sobre las ~30 pantallas de `lib/presentation/screens/`. Dos hallazgos concretos, resueltos:

**Referencia vieja al `applicationId`.** `mapa_screen.dart` seguía con `userAgentPackageName: 'com.example.patas_al_dia'` en la configuración del `TileLayer` — un string de Dart, no un archivo de proyecto Android/iOS/macOS, así que se pasó por alto en el cambio de `applicationId` de esa misma sesión (ver la entrada correspondiente, arriba). Corregido a `dev.breakpointx.patasaldia`.

**Tres formularios sin indicador de carga.** `FormularioMascotaScreen`, `FormularioDocumentoScreen` y `FormularioAgendaEventoScreen` eran los únicos formularios de la app sin la bandera `_guardando` que sí tienen `RegistroScreen`, `CambiarContrasenaScreen`, `NuevaContrasenaScreen`, `RecuperarContrasenaScreen`, `IniciarSesionScreen` y `FormularioReporteMascotaExtraviadaScreen` — el botón "Guardar" quedaba tocable durante todo el trabajo asíncrono de guardar (copiar archivos a un directorio persistente, escrituras en la base), sin aviso visual ni protección contra doble toque. Se sumó el mismo patrón a los tres (`bool _guardando`, `try/finally` alrededor del cuerpo real de `_guardar()`, botón con `CircularProgressIndicator` mientras dura). Ver `formularioMascotaScreen.md` (punto 14), `formularioDocumentoScreen.md` (punto 6) y `formularioAgendaEventoScreen.md` (punto 7, donde además se dividió `_guardar()` en dos métodos por el tamaño del cuerpo).

**Un tercer punto quedó señalado pero sin resolver, a propósito:** solo `FormularioMascotaScreen` usa `SeparadorSeccionFicha` para agrupar visualmente sus campos; `FormularioAgendaEventoScreen`/`FormularioDocumentoScreen` son listas planas. Marcado como opinión de diseño, no como defecto — el usuario no pidió tocarlo.

---

## De aquí en adelante

Cada vez que se tome una decisión de arquitectura nueva (enfoque, tecnología, estructura — no un simple fix o ajuste de código), se agrega una entrada acá con: fecha, la decisión, el porqué, y alternativas consideradas si las hubo.
