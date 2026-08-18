import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/login_screen.dart';
import 'package:patas_al_dia/providers/agenda_evento_provider.dart';
import 'package:patas_al_dia/providers/documento_provider.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';
import 'package:patas_al_dia/providers/medicamento_evento_provider.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';
import 'package:url_launcher/url_launcher.dart';

final _urlKoFi = Uri.parse('https://ko-fi.com/breakpointx');

const _escalasTexto = [0.85, 1.0, 1.2];
const _temas = ['sistema', 'claro', 'oscuro'];
const _iconosTema = [Icons.brightness_auto, Icons.light_mode, Icons.dark_mode];

// Los idiomas se muestran con su propio nombre nativo (no se traducen según
// el idioma activo) — así el usuario siempre reconoce su idioma, aunque no
// entienda el que esté puesto en ese momento.
const _idiomas = ['sistema', 'es', 'en', 'pt'];
const _etiquetasIdioma = ['Sistema', 'Español', 'English', 'Português'];
const _iconosIdioma = [
  Icons.brightness_auto,
  Icons.language,
  Icons.language,
  Icons.language,
];

class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  Future<void> _abrirKoFi(BuildContext context) async {
    final abierto = await launchUrl(
      _urlKoFi,
      mode: LaunchMode.externalApplication,
    );
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorAbrirEnlace)),
      );
    }
  }

  Future<void> _confirmarCerrarSesion(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cerrarSesionLabel),
        content: Text(l10n.cerrarSesionContenido),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.accionCancelar),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.cerrarSesionLabel),
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
    final l10n = AppLocalizations.of(context);
    final usuario = ref.watch(usuarioProvider);
    final escalaActual = usuario?.escalaTexto ?? 1.0;
    var indiceActual = _escalasTexto.indexOf(escalaActual);
    if (indiceActual == -1) {
      indiceActual = 1;
    }
    final temaActual = usuario?.tema ?? 'sistema';
    var indiceTema = _temas.indexOf(temaActual);
    if (indiceTema == -1) {
      indiceTema = 0;
    }
    final idiomaActual = usuario?.idioma ?? 'sistema';
    var indiceIdioma = _idiomas.indexOf(idiomaActual);
    if (indiceIdioma == -1) {
      indiceIdioma = 0;
    }
    final etiquetasTema = [l10n.temaSistema, l10n.temaClaro, l10n.temaOscuro];
    final etiquetasEscalaTexto = [
      l10n.tamanoPequeno,
      l10n.tamanoNormal,
      l10n.tamanoGrande,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ajustesTitulo)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: Text(l10n.temaLabel),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: [
                for (var i = 0; i < _temas.length; i++)
                  ButtonSegment(
                    value: _temas[i],
                    label: Text(etiquetasTema[i]),
                    icon: Icon(_iconosTema[i]),
                  ),
              ],
              selected: {_temas[indiceTema]},
              onSelectionChanged: (seleccion) {
                ref
                    .read(usuarioProvider.notifier)
                    .actualizarTema(seleccion.first);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: Text(l10n.tamanoLetraLabel),
            subtitle: Text(etiquetasEscalaTexto[indiceActual]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: indiceActual.toDouble(),
              min: 0,
              max: 2,
              divisions: 2,
              label: etiquetasEscalaTexto[indiceActual],
              onChanged: (valor) {
                ref
                    .read(usuarioProvider.notifier)
                    .actualizarEscalaTexto(_escalasTexto[valor.round()]);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.idiomaLabel),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: [
                for (var i = 0; i < _idiomas.length; i++)
                  ButtonSegment(
                    value: _idiomas[i],
                    label: Text(_etiquetasIdioma[i]),
                    icon: Icon(_iconosIdioma[i]),
                  ),
              ],
              selected: {_idiomas[indiceIdioma]},
              onSelectionChanged: (seleccion) {
                ref
                    .read(usuarioProvider.notifier)
                    .actualizarIdioma(seleccion.first);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: Text(l10n.aportesVoluntariosLabel),
            subtitle: Text(l10n.aportesVoluntariosSubtitulo),
            onTap: () => _abrirKoFi(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.cerrarSesionLabel),
            onTap: () => _confirmarCerrarSesion(context, ref),
          ),
        ],
      ),
    );
  }
}
