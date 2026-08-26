import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/repositories/mascota_extraviada_repository.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/widgets/dialogo_confirmacion.dart';
import 'package:patas_al_dia/presentation/widgets/icono_tipo_reporte.dart';
import 'package:patas_al_dia/providers/mascota_extraviada_provider.dart';

// Pantalla de moderación, solo para el admin (ver AjustesScreen — el ítem
// que lleva acá solo se muestra si usuario.email == correoAdmin, y la
// política RLS denuncias_reportes_leer_admin del lado de Supabase hace
// cumplir lo mismo del lado del servidor). Lista los reportes con al menos
// una denuncia y permite borrarlos — reemplaza el flujo anterior de
// revisar/borrar a mano desde el panel de Supabase (2026-08-25, ver
// decisiones_arquitectura.md). Fetch directo al repository, sin pasar por
// mascotaExtraviadaProvider: esa lista solo trae reportes activos, y un
// reporte denunciado puede ya estar resuelto y de todas formas necesitar
// revisión.
class AdminModeracionScreen extends ConsumerStatefulWidget {
  const AdminModeracionScreen({super.key});

  @override
  ConsumerState<AdminModeracionScreen> createState() =>
      _AdminModeracionScreenState();
}

class _AdminModeracionScreenState
    extends ConsumerState<AdminModeracionScreen> {
  late Future<List<ReporteDenunciado>> _futuroReportes;

  @override
  void initState() {
    super.initState();
    _futuroReportes = _cargar();
  }

  Future<List<ReporteDenunciado>> _cargar() {
    return ref
        .read(mascotaExtraviadaRepositoryProvider)
        .obtenerReportesDenunciados();
  }

  Future<void> _eliminar(ReporteDenunciado item) async {
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
    await ref
        .read(mascotaExtraviadaRepositoryProvider)
        .eliminarReporte(item.reporte);
    if (!mounted) {
      return;
    }
    setState(() => _futuroReportes = _cargar());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moderacionTitulo)),
      body: FutureBuilder<List<ReporteDenunciado>>(
        future: _futuroReportes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final reportes = snapshot.data ?? const <ReporteDenunciado>[];
          if (reportes.isEmpty) {
            return Center(child: Text(l10n.sinReportesDenunciados));
          }
          return ListView(
            children: [
              for (final item in reportes)
                ListTile(
                  leading: IconoTipoReporte(tipo: item.reporte.tipo),
                  title: Text(
                    item.reporte.mascotaNombre ?? l10n.mascotaFallback,
                  ),
                  subtitle: Text(
                    l10n.cantidadDenunciasLabel(item.cantidadDenuncias),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _eliminar(item),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
