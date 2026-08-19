# Nota de Obsidian: `FormularioReporteMascotaExtraviadaScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/formulario_reporte_mascota_extraviada_screen.dart`

Se abre desde `DetalleMascotaScreen` — nuevo ítem "Reportar mascota perdida" entre Documentos y Eliminar mascota, recibe la `MascotaModel` completa como parámetro (no un id, a diferencia de `AgendaScreen`/`DocumentosScreen`: acá hacen falta los datos de la mascota para denormalizarlos en el reporte, no solo su id).

## 🎯 Propósito del Archivo

Formulario para publicar un reporte de mascota perdida — primera pantalla del módulo Mapa (v2). A diferencia de todos los formularios anteriores del proyecto, **no** guarda en SQLite local: publica directo en Supabase, vía `mascotaExtraviadaProvider`.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Solo crea reportes — no edita ni elimina (a diferencia de `FormularioDocumentoScreen`/`FormularioMascotaScreen`, que sirven para ambos casos). Editar/marcar como encontrado/eliminar un reporte ya publicado son acciones de una futura pantalla de detalle del reporte (parte de la UI de Mapa, todavía no construida).

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. Datos de la mascota, denormalizados sin traducir

```dart
final especieDenormalizada = mascota.especie == 'Otro'
    ? (mascota.especiePersonalizada ?? mascota.especie)
    : mascota.especie;
```

Ver `mascotaExtraviada.model.md`, punto 1, para el porqué de la denormalización en sí (la tabla `mascotas` de Supabase está vacía, no hay sync todavía). Acá, el detalle importante es que se guarda el valor **canónico** (`mascota.especie`, en español, o el texto libre si es "Otro") — no el resultado de `especieMostrar(context, mascota)`, que sí se usa unas líneas más arriba, pero solo para mostrarle al usuario actual (el que está reportando) qué mascota está eligiendo, en su propio idioma. El reporte lo va a ver cualquier otro usuario, con cualquier idioma activo — si se guardara ya traducido, quedaría fijo en el idioma de quien publicó, sin poder traducirse para quien lo lee. Mismo criterio que el resto de los valores guardados de la app (ver `sistemaIdiomas.md`, punto 3) — aunque acá el "guardado" es en Supabase, no en SQLite.

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

### 3. Ubicación es opcional, no bloquea publicar

Ningún camino de ubicación es obligatorio — `ubicacionLat`/`ubicacionLng` quedan `null` si el usuario no completa ninguno de los dos, y el reporte se publica igual. Tiene sentido: alguien puede querer reportar una mascota perdida en una zona que no es la suya actual (ej. la perdió cerca del trabajo, está reportando desde su casa), y forzar la ubicación del dispositivo en ese caso sería incorrecto, no solo inconveniente.

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

**A propósito, sin `countrycodes` ni agregar ", Chile" a la consulta:** aunque la app está pensada inicialmente para Chile (ver `NotificacionService`), geocodificar solo dentro de Chile cerraría la puerta a un usuario de otro país — mismo criterio ya aplicado a RUT y número de chip (ver memoria de sesión "Validación de campos: no cerrar puertas a extranjeros"). Si Nominatim no encuentra resultados, no se bloquea la publicación — se avisa (`errorGeocodificacion`) y el reporte sigue su curso sin ubicación, coherente con que todo este bloque es opcional.

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

### 6. Foto de la mascota — no se envía (pendiente)

`MascotaExtraviadaModel.mascotaFotoUrl` queda sin llenar al construir el reporte acá — `mascota.fotoUrl` es una ruta de archivo local, inútil para cualquier otro usuario viendo el reporte desde otro teléfono. Mostrar la foto real requiere Supabase Storage (Fase 5, todavía no implementada) — ver `decisiones_arquitectura.md`, entrada del 2026-08-18, para el detalle completo y qué falta conectar cuando se implemente.

### 7. `_tieneRecompensa` — switch en vez de campo opcional (2026-08-19)

Mismo patrón que `_usarUbicacionActual` (punto 3b): `SwitchListTile` + campo condicional (`if (_tieneRecompensa) TextFormField(...)`), calcado del switch "No sé la fecha exacta de nacimiento" de `FormularioMascotaScreen` — se prefirió reusar ese lenguaje visual ya establecido en la app en vez de inventar un componente nuevo tipo "check/x". A diferencia de antes (campo de texto siempre visible, vacío = sin recompensa), ahora el campo de monto ni siquiera se muestra si el switch está apagado, y se vuelve obligatorio (con su propio `validator`) recién cuando se prende.

### 8. Descripción pasó a obligatoria (2026-08-19)

Decisión explícita del usuario: todos los campos del formulario son obligatorios salvo recompensa y ubicación (las dos únicas que tienen una razón real para quedar opcionales — no siempre hay premio, y no siempre se quiere/puede dar la ubicación exacta). `campoDescripcionObligatoria`/`errorDescripcionObligatoria` reemplazan a las claves viejas (`campoDescripcionOpcional`, ya borrada de los tres `.arb`).

### 9. `<uses-permission android:name="android.permission.INTERNET" />` en el manifiesto principal (2026-08-19)

Hallazgo al construir esta pantalla: el permiso de Internet en Android solo estaba declarado en `android/app/src/debug/AndroidManifest.xml` (lo agrega Flutter automáticamente, pero **solo** para builds de debug). El manifiesto principal (`android/app/src/main/AndroidManifest.xml`, el que se usa en un build de release) no lo tenía — no se había notado porque hasta ahora la app solo se probó en modo debug. Sin este permiso, un build de release no podría hablar con Supabase ni con Nominatim, fallando en silencio. Se agregó al manifiesto principal para cubrir los dos casos.
