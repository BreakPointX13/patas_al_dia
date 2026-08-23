# Glosario de conceptos — Dart & Flutter en Patas al Día

Guía de referencia rápida para cuando se te olvide "¿qué era un provider, de nuevo?" — cada concepto tiene una analogía corta, la explicación mínima, y un ejemplo real sacado del proyecto (no inventado), con el archivo donde vive. Pensado para consultar, no para leer de corrido.

Para ver *cómo se navega* entre pantallas: `mapaNavegacion.md`/`.html`, en esta misma carpeta. Para el *porqué* de cada decisión de arquitectura: `decisiones_arquitectura.md`.

---

## El camino de un dato, resumido

Antes de entrar en cada pieza por separado, así se conectan entre sí (de afuera hacia adentro):

```
Pantalla (Widget)  →  Provider (estado en memoria)  →  Repository (persistencia)  →  SQLite / Supabase
     ↑                                                                                        │
     └────────────────────────── la pantalla se redibuja sola cuando el estado cambia ────────┘
```

Ejemplo real, completo, de "crear una mascota nueva":
1. `FormularioMascotaScreen` (pantalla) arma un `MascotaModel` con lo que tipeó el usuario.
2. Llama a `ref.read(mascotasProvider.notifier).agregarMascota(mascota)` (provider).
3. El provider llama a `MascotaRepository.crearMascota(mascota)` (repository).
4. El repository hace un `INSERT` en SQLite (`database_helper.dart`).
5. El provider actualiza su lista en memoria — y como `HomeScreen` está "escuchando" ese provider, se redibuja sola mostrando la mascota nueva, sin que nadie le avise directamente.

Cada pieza de esa cadena es una de las de abajo.

---

## Widget

**Analogía:** un widget es un Lego. Todo lo que ves en pantalla — un botón, un texto, una fila, la pantalla completa — es un Lego, y armás la app encastrando Legos dentro de Legos.

Hay dos tipos base:
- **`StatelessWidget`** — no cambia solo, una vez dibujado queda igual hasta que algo de afuera lo reconstruya. Bueno para cosas fijas (un ícono, una tarjeta de datos).
- **`StatefulWidget`** — tiene memoria propia (`State`) y puede redibujarse a sí mismo con `setState(...)`. Se usa para lo que cambia por interacción directa del usuario dentro de esa misma pantalla (un formulario mientras se tipea, un `_guardando` mientras se espera una respuesta).

En este proyecto casi todo lo que además necesita leer/escribir un **provider** usa la versión "Consumer" de estos dos: `ConsumerWidget` y `ConsumerStatefulWidget` — son lo mismo, pero además te dan el objeto `ref` (ver más abajo).

```dart
// lib/presentation/screens/home_screen.dart
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
```

**Dónde está:** cada archivo en `lib/presentation/screens/` y `lib/presentation/widgets/`.

---

## Screen (pantalla)

No es un concepto de Flutter en sí — es una convención de este proyecto: un widget que ocupa toda la pantalla (normalmente empieza con `Scaffold`) y tiene su propio archivo en `lib/presentation/screens/`. Un widget "chico" reutilizable (un botón custom, una tarjeta) va en `lib/presentation/widgets/` en cambio.

**Dónde está:** las ~24 pantallas de `lib/presentation/screens/` — ver `mapaNavegacion.md` para cómo se conectan.

---

## Model

**Analogía:** un model es un molde de galletas — define qué forma tiene un dato (una Mascota, un Documento), no qué hacer con él.

Es una clase Dart simple, sin lógica de negocio, que representa una fila de la base de datos. Este proyecto no usa ningún generador de código para esto (nada de `.g.dart`) — cada model escribe a mano su conversión entre el `Map` que devuelve SQLite y el objeto Dart:

```dart
// lib/data/models/mascota_model.dart
class MascotaModel {
  final String id;
  final String nombre;
  final bool esterilizado;
  // ...

  // Convierte un Mapa (fila de la BDD) a un objeto MascotaModel
  factory MascotaModel.fromMap(Map<String, dynamic> map) {
    return MascotaModel(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      // ...
    );
  }
}
```

`factory` acá es una palabra clave de Dart para un constructor que, en vez de simplemente llenar los campos, puede tener lógica antes de decidir qué instancia devolver — en este caso, leer el `Map` y convertir cada valor al tipo correcto.

