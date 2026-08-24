# Nota de Obsidian: `MisReportesScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/mis_reportes_screen.dart`

Se accede desde `MapaScreen`, ícono de lista en la barra superior (junto al avatar de usuario).

## 🎯 Propósito del Archivo

Lista de los reportes de mascota perdida/encontrada **activos** que publicó el usuario actual — pedido explícito del usuario (2026-08-24) al descubrir que no había forma de ver "mis reportes" sin ir tocándolos uno por uno en el mapa. Solo activos: uno resuelto ya no se puede "reactivar", si fue un error se vuelve a publicar (decisión del usuario, misma sesión).

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

No agrega ningún estado ni consulta nueva a Supabase — reusa exactamente el mismo `mascotaExtraviadaProvider` que ya carga `MapaScreen` (todos los reportes activos, públicos), y simplemente lo filtra por dueño. Mismo criterio de "esMio" que ya usa `DetalleReporteMascotaExtraviadaScreen`: compara `Supabase.instance.client.auth.currentSession?.user.id` contra `reporte.usuarioId` — un invitado que nunca publicó nada no tiene sesión todavía, así que la lista le queda vacía sin errores.

Al tocar un reporte, navega a la misma `DetalleReporteMascotaExtraviadaScreen` que ya usa el mapa — no duplica ninguna acción (resolver/borrar/denunciar), esas ya viven ahí.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. Sin `ConsumerStatefulWidget`, sin `initState`

Es un `ConsumerWidget` simple — no necesita cargar nada al abrirse porque `mascotaExtraviadaProvider` ya está poblado desde que se abrió `MapaScreen` (de donde siempre se llega a esta pantalla).

### 2. Filtro por dueño, no por consulta nueva

```dart
final usuarioActualId = Supabase.instance.client.auth.currentSession?.user.id;
final misReportes = usuarioActualId == null
    ? const <MascotaExtraviadaModel>[]
    : reportes.where((r) => r.usuarioId == usuarioActualId).toList();
```

Filtrado en memoria sobre la lista que ya está cargada — no hay ninguna consulta adicional a Supabase.
