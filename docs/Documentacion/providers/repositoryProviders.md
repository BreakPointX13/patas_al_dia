# Nota de Obsidian: Repository Providers (Riverpod)

## 📁 Ubicación en el Proyecto

```
lib/providers/
├── mascota_provider.dart
├── usuario_provider.dart
├── agenda_evento_provider.dart
└── documento_provider.dart
```

Los cuatro archivos siguen exactamente el mismo patrón — esta nota cubre a los cuatro en conjunto en vez de repetir la misma explicación cuatro veces.

## 🎯 Propósito del Archivo

Cada archivo expone, vía Riverpod, una única instancia del repository correspondiente (`MascotaRepository`, `UsuarioRepository`, `AgendaEventoRepository`, `DocumentoRepository`). Es la primera pieza de la capa de gestión de estado elegida para el proyecto (Riverpod, ver regla 7 de `CLAUDE.md`): antes de esto, cualquier pantalla que necesitara guardar o leer datos tenía que escribir `MascotaRepository()` por su cuenta; ahora lo pide "prestado" desde un lugar único y compartido.

---

## 🗺️ Mapa de Conexión Conceptual

### 🏛️ En un Proyecto Estándar de la Industria

Este patrón se llama **inyección de dependencias (Dependency Injection)**: en vez de que cada clase cree sus propias dependencias (`new Repository()` esparcido por todo el código), un contenedor central las crea una sola vez y las entrega a quien las pida. Esto facilita el testing (se puede reemplazar el repository real por uno falso/mock sin tocar las pantallas) y centraliza los cambios (si el constructor del repository cambia, se actualiza en un solo lugar).

### 🐾 En Nuestro Proyecto "Patas al día"

Usamos el `Provider` más simple de Riverpod — el que no maneja estado que cambia con el tiempo, solo expone un objeto fijo. Es literalmente un gancho en la pared con una llave colgada: siempre la misma llave, siempre en el mismo lugar.

```dart
// mascota_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/repositories/mascota_repository.dart';

final mascotaRepositoryProvider = Provider<MascotaRepository>((ref) {
  return MascotaRepository();
});
```

### 🔄 Comparativa y Ventajas Técnicas

- **Proyecto Estándar:** Muchos frameworks de DI (`get_it`, `injectable`) requieren un paso de "registro" explícito en un archivo de configuración central, a veces con generación de código.
- **Nuestro Enfoque:** Riverpod resuelve esto sin configuración adicional — declarar el `final xProvider = Provider<X>((ref) => X());` en cualquier archivo ya lo deja disponible en toda la app apenas se importe, sin generación de código (`.g.dart`), consistente con la filosofía de dependencias mínimas del proyecto.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `Provider<T>((ref) => ...)`

- **Definición Estándar:** Es el tipo de provider más básico de Riverpod: expone un valor u objeto que se calcula una sola vez (la primera vez que alguien lo pide) y se reutiliza después. No tiene métodos para "cambiar" ese valor — para eso existen otros tipos de provider (`NotifierProvider`, ya implementado para la lista de mascotas — ver `mascotasNotifier.md`).
- **En Nuestro Proyecto:** Cada uno de los 4 archivos declara exactamente un `Provider` de este tipo, envolviendo el constructor sin argumentos de su repository correspondiente (`MascotaRepository()`, `UsuarioRepository()`, etc.).

### 2. El parámetro `ref`

- **Definición Estándar:** Es una referencia que Riverpod le pasa a la función del provider, y que permite —entre otras cosas— leer otros providers desde adentro (por ejemplo, si `MascotaRepository` necesitara en el futuro otro objeto ya provisto por Riverpod).
- **En Nuestro Proyecto:** Por ahora `ref` no se usa dentro de la función (los repositories no reciben dependencias), pero es parte obligatoria de la firma — Riverpod siempre pasa ese parámetro, se use o no.

### 3. `ref.watch(xRepositoryProvider)` — cómo se consume desde una pantalla

- **Definición Estándar:** Es la forma en la que un widget "pide" el valor de un provider. Si el provider fuera de los que cambian, `ref.watch` además hace que el widget se reconstruya automáticamente cuando ese valor cambie.
- **En Nuestro Proyecto:** Ejemplo de uso futuro, desde una pantalla de "Agregar mascota":

```dart
class AgregarMascotaScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(mascotaRepositoryProvider); // toma la "llave del gancho"

    return ElevatedButton(
      onPressed: () async {
        await repo.crearMascota(nuevaMascota); // usa el repository sin instanciarlo manualmente
      },
      child: Text('Guardar'),
    );
  }
}
```

Como estos cuatro providers no cambian con el tiempo (siempre devuelven la misma instancia), en la práctica también podría usarse `ref.read(...)` en vez de `ref.watch(...)` sin diferencia de comportamiento — `ref.watch` se deja como estándar por ser el más seguro por defecto en cualquier lugar donde se lea un provider.

### 4. Por qué son 4 archivos y no 1

- **En Nuestro Proyecto:** Se mantiene la convención de "un archivo por entidad" ya usada en `models/` y `repositories/`, en vez de agrupar los cuatro providers en un solo archivo genérico. La razón es que cada uno de estos archivos crece con el tiempo: `mascota_provider.dart` ya sumó el `NotifierProvider` que mantiene la lista de mascotas en memoria y notifica a la UI cuando cambia (`MascotasNotifier`/`mascotasProvider`, documentado en detalle en `mascotasNotifier.md`) — ese código vive naturalmente junto al `mascotaRepositoryProvider`, no en un archivo separado. Los otros tres providers sumarán su propio `NotifierProvider` de la misma forma cuando se necesiten.