**Dónde está:** `lib/data/models/` — seis archivos, uno por entidad (`mascota`, `agenda_evento`, `medicamento_evento`, `documento`, `mascota_extraviada`, `usuario`).

---

## Repository

**Analogía:** el repository es el bibliotecario. Vos no vas directo al estante (la base de datos) — le pedís el libro al bibliotecario, y él sabe dónde está guardado y cómo acomodarlo de vuelta.

Es la única capa que sabe hablar con SQLite (`database_helper.dart`) o con Supabase directamente. Una pantalla nunca hace SQL a mano — siempre pasa por un repository.

```dart
// lib/data/repositories/mascota_repository.dart
Future<List<MascotaModel>> obtenerMascotasPorUsuario(String usuarioId) async {
  final db = await DatabaseHelper.instance.database;
  final List<Map<String, dynamic>> maps = await db.query(
    'mascotas',
    where: 'usuario_id = ? AND eliminado = 0',
    whereArgs: [usuarioId],
  );
  return maps.map((mapa) => MascotaModel.fromMap(mapa)).toList();
}
```

**Dónde está:** `lib/data/repositories/` — uno por model (más `usuario_repository.dart`, que además habla con Supabase Auth).

---

## Service

**Analogía:** si el repository es el bibliotecario de *tus propios* datos, el service es el mensajero que sale del edificio — habla con algo de afuera que no es "guardar/leer una entidad": el sistema de archivos del teléfono, las notificaciones, el correo, Supabase Storage.

No tiene tabla ni model detrás — es una clase chica con una responsabilidad puntual.

```dart
// lib/services/almacenamiento_local_service.dart
class AlmacenamientoLocalService {
  // Ruta persistente donde vive la foto de una mascota en este dispositivo.
  static Future<String> rutaFotosMascotas(String nombreArchivo) async {
    return _rutaEnCarpeta('fotos_mascotas', nombreArchivo);
  }
}
```

**Dónde está:** `lib/services/` — `sync_service.dart` (motor de sincronización), `notificacion_service.dart` (recordatorios locales), `almacenamiento_local_service.dart` (rutas de archivos), `reportar_bug_service.dart` (envía el correo del formulario de bug).

---

## Provider (Riverpod)

**Analogía:** un provider es una pizarra compartida en la sala de profesores. Cualquier pantalla puede mirarla para saber el dato actual, y si alguien la actualiza, todos los que la estaban mirando se enteran solos, sin que nadie tenga que ir avisándoles uno por uno.

Es la solución de **gestión de estado** que usa todo el proyecto (regla 7 de `CLAUDE.md` — sin mezclar con otros enfoques). Los dos tipos que vas a ver todo el tiempo acá:

- **`Provider`** — un valor fijo, normalmente una instancia de algo (como un repository) que no cambia.
- **`NotifierProvider`** — estado que sí cambia con el tiempo (una lista de mascotas, por ejemplo), con métodos propios para modificarlo.

```dart
// lib/providers/mascota_provider.dart

// Instancia única del repository, para no crearla de nuevo en cada pantalla.
final mascotaRepositoryProvider = Provider<MascotaRepository>((ref) {
  return MascotaRepository();
});

// Guarda en memoria las mascotas ya cargadas, para que la UI no lea SQLite en cada build.
class MascotasNotifier extends Notifier<List<MascotaModel>> {
  @override
  List<MascotaModel> build() => [];

  Future<void> agregarMascota(MascotaModel mascota) async {
    final repo = ref.read(mascotaRepositoryProvider);
    await repo.crearMascota(mascota);
    state = [...state, mascota]; // "cambiar el estado" = pisar `state`
  }
}

final mascotasProvider = NotifierProvider<MascotasNotifier, List<MascotaModel>>(
  () => MascotasNotifier(),
);
```

### `ref` — la mano que usás para tocar un provider

Dentro de un `ConsumerWidget`/`ConsumerStatefulWidget` tenés acceso a `ref`, con tres formas distintas de usarlo — la diferencia entre las tres es la parte que más confunde al principio:

