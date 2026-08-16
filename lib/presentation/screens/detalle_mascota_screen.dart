import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/presentation/screens/agenda_screen.dart';
import 'package:patas_al_dia/presentation/screens/documentos_screen.dart';
import 'package:patas_al_dia/presentation/screens/formulario_mascota_screen.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';

class DetalleMascotaScreen extends ConsumerWidget {
  final String mascotaId;
  const DetalleMascotaScreen({super.key, required this.mascotaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mascotas = ref.watch(mascotasProvider);
    MascotaModel? mascotaEncontrada;
    for (final m in mascotas) {
      if (m.id == mascotaId) {
        mascotaEncontrada = m;
        break;
      }
    }
    if (mascotaEncontrada == null) {
      // Puede pasar si la mascota se borró (o se cerró sesión) justo
      // mientras esta pantalla seguía abierta — no hay nada que mostrar.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mascota = mascotaEncontrada;

    final datosTiles = [
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
    ];

    return Scaffold(
      appBar: AppBar(title: Text(mascota.nombre)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
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
          for (final tile in datosTiles) Card(child: tile),
          const SizedBox(height: 16),
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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      AgendaScreen(mascotaIdInicial: mascotaId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Documentos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DocumentosScreen(mascotaId: mascotaId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
