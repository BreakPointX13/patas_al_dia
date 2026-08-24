import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_al_dia/data/models/mascota_extraviada_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/detalle_reporte_mascota_extraviada_screen.dart';
import 'package:patas_al_dia/presentation/widgets/icono_tipo_reporte.dart';
import 'package:patas_al_dia/providers/mascota_extraviada_provider.dart';

// Lista de los reportes activos publicados por el usuario actual — reusa el
// mismo estado que ya carga MapaScreen (todos los reportes activos), sin
// pedir nada nuevo a Supabase; solo filtra por dueño. Un reporte resuelto ya
// no está aquí (mismo criterio que en el mapa): si fue un error, se vuelve a
// publicar, no hay forma de "reactivarlo".
class MisReportesScreen extends ConsumerWidget {
  const MisReportesScreen({super.key});

  void _abrirDetalle(BuildContext context, String reporteId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            DetalleReporteMascotaExtraviadaScreen(reporteId: reporteId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reportes = ref.watch(mascotaExtraviadaProvider);
    // Mismo criterio que "esMio" en DetalleReporteMascotaExtraviadaScreen —
    // un invitado que nunca publicó nada no tiene sesión de Supabase todavía.
    final usuarioActualId =
        Supabase.instance.client.auth.currentSession?.user.id;
    final misReportes = usuarioActualId == null
        ? const <MascotaExtraviadaModel>[]
        : reportes.where((r) => r.usuarioId == usuarioActualId).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.misReportesTitulo)),
      body: misReportes.isEmpty
          ? Center(child: Text(l10n.sinMisReportesActivos))
          : ListView(
              children: [
                for (final reporte in misReportes)
                  ListTile(
                    leading: IconoTipoReporte(tipo: reporte.tipo),
                    title: Text(reporte.mascotaNombre ?? l10n.mascotaFallback),
                    subtitle: Text(
                      reporte.tipo == 'perdido'
                          ? l10n.tipoPerdidoChip
                          : l10n.tipoEncontradoChip,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrirDetalle(context, reporte.id),
                  ),
              ],
            ),
    );
  }
}
