import 'package:flutter/material.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';

/// Diálogo de "¿confirmar esta acción?" compartido — antes se reconstruía a
/// mano en cada pantalla (eliminar mascota, eliminar documento, eliminar
/// evento, eliminar/denunciar/resolver un reporte, cerrar sesión, eliminar
/// cuenta), siempre con la misma forma: `TextButton` de cancelar (pop
/// `false`) + botón de confirmar (pop `true`), a veces en rojo para acciones
/// destructivas. Devuelve `true` si se confirmó, `false`/`null` si se
/// canceló — el llamador sigue chequeando `confirmar != true`, igual que
/// antes de existir esta función.
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.accionCancelar),
        ),
        ElevatedButton(
          style: destructivo
              ? ElevatedButton.styleFrom(backgroundColor: Colors.red)
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
}
