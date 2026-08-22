import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/utils/errores_autenticacion.dart';
import 'package:patas_al_dia/presentation/utils/validador_contrasena.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

// "Cambiar contraseña" desde AjustesScreen (2026-08-21, retoque post-Sync —
// ver decisiones_arquitectura.md). Distinta de NuevaContrasenaScreen (último
// paso de "olvidé mi contraseña"): esta pantalla pide la contraseña ACTUAL
// además de la nueva, porque acá no hay ningún enlace de correo que ya haya
// probado la identidad — solo una sesión ya iniciada en el teléfono.
class CambiarContrasenaScreen extends ConsumerStatefulWidget {
  const CambiarContrasenaScreen({super.key});

  @override
  ConsumerState<CambiarContrasenaScreen> createState() =>
      _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState
    extends ConsumerState<CambiarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  // Valida el formulario y llama a Supabase Auth para cambiar la contraseña.
  Future<void> _cambiar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _guardando = true);
    try {
      await ref
          .read(usuarioProvider.notifier)
          .cambiarContrasena(
            contrasenaActual: _actualController.text,
            nuevaContrasena: _nuevaController.text,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.avisoContrasenaActualizada)));
    } on AuthException catch (e) {
      debugPrint(
        'DEBUG cambiarContrasena AuthException: code=${e is AuthApiException ? e.code : '?'} message=${e.message}',
      );
      if (!mounted) {
        return;
      }
      final esCredencialInvalida =
          e is AuthApiException && e.code == 'invalid_credentials';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esCredencialInvalida
                ? l10n.errorContrasenaActualIncorrecta
                : mensajeErrorAutenticacion(l10n, e),
          ),
        ),
      );
    } catch (e) {
      debugPrint('DEBUG cambiarContrasena error genérico: $e');
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
      appBar: AppBar(title: Text(l10n.tituloCambiarContrasena)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Image.asset(
              'assets/images/logo_patas_al_dia.png',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.cambiarContrasenaSubtitulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _actualController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.campoContrasenaActual),
              validator: (valor) {
                if (valor == null || valor.isEmpty) {
                  return l10n.errorContrasenaObligatoria;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nuevaController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.campoNuevaContrasena,
                helperText: l10n.avisoRequisitosContrasena,
                helperMaxLines: 2,
              ),
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
                if (valor != _nuevaController.text) {
                  return l10n.errorContrasenasNoCoinciden;
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _guardando ? null : _cambiar,
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.botonCambiarContrasena),
            ),
          ],
        ),
      ),
    );
  }
}
