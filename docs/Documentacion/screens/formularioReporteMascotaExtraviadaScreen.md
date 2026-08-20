# Nota de Obsidian: `FormularioReporteMascotaExtraviadaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/formulario_reporte_mascota_extraviada_screen.dart`

Dos puntos de entrada: `DetalleMascotaScreen` (ítem "Reportar mascota perdida", pasa `mascota` fija + `tipo: 'perdido'`) y el FAB de `MapaScreen` (ver `mapaScreen.md`), que cubre las otras dos variantes — mascota propia sin registrar, y "encontré una mascota que no es mía".

## 🎯 Propósito del Archivo

Formulario para publicar un reporte, en tres variantes posibles (ver punto 0). Primera pantalla construida del módulo Mapa (v2). A diferencia de todos los formularios anteriores del proyecto, **no** guarda en SQLite local: publica directo en Supabase, vía `mascotaExtraviadaProvider`. Solo crea — editar/marcar como resuelto/eliminar/denunciar un reporte ya publicado son acciones de `DetalleReporteMascotaExtraviadaScreen`.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Editar/marcar como resuelto/eliminar/denunciar un reporte ya publicado son acciones de `DetalleReporteMascotaExtraviadaScreen`, no de este formulario.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 0. `mascota` opcional + `tipo` — las tres variantes de reporte (2026-08-19)

```dart
class FormularioReporteMascotaExtraviadaScreen extends ConsumerStatefulWidget {
  final MascotaModel? mascota; // null = nombre/especie a mano
  final String tipo; // 'perdido' o 'encontrado'
  ...
}

bool get _mascotaRegistrada => widget.mascota != null;
bool get _esPerdido => widget.tipo == 'perdido';
```

Un mismo formulario cubre las tres formas de reportar que pidió el usuario, combinando dos parámetros independientes:

| | `mascota` | `tipo` | Nombre | Especie | Recompensa |
|---|---|---|---|---|---|
| Mascota mía, registrada | fija | `'perdido'` | fijo, de la mascota | fijo, de la mascota | opcional |
| Mascota mía, sin registrar | `null` | `'perdido'` | obligatorio, a mano | obligatorio (dropdown + "Otro") | opcional |
| Encontré una mascota | `null` | `'encontrado'` | **opcional**, a mano | obligatorio (dropdown + "Otro") | oculta (`if (_esPerdido)`) |

Cuando `mascota == null`, el formulario reusa `especiesDisponibles` (antes `_especies`, privada de `FormularioMascotaScreen` — se hizo pública con el mismo criterio ya usado para `tiposDocumentoDisponibles` en Documentos) para el dropdown de especie, con el mismo patrón "Otro" + texto libre que ya usa `FormularioMascotaScreen`.

**Por qué el nombre es opcional solo en "encontré":** si perdiste tu propia mascota (registrada o no), sabés su nombre — tiene sentido exigirlo. Si encontraste una mascota ajena, es normal no saber cómo se llama; forzar el campo ahí sería pedirle a la persona un dato que probablemente no tiene.

**Por qué la recompensa no aplica a "encontré":** la recompensa la ofrece quien perdió a su mascota, no quien la encuentra — mostrar el switch en ese flujo no tendría sentido, así que todo el bloque queda condicionado a `_esPerdido`.

### 1. Datos de la mascota, denormalizados sin traducir

```dart
if (_mascotaRegistrada) {
  nombreFinal = mascota.nombre;
  especieFinal = mascota.especie == 'Otro' ? (mascota.especiePersonalizada ?? mascota.especie) : mascota.especie;
  mascotaIdFinal = mascota.id;
} else {
  nombreFinal = _nombreController.text.trim().isEmpty ? null : _nombreController.text.trim();
  especieFinal = _especie == 'Otro' ? _especiePersonalizadaController.text.trim() : _especie;
  mascotaIdFinal = null;
}
```

