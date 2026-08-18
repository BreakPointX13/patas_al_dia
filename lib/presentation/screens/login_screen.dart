import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:patas_al_dia/data/models/usuario_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/navegacion_principal_screen.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Future<void> _continuarComoInvitado(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final usuarioInvitado = UsuarioModel(id: const Uuid().v4());
    await ref.read(usuarioProvider.notifier).crearUsuario(usuarioInvitado);

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const NavegacionPrincipalScreen()),
    );
  }

  void _mostrarLoginNoDisponible(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).loginNoDisponible)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_patas_al_dia.png',
                width: 140,
                height: 140,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.appTitulo,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(l10n.loginEslogan, textAlign: TextAlign.center),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _mostrarLoginNoDisponible(context),
                  child: Text(l10n.loginIniciarSesion),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _continuarComoInvitado(context, ref),
                  child: Text(l10n.loginContinuarInvitado),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
