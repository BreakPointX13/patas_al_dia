import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/navegacion_principal_screen.dart';
import 'package:patas_al_dia/presentation/utils/errores_autenticacion.dart';
import 'package:patas_al_dia/presentation/utils/validador_contrasena.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

// Último paso de "olvidé mi contraseña" (2026-08-19, ver
// decisiones_arquitectura.md): se llega acá desde el enlace de recuperación
// que manda Supabase por correo, capturado por main.dart al escuchar
// AuthChangeEvent.passwordRecovery — para cuando esta pantalla se muestra ya
// hay una sesión de recuperación válida (la estableció el propio enlace), así
// que no hace falta pedir el correo de nuevo, solo la contraseña nueva.
class NuevaContrasenaScreen extends ConsumerStatefulWidget {
  const NuevaContrasenaScreen({super.key});

  @override
  ConsumerState<NuevaContrasenaScreen> createState() =>
      _NuevaContrasenaScreenState();
}

class _NuevaContrasenaScreenState
    extends ConsumerState<NuevaContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _restablecer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _guardando = true);
    try {
      await ref
          .read(usuarioProvider.notifier)
          .completarRecuperacion(nuevaContrasena: _passwordController.text);
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const NavegacionPrincipalScreen(),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      debugPrint(
        'DEBUG completarRecuperacion AuthException: code=${e is AuthApiException ? e.code : '?'} message=${e.message}',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeErrorAutenticacion(l10n, e))),
      );
    } catch (e) {
      debugPrint('DEBUG completarRecuperacion error genérico: $e');
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
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.campoNuevaContrasena),
              validator: (valor) => validarContrasena(l10n, valor),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmarController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.campoConfirmarContrasena,
              ),
              validator: (valor) {
                if (valor != _passwordController.text) {
                  return l10n.errorContrasenasNoCoinciden;
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _guardando ? null : _restablecer,
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.botonRestablecerContrasena),
            ),
          ],
        ),
      ),
    );
  }
}