Ver `mascotaExtraviada.model.md`, punto 1, para el porqué de la denormalización en sí (la tabla `mascotas` de Supabase está vacía, no hay sync todavía). Acá, el detalle importante es que se guarda el valor **canónico** (español, o el texto libre si es "Otro") — no el resultado de `especieMostrar`/`especieValorMostrar`, que sí se usa para mostrarle al usuario actual (el que está reportando) qué está eligiendo, en su propio idioma. El reporte lo va a ver cualquier otro usuario, con cualquier idioma activo — si se guardara ya traducido, quedaría fijo en el idioma de quien publicó. Mismo criterio que el resto de los valores guardados de la app (ver `sistemaIdiomas.md`, punto 3) — aunque acá el "guardado" es en Supabase, no en SQLite.

**Diferencia importante en el caso sin registrar:** cuando `_especie == 'Otro'`, el texto libre se guarda **directo** en `mascotaEspecie` (no hay un campo `mascotaEspeciepersonalizada` aparte, a diferencia de `MascotaModel`) — `MascotaExtraviadaModel` es una sola columna denormalizada, no el par especie/personalizada. Esto exigió un ajuste en `especieValorMostrar` para no perder ese texto al mostrarlo — ver `etiquetasLocalizadas.md`, punto 5.

### 2. `_obtenerUbicacion()` — permisos de `geolocator`, paso a paso

```dart
final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
if (!servicioHabilitado) throw l10n.errorServicioUbicacionDeshabilitado;

var permiso = await Geolocator.checkPermission();
if (permiso == LocationPermission.denied) {
  permiso = await Geolocator.requestPermission();
  if (permiso == LocationPermission.denied) throw l10n.errorPermisoUbicacionDenegado;
}
if (permiso == LocationPermission.deniedForever) throw l10n.errorPermisoUbicacionPermanente;

final posicion = await Geolocator.getCurrentPosition();
```

Tres chequeos distintos, cada uno con su propio mensaje de error: (1) el servicio de ubicación del sistema puede estar apagado (nada que ver con permisos — el GPS del teléfono está desactivado); (2) el permiso puede no estar concedido todavía, en cuyo caso se pide (`requestPermission()`); (3) el permiso puede estar bloqueado **para siempre** (`deniedForever` — el usuario lo negó antes marcando "no volver a preguntar"), caso en el que pedirlo de nuevo no sirve de nada, solo cambiándolo manualmente desde los ajustes del sistema puede desbloquearlo. Los `throw` usan strings (ya traducidos con `l10n`) en vez de `Exception`, capturados más abajo como `catch (e) { final mensaje = e is String ? e : l10n.errorObtenerUbicacion; ... }` — un atajo deliberado para no tener que definir una jerarquía de excepciones propia solo para mostrar tres mensajes distintos.

### 3. Ubicación obligatoria (2026-08-19, antes opcional)

```dart
if (_ubicacionLat == null || _ubicacionLng == null) {
  setState(() => _guardando = false);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorUbicacionObligatoria)));
  return;
}
```

La ubicación pasó de opcional a obligatoria — decisión del usuario, tras notar que un reporte sin ubicación no aparece en el mapa (que es el propósito central del módulo). No se valida vía `_formKey.currentState!.validate()` porque depende del resultado de una operación asíncrona (GPS o geocodificación), no de un campo de texto simple — se chequea a mano, después de intentar geocodificar si corresponde, antes de armar el objeto a publicar.

**No es "todo o nada" en la UI:** sigue habiendo dos caminos (GPS o dirección manual, ver punto 3b) y el usuario elige cuál usar — lo obligatorio es que **uno de los dos** termine con éxito, no un campo puntual fijo. Si el GPS falla o la dirección no se puede geocodificar, el bloqueo avisa con `errorUbicacionObligatoria` y dan la posibilidad de reintentar, en vez de dejar publicar sin ubicación.

**Repercusión en el esquema:** se agregó un `check` constraint en Supabase (`mascotas_extraviadas_ubicacion_obligatoria`, con `not valid` para no romper con datos de prueba viejos) — mismo criterio que el límite de 3 reportes activos: una validación solo del lado de la app se puede saltar llamando a la API directo, así que la regla real también vive en la base. Ver el `.sql`.

