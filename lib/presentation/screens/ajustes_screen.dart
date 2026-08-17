import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/presentation/screens/login_screen.dart';
import 'package:patas_al_dia/providers/agenda_evento_provider.dart';
import 'package:patas_al_dia/providers/documento_provider.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';
import 'package:patas_al_dia/providers/medicamento_evento_provider.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';
import 'package:url_launcher/url_launcher.dart';

final _urlKoFi = Uri.parse('https://ko-fi.com/breakpointx');

class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  Future<void> _abrirKoFi(BuildContext context) async {
    final abierto = await launchUrl(
      _urlKoFi,
      mode: LaunchMode.externalApplication,
    );
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  Future<void> _confirmarCerrarSesion(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          'Como invitado, no hay forma de volver a esta sesión después de '
          'cerrarla: no vas a poder ver de nuevo tus mascotas ni los datos '
          'cargados. ¿Cerrar sesión de todos modos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) {
      return;
    }
    await _cerrarSesion(context, ref);
  }

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    await ref.read(usuarioProvider.notifier).cerrarSesion();

    // Limpia el estado en memoria del usuario que se va — sin esto, un
    // invitado nuevo podía ver por un momento la agenda del invitado
    // anterior (mascotasProvider ya se resetea al cargar el nuevo usuario,
    // pero agendaEventosProvider/medicamentoEventoProvider/documentosProvider
    // seguían con los datos viejos hasta que algo los recargara).
    ref.invalidate(mascotasProvider);
    ref.invalidate(agendaEventosProvider);
    ref.invalidate(medicamentoEventoProvider);
    ref.invalidate(documentosProvider);

    if (!context.mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
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
            leading: const Icon(Icons.favorite_border),
            title: const Text('Aportes voluntarios'),
            subtitle: const Text('Si quieres apoyar el proyecto, es en Ko-fi'),
            onTap: () => _abrirKoFi(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () => _confirmarCerrarSesion(context, ref),
          ),
        ],
      ),
    );
  }
}
