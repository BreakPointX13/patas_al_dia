import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';

// Envuelve ImagePicker.pickImage pidiendo el permiso de cámara explícito
// antes de abrir el selector (2026-08-25, reportado por un tester: tocaba
// "tomar foto" y no pasaba nada, sin ningún mensaje — el permiso ya estaba
// denegado para siempre, y en ese estado Android nunca vuelve a mostrar el
// diálogo del sistema, así que hace falta guiar al usuario a Ajustes a mano).
// La galería no se gestiona igual a propósito: en Android 13+ el selector de
// fotos del sistema no pide ningún permiso, así que pedirlo igual bloquearía
// sin necesidad a quien lo negara. Ahí solo se atrapa el error por si el
// selector clásico (Android 12 o anterior) lo necesita y no lo tiene.
Future<XFile?> elegirImagenConPermiso(
  BuildContext context,
  ImagePicker picker, {
  required ImageSource source,
  double? maxWidth,
  int? imageQuality,
}) async {
  final l10n = AppLocalizations.of(context);

  if (source == ImageSource.camera) {
    var estado = await Permission.camera.status;
    if (!estado.isGranted) {
      estado = await Permission.camera.request();
    }
    if (estado.isPermanentlyDenied) {
      if (!context.mounted) {
        return null;
      }
      await _avisarPermisoDenegado(context, l10n.errorPermisoCamaraPermanente);
      return null;
    }
    if (!estado.isGranted) {
      return null;
    }
  }

  try {
    return await picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      imageQuality: imageQuality,
    );
  } on PlatformException {
    if (!context.mounted) {
      return null;
    }
    await _avisarPermisoDenegado(context, l10n.errorPermisoFotosGenerico);
    return null;
  }
}

Future<void> _avisarPermisoDenegado(BuildContext context, String mensaje) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.avisoMapaEntendido),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            openAppSettings();
          },
          child: Text(l10n.abrirAjustesBoton),
        ),
      ],
    ),
  );
}