**Consecuencia en `MapaScreen`:** con esto, la botón/lista de "reportes sin ubicación" que se había construido dejó de tener sentido (nunca iba a haber ninguno) — se sacó por completo, incluidas las claves de traducción que solo usaba (ver `mapaScreen.md`, punto 6).

### 3b. `_usarUbicacionActual` — GPS o dirección a mano (2026-08-19)

```dart
SwitchListTile(title: Text(l10n.usarUbicacionActualSwitch), value: _usarUbicacionActual, ...),
if (_usarUbicacionActual)
  ListTile(...) // el botón "Obtener ubicación" que ya usaba geolocator
else
  Row(children: [TextFormField(calle), TextFormField(numero)]) // se geocodifican recién al publicar
```

Segunda forma de indicar la ubicación, pedida por el usuario: en vez de forzar siempre GPS, un `SwitchListTile` decide entre usar la ubicación real del dispositivo (`geolocator`, como antes) o escribir una dirección a mano (Calle + Número). Ninguna de las dos ramas es obligatoria por sí sola — es la combinación de las dos lo que mantiene la ubicación opcional en general (ver punto 3): con el switch en modo GPS alcanza con no tocar "Obtener ubicación"; en modo dirección alcanza con dejar los campos vacíos.

### 3c. `_geocodificarDireccion()` — Nominatim, sin restringir a ningún país

```dart
final uri = Uri.https('nominatim.openstreetmap.org', '/search', {'q': direccion, 'format': 'json', 'limit': '1'});
final respuesta = await http.get(uri, headers: {'User-Agent': 'PatasAlDia-App/1.0'});
```

Convierte "Calle + Número" en `ubicacionLat`/`ubicacionLng`, llamado recién al tocar "Guardar" (no mientras se escribe, para no spamear la API con una consulta por cada tecla). Usa Nominatim, el servicio de geocodificación de OpenStreetMap — gratis, sin API key, mismo ecosistema que `flutter_map` (ver `decisiones_arquitectura.md`, entrada del 2026-08-18, "Mapa, punto 3"). Exige un header `User-Agent` identificando la app, por política de uso del servicio público.

**Calle obligatoria en el modo dirección (2026-08-19):** el campo "Calle" ahora tiene su propio `validator` (obligatorio solo cuando `!_usarUbicacionActual`) — antes cualquiera de los tres campos podía quedar vacío sin avisar nada, y recién al tocar "Guardar" fallaba la geocodificación en silencio (el reporte se publicaba igual, sin ubicación, porque era opcional). "Número" y "Referencia" siguen sin `validator` — para geocodificar alcanza con el nombre de la calle, no hace falta un número exacto.

**A propósito, sin `countrycodes` ni agregar ", Chile" a la consulta:** aunque la app está pensada inicialmente para Chile (ver `NotificacionService`), geocodificar solo dentro de Chile cerraría la puerta a un usuario de otro país — mismo criterio ya aplicado a RUT y número de chip (ver memoria de sesión "Validación de campos: no cerrar puertas a extranjeros"). Si Nominatim no encuentra resultados, no se bloquea la publicación — se avisa (`errorGeocodificacion`) y el reporte sigue su curso sin ubicación, coherente con que todo este bloque es opcional.

**`_referenciaController` — tercer campo opcional, sumado a la búsqueda (2026-08-19):** pedido del usuario tras probar el formulario — un campo "Referencia (depto, esquina, etc. — opcional)" debajo de Calle/Número, visible solo junto con esos dos (`if (!_usarUbicacionActual)`). Se concatena a la consulta de Nominatim (`[calle, numero, referencia].where((s) => s.isNotEmpty).join(' ')`) — Nominatim tolera texto descriptivo extra en la búsqueda razonablemente bien, y de no aportar nada al resultado tampoco perjudica (el campo es opcional, así que puede quedar vacío sin afectar la consulta).

### 3d. `http` como dependencia nueva, ya presente de forma transitiva

