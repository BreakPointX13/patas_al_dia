import 'package:flutter/material.dart';
import 'package:patas_al_dia/presentation/widgets/menu_usuario_avatar.dart';

class MapaScreen extends StatelessWidget {
  const MapaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: const [MenuUsuarioAvatar()],
      ),
      body: const Center(child: Text('Próximamente')),
    );
  }
}
