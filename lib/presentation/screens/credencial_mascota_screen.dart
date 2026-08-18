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
    final edadTexto = _edadTexto(mascota.fechaNacimiento);

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
              constraints: const BoxConstraints(maxWidth: 396),
              decoration: BoxDecoration(
                color: const Color(0xFFF3C98F),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFD06D1F), width: 3),
              ),
              padding: const EdgeInsets.all(29),
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
                        radius: 76,
                        backgroundImage: mascota.fotoUrl != null
                            ? FileImage(File(mascota.fotoUrl!))
                            : null,
                        child: mascota.fotoUrl == null
                            ? const Icon(Icons.pets, size: 76)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            mascota.nombre,
                            style: const TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7A4A22),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (mascota.sexo == 'Macho' ||
                            mascota.sexo == 'Hembra') ...[
                          const SizedBox(width: 7),
                          Text(
                            mascota.sexo == 'Macho' ? '♂' : '♀',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: mascota.sexo == 'Macho'
                                  ? Colors.blue
                                  : Colors.pink,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    razaTexto,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF7A4A22),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  const Divider(color: Color(0xFFD06D1F), thickness: 1.5),
                  const SizedBox(height: 11),
                  _filaCredencial('RUT de la mascota', mascota.rutMascota),
                  _filaCredencial('Número de chip', mascota.numeroChip),
                  _filaCredencial('Edad', edadTexto),
                  _filaCredencial(
                    'Esterilizado',
                    mascota.esterilizado ? 'Sí' : 'No',
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo_patas_al_dia.png',
                          height: 18,
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Patas al Día',
                          style: TextStyle(
                            fontSize: 13,
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

  String? _edadTexto(DateTime? fechaNacimiento) {
    if (fechaNacimiento == null) {
      return null;
    }
    final hoy = DateTime.now();
    var edad = hoy.year - fechaNacimiento.year;
    final aunNoCumpleEsteAnio =
        hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day);
    if (aunNoCumpleEsteAnio) {
      edad--;
    }
    return '$edad años';
  }

  Widget _filaCredencial(String etiqueta, String? valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7A4A22),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor == null || valor.trim().isEmpty ? 'No especificado' : valor,
            style: const TextStyle(fontSize: 18, color: Color(0xFF7A4A22)),
          ),
        ],
      ),
    );
  }
}
