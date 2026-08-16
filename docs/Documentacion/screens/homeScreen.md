# Nota de Obsidian: `HomeScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/home_screen.dart`

Desde el 2026-08-12 ya no es una pantalla completa independiente: es la pantalla raíz de la pestaña "Mascotas" dentro de `NavegacionPrincipalScreen` (ver `navegacionPrincipalScreen.md`), a la que se llega tras "Continuar como invitado" (o, en el futuro, tras un login exitoso).

## 🎯 Propósito del Archivo

Pantalla "Mis Mascotas": muestra la lista de mascotas del usuario actual, cargándolas desde SQLite a través de `mascotasProvider` apenas se abre la pantalla. Si el usuario todavía no tiene ninguna, muestra un estado vacío en vez de una lista en blanco confusa. El botón flotante extendido y centrado ("Agregar mascota", igual estilo que el de `AgendaScreen` desde el 2026-08-16) abre `FormularioMascotaScreen` en modo crear. Tocar una mascota de la lista abre `DetalleMascotaScreen`, pasándole solo el `id` (no el objeto completo — ver la nota sobre esto en `detalleMascotaScreen.md`). El `AppBar` usa `MenuUsuarioAvatar` (ver `menuUsuarioAvatar.md`), que abre `AjustesScreen`, donde vive "Cerrar sesión" (ver `ajustesScreen.md`) — antes era un ícono de engranaje propio de esta pantalla; se reemplazó por el widget compartido porque ahora el mismo ícono aparece también en `AgendaScreen` y `MapaScreen`.

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Cargar datos "al entrar a la pantalla" es un patrón extremadamente común — casi toda app con listas remotas o locales dispara su fetch inicial en el punto de entrada del widget, antes de que el usuario vea contenido.

### 🐾 En Nuestro Proyecto "Patas al día"

A diferencia de `LoginScreen` (que no necesitaba estado propio), acá sí hace falta un lugar donde ejecutar código **una sola vez** al entrar — por eso este widget es `ConsumerStatefulWidget` en vez de `ConsumerWidget`.

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** proyectos Riverpod más grandes suelen usar `FutureProvider`/`AsyncNotifier` para modelar el "cargando / error / listo" de forma explícita.
- **Nuestro Enfoque:** mantenemos el `Notifier<List<MascotaModel>>` ya construido (mismo patrón que el resto del proyecto) y disparamos la carga manualmente desde `initState`. Es más simple de entender por ahora; el costo es que no hay indicador de "cargando" — el estado vacío puede verse por una fracción de segundo antes de que lleguen los datos reales. Aceptable para SQLite local (es rápido), lo reconsideraríamos si en el futuro los datos vinieran de la red.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `ConsumerStatefulWidget` + `ConsumerState`

```dart
class HomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> { ... }
```

Es la versión Riverpod de un `StatefulWidget` normal — da acceso a `ref` (para hablar con providers) *y* a los métodos de ciclo de vida como `initState()`, que `ConsumerWidget` no tiene.

### 2. `initState()`

```dart
@override
void initState() {
  super.initState();
  final usuarioId = ref.read(usuarioProvider)!.id;
  ref.read(mascotasProvider.notifier).cargarMascotas(usuarioId);
}
```

- Corre **una sola vez**, cuando la pantalla se crea (a diferencia de `build`, que se repite con cada cambio).
- `super.initState()` va siempre primero — es obligatorio.
- `ref.read(usuarioProvider)!.id`: toma el usuario que `LoginScreen` ya dejó guardado. El `!` indica "sabemos que no es null acá" (siempre viene de `LoginScreen`, que lo crea antes de navegar).
- `cargarMascotas(usuarioId)` no lleva `await`: `initState` no puede ser `async`. Se dispara en segundo plano ("fire and forget"); cuando termine, el `state` del notifier cambia solo y `build` se vuelve a ejecutar automáticamente porque usa `ref.watch`.

### 3. `ref.watch(mascotasProvider)` vs. `ref.read(...)`

`watch` (usado en `build`) hace que el widget se reconstruya solo cuando la lista cambia. `read` (usado en `initState` y en el botón) se usa cuando solo queremos leer o disparar una acción una vez, sin "suscribirnos" a cambios futuros desde ese punto del código.

### 4. `ListView.builder`

```dart
ListView.builder(
  itemCount: mascotas.length,
  itemBuilder: (context, index) {
    final mascota = mascotas[index];
    return ListTile(...);
  },
)
```

Construye solo los ítems visibles en pantalla en cada momento (a diferencia de un `Column` con muchos hijos, que los crea todos de una) — la forma eficiente de mostrar listas potencialmente largas en Flutter.

### 5. `mascota.especie ?? 'Especie no especificada'`

El operador `??` ("si es null, usa esto otro") cubre el caso en que `especie` no se cargó al registrar la mascota (es un campo opcional en `MascotaModel`).

### 6. `onTap` del `ListTile` — navegar solo con el id

```dart
onTap: () {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => DetalleMascotaScreen(mascotaId: mascota.id),
    ),
  );
}
```

Se le pasa `mascota.id` (un `String`), no el objeto `mascota` completo. Así, `DetalleMascotaScreen` siempre busca el dato más actualizado en `mascotasProvider` en vez de quedarse con una copia que puede volverse vieja si el usuario edita la mascota. Ver el detalle de esta decisión en `detalleMascotaScreen.md`.
