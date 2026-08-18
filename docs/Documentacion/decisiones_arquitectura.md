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

## De aquí en adelante

Cada vez que se tome una decisión de arquitectura nueva (enfoque, tecnología, estructura — no un simple fix o ajuste de código), se agrega una entrada acá con: fecha, la decisión, el porqué, y alternativas consideradas si las hubo.
