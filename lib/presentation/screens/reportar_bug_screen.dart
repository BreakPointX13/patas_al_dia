import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/services/reportar_bug_service.dart';

// Formulario para reportar un bug: descripción + imagen opcional, por correo.
class ReportarBugScreen extends ConsumerStatefulWidget {
  const ReportarBugScreen({super.key});

  @override
  ConsumerState<ReportarBugScreen> createState() => _ReportarBugScreenState();
}

class _ReportarBugScreenState extends ConsumerState<ReportarBugScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final _servicio = ReportarBugService();

  String? _imagenPath;
  bool _enviando = false;

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _elegirImagen() async {
    final l10n = AppLocalizations.of(context);
    final opcion = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l10n.tomarFoto),
              onTap: () => Navigator.of(context).pop('camara'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.elegirImagenGaleria),
              onTap: () => Navigator.of(context).pop('galeria'),
            ),
          ],
        ),
      ),
    );

    if (opcion == null || !mounted) {
      return;
    }

    // Misma compresión que las fotos que ya viajan a la nube (foto de
    // mascota, foto de reporte) — esta también sale del dispositivo.
    final foto = await _picker.pickImage(
      source: opcion == 'camara' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (foto == null) {
      return;
    }
    setState(() => _imagenPath = foto.path);
  }

  // Codifica la imagen (si hay) y envía el reporte por la Edge Function.
  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _enviando = true);
    try {
      String? imagenBase64;
      String? imagenNombre;
      if (_imagenPath != null) {
        final bytes = await File(_imagenPath!).readAsBytes();
        imagenBase64 = base64Encode(bytes);
        imagenNombre = 'captura.${_imagenPath!.split('.').last}';
      }

      await _servicio.enviarReporte(
        descripcion: _descripcionController.text.trim(),
        imagenBase64: imagenBase64,
        imagenNombre: imagenNombre,
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.avisoReporteEnviado)));
    } catch (e) {
      debugPrint('DEBUG enviarReporte error: $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorAutenticacionGenerico)));
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportarBugTitulo)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.reportarBugIntro),
            const SizedBox(height: 24),
            TextFormField(
              controller: _descripcionController,
              decoration: InputDecoration(labelText: l10n.campoDescripcionBug),
              maxLines: 5,
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return l10n.errorDescripcionBugObligatoria;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (_imagenPath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_imagenPath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.image_outlined),
              title: Text(
                _imagenPath == null
                    ? l10n.sinArchivoElegido
                    : l10n.archivoElegido,
              ),
              trailing: TextButton(
                onPressed: _elegirImagen,
                child: Text(
                  _imagenPath == null ? l10n.accionElegir : l10n.accionCambiar,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              child: _enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.botonEnviarReporte),
            ),
          ],
        ),
      ),
    );
  }
}
