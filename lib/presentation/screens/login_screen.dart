import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:patas_al_dia/data/models/usuario_model.dart';
import 'package:patas_al_dia/presentation/screens/home_screen.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Future<void> _continuarComoInvitado(BuildContext context, WidgetRef ref) async {
    final usuarioInvitado = UsuarioModel(id: const Uuid().v4());
    await ref.read(usuarioProvider.notifier).crearUsuario(usuarioInvitado);

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _mostrarLoginNoDisponible(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Inicio de sesión no disponible todavía: estamos en fase de desarrollo.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets, size: 96),
              const SizedBox(height: 16),
              Text(
                'Patas al Día',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Gestiona la salud de tu mascota, donde estés',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _mostrarLoginNoDisponible(context),
                  child: const Text('Iniciar sesión'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _continuarComoInvitado(context, ref),
                  child: const Text('Continuar como invitado'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