El paquete no sumó ninguna descarga nueva al proyecto — ya llegaba como dependencia transitiva de otros paquetes (`supabase_flutter`, entre otros). Se agregó igual como dependencia directa en `pubspec.yaml` (`http: ^1.6.0`) para no depender silenciosamente de una versión que otro paquete decida dejar de usar en el futuro.

### 4. Sesión de Supabase, recién al publicar

```dart
final repo = ref.read(mascotaExtraviadaRepositoryProvider);
final usuarioIdSupabase = await repo.obtenerUsuarioIdSupabase();
```

`obtenerUsuarioIdSupabase()` (ver `mascotaExtraviada.repository.md`) crea (o reutiliza) una sesión anónima de Supabase Auth — la primera vez que alguien publica un reporte en toda la vida de la app, no antes. El resultado (`auth.uid()`) es el que se guarda como `usuarioId` del reporte — **no** es el mismo id que `UsuarioModel.id` (el usuario local de SQLite, usado en Mascotas/Agenda/Documentos): son dos espacios de identidad separados por ahora (ver `decisiones_arquitectura.md`, entrada del 2026-08-18, "Arranca Supabase").

### 5. `PostgrestException` — distinguir el límite de reportes de un error genérico

```dart
} on PostgrestException catch (e) {
  final mensaje = e.code == 'P0001'
      ? l10n.errorLimiteReportesActivos
      : l10n.errorPublicarReporte;
  ...
}
```

El trigger `limitar_reportes_activos()` (ver `TablaMaestraAppVetMovil1.sql`) rechaza el insert con un mensaje en español fijo, escrito en la base — no puede usar `AppLocalizations`, que solo existe en el lado de Flutter. En vez de mostrarle al usuario ese texto crudo (quedaría en español sin importar el idioma de la app), se detecta el código de error (`'P0001'`, el código por defecto de un `raise exception` de usuario en Postgres) y se muestra en su lugar un mensaje propio, ya traducido a los tres idiomas. Cualquier otro `PostgrestException` (por ejemplo, sin conexión) cae al mensaje genérico `errorPublicarReporte` — este es, además, el aviso "sin conexión" acordado con el usuario: reactivo (se muestra si la publicación falla), sin ningún paquete de detección de conectividad de por medio.

### 5b. `on AuthException catch` — bug real encontrado en producción: el mensaje de "conexión" mentía (2026-08-19)

El usuario reportó que no podía publicar ningún reporte — siempre salía el mensaje `errorPublicarReporte` ("revisa tu conexión"), aunque sí tenía conexión. Antes de intentar un arreglo a ciegas, se instrumentó el `catch` genérico con un `debugPrint(e)` temporal, se reinstaló, y se capturó el error real vía `adb logcat` mientras el usuario reproducía la acción (sin pedirle nada más que repetir lo que ya estaba haciendo):

```
AuthApiException(message: Anonymous sign-ins are disabled, statusCode: 422, code: anonymous_provider_disabled)
```

La causa real no tenía nada que ver con la red: la opción **"Anonymous Sign-ins"** del proyecto de Supabase (habilitada en la Fase 2 del plan de Supabase, ver `decisiones_arquitectura.md`) había quedado deshabilitada — sin ella, `obtenerUsuarioIdSupabase()` (que llama a `signInAnonymously()` la primera vez que alguien publica) falla con un `AuthApiException`, capturado antes por el `catch` genérico y mostrado con el mensaje de conexión, que era simplemente incorrecto para este caso. Se agregó un `on AuthException catch (e)` propio, con su mensaje ya traducido (`errorAutenticacionReporte`, "No se pudo verificar tu identidad...") en vez de reusar el texto orientado a conectividad — y se le pidió al usuario reactivar la opción en el panel de Supabase (Authentication → Sign In / Providers).

Los `debugPrint` de diagnóstico (acá y en el catch de `PostgrestException`) se dejaron en el código, marcados `// TEMPORAL` — no molestan en producción (`debugPrint` no imprime nada en release builds por defecto) y ahorran tener que repetir este mismo proceso de instrumentación si aparece un error parecido más adelante.

### 6. Foto obligatoria — sube a Supabase Storage al publicar (2026-08-19)

