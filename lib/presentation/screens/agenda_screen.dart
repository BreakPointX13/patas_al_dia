import 'package:flutter/material.dart';
import 'package:patas_al_dia/presentation/widgets/menu_usuario_avatar.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: const [MenuUsuarioAvatar()],
      ),
      body: const Center(child: Text('Próximamente')),
    );
  }
}
