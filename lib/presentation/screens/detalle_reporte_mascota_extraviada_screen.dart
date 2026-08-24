import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_al_dia/data/models/mascota_extraviada_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/utils/etiquetas_localizadas.dart';
import 'package:patas_al_dia/presentation/utils/mapa_tiles.dart';
import 'package:patas_al_dia/presentation/widgets/dialogo_confirmacion.dart';
import 'package:patas_al_dia/presentation/widgets/icono_tipo_reporte.dart';
import 'package:patas_al_dia/providers/mascota_extraviada_provider.dart';

// Ficha de un reporte de mascota perdida/encontrada, con mapa y acciones (denunciar, resolver, borrar).
class DetalleReporteMascotaExtraviadaScreen extends ConsumerStatefulWidget {
  final String reporteId;

  const DetalleReporteMascotaExtraviadaScreen({
    super.key,
    required this.reporteId,
  });

  @override
  ConsumerState<DetalleReporteMascotaExtraviadaScreen> createState() =>
      _DetalleReporteMascotaExtraviadaScreenState();
}

class _DetalleReporteMascotaExtraviadaScreenState
    extends ConsumerState<DetalleReporteMascotaExtraviadaScreen> {
  // Mismo bloqueo de gestos que MapaScreen, mismo motivo — ver
  // decisiones_arquitectura.md, entrada del 2026-08-24.
  bool _mapaInteractivo = false;
  Timer? _timerMapaListo;

  @override
  void initState() {
    super.initState();
    _timerMapaListo = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _mapaInteractivo = true);
      }
    });
  }

  @override
  void dispose() {
    _timerMapaListo?.cancel();
    super.dispose();
  }

  // Confirma y marca el reporte como denunciado por abuso.
  Future<void> _denunciar(MascotaExtraviadaModel reporte) async {
    final l10n = AppLocalizations.of(context);
    final confirmar = await confirmarAccion(
      context,
      titulo: l10n.confirmarDenunciaTitulo,
      contenido: l10n.confirmarDenunciaContenido,
      textoConfirmar: l10n.denunciarReporteLabel,
    );
    if (confirmar != true || !mounted) {
      return;
    }
    await ref
        .read(mascotaExtraviadaProvider.notifier)
        .denunciarReporte(reporte.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.denunciaEnviadaAviso)));
  }

  // Confirma y marca el reporte como resuelto (mascota encontrada/entregada).
  Future<void> _marcarComoResuelto(MascotaExtraviadaModel reporte) async {
    final l10n = AppLocalizations.of(context);
    final confirmar = await confirmarAccion(
      context,
      titulo: l10n.confirmarResueltoTitulo,
      contenido: l10n.confirmarResueltoContenido,
      textoConfirmar: l10n.marcarComoResueltoLabel,
    );
    if (confirmar != true || !mounted) {
      return;
    }
    await ref
        .read(mascotaExtraviadaProvider.notifier)
        .marcarComoResuelto(reporte);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Confirma y borra el reporte (borrado real, incluida la foto en Storage).
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
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reportes = ref.watch(mascotaExtraviadaProvider);
    MascotaExtraviadaModel? reporte;
    for (final r in reportes) {
      if (r.id == widget.reporteId) {
        reporte = r;
        break;
      }
    }
    if (reporte == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // No fuerza una sesión de Supabase solo por ver el detalle — si el
    // usuario nunca publicó nada, `currentSession` es null y, en ese caso,
    // el reporte simplemente no puede ser suyo.
    final usuarioActualId =
        Supabase.instance.client.auth.currentSession?.user.id;
    final esMio =
        usuarioActualId != null && usuarioActualId == reporte.usuarioId;
    // isFinite + rango real (2026-08-24, mismo motivo que en MapaScreen):
    // una coordenada inválida hace que flutter_map truene con "Infinity or
    // NaN toInt" al calcular los tiles del mini-mapa.
    final conUbicacion =
        reporte.ubicacionLat != null &&
        reporte.ubicacionLng != null &&
        reporte.ubicacionLat!.isFinite &&
        reporte.ubicacionLng!.isFinite &&
        reporte.ubicacionLat! >= -90 &&
        reporte.ubicacionLat! <= 90 &&
        reporte.ubicacionLng! >= -180 &&
        reporte.ubicacionLng! <= 180;

    return Scaffold(
      appBar: AppBar(
        title: Text(reporte.mascotaNombre ?? l10n.mascotaFallback),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // La foto es obligatoria desde 2026-08-19 (ver decisiones_arquitectura.md),
          // pero un reporte de prueba anterior a esa fecha puede no tenerla —
          // el null-check acá es solo esa red de seguridad, no una feature.
          if (reporte.mascotaFotoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                reporte.mascotaFotoUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (reporte.mascotaFotoUrl != null) const SizedBox(height: 16),
          Chip(
            avatar: IconoTipoReporte(tipo: reporte.tipo, size: 22),
            label: Text(
              reporte.tipo == 'perdido'
                  ? l10n.tipoPerdidoChip
                  : l10n.tipoEncontradoChip,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.campoEspecie),
            subtitle: Text(especieValorMostrar(l10n, reporte.mascotaEspecie)),
          ),
          if (reporte.tipo == 'perdido' && reporte.recompensa > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.recompensaLabel),
              subtitle: Text(reporte.recompensa.toString()),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.contactoLabel),
            subtitle: Text(reporte.contactoEmergencia),
          ),
          if (reporte.descripcion != null && reporte.descripcion!.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.campoDescripcionObligatoria),
              subtitle: Text(reporte.descripcion!),
            ),
          if (reporte.fechaPublicacion != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.fechaPublicacionLabel),
              subtitle: Text(
                '${reporte.fechaPublicacion!.day}/'
                '${reporte.fechaPublicacion!.month}/'
                '${reporte.fechaPublicacion!.year}',
              ),
            ),
          const SizedBox(height: 16),
          Text(
            l10n.campoUbicacion,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (reporte.ciudad != null || reporte.pais != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  reporte.comuna,
                  reporte.ciudad,
                  reporte.pais,
                ].where((s) => s != null && s.isNotEmpty).join(', '),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 8),
          if (conUbicacion)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: IgnorePointer(
                  ignoring: !_mapaInteractivo,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        reporte.ubicacionLat!,
                        reporte.ubicacionLng!,
                      ),
                      initialZoom: 15,
                      minZoom: 2,
                      maxZoom: 19,
                      // Sin zoom por gesto ni inercia — mismo motivo que en
                      // MapaScreen (ver decisiones_arquitectura.md). Es solo
                      // una vista previa chica, no necesita botones de zoom.
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: urlTilesSegunTema(context),
                        userAgentPackageName: 'patas_al_dia.app',
                        minZoom: 2,
                        maxZoom: 19,
                      ),
                      atribucionMapa,
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              reporte.ubicacionLat!,
                              reporte.ubicacionLng!,
                            ),
                            child: IconoTipoReporte(tipo: reporte.tipo),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Text(l10n.sinUbicacionLabel),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => _denunciar(reporte!),
            icon: const Icon(Icons.flag_outlined),
            label: Text(l10n.denunciarReporteLabel),
          ),
          if (esMio) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _marcarComoResuelto(reporte!),
              child: Text(l10n.marcarComoResueltoLabel),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                l10n.eliminarReporteTitulo,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () => _eliminar(reporte!),
            ),
          ],
        ],
      ),
    );
  }
}