```dart
final reporteId = const Uuid().v4();
final fotoUrl = await repo.subirFoto(
  usuarioId: usuarioIdSupabase,
  reporteId: reporteId,
  rutaLocal: _fotoPath!,
);
```

Decisión del usuario: la foto es obligatoria en todo reporte (antes iba a quedar opcional/pendiente, ver decisión original en `decisiones_arquitectura.md`, entrada del 2026-08-18). Se valida a mano al principio de `_publicarReporte()` (mismo patrón que la ubicación, punto 3 — no puede ir en el `Form.validator` porque no es un campo de texto) y bloquea el guardado con `errorFotoObligatoria` si `_fotoPath == null`.

**Siempre se pide una foto nueva, incluso con mascota registrada:** aunque `widget.mascota` ya tenga `fotoUrl` (una ruta local del dispositivo, ver `mascota.repository.md`), **no se reutiliza** — decisión explícita del usuario. La foto del reporte debe reflejar cómo se ve/estaba la mascota justo antes de perderse o al encontrarla, no una foto de perfil vieja que puede no coincidir (pelaje distinto, un collar puesto que antes no tenía, etc.).

**`_elegirFoto()` — mismo patrón cámara/galería que `formulario_documento_screen.dart`,** pero sin la opción PDF (acá no aplica). Guarda solo la ruta local en `_fotoPath`; la subida real a Storage ocurre recién al publicar, no al elegir la foto — evita subir archivos que después el usuario podría cancelar sin guardar.

**`maxWidth: 1600, imageQuality: 75` en `pickImage` (2026-08-20):** sin esto, la foto se subía tal cual la entrega la cámara — 3 a 8 MB en un teléfono moderno, contra ~100-200 KB comprimida (medido en producción: una foto real bajó de varios MB a 117 KB). Es la única foto de todo el proyecto que sube a Supabase Storage (las de `formulario_mascota_screen.dart`/`formulario_documento_screen.dart` quedan solo en el dispositivo, nunca se suben a ningún lado) — es también la única que tiene un motivo de costo real para comprimirse. Se evaluó comprimir también las otras dos, pero se descartó: la foto de mascota es solo estética (bajo riesgo si se comprime, pero sin costo de nube que lo justifique) y la de documentos necesita legibilidad de texto (dosis, fechas) — comprimir de más ahí arriesgaría más de lo que ahorra, sin ningún costo de Storage de por medio que lo justifique. Ver `decisiones_arquitectura.md`.

**La subida ocurre antes de armar el `MascotaExtraviadaModel`,** porque `reporteId` (el mismo que usa el modelo) forma parte de la ruta del archivo en Storage (`usuarioId/reporteId.ext`, ver `subirFoto()` en `mascotaExtraviada.repository.md`) — se genera con `Uuid()` acá mismo, antes del `insert`, en vez de dejar que Supabase lo genere.

**`on StorageException catch`:** igual que `AuthException`/`PostgrestException` (puntos 5, 5b), un catch propio con mensaje dedicado (`errorSubirFoto`) en vez de caer en el genérico "revisa tu conexión" — mismo criterio de no usar un mensaje engañoso para un error que no es de conectividad.

### 7. `_tieneRecompensa` — switch en vez de campo opcional (2026-08-19)

Mismo patrón que `_usarUbicacionActual` (punto 3b): `SwitchListTile` + campo condicional (`if (_tieneRecompensa) TextFormField(...)`), calcado del switch "No sé la fecha exacta de nacimiento" de `FormularioMascotaScreen` — se prefirió reusar ese lenguaje visual ya establecido en la app en vez de inventar un componente nuevo tipo "check/x". A diferencia de antes (campo de texto siempre visible, vacío = sin recompensa), ahora el campo de monto ni siquiera se muestra si el switch está apagado, y se vuelve obligatorio (con su propio `validator`) recién cuando se prende.

### 8. Descripción pasó a obligatoria (2026-08-19)

