import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/presentation/screens/formulario_mascota_screen.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';

class DetalleMascotaScreen extends ConsumerWidget {
  final String mascotaId;
  const DetalleMascotaScreen({super.key, required this.mascotaId});

  void _mostrarProximamente(BuildContext context, String funcionalidad) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$funcionalidad: próximamente.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mascota = ref
        .watch(mascotasProvider)
        .firstWhere((m) => m.id == mascotaId);

    return Scaffold(
      appBar: AppBar(title: Text(mascota.nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 56,
              backgroundImage: mascota.fotoUrl != null
                  ? FileImage(File(mascota.fotoUrl!))
                  : null,
              child: mascota.fotoUrl == null
                  ? const Icon(Icons.pets, size: 56)
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Especie'),
            subtitle: Text(mascota.especie ?? 'No especificada'),
          ),
          ListTile(
            title: const Text('Raza'),
            subtitle: Text(mascota.raza ?? 'No especificada'),
          ),
          ListTile(
            title: const Text('Sexo'),
            subtitle: Text(mascota.sexo ?? 'No especificado'),
          ),
          ListTile(
            title: Text(
              mascota.fechaEstimada ? 'Edad estimada' : 'Fecha de nacimiento',
            ),
            subtitle: Text(
              mascota.fechaNacimiento == null
                  ? 'No especificada'
                  : mascota.fechaEstimada
                  ? '${DateTime.now().year - mascota.fechaNacimiento!.year} años'
                  : '${mascota.fechaNacimiento!.day}/'
                        '${mascota.fechaNacimiento!.month}/'
                        '${mascota.fechaNacimiento!.year}',
            ),
          ),
          ListTile(
            title: const Text('Peso'),
            subtitle: Text(
              mascota.pesoActual == null
                  ? 'No especificado'
                  : '${mascota.pesoActual} kg',
            ),
          ),
          ListTile(
            title: const Text('Esterilizado'),
            subtitle: Text(mascota.esterilizado ? 'Sí' : 'No'),
          ),
          ListTile(
            title: const Text('RUT de la mascota'),
            subtitle: Text(mascota.rutMascota ?? 'No especificado'),
          ),
          ListTile(
            title: const Text('Colores'),
            subtitle: Text(mascota.colores ?? 'No especificado'),
          ),
          ListTile(
            title: const Text('Número de chip'),
            subtitle: Text(mascota.numeroChip ?? 'No especificado'),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar datos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      FormularioMascotaScreen(mascotaExistente: mascota),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_note),
            title: const Text('Agenda'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _mostrarProximamente(context, 'Agenda'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Documentos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _mostrarProximamente(context, 'Documentos'),
          ),
        ],
      ),
    );
  }
}
