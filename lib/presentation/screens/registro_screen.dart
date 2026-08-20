import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/navegacion_principal_screen.dart';
import 'package:patas_al_dia/presentation/utils/errores_autenticacion.dart';
import 'package:patas_al_dia/presentation/utils/validador_contrasena.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  // true (default): se llega acá desde LoginScreen, sin ningún shell de la
  // app todavía montado — al registrarse hay que navegar adentro. false: se
  // llega desde AjustesScreen, con un invitado que ya está usando la app
  // (NavegacionPrincipalScreen ya está montado) — alcanza con volver atrás.
  final bool entrarComoApp;

  const RegistroScreen({super.key, this.entrarComoApp = true});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _guardando = true);

    try {
      await ref
          .read(usuarioProvider.notifier)
          .registrarUsuario(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.avisoRevisaCorreo)));

      if (widget.entrarComoApp) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const NavegacionPrincipalScreen(),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      // TEMPORAL — mismo patrón de diagnóstico ya usado en el módulo Mapa
      // (ver formularioReporteMascotaExtraviadaScreen.md, punto 5b).
      debugPrint(
        'DEBUG registrarUsuario AuthException: code=${e is AuthApiException ? e.code : '?'} message=${e.message}',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeErrorAutenticacion(l10n, e))),
      );
    } catch (e) {
      debugPrint('DEBUG registrarUsuario error genérico: $e');
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
      appBar: AppBar(title: Text(l10n.tituloRegistrarse)),
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
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(valor.trim())) {
                  return l10n.errorEmailInvalido;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.campoContrasena),
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
              onPressed: _guardando ? null : _registrar,
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.botonRegistrarse),
            ),
            // Solo tiene sentido en el flujo de LoginScreen → registrarse
            // (entrarComoApp == true) — un invitado que ya está usando la
            // app y decide registrarse (ver AjustesScreen) no está "por
            // error" acá, no necesita un atajo a otra cuenta.
            if (widget.entrarComoApp) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.linkYaTenesCuenta),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
