# Nota de Obsidian: `syncServiceProvider` / `sincronizandoProvider`

## 📁 Ubicación en el Proyecto

`lib/providers/sync_provider.dart`

## 🎯 Propósito del Archivo

Expone, vía Riverpod, las dos piezas que el resto de la app necesita para usar el motor de sync (ver `syncService.md`): una instancia de `SyncService` lista para usar, y un booleano que indica si hay una sincronización en curso ahora mismo.

```dart
final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));

class SincronizandoNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void establecer(bool valor) => state = valor;
}

final sincronizandoProvider = NotifierProvider<SincronizandoNotifier, bool>(SincronizandoNotifier.new);
```

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Dos providers con roles distintos, a diferencia de los 4 `xRepositoryProvider` (ver `repositoryProviders.md`), que son todos el mismo patrón repetido:

- **`syncServiceProvider`** es un `Provider` simple, igual que los `xRepositoryProvider` — expone una única instancia de `SyncService`, que recibe el propio `Ref` en el constructor (`SyncService(ref)`) para poder leer/llamar a los repositories y providers de las 4 entidades desde adentro, sin que cada pantalla tenga que pasarle esas dependencias a mano.
- **`sincronizandoProvider`** es un `NotifierProvider<SincronizandoNotifier, bool>` — cumple doble función: es la señal que la UI usa para mostrar "Sincronizando..." (`AjustesScreen`, ver `ajustesScreen.md`, punto 9), **y** es al mismo tiempo la bandera que `SyncService.sincronizar()` usa para evitar dos corridas en paralelo (ver `syncService.md`, punto 1) — una sola fuente de verdad para las dos cosas, sin necesitar un flag privado aparte dentro de `SyncService`.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `establecer(bool valor)` — por qué existe, en vez de asignar `.state` directo

- **El problema:** Riverpod marca `state` como `@protected` dentro de un `Notifier` — solo la propia clase puede asignarlo. `SyncService.sincronizar()` necesita prender la bandera antes de sincronizar y apagarla al terminar (`finally`), pero vive en una clase distinta (`SyncService`, no `SincronizandoNotifier`). Escribir `_ref.read(sincronizandoProvider.notifier).state = true` directo desde afuera dispara un warning del linter (`invalid_use_of_protected_member`).
- **La solución:** un método público `establecer(bool valor) => state = valor;` — desde adentro de la clase, así que sí tiene permiso para tocar `state`, y expone ese permiso hacia afuera de forma explícita y controlada (en vez de simplemente sacarle la protección a `state`, que abriría la puerta a que cualquier código de cualquier lado lo pise sin pasar por `SincronizandoNotifier`).
- **Uso real, en `SyncService.sincronizar()`:**

```dart
final bandera = _ref.read(sincronizandoProvider.notifier);
bandera.establecer(true);
try {
  await _sincronizarInterno(usuario.id, usuario.ultimaSincronizacion);
} finally {
  bandera.establecer(false);
}
```

El `try/finally` garantiza que la bandera se apague incluso si `_sincronizarInterno` lanza una excepción no capturada — sin esto, un error inesperado dejaría la app "trabada" pensando que sigue sincronizando para siempre, bloqueando cualquier corrida futura por la guarda del punto 1 de `syncService.md`.

### 2. Por qué es un archivo nuevo, y no se sumó a `repositoryProviders.md`

`repositoryProviders.md` documenta los 4 `Provider<XRepository>` — todos exactamente el mismo patrón, sin estado que cambie. `sync_provider.dart` no encaja ahí: `syncServiceProvider` envuelve un *servicio*, no un repository, y `sincronizandoProvider` es un `NotifierProvider` con estado real (`bool`) que cambia y notifica a la UI — arquitectura distinta, mismo criterio ya usado para separar `mascotasNotifier.md` de `repositoryProviders.md` (un `Provider` simple y un `NotifierProvider` con estado documentados aparte, aunque vivan en el mismo archivo `.dart`).
