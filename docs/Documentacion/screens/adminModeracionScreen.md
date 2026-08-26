# Nota de Obsidian: `AdminModeracionScreen`

## 📁 Ubicación en el Proyecto

`lib/presentation/screens/admin_moderacion_screen.dart`

Se accede desde `AjustesScreen` — un ítem que solo aparece cuando `usuario.email == correoAdmin` (ver `supabase_config.dart`).

## 🎯 Propósito del Archivo

Lista los reportes de mascota perdida/encontrada que tienen al menos una denuncia, con la opción de borrarlos (2026-08-25). Reemplaza el diseño original del módulo Mapa (ver `decisiones_arquitectura.md`, entrada "Moderación de contenido", 2026-08-19), donde revisar y borrar un reporte denunciado se hacía a mano desde el Table Editor de Supabase — el usuario pidió tener esa acción dentro de la app.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Solo un admin fijo, identificado por correo (no hay tabla de roles): `usuario.email == correoAdmin` en la app decide si se **muestra** el ítem en `AjustesScreen`, y la política RLS `denuncias_reportes_leer_admin` (compara `auth.jwt() ->> 'email'` contra el mismo correo, ver `TablaMaestraAppVetMovil1.sql`) decide si la consulta **funciona** del lado del servidor — la primera es solo UX, la segunda es la protección real. Lo mismo para borrar: la política `mascotas_extraviadas_borrar_dueno` se extendió para aceptar también al admin, no solo al dueño del reporte.

`ReporteDenunciado` (en `mascota_extraviada_repository.dart`, no un model aparte) empareja un `MascotaExtraviadaModel` con su conteo de denuncias — el conteo no vive en la tabla de reportes, así que no encaja como campo del model.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `FutureBuilder`, no un provider de Riverpod

Pantalla de uso raro (un solo admin, no en el camino común de la app) — se decidió no construir un `AsyncNotifier` aparte solo para esto. `_futuroReportes` se guarda en el estado del widget y se reasigna (con `setState`) después de cada borrado, para recargar la lista sin salir de la pantalla.

### 2. `obtenerReportesDenunciados()` no filtra por `resuelto`

Un reporte denunciado por contenido abusivo sigue necesitando revisión aunque su dueño ya lo haya marcado como resuelto — a diferencia de `mascotaExtraviadaProvider` (que solo carga activos, para el mapa), esta consulta trae reportes denunciados sin importar su estado.

### 3. Agrupado en Dart, no en SQL

Supabase (vía `postgrest`) no ofrece un `group by` directo desde el cliente sin una vista o función RPC aparte — con el volumen esperado de denuncias, se prefirió traer las filas de `denuncias_reportes` y contarlas en memoria (`Map<String, int>`) antes que sumar una vista nueva a la base solo para esto.
