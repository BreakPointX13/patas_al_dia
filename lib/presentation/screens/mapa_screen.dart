import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/widgets/logo_barra_superior.dart';
import 'package:patas_al_dia/presentation/widgets/menu_usuario_avatar.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

class MapaScreen extends ConsumerStatefulWidget {
  final ValueNotifier<int> indiceActualNotifier;

  const MapaScreen({super.key, required this.indiceActualNotifier});

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  // Índice 2 = Mapa, mismo orden que _pantallasRaiz/_iconosDestino en
  // NavegacionPrincipalScreen.
  static const _indiceMapa = 2;

  bool _mostrandoAviso = false;

  @override
  void initState() {
    super.initState();
    widget.indiceActualNotifier.addListener(_alCambiarPestana);
    // Por si esta pantalla se monta ya con Mapa como pestaña activa (no
    // pasa hoy — la app siempre arranca en Mascotas — pero cubre el caso).
    _alCambiarPestana();
  }

  @override
  void dispose() {
    widget.indiceActualNotifier.removeListener(_alCambiarPestana);
    super.dispose();
  }

  void _alCambiarPestana() {
    if (widget.indiceActualNotifier.value == _indiceMapa) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _mostrarAvisoSiCorresponde(),
      );
    }
  }

  // Se muestra una sola vez por usuario (marca guardada en UsuarioModel,
  // igual que tema/idioma) — no cada vez que se entra a la pestaña. Ver
  // mapaScreen.md.
  Future<void> _mostrarAvisoSiCorresponde() async {
    final usuario = ref.read(usuarioProvider);
    if (usuario == null ||
        usuario.avisoMapaVisto ||
        _mostrandoAviso ||
        !mounted) {
      return;
    }
    _mostrandoAviso = true;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_patas_al_dia.png',
              width: 64,
              height: 64,
            ),
            const SizedBox(height: 12),
            Text(l10n.avisoMapaTitulo, textAlign: TextAlign.center),
          ],
        ),
        content: Text(l10n.avisoMapaContenido),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.avisoMapaEntendido),
          ),
        ],
      ),
    );
    if (mounted) {
      await ref.read(usuarioProvider.notifier).marcarAvisoMapaVisto();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const LogoBarraSuperior(),
        title: const Text('Mapa'),
        actions: const [MenuUsuarioAvatar()],
      ),
      body: const Center(child: Text('Próximamente')),
    );
  }
}
