import 'package:flutter/material.dart';
import 'package:patas_al_dia/presentation/screens/ajustes_screen.dart';

/// Ícono de avatar para el AppBar que abre un menú con acceso a Ajustes.
/// No muestra una foto real: UsuarioModel todavía no tiene un campo de foto,
/// así que por ahora es un ícono genérico de persona.
class MenuUsuarioAvatar extends StatelessWidget {
  const MenuUsuarioAvatar({super.key});

  void _irAAjustes(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AjustesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: 'Cuenta',
      icon: const CircleAvatar(child: Icon(Icons.person)),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          onTap: () => _irAAjustes(context),
          child: const ListTile(
            leading: Icon(Icons.settings),
            title: Text('Ajustes'),
          ),
        ),
      ],
    );
  }
}
