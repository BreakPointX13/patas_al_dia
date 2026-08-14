import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/presentation/screens/login_screen.dart';
import 'package:patas_al_dia/presentation/screens/navegacion_principal_screen.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

class SesionInicialScreen extends ConsumerStatefulWidget {
  const SesionInicialScreen({super.key});

  @override
  ConsumerState<SesionInicialScreen> createState() =>
      _SesionInicialScreenState();
}

class _SesionInicialScreenState extends ConsumerState<SesionInicialScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificarSesion());
  }

  Future<void> _verificarSesion() async {
    final haySesionActiva = await ref
        .read(usuarioProvider.notifier)
        .cargarSesionActiva();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => haySesionActiva
            ? const NavegacionPrincipalScreen()
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
