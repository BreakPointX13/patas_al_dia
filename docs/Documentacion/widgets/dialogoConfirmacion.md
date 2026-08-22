# Nota de Obsidian: `confirmarAccion`

## 📁 Ubicación en el Proyecto

`lib/presentation/widgets/dialogo_confirmacion.dart`

Usado en `DetalleMascotaScreen`, `DetalleDocumentoScreen`, `DetalleAgendaEventoScreen`, `DetalleReporteMascotaExtraviadaScreen` (tres veces — denunciar, marcar resuelto, eliminar) y `AjustesScreen` (cerrar sesión, eliminar cuenta).

## 🎯 Propósito del Archivo

Diálogo de "¿confirmar esta acción?" — antes de esta función, cada una de esas 7 llamadas reconstruía el mismo `AlertDialog` a mano, encontrado como duplicación real en una revisión completa del código pedida por el usuario (ver `decisiones_arquitectura.md`).

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Función suelta, no una clase `Widget` — a diferencia de `SeparadorSeccionFicha`/`TarjetaClara` (que se insertan en un árbol de widgets y se quedan ahí), esto es una acción puntual (mostrar un diálogo, esperar la respuesta) más parecida a `showDialog` en sí que a un widget de layout. Vive en `presentation/widgets/` igual que los demás porque compone directamente un widget de Flutter (`AlertDialog`), no porque sea una clase `StatelessWidget`.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `confirmarAccion(context, {titulo, contenido, textoConfirmar, destructivo = false})`

```dart
Future<bool?> confirmarAccion(
  BuildContext context, {
  required String titulo,
  required String contenido,
  required String textoConfirmar,
  bool destructivo = false,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(contenido),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.accionCancelar)),
        ElevatedButton(
          style: destructivo ? ElevatedButton.styleFrom(backgroundColor: Colors.red) : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
}
```

- **Devuelve `Future<bool?>`, no `Future<bool>`** — mismo motivo que el `showDialog<bool>` que reemplaza: si el usuario cierra el diálogo tocando afuera (sin elegir ningún botón), no hay ningún `pop()` explícito y el `Future` se resuelve en `null`. Todos los llamadores ya chequean `confirmar != true` (no `!confirmar`), tratando tanto `false` como `null` como "no confirmado" — ese chequeo no cambió al extraer la función, sigue viviendo en cada pantalla.
- **`textoConfirmar` es un parámetro obligatorio, no fijo en `l10n.accionEliminar`:** de las 7 llamadas, solo 4 confirman un borrado — las otras 3 confirman denunciar un reporte, marcar un reporte como resuelto, o cerrar sesión, cada una con su propio texto de botón (`l10n.denunciarReporteLabel`, `l10n.marcarComoResueltoLabel`, `l10n.cerrarSesionLabel`). Fijar el texto habría dejado afuera a esos 3 casos.
- **`destructivo: bool`, no un enum ni un `Color` a mano:** de las 7 llamadas, 4 son genuinamente destructivas (eliminar mascota/documento/evento/reporte, con el botón en rojo) y 3 no lo son (denunciar, marcar resuelto, cerrar sesión — acciones reversibles o no destructivas, con el botón en el color por defecto del tema). Un booleano alcanza porque solo hay dos casos reales; no se generalizó a "elegí cualquier color" porque nadie lo necesitaba.
- **No incluye el `try/catch` ni la lógica posterior a la confirmación** — cada pantalla sigue manejando qué pasa después (`await ref.read(...).eliminarX(...)`, navegar, mostrar un `SnackBar` de error) exactamente como antes. La función solo reemplaza la construcción del diálogo en sí, no el flujo alrededor — mantiene el reemplazo acotado y de bajo riesgo, sin tocar comportamiento.