Decisión explícita del usuario: todos los campos del formulario son obligatorios salvo recompensa (la única que tiene una razón real para quedar opcional — no siempre hay premio) — con la excepción adicional del nombre en el flujo "encontré una mascota" (ver punto 0). `campoDescripcionObligatoria`/`errorDescripcionObligatoria` reemplazan a las claves viejas (`campoDescripcionOpcional`, ya borrada de los tres `.arb`). La ubicación (punto 3) y la foto (punto 6) también pasaron de opcionales a obligatorias, aunque cada una se valida por su cuenta (no vía `Form.validator`) por depender de una operación async o de un picker externo, no de un campo de texto simple.

### 9b. Ubicación automática al abrir el formulario (2026-08-19)

```dart
@override
void initState() {
  super.initState();
  if (_usarUbicacionActual) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _obtenerUbicacion());
  }
}
```

Feedback del usuario tras usar el formulario varias veces: el switch "Usar mi ubicación actual" ya arranca activado por defecto, así que pedirle además que toque el botón "Obtener ubicación" era un paso de más para el camino más común (reportar desde donde uno está). Se dispara solo en `initState()` si el switch ya está en modo GPS — mismo criterio de "hacer algo apenas termina el primer build" que usa el resto del proyecto. El `onChanged` del switch tiene el mismo comportamiento: si se prende manualmente y todavía no hay una ubicación cargada (`_ubicacionLat == null`), dispara `_obtenerUbicacion()` de inmediato — pero no vuelve a pedirla si ya se tenía una de antes (ej. el usuario lo prendió, apagó por error y lo volvió a prender sin moverse). El botón "Obtener ubicación" se mantiene visible igual, para reintentar a mano si el primer intento falla o si el usuario se movió.

**Check visual cuando ya se obtuvo la ubicación (2026-08-19, mismo día):** el `leading` del `ListTile` cambia de `Icons.location_on_outlined` a `Icons.check_circle` en verde cuando `_ubicacionLat != null` — antes el único indicio de éxito era el texto (`ubicacionObtenidaLabel` vs. `sinUbicacionLabel`), poco visible de un vistazo. El botón "Obtener ubicación" sigue apareciendo igual en los dos casos — confirmado explícitamente con el usuario: sirve para reintentar si el primer intento falla o si la persona se movió después de obtenerla.

**Sobre el diálogo del sistema pidiendo permiso de ubicación — comportamiento esperado, no un bug:** el usuario notó que no aparecía ningún diálogo nativo de Android pidiendo permiso. No es un problema: Android solo muestra ese diálogo la primera vez que una app pide un permiso — como el usuario ya lo había concedido en pruebas anteriores de esta misma sesión, las siguientes veces `Geolocator.checkPermission()` devuelve directamente "concedido" sin volver a preguntar. Se puede confirmar reinstalando la app desde cero (que resetea los permisos) o revocando el permiso manualmente desde Ajustes del sistema → Apps → Patas al Día → Permisos.

### 10. `tipo` reemplaza a `estado` en el reporte publicado (2026-08-19)

El campo que este formulario le pasa a `MascotaExtraviadaModel` se llama `tipo`, no `estado` — ver `mascotaExtraviada.model.md`, punto 4, para el porqué de la separación entre `tipo` (no cambia nunca) y `resuelto` (lo único que se actualiza al cerrar un reporte). Este formulario solo escribe `tipo`; nunca toca `resuelto` (siempre nace en `false`, el valor por defecto del modelo).

### 9. `<uses-permission android:name="android.permission.INTERNET" />` en el manifiesto principal (2026-08-19)

Hallazgo al construir esta pantalla: el permiso de Internet en Android solo estaba declarado en `android/app/src/debug/AndroidManifest.xml` (lo agrega Flutter automáticamente, pero **solo** para builds de debug). El manifiesto principal (`android/app/src/main/AndroidManifest.xml`, el que se usa en un build de release) no lo tenía — no se había notado porque hasta ahora la app solo se probó en modo debug. Sin este permiso, un build de release no podría hablar con Supabase ni con Nominatim, fallando en silencio. Se agregó al manifiesto principal para cubrir los dos casos.
