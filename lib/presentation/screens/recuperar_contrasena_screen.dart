import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

// Primer (y único) paso de "olvidé mi contraseña" en esta pantalla — pide el
// correo y dispara el enlace de recuperación de Supabase (2026-08-19, ver
// decisiones_arquitectura.md: se eligió enlace por correo, no código de 6
// dígitos, porque el correo con código exige SMTP propio configurado en
// Supabase, y enlace funciona con el correo por defecto sin nada más). El
// paso siguiente (poner la contraseña nueva) no ocurre acá — pasa en
// NuevaContrasenaScreen, cuando el usuario vuelve a abrir la app tocando el
// enlace del correo (ver main.dart, AuthChangeEvent.passwordRecovery).
class RecuperarContrasenaScreen extends ConsumerStatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  @override
  ConsumerState<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState
    extends ConsumerState<RecuperarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _guardando = false;
  bool _enviado = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Pide a Supabase que mande el correo con el enlace de recuperación.
  Future<void> _enviarEnlace() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _guardando = true);
    try {
      final repo = ref.read(usuarioRepositoryProvider);
      await repo.enviarCorreoRecuperacion(_emailController.text.trim());
      if (!mounted) {
        return;
      }
      setState(() => _enviado = true);
    } catch (e) {
      debugPrint('DEBUG enviarCorreoRecuperacion error: $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorAutenticacionGenerico)));
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tituloRecuperarContrasena)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_enviado)
              Text(l10n.avisoEnlaceEnviado)
            else ...[
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.campoEmail),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return l10n.errorEmailObligatorio;
                  }
                  if (!RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  ).hasMatch(valor.trim())) {
                    return l10n.errorEmailInvalido;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _guardando ? null : _enviarEnlace,
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.botonEnviarEnlace),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
