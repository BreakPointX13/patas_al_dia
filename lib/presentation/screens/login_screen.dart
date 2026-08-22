import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:patas_al_dia/data/models/usuario_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/iniciar_sesion_screen.dart';
import 'package:patas_al_dia/presentation/screens/navegacion_principal_screen.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

// Pantalla de bienvenida: iniciar sesión, registrarse o entrar como invitado.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  // Política de privacidad (2026-08-21, retoque post-Sync — ver
  // decisiones_arquitectura.md), una página por idioma en el mismo repo de
  // GitHub Pages que la de confirmación de correo (Supabase Storage no
  // puede servir HTML real, ver esa entrada). Visible en LoginScreen (no
  // solo en AjustesScreen) para que esté al alcance de cualquiera, incluido
  // quien todavía no tiene ni siquiera una cuenta de invitado creada.
  Future<void> _abrirPoliticaPrivacidad(BuildContext context) async {
    final idioma = Localizations.localeOf(context).languageCode;
    final sufijo = ['es', 'en', 'pt'].contains(idioma) ? idioma : 'es';
    final uri = Uri.parse(
      'https://breakpointx13.github.io/PatasAlDiaWeb/privacidad-$sufijo.html',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // Crea un usuario invitado local (sin cuenta) y entra a la app.
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

  // Abre la pantalla de inicio de sesión.
  void _irAIniciarSesion(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const IniciarSesionScreen()),
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
                  onPressed: () => _irAIniciarSesion(context),
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
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _abrirPoliticaPrivacidad(context),
                child: Text(l10n.linkPoliticaPrivacidad),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
