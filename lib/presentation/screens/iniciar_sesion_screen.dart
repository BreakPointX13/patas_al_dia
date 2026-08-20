import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/navegacion_principal_screen.dart';
import 'package:patas_al_dia/presentation/screens/recuperar_contrasena_screen.dart';
import 'package:patas_al_dia/presentation/screens/registro_screen.dart';
import 'package:patas_al_dia/presentation/utils/errores_autenticacion.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

class IniciarSesionScreen extends ConsumerStatefulWidget {
  const IniciarSesionScreen({super.key});

  @override
  ConsumerState<IniciarSesionScreen> createState() =>
      _IniciarSesionScreenState();
}

class _IniciarSesionScreenState extends ConsumerState<IniciarSesionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _guardando = true);

    try {
      await ref
          .read(usuarioProvider.notifier)
          .iniciarSesion(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
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
        'DEBUG iniciarSesion AuthException: code=${e is AuthApiException ? e.code : '?'} message=${e.message}',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeErrorAutenticacion(l10n, e))),
      );
    } catch (e) {
      debugPrint('DEBUG iniciarSesion error genérico: $e');
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
      appBar: AppBar(title: Text(l10n.loginIniciarSesion)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.campoEmail),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return l10n.errorEmailObligatorio;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.campoContrasena),
              validator: (valor) {
                if (valor == null || valor.isEmpty) {
                  return l10n.errorContrasenaObligatoria;
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _guardando ? null : _iniciarSesion,
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.loginIniciarSesion),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RecuperarContrasenaScreen(),
                ),
              ),
              child: Text(l10n.linkOlvideContrasena),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const RegistroScreen()),
              ),
              child: Text(l10n.linkNoTenesCuenta),
            ),
          ],
        ),
      ),
    );
  }
}
