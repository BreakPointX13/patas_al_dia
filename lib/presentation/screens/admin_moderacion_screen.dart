import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/mascota_extraviada_model.dart';
import 'package:patas_al_dia/data/repositories/mascota_extraviada_repository.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/detalle_reporte_mascota_extraviada_screen.dart';
import 'package:patas_al_dia/presentation/utils/etiquetas_localizadas.dart';
import 'package:patas_al_dia/presentation/widgets/dialogo_confirmacion.dart';
import 'package:patas_al_dia/presentation/widgets/icono_tipo_reporte.dart';
import 'package:patas_al_dia/providers/mascota_extraviada_provider.dart';

// Pantalla de moderación, solo para el admin (ver AjustesScreen — el ítem
// que lleva acá solo se muestra si usuario.email == correoAdmin, y las
// políticas RLS del lado de Supabase hacen cumplir lo mismo del lado del
// servidor). Reemplaza el flujo anterior de revisar/borrar a mano desde el
// panel de Supabase (2026-08-25, ver decisiones_arquitectura.md).
//
// Tres pestañas (2026-09-27, ver decisiones_arquitectura.md — el usuario
// pidió poder actuar sobre cualquier reporte activo, no solo los
// denunciados, y poder restringir a quien abusa del módulo):
// - Denunciados: reportes con al menos una denuncia (comportamiento
//   original de esta pantalla).
// - Todos: cualquier reporte activo, sin importar si fue denunciado.
// - Bloqueados: usuarios restringidos de publicar, con opción de
//   desbloquear.
// Fetch directo al repository en las dos primeras, sin pasar por
// mascotaExtraviadaProvider: ese provider solo trae reportes activos (no
// sirve para "Denunciados", que puede incluir resueltos).
class AdminModeracionScreen extends ConsumerStatefulWidget {
  const AdminModeracionScreen({super.key});

  @override
  ConsumerState<AdminModeracionScreen> createState() =>
      _AdminModeracionScreenState();
}

