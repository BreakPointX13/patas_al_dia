import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/presentation/screens/login_screen.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    await ref.read(usuarioProvider.notifier).cerrarSesion();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () => _cerrarSesion(context, ref),
          ),
        ],
      ),
    );
  }
}
