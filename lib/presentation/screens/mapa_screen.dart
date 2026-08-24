import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:patas_al_dia/data/models/mascota_extraviada_model.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/detalle_reporte_mascota_extraviada_screen.dart';
import 'package:patas_al_dia/presentation/screens/formulario_reporte_mascota_extraviada_screen.dart';
import 'package:patas_al_dia/presentation/screens/mis_reportes_screen.dart';
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

// Pestaña Mapa: muestra los reportes activos de mascotas perdidas/encontradas.
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

  // Controller propio y persistente (2026-08-24) — sin esto, cada vez que
  // cambia `reportes` (agregar/borrar un reporte) `_construirMapa` arma un
  // `FlutterMap` nuevo sin controller explícito, y `flutter_map` recomienda
  // justamente lo contrario cuando el árbol de widgets puede reconstruirse
  // seguido: se sospecha que esto estaba detrás de un crash real
  // ("Infinity or NaN toInt" + Out of Memory) al crear/borrar varios
  // reportes seguidos durante testing — ver decisiones_arquitectura.md.
  final _mapController = MapController();

  // Bloqueo de gestos apenas se (re)dibuja el mapa (2026-08-24) — la causa
  // real del crash de "Infinity or NaN toInt" (ver decisiones_arquitectura.md):
  // flutter_map usa un tamaño de cámara "imposible" como valor de arranque
  // hasta que su propio LayoutBuilder recibe las medidas reales del layout,
  // y si un gesto llega justo en esa ventana, dispara el cálculo roto. Medio
  // segundo de gestos bloqueados (imperceptible, nadie gesticula apenas se
  // termina de dibujar la pantalla) es más que suficiente para que ese
  // layout real ya esté listo, y evita el problema de raíz en vez de
  // reaccionar después de que ya pasó.
  bool _mapaInteractivo = false;
  Timer? _timerMapaListo;

  void _reiniciarVentanaDeLayout() {
    _timerMapaListo?.cancel();
    if (_mapaInteractivo) {
      setState(() => _mapaInteractivo = false);
    }
    _timerMapaListo = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _mapaInteractivo = true);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    widget.indiceActualNotifier.addListener(_alCambiarPestana);
    // Por si esta pantalla se monta ya con Mapa como pestaña activa (no
    // pasa hoy — la app siempre arranca en Mascotas — pero cubre el caso).
    _alCambiarPestana();
    _cargarReportes();
    _reiniciarVentanaDeLayout();
  }

  @override
  void dispose() {
    widget.indiceActualNotifier.removeListener(_alCambiarPestana);
    _mapController.dispose();
    _timerMapaListo?.cancel();
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

  // Abre el detalle de un reporte.
  void _abrirDetalle(String reporteId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            DetalleReporteMascotaExtraviadaScreen(reporteId: reporteId),
      ),
    );
  }

  // Abre el formulario de reporte, ya sea con una mascota o sin ella.
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

  // Pide elegir cuál mascota registrada se perdió (o "no registrada").
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

  // Hoja inferior: elegir entre reportar mascota perdida o encontrada.
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
    // Crear/borrar un reporte reconstruye el mapa — reinicia la ventana de
    // bloqueo de gestos, mismo motivo que en initState().
    ref.listen(mascotaExtraviadaProvider, (previo, actual) {
      if (previo?.length != actual.length) {
        _reiniciarVentanaDeLayout();
      }
    });

    MascotaExtraviadaModel? reporteSeleccionado;
    if (_reporteSeleccionadoId != null) {
      for (final r in reportes) {
        if (r.id == _reporteSeleccionadoId) {
          reporteSeleccionado = r;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: const LogoBarraSuperior(),
        title: Text(l10n.navMapa),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: l10n.misReportesTitulo,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MisReportesScreen(),
              ),
            ),
          ),
          const MenuUsuarioAvatar(),
        ],
      ),
      body: _construirCuerpo(l10n, reportes, reporteSeleccionado),
      // Oculto mientras hay un reporte seleccionado — la tarjeta de abajo
      // ocupa casi todo el ancho, y el FAB centrado quedaba encima de ella
      // sin importar cuánto margen se le diera (ver decisiones_arquitectura.md,
      // entrada del 2026-08-24). La tarjeta ya tiene su propia "X" para cerrar.
      floatingActionButton: reporteSeleccionado == null
          ? FloatingActionButton.extended(
              onPressed: _abrirOpcionesReportar,
              icon: const Icon(Icons.add),
              label: Text(l10n.accionReportarFab),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _construirCuerpo(
    AppLocalizations l10n,
    List<MascotaExtraviadaModel> reportes,
    MascotaExtraviadaModel? reporteSeleccionado,
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
    // haber quedado sin ubicación en la base. `isFinite` + rango real
    // (2026-08-24): una coordenada NaN/Infinity o fuera de rango hace que
    // flutter_map truene con "Infinity or NaN toInt" al calcular en qué
    // tiles dibujar el marcador — mejor no llegar a pasársela nunca.
    final conUbicacion = reportes.where((r) {
      final lat = r.ubicacionLat;
      final lng = r.ubicacionLng;
      return lat != null &&
          lng != null &&
          lat.isFinite &&
          lng.isFinite &&
          lat >= -90 &&
          lat <= 90 &&
          lng >= -180 &&
          lng <= 180;
    }).toList();
    return Stack(
      children: [
        IgnorePointer(
          ignoring: !_mapaInteractivo,
          child: _construirMapa(conUbicacion),
        ),
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
                onTap: () => _abrirDetalle(reporteSeleccionado.id),
              ),
            ),
          ),
        // Zoom por botones, no por gesto (2026-08-24) — se sacó el pellizco
        // y el doble-tap del mapa por el crash de flutter_map documentado
        // en decisiones_arquitectura.md; arrastrar para moverse por el mapa
        // sigue funcionando normal, solo el zoom pasó a ser explícito.
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'mapaZoomMas',
                onPressed: () => _acercarZoom(1),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'mapaZoomMenos',
                onPressed: () => _acercarZoom(-1),
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Suma o resta un nivel de zoom, sin pasarse de los límites del mapa.
  void _acercarZoom(int delta) {
    final camera = _mapController.camera;
    final nuevoZoom = (camera.zoom + delta).clamp(2.0, 19.0);
    _mapController.move(camera.center, nuevoZoom);
  }

  Widget _construirMapa(List<MascotaExtraviadaModel> conUbicacion) {
    return FlutterMap(
      mapController: _mapController,
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
        // Todo el zoom por gesto desactivado (2026-08-24) — pellizco y
        // doble-tap dispararon el mismo crash real de flutter_map ("Infinity
        // or NaN toInt", ver decisiones_arquitectura.md), cada uno en una
        // prueba distinta. Arrastrar (mover el mapa) sigue funcionando
        // normal; el zoom pasó a los botones +/- de la esquina.
        // flingAnimation (la inercia al soltar el dedo después de un
        // arrastre rápido) también se sacó — un cuarto intento del mismo
        // crash pasó justo moviéndose rápido por el mapa, y esa inercia
        // genera muchas actualizaciones de cámara seguidas por sí sola,
        // parecido al pellizco. El mapa ahora se frena en seco al soltar,
        // sin inercia — arrastrar en sí sigue igual.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag,
        ),
        // Tocar el mapa fuera de cualquier marcador cierra la burbuja
        // (mismo comportamiento que Google Maps/Apple Maps).
        onTap: (_, _) => setState(() => _reporteSeleccionadoId = null),
      ),
      children: [
        TileLayer(
          urlTemplate: urlTilesSegunTema(context),
          userAgentPackageName: 'patas_al_dia.app',
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