class _AdminModeracionScreenState
    extends ConsumerState<AdminModeracionScreen> {
  // `null` = todavía cargando, `[]` = cargó y no hay nada — listas ya
  // resueltas en el estado, no un Future guardado (2026-09-27, bug real
  // reportado por el usuario: reasignar el Future y confiar en que
  // FutureBuilder detectara el cambio no refrescaba la lista de forma
  // confiable tras borrar/bloquear). Actualizar estas listas a mano en el
  // momento de cada acción es inmediato y no depende de ningún viaje de
  // red nuevo ni de ninguna sutileza de reconstrucción de widgets.
  List<ReporteDenunciado>? _denunciados;
  List<MascotaExtraviadaModel>? _activos;
  List<UsuarioBloqueado>? _bloqueados;

  @override
  void initState() {
    super.initState();
    _cargarDenunciados();
    _cargarActivos();
    _cargarBloqueados();
  }

  Future<void> _cargarDenunciados() async {
    final datos = await ref
        .read(mascotaExtraviadaRepositoryProvider)
        .obtenerReportesDenunciados();
    if (mounted) {
      setState(() => _denunciados = datos);
    }
  }

  Future<void> _cargarActivos() async {
    final datos = await ref
        .read(mascotaExtraviadaRepositoryProvider)
        .obtenerReportesActivos();
    if (mounted) {
      setState(() => _activos = datos);
    }
  }

  Future<void> _cargarBloqueados() async {
    final datos = await ref
        .read(mascotaExtraviadaRepositoryProvider)
        .obtenerUsuariosBloqueados();
    if (mounted) {
      setState(() => _bloqueados = datos);
    }
  }

  // Borra un reporte desde cualquiera de las dos pestañas de reportes — se
  // saca a mano de las dos listas en memoria, no solo de la que disparó la
  // acción: un reporte denunciado borrado acá también tiene que
  // desaparecer de "Todos", y viceversa.
  //
  // Pasa por mascotaExtraviadaProvider.notifier, no por el repository
  // directo (2026-09-27, otro bug real reportado por el usuario): ese
  // provider es el que alimenta a MapaScreen, con su propia copia en
  // memoria de los reportes activos — borrar solo en la base (como hacía
  // antes) dejaba esa copia vieja, así que el reporte borrado seguía
  // viéndose en el mapa hasta reabrir la app entera. El notifier hace las
  // dos cosas: borra en Supabase y actualiza su propio estado, del que
  // MapaScreen ya escucha con ref.watch.
  Future<void> _eliminar(MascotaExtraviadaModel reporte) async {
    final l10n = AppLocalizations.of(context);
    final confirmar = await confirmarAccion(
      context,
      titulo: l10n.eliminarReporteTitulo,
      contenido: l10n.eliminarReporteContenido,
      textoConfirmar: l10n.accionEliminar,
      destructivo: true,
    );
    if (confirmar != true || !mounted) {
      return;
    }
    await ref.read(mascotaExtraviadaProvider.notifier).eliminarReporte(reporte);
    if (!mounted) {
      return;
    }
    setState(() {
      _denunciados = _denunciados
          ?.where((item) => item.reporte.id != reporte.id)
          .toList();
      _activos = _activos?.where((r) => r.id != reporte.id).toList();
    });
  }

  // Abre el detalle del reporte — se le pasa el reporte ya en mano
  // (reporteInicial) porque mascotaExtraviadaProvider puede no tenerlo
  // (denunciados ya resueltos, o cualquiera visto sin haber pasado antes
  // por MapaScreen en esta sesión) — ver detalleReporteMascotaExtraviadaScreen.md.
  //
  // Espera el resultado del pop (2026-09-27, bug real reportado por el
  // usuario: borrar desde adentro del detalle no refrescaba esta lista al
  // volver) — DetalleReporteMascotaExtraviadaScreen devuelve `true` si borró
  // o marcó como resuelto el reporte (ver ese archivo, punto 7); en ese
  // caso se vuelve a pedir todo a Supabase, más simple y confiable acá que
  // tratar de adivinar qué cambió exactamente para sacarlo a mano de las
  // listas locales (ver punto 1 del doc de esta pantalla).
  Future<void> _abrirDetalle(MascotaExtraviadaModel reporte) async {
    final cambio = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => DetalleReporteMascotaExtraviadaScreen(
          reporteId: reporte.id,
          reporteInicial: reporte,
        ),
      ),
    );
    if (cambio == true && mounted) {
      _cargarDenunciados();
      _cargarActivos();
    }
  }

  // Restringe al autor del reporte de publicar nuevos — el reporte en sí
  // no se borra acá (son dos acciones separadas a propósito: bloquear a
  // alguien no implica necesariamente que este reporte puntual sea el que
  // se quiere borrar, y viceversa).
  Future<void> _bloquear(MascotaExtraviadaModel reporte) async {
    final l10n = AppLocalizations.of(context);
    final confirmar = await confirmarAccion(
      context,
      titulo: l10n.bloquearUsuarioTitulo,
      contenido: l10n.bloquearUsuarioContenido,
      textoConfirmar: l10n.accionBloquear,
      destructivo: true,
    );
    if (confirmar != true || !mounted) {
      return;
    }
    await ref
        .read(mascotaExtraviadaRepositoryProvider)
        .bloquearUsuario(reporte.usuarioId);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.usuarioBloqueadoAviso)));
    setState(() {
      _bloqueados = [
        UsuarioBloqueado(usuarioId: reporte.usuarioId, fecha: DateTime.now()),
        ...?_bloqueados,
      ];
    });
  }

  Future<void> _desbloquear(UsuarioBloqueado item) async {
    final l10n = AppLocalizations.of(context);
    final confirmar = await confirmarAccion(
      context,
      titulo: l10n.desbloquearUsuarioTitulo,
      contenido: l10n.desbloquearUsuarioContenido,
      textoConfirmar: l10n.accionDesbloquear,
    );
    if (confirmar != true || !mounted) {
      return;
    }
    await ref
        .read(mascotaExtraviadaRepositoryProvider)
        .desbloquearUsuario(item.usuarioId);
    if (!mounted) {
      return;
    }
    setState(() {
      _bloqueados = _bloqueados
          ?.where((b) => b.usuarioId != item.usuarioId)
          .toList();
    });
  }

  // Fila compartida entre las pestañas "Denunciados" y "Todos" — mismas dos
  // acciones (bloquear autor / eliminar) en las dos, solo cambia qué texto
  // va de subtítulo (cantidad de denuncias en una, fecha de publicación en
  // la otra).
  Widget _tileReporte(MascotaExtraviadaModel reporte, {required String subtitulo}) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      onTap: () => _abrirDetalle(reporte),
      leading: IconoTipoReporte(tipo: reporte.tipo),
      title: Text(reporte.mascotaNombre ?? l10n.mascotaFallback),
      subtitle: Text(subtitulo),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.block),
            tooltip: l10n.bloquearAutorTooltip,
            onPressed: () => _bloquear(reporte),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _eliminar(reporte),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.moderacionTitulo),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.moderacionTabDenunciados),
              Tab(text: l10n.moderacionTabTodos),
              Tab(text: l10n.moderacionTabBloqueados),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (_denunciados == null)
              const Center(child: CircularProgressIndicator())
            else if (_denunciados!.isEmpty)
              Center(child: Text(l10n.sinReportesDenunciados))
            else
              ListView(
                children: [
                  for (final item in _denunciados!)
                    _tileReporte(
                      item.reporte,
                      subtitulo: l10n.cantidadDenunciasLabel(
                        item.cantidadDenuncias,
                      ),
                    ),
                ],
              ),
            if (_activos == null)
              const Center(child: CircularProgressIndicator())
            else if (_activos!.isEmpty)
              Center(child: Text(l10n.sinReportesActivos))
            else
              ListView(
                children: [
                  for (final reporte in _activos!)
                    _tileReporte(
                      reporte,
                      subtitulo: reporte.fechaPublicacion != null
                          ? fechaHoraCorta(reporte.fechaPublicacion!)
                          : '',
                    ),
                ],
              ),
            if (_bloqueados == null)
              const Center(child: CircularProgressIndicator())
            else if (_bloqueados!.isEmpty)
              Center(child: Text(l10n.sinUsuariosBloqueados))
            else
              ListView(
                children: [
                  for (final item in _bloqueados!)
                    ListTile(
                      leading: const Icon(Icons.person_off_outlined),
                      title: Text(
                        l10n.usuarioBloqueadoIdLabel(
                          item.usuarioId.substring(0, 8),
                        ),
                      ),
                      subtitle: Text(
                        l10n.usuarioBloqueadoFechaLabel(
                          fechaHoraCorta(item.fecha),
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () => _desbloquear(item),
                        child: Text(l10n.accionDesbloquear),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
