import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/presentation/screens/detalle_mascota_screen.dart';
import 'package:patas_al_dia/presentation/screens/formulario_mascota_screen.dart';
import 'package:patas_al_dia/presentation/widgets/logo_barra_superior.dart';
import 'package:patas_al_dia/presentation/widgets/menu_usuario_avatar.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final usuarioId = ref.read(usuarioProvider)!.id;
    ref.read(mascotasProvider.notifier).cargarMascotas(usuarioId);
  }

  void _irAAgregarMascota() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FormularioMascotaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mascotas = ref.watch(mascotasProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const LogoBarraSuperior(),
        title: const Text('Mis Mascotas'),
        actions: const [MenuUsuarioAvatar()],
      ),
      body: mascotas.isEmpty
          ? const Center(child: Text('Aún no tienes mascotas registradas'))
          : ListView.builder(
              itemCount: mascotas.length,
              itemBuilder: (context, index) {
                final mascota = mascotas[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF7A4A22),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundImage: mascota.fotoUrl != null
                            ? FileImage(File(mascota.fotoUrl!))
                            : null,
                        child: mascota.fotoUrl == null
                            ? const Icon(Icons.pets)
                            : null,
                      ),
                    ),
                    title: Text(mascota.nombre),
                    subtitle: Text(
                      mascota.especie ?? 'Especie no especificada',
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              DetalleMascotaScreen(mascotaId: mascota.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irAAgregarMascota,
        icon: const Icon(Icons.add),
        label: const Text('Agregar mascota'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
