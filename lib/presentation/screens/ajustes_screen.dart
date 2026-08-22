import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/cambiar_contrasena_screen.dart';
import 'package:patas_al_dia/presentation/screens/login_screen.dart';
import 'package:patas_al_dia/presentation/screens/registro_screen.dart';
import 'package:patas_al_dia/presentation/widgets/separador_seccion_ficha.dart';
import 'package:patas_al_dia/providers/agenda_evento_provider.dart';
import 'package:patas_al_dia/providers/documento_provider.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';
import 'package:patas_al_dia/providers/medicamento_evento_provider.dart';
import 'package:patas_al_dia/providers/sync_provider.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';
import 'package:url_launcher/url_launcher.dart';

final _urlKoFi = Uri.parse('https://ko-fi.com/breakpointx');

// Mismo criterio que en documentos_screen.dart (ver separadorSeccionFicha.md,
// punto 4): el ícono del separador queda fijo, el texto que lo acompaña
// necesita variante oscura porque va directo sobre el fondo de la pantalla.
Color _colorTextoSeparador(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFFFF7EC)
    : const Color(0xFF7A4A22);

Widget _encabezadoSeccion(BuildContext context, IconData icono, String texto) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: SeparadorSeccionFicha(
      icono: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: const Color(0xFFD06D1F), size: 24),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              color: _colorTextoSeparador(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

// Sin paquete nuevo — intl no trae un helper de tiempo relativo, se calcula
// a mano. Solo necesita cuatro escalones (nunca, minutos, horas, días), no
// hace falta granularidad de semanas/meses para esta pantalla.
String _tiempoRelativo(AppLocalizations l10n, DateTime? momento) {
  if (momento == null) {
    return l10n.ultimaSincronizacionNunca;
  }
  final diferencia = DateTime.now().difference(momento);
  if (diferencia.inMinutes < 1) {
    return l10n.ultimaSincronizacionConValor(l10n.tiempoRelativoAhora);
  }
  if (diferencia.inHours < 1) {
    return l10n.ultimaSincronizacionConValor(
      l10n.tiempoRelativoMinutos(diferencia.inMinutes),
    );
  }
  if (diferencia.inDays < 1) {
    return l10n.ultimaSincronizacionConValor(
      l10n.tiempoRelativoHoras(diferencia.inHours),
    );
  }
  return l10n.ultimaSincronizacionConValor(
    l10n.tiempoRelativoDias(diferencia.inDays),
  );
}

const _escalasTexto = [0.85, 1.0, 1.2];
const _temas = ['sistema', 'claro', 'oscuro'];
const _iconosTema = [Icons.brightness_auto, Icons.light_mode, Icons.dark_mode];

// Los idiomas se muestran con su propio nombre nativo (no se traducen según
// el idioma activo) — así el usuario siempre reconoce su idioma, aunque no
// entienda el que esté puesto en ese momento. "Sistema" es la excepción: no
// es el nombre de un idioma, es un concepto de la interfaz ("seguir el
// idioma del sistema operativo"), así que sí se traduce vía l10n.
const _idiomas = ['sistema', 'es', 'en', 'pt'];
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

  Future<void> _confirmarCerrarSesion(
    BuildContext context,
    WidgetRef ref,
    bool esInvitado,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cerrarSesionLabel),
        content: Text(
          esInvitado
              ? l10n.cerrarSesionContenido
              : l10n.cerrarSesionContenidoRegistrado,
        ),
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

  Future<void> _confirmarEliminarCuenta(
    BuildContext context,
    WidgetRef ref,
    bool esInvitado,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.eliminarCuentaLabel),
        content: Text(
          esInvitado
              ? l10n.eliminarCuentaContenido
              : l10n.eliminarCuentaContenidoRegistrado,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.accionCancelar),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.accionEliminar),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) {
      return;
    }
    await _eliminarCuenta(context, ref);
  }

  Future<void> _eliminarCuenta(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(usuarioProvider.notifier).eliminarUsuario();
    } catch (e) {
      // TEMPORAL — mismo patrón de diagnóstico que el resto del proyecto con
      // Supabase (ver formularioReporteMascotaExtraviadaScreen.md, punto 5b).
      debugPrint('DEBUG eliminarCuenta error: $e');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorAutenticacionGenerico)));
      return;
    }

    // Mismo motivo que en _cerrarSesion: sin esto, un invitado nuevo podía
    // ver por un momento los datos del que se acaba de borrar.
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
    final sincronizando = ref.watch(sincronizandoProvider);
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
    final etiquetasIdioma = [l10n.idiomaSistemaLabel, 'ES', 'EN', 'PT'];
    final etiquetasEscalaTexto = [
      l10n.tamanoPequeno,
      l10n.tamanoNormal,
      l10n.tamanoGrande,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ajustesTitulo)),
      body: ListView(
        children: [
          _encabezadoSeccion(context, Icons.favorite, l10n.seccionApoyoLabel),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: Text(l10n.aportesVoluntariosLabel),
            subtitle: Text(l10n.aportesVoluntariosSubtitulo),
            onTap: () => _abrirKoFi(context),
          ),
          _encabezadoSeccion(
            context,
            Icons.palette_outlined,
            l10n.seccionAparienciaLabel,
          ),
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
                    label: Text(etiquetasIdioma[i]),
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
          _encabezadoSeccion(
            context,
            Icons.account_circle_outlined,
            l10n.seccionCuentaLabel,
          ),
          if (usuario != null && usuario.esInvitado)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.cuentaInvitadoLabel),
              subtitle: Text(l10n.registrarmeSubtitulo),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const RegistroScreen(entrarComoApp: false),
                ),
              ),
            )
          else if (usuario != null)
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(usuario.email ?? ''),
            ),
          if (usuario != null && !usuario.esInvitado)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.tituloCambiarContrasena),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CambiarContrasenaScreen(),
                ),
              ),
            ),
          // La sincronización en sí se dispara sola (ver main.dart) — este
          // botón queda como respaldo manual, más el estado de la última
          // corrida para que el usuario tenga algo visible en qué confiar.
          if (usuario != null && !usuario.esInvitado)
            ListTile(
              leading: sincronizando
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              title: Text(l10n.sincronizarAhoraLabel),
              subtitle: Text(
                _tiempoRelativo(l10n, usuario.ultimaSincronizacion),
              ),
              onTap: sincronizando
                  ? null
                  : () => ref.read(syncServiceProvider).sincronizar(),
            ),
          _encabezadoSeccion(
            context,
            Icons.shield_outlined,
            l10n.seccionSesionLabel,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.cerrarSesionLabel),
            onTap: () => _confirmarCerrarSesion(
              context,
              ref,
              usuario?.esInvitado ?? true,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              l10n.eliminarCuentaLabel,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => _confirmarEliminarCuenta(
              context,
              ref,
              usuario?.esInvitado ?? true,
            ),
          ),
        ],
      ),
    );
  }
}
