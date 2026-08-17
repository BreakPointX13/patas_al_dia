import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';
import 'package:share_plus/share_plus.dart';

class CredencialMascotaScreen extends ConsumerStatefulWidget {
  final String mascotaId;
  const CredencialMascotaScreen({super.key, required this.mascotaId});

  @override
  ConsumerState<CredencialMascotaScreen> createState() =>
      _CredencialMascotaScreenState();
}

class _CredencialMascotaScreenState
    extends ConsumerState<CredencialMascotaScreen> {
  final _tarjetaKey = GlobalKey();
  bool _compartiendo = false;

  Future<void> _compartirCredencial(String nombreMascota) async {
    setState(() => _compartiendo = true);
    try {
      final boundary =
          _tarjetaKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final imagen = await boundary.toImage(pixelRatio: 3);
      final byteData = await imagen.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final bytes = byteData!.buffer.asUint8List();

      final archivo = File(
        '${Directory.systemTemp.path}/credencial_$nombreMascota.png',
      );
      await archivo.writeAsBytes(bytes);

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(archivo.path)],
          text: 'Credencial de $nombreMascota',
        ),
      );
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mascotas = ref.watch(mascotasProvider);
    MascotaModel? mascotaEncontrada;
    for (final m in mascotas) {
      if (m.id == widget.mascotaId) {
        mascotaEncontrada = m;
        break;
      }
    }
    if (mascotaEncontrada == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mascota = mascotaEncontrada;
    final razaTexto = mascota.raza == null || mascota.raza!.trim().isEmpty
        ? mascota.especieTexto
        : '${mascota.especieTexto} · ${mascota.raza}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credencial'),
        actions: [
          IconButton(
            icon: _compartiendo
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            tooltip: 'Compartir',
            onPressed: _compartiendo
                ? null
                : () => _compartirCredencial(mascota.nombre),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: RepaintBoundary(
            key: _tarjetaKey,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              decoration: BoxDecoration(
                color: const Color(0xFFF3C98F),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFD06D1F), width: 3),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF7A4A22),
                          width: 4,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 84,
                        backgroundImage: mascota.fotoUrl != null
                            ? FileImage(File(mascota.fotoUrl!))
                            : null,
                        child: mascota.fotoUrl == null
                            ? const Icon(Icons.pets, size: 84)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    mascota.nombre,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7A4A22),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    razaTexto,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF7A4A22),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  const Divider(color: Color(0xFFD06D1F), thickness: 1.5),
                  const SizedBox(height: 12),
                  _filaCredencial('RUT de la mascota', mascota.rutMascota),
                  _filaCredencial('Número de chip', mascota.numeroChip),
                  _filaCredencial(
                    'Esterilizado',
                    mascota.esterilizado ? 'Sí' : 'No',
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo_patas_al_dia.png',
                          height: 20,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Patas al Día',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7A4A22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filaCredencial(String etiqueta, String? valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF7A4A22),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor == null || valor.trim().isEmpty ? 'No especificado' : valor,
            style: const TextStyle(fontSize: 20, color: Color(0xFF7A4A22)),
          ),
        ],
      ),
    );
  }
}