| | Qué hace | Cuándo usarlo |
|---|---|---|
| `ref.watch(provider)` | Lee el valor **y** hace que este widget se redibuje solo cada vez que cambie | Dentro de `build()`, para mostrar datos que pueden cambiar |
| `ref.read(provider)` | Lee el valor **una sola vez**, sin suscribirse a cambios futuros | Dentro de una función (un `onPressed`, un `initState`), donde no querés redibujar nada, solo actuar |
| `ref.listen(provider, ...)` | No lee para mostrar nada — ejecuta una función cuando el valor cambia | Para reaccionar a un cambio con algo que no es "redibujar la UI" (navegar, mostrar un SnackBar) |

```dart
// lib/presentation/screens/home_screen.dart
@override
Widget build(BuildContext context) {
  final mascotas = ref.watch(mascotasProvider); // se redibuja si la lista cambia
  // ...
}

@override
void initState() {
  super.initState();
  final usuarioId = ref.read(usuarioProvider)!.id; // solo necesito el valor de ahora
  ref.read(mascotasProvider.notifier).cargarMascotas(usuarioId);
}
```

**Dónde está:** `lib/providers/` — un archivo por entidad, más `sync_provider.dart` y `usuario_provider.dart`.

---

## `BuildContext`

Es el "dónde estoy parado en el árbol de widgets" — lo necesitás cada vez que algo depende de la ubicación (abrir una pantalla nueva con `Navigator.of(context)`, leer el tema o el idioma actual con `Theme.of(context)`/`AppLocalizations.of(context)`). Siempre te lo pasa Flutter solo, como parámetro de `build(BuildContext context)` — nunca lo creás vos.

---

## `Future`, `async`, `await`

**Analogía:** pedir algo por delivery. Hacés el pedido (`Future`) y seguís con lo tuyo; cuando llega, recién ahí lo usás.

- **`Future<T>`** — una promesa de que en algún momento vas a tener un valor de tipo `T` (o un error). Casi todo lo que toca la base de datos, un archivo, o internet, devuelve un `Future`.
- **`async`** — marca una función como "adentro hay operaciones que toman tiempo".
- **`await`** — "pausá acá hasta que este `Future` termine, después seguí" — sin bloquear el resto de la app mientras tanto.

```dart
Future<void> _guardar() async {
  setState(() => _guardando = true);
  try {
    await ref.read(mascotasProvider.notifier).agregarMascota(mascota); // espera sin trabar la UI
  } finally {
    if (mounted) setState(() => _guardando = false);
  }
}
```

Este patrón (`_guardando` + `try/finally`) es el que usa cada formulario del proyecto para mostrar el círculo de carga en el botón mientras se guarda.

---

## Nulabilidad (`String` vs `String?`)

Dart distingue entre "este valor siempre va a estar" y "este valor puede faltar" directamente en el tipo — no es opcional, es parte del sistema de tipos:

- `String nombre` — nunca puede ser `null`. El compilador no te deja ni intentarlo.
- `String? raza` — puede ser `null` (en este proyecto, casi siempre significa "campo opcional que el usuario no llenó").

Por eso ves tanto `?` y `!` dando vueltas: `mascota.especie != null && ...` (pregunta si tiene valor antes de usarlo), `usuarioProvider)!.id` (el `!` le dice al compilador "confío en que acá nunca es null, no me preguntes"). Se usa `!` solo cuando estás seguro por el contexto (por ejemplo, esa pantalla nunca se muestra sin usuario logueado) — usarlo sin estar seguro es la forma más común de hacer explotar la app con un `null check operator used on a null value`.

---

## `Navigator`

Cómo se pasa de una pantalla a otra — cada `push` apila una pantalla nueva arriba de la actual (el botón "atrás" la saca y volvés a la de abajo).

```dart
// lib/presentation/screens/home_screen.dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => const FormularioMascotaScreen()),
);
```

Ver `mapaNavegacion.md` para el mapa completo de qué pantalla abre a cuál.

---

## Resumen en una tabla

| Concepto | Analogía | Vive en |
|---|---|---|
| Widget | Un Lego | `lib/presentation/` |
| Screen | Un Lego del tamaño de toda la pantalla | `lib/presentation/screens/` |
| Model | Un molde de galletas | `lib/data/models/` |
| Repository | El bibliotecario | `lib/data/repositories/` |
| Service | El mensajero que sale del edificio | `lib/services/` |
| Provider | La pizarra compartida | `lib/providers/` |
| `ref.watch`/`.read`/`.listen` | Formas de mirar la pizarra | dentro de cada pantalla |
