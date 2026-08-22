import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:patas_al_dia/data/models/mascota_extraviada_model.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/detalle_reporte_mascota_extraviada_screen.dart';
import 'package:patas_al_dia/presentation/screens/formulario_reporte_mascota_extraviada_screen.dart';
import 'package:patas_al_dia/presentation/utils/etiquetas_localizadas.dart';
import 'package:patas_al_dia/presentation/utils/mapa_tiles.dart';
import 'package:patas_al_dia/presentation/widgets/icono_tipo_reporte.dart';
import 'package:patas_al_dia/presentation/widgets/logo_barra_superior.dart';
import 'package:patas_al_dia/presentation/widgets/menu_usuario_avatar.dart';
import 'package:patas_al_dia/presentation/widgets/tarjeta_clara.dart';
import 'package:patas_al_dia/providers/mascota_extraviada_provider.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

// Marca la opción "otra mascota (no registrada)" dentro del selector de
// mascota — distinta de `null`, que en ese mismo diálogo significa "el
// usuario lo cerró sin elegir nada".
const _mascotaNoRegistrada = Object();

// Centro por defecto del mapa (Santiago) cuando no hay reportes con
// ubicación que centrar — misma zona horaria que ya usa NotificacionService
// como base de la app.
const _centroPorDefecto = LatLng(-33.4489, -70.6693);

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
  bool _cargando = true;
  bool _error = false;
  // Se guarda solo el id, no el objeto — así la burbuja siempre refleja el
  // estado actual del provider (ver punto 10b en mapaScreen.md): si el
  // reporte se borra o se marca resuelto mientras la burbuja está abierta,
  // deja de encontrarse en `reportes` y la burbuja se cierra sola, en vez
  // de seguir mostrando una copia vieja para siempre.
  String? _reporteSeleccionadoId;

  @override
  void initState() {
    super.initState();
    widget.indiceActualNotifier.addListener(_alCambiarPestana);
    // Por si esta pantalla se monta ya con Mapa como pestaña activa (no
    // pasa hoy — la app siempre arranca en Mascotas — pero cubre el caso).
    _alCambiarPestana();
    _cargarReportes();
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

  // Sin ningún paquete de detección de conectividad — reactivo, igual que
  // el resto del módulo Mapa: se intenta cargar y, si falla, se muestra un
  // aviso con reintentar (ver decisiones_arquitectura.md).
  Future<void> _cargarReportes() async {
    setState(() {
      _cargando = true;
      _error = false;
    });
    try {
      await ref
          .read(mascotaExtraviadaProvider.notifier)
          .cargarReportesActivos();
    } catch (_) {
      _error = true;
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
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

  void _abrirDetalle(String reporteId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            DetalleReporteMascotaExtraviadaScreen(reporteId: reporteId),
      ),
    );
  }

  void _irAFormulario({MascotaModel? mascota, required String tipo}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FormularioReporteMascotaExtraviadaScreen(
          mascota: mascota,
          tipo: tipo,
        ),
      ),
    );
  }

  Future<void> _elegirMascotaParaPerdida() async {
    final mascotas = ref.read(mascotasProvider);
    if (mascotas.isEmpty) {
      _irAFormulario(tipo: 'perdido');
      return;
    }
    final l10n = AppLocalizations.of(context);
    final resultado = await showModalBottomSheet<Object?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.eligeMascotaReporteTitulo,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final mascota in mascotas)
              ListTile(
                leading: const Icon(Icons.pets),
                title: Text(mascota.nombre),
                subtitle: Text(especieMostrar(context, mascota)),
                onTap: () => Navigator.of(context).pop(mascota),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.opcionMascotaNoRegistrada),
              onTap: () => Navigator.of(context).pop(_mascotaNoRegistrada),
            ),
          ],
        ),
      ),
    );
    if (resultado == null || !mounted) {
      return;
    }
    _irAFormulario(
      mascota: resultado == _mascotaNoRegistrada
          ? null
          : resultado as MascotaModel,
      tipo: 'perdido',
    );
  }

  void _abrirOpcionesReportar() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: Text(l10n.opcionReportarPerdida),
              onTap: () {
                Navigator.of(context).pop();
                _elegirMascotaParaPerdida();
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets),
              title: Text(l10n.opcionReportarEncontrada),
              onTap: () {
                Navigator.of(context).pop();
                _irAFormulario(tipo: 'encontrado');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reportes = ref.watch(mascotaExtraviadaProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const LogoBarraSuperior(),
        title: Text(l10n.navMapa),
        actions: const [MenuUsuarioAvatar()],
      ),
      body: _construirCuerpo(l10n, reportes),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirOpcionesReportar,
        icon: const Icon(Icons.add),
        label: Text(l10n.accionReportarFab),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _construirCuerpo(
    AppLocalizations l10n,
    List<MascotaExtraviadaModel> reportes,
  ) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.errorCargarReportes, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarReportes,
                child: Text(l10n.accionAplicar),
              ),
            ],
          ),
        ),
      );
    }
    // La ubicación es obligatoria desde el 2026-08-19 (ver
    // decisiones_arquitectura.md) — este filtro es solo una salvaguarda
    // contra reportes de prueba viejos, de antes de ese cambio, que puedan
    // haber quedado sin ubicación en la base.
    final conUbicacion = reportes
        .where((r) => r.ubicacionLat != null && r.ubicacionLng != null)
        .toList();
    MascotaExtraviadaModel? reporteSeleccionado;
    if (_reporteSeleccionadoId != null) {
      for (final r in reportes) {
        if (r.id == _reporteSeleccionadoId) {
          reporteSeleccionado = r;
          break;
        }
      }
    }
    return Stack(
      children: [
        _construirMapa(conUbicacion),
        if (reportes.isEmpty)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: TarjetaClara(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  l10n.sinReportesActivos,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        if (reporteSeleccionado != null)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: TarjetaClara(
              child: ListTile(
                leading: IconoTipoReporte(
                  tipo: reporteSeleccionado.tipo,
                  size: 28,
                ),
                title: Text(
                  reporteSeleccionado.mascotaNombre ?? l10n.mascotaFallback,
                ),
                subtitle: Text(
                  reporteSeleccionado.tipo == 'perdido'
                      ? l10n.tipoPerdidoChip
                      : l10n.tipoEncontradoChip,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      setState(() => _reporteSeleccionadoId = null),
                ),
                onTap: () => _abrirDetalle(reporteSeleccionado!.id),
              ),
            ),
          ),
      ],
    );
  }

  Widget _construirMapa(List<MascotaExtraviadaModel> conUbicacion) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: conUbicacion.isNotEmpty
            ? LatLng(
                conUbicacion.first.ubicacionLat!,
                conUbicacion.first.ubicacionLng!,
              )
            : _centroPorDefecto,
        initialZoom: conUbicacion.isNotEmpty ? 12 : 10,
        // Límites de zoom explícitos — sin esto, flutter_map puede llegar a
        // un estado de cálculo inválido (crashea con "Infinity or NaN
        // toInt") si el zoom se aleja demasiado.
        minZoom: 2,
        maxZoom: 19,
        // Tocar el mapa fuera de cualquier marcador cierra la burbuja
        // (mismo comportamiento que Google Maps/Apple Maps).
        onTap: (_, _) => setState(() => _reporteSeleccionadoId = null),
      ),
      children: [
        TileLayer(
          urlTemplate: urlTilesSegunTema(context),
          userAgentPackageName: 'dev.breakpointx.patasaldia',
          // El límite de zoom de MapOptions no alcanza por sí solo — el
          // cálculo de qué teselas pedir vive acá, en TileLayer, y necesita
          // su propio límite para no terminar en un rango inválido
          // ("Infinity or NaN toInt", bug conocido de flutter_map).
          minZoom: 2,
          maxZoom: 19,
        ),
        atribucionMapa,
        MarkerLayer(
          markers: [
            for (final reporte in conUbicacion)
              Marker(
                point: LatLng(reporte.ubicacionLat!, reporte.ubicacionLng!),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _reporteSeleccionadoId = reporte.id),
                  child: IconoTipoReporte(tipo: reporte.tipo),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
