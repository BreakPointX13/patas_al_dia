import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:patas_al_dia/data/models/mascota_extraviada_model.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/formulario_mascota_screen.dart'
    show especiesDisponibles;
import 'package:patas_al_dia/presentation/utils/etiquetas_localizadas.dart';
import 'package:patas_al_dia/presentation/utils/selector_imagen.dart';
import 'package:patas_al_dia/presentation/widgets/tarjeta_clara.dart';
import 'package:patas_al_dia/providers/mascota_extraviada_provider.dart';

// Formulario para publicar un reporte de mascota perdida o encontrada.
class FormularioReporteMascotaExtraviadaScreen extends ConsumerStatefulWidget {
  // Si viene una mascota registrada, su nombre/especie quedan fijos (no
  // editables) — cubre el flujo "mascota mía, ya cargada en la app". Si
  // viene null, el usuario tipea nombre/especie a mano — cubre tanto
  // "mascota mía, no la cargué" (tipo 'perdido') como "encontré una
  // mascota que no es mía" (tipo 'encontrado').
  final MascotaModel? mascota;
  final String tipo;

  const FormularioReporteMascotaExtraviadaScreen({
    super.key,
    this.mascota,
    required this.tipo,
  });

  @override
  ConsumerState<FormularioReporteMascotaExtraviadaScreen> createState() =>
      _FormularioReporteMascotaExtraviadaScreenState();
}

class _FormularioReporteMascotaExtraviadaScreenState
    extends ConsumerState<FormularioReporteMascotaExtraviadaScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final _nombreController = TextEditingController();
  final _especiePersonalizadaController = TextEditingController();
  final _paisController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _comunaController = TextEditingController();
  final _direccionController = TextEditingController();
  final _recompensaController = TextEditingController();
  final _contactoController = TextEditingController();
  final _descripcionController = TextEditingController();

  String _especie = especiesDisponibles.first;
  // Foto obligatoria (decisión del usuario, 2026-08-19), y siempre se pide
  // una foto nueva acá aunque la mascota ya tenga una foto guardada — no se
  // reutiliza `mascota.fotoUrl` (decisión del usuario: la foto del reporte
  // debe reflejar cómo se ve/estaba la mascota justo antes de perderse o al
  // encontrarla, no la foto de perfil que puede ser vieja).
  String? _fotoPath;
  bool _usarUbicacionActual = true;
  double? _ubicacionLat;
  double? _ubicacionLng;
  bool _obteniendoUbicacion = false;
  bool _tieneRecompensa = false;
  bool _guardando = false;

  // Dirección manual: se busca y se elige de una lista (no autocompletado
  // en vivo — Nominatim prohíbe una consulta por cada tecla). El texto
  // exacto de la sugerencia elegida, para saber si lo que hay en el campo
  // sigue siendo esa selección o si el usuario volvió a escribir encima.
  List<Map<String, dynamic>> _sugerenciasDireccion = [];
  bool _buscandoDireccion = false;
  String? _direccionConfirmada;

  bool get _mascotaRegistrada => widget.mascota != null;
  bool get _esPerdido => widget.tipo == 'perdido';

  @override
  void initState() {
    super.initState();
    // El switch de ubicación ya arranca en modo GPS por defecto — pedirle
    // además al usuario que toque "Obtener ubicación" era un segundo paso
    // de más para el camino más común. Se dispara solo, apenas se abre la
    // pantalla, con el mismo patrón que el resto de los "hacer algo apenas
    // termina el primer build" del proyecto.
    if (_usarUbicacionActual) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _obtenerUbicacion());
    }
    // Si el usuario vuelve a escribir sobre una dirección ya confirmada, esa
    // selección queda obsoleta — se limpia para forzar una nueva búsqueda
    // antes de poder publicar (evita guardar una ubicación que ya no
    // corresponde al texto que se ve en el campo).
    _direccionController.addListener(() {
      if (_direccionConfirmada != null &&
          _direccionController.text != _direccionConfirmada) {
        setState(() {
          _direccionConfirmada = null;
          _ubicacionLat = null;
          _ubicacionLng = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _especiePersonalizadaController.dispose();
    _paisController.dispose();
    _ciudadController.dispose();
    _comunaController.dispose();
    _direccionController.dispose();
    _recompensaController.dispose();
    _contactoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  // Abre la hoja inferior para elegir la foto del reporte.
  Future<void> _elegirFoto() async {
    final l10n = AppLocalizations.of(context);
    final opcion = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l10n.tomarFoto),
              onTap: () => Navigator.of(context).pop('camara'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.elegirImagenGaleria),
              onTap: () => Navigator.of(context).pop('galeria'),
            ),
          ],
        ),
      ),
    );

    if (opcion == null || !mounted) {
      return;
    }

    // maxWidth/imageQuality (2026-08-20, ver decisiones_arquitectura.md): sin
    // esto, la foto se subía a Storage tal cual la entrega la cámara — 3 a
    // 8 MB en un teléfono moderno. Es la única foto de todo el proyecto que
    // va a la nube (las de mascotas/documentos quedan solo en el
    // dispositivo), así que es la única que vale la pena comprimir por
    // costo de almacenamiento. 1600px/75% de calidad no se nota a simple
    // vista y baja el peso típico a unos cientos de KB.
    final imagen = await elegirImagenConPermiso(
      context,
      _picker,
      source: opcion == 'camara' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (imagen == null) {
      return;
    }
    setState(() => _fotoPath = imagen.path);
  }

  // Pide permiso de GPS y guarda la ubicación actual del dispositivo.
  Future<void> _obtenerUbicacion() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _obteniendoUbicacion = true);
    try {
      final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        throw l10n.errorServicioUbicacionDeshabilitado;
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          throw l10n.errorPermisoUbicacionDenegado;
        }
      }
      if (permiso == LocationPermission.deniedForever) {
        throw l10n.errorPermisoUbicacionPermanente;
      }
      final posicion = await Geolocator.getCurrentPosition();
      if (!mounted) {
        return;
      }
      setState(() {
        _ubicacionLat = posicion.latitude;
        _ubicacionLng = posicion.longitude;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      final mensaje = e is String ? e : l10n.errorObtenerUbicacion;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } finally {
      if (mounted) {
        setState(() => _obteniendoUbicacion = false);
      }
    }
  }

  // Busca la dirección tipeada en Nominatim (geocodificación de OpenStreetMap
  // — gratis, sin API key, mismo ecosistema que flutter_map) y muestra hasta
  // 5 resultados para que el usuario elija el correcto — una sola consulta
  // por búsqueda explícita, nunca por tecla (Nominatim prohíbe
  // autocompletado en vivo contra su servicio público).
  //
  // País/ciudad van en la consulta (2026-08-24) — sin ellos, una calle común
  // puede resolver a otro país por error (caso real: "Alameda 1200" trajo
  // una calle de Estados Unidos en vez de la de Santiago). Comuna es
  // opcional, se suma si está. No se restringe la BÚSQUEDA por país vía
  // parámetro (`countrycodes`) — el propio texto de país/ciudad ya acota lo
  // suficiente, y así sigue funcionando para un usuario fuera de Chile.
  Future<void> _buscarDireccion() async {
    final l10n = AppLocalizations.of(context);
    final direccionLibre = _direccionController.text.trim();
    if (direccionLibre.isEmpty) {
      return;
    }
    final consulta = [
      direccionLibre,
      _comunaController.text.trim(),
      _ciudadController.text.trim(),
      _paisController.text.trim(),
    ].where((s) => s.isNotEmpty).join(', ');
    setState(() {
      _buscandoDireccion = true;
      _sugerenciasDireccion = [];
    });
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': consulta,
      'format': 'json',
      'limit': '5',
    });
    try {
      final respuesta = await http.get(
        uri,
        headers: {'User-Agent': 'PatasAlDia-App/1.0'},
      );
      final resultados = (jsonDecode(respuesta.body) as List)
          .cast<Map<String, dynamic>>();
      if (!mounted) {
        return;
      }
      if (resultados.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeocodificacion)));
      }
      setState(() => _sugerenciasDireccion = resultados);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeocodificacion)));
      }
    } finally {
      if (mounted) {
        setState(() => _buscandoDireccion = false);
      }
    }
  }

  // Confirma una de las sugerencias como la ubicación del reporte. El orden
  // importa: `_direccionConfirmada` se fija ANTES de tocar el controller,
  // para que el listener de dispose() (que limpia la selección si el texto
  // cambia) no se dispare en falso por el propio cambio de texto de acá.
  void _seleccionarDireccion(Map<String, dynamic> resultado) {
    final displayName = resultado['display_name'] as String;
    setState(() {
      _ubicacionLat = double.parse(resultado['lat'] as String);
      _ubicacionLng = double.parse(resultado['lon'] as String);
      _direccionConfirmada = displayName;
      _direccionController.text = displayName;
      _sugerenciasDireccion = [];
    });
  }

  // Valida el formulario, sube la foto y guarda el reporte en Supabase.
  Future<void> _publicarReporte() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);

    if (_fotoPath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorFotoObligatoria)));
      return;
    }

    setState(() => _guardando = true);

    // Ubicación obligatoria (decisión del usuario, 2026-08-19): sin esto un
    // reporte no aparece en el mapa, que es el propósito central del
    // módulo. No se valida antes vía el Form porque depende del resultado
    // de una operación async (GPS o geocodificación), no de un campo de
    // texto simple.
    if (_ubicacionLat == null || _ubicacionLng == null) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorUbicacionObligatoria)));
      }
      return;
    }

    // Se guarda el valor canónico (español, o el texto libre de "Otro"), no
    // la versión traducida al idioma actual — el reporte lo puede ver
    // cualquier usuario, con cualquier idioma. Mismo criterio que el resto
    // de los valores guardados de la app (ver sistemaIdiomas.md, punto 3).
    final String? nombreFinal;
    final String? especieFinal;
    final String? mascotaIdFinal;
    if (_mascotaRegistrada) {
      final mascota = widget.mascota!;
      nombreFinal = mascota.nombre;
      especieFinal = mascota.especie == 'Otro'
          ? (mascota.especiePersonalizada ?? mascota.especie)
          : mascota.especie;
      mascotaIdFinal = mascota.id;
    } else {
      nombreFinal = _nombreController.text.trim().isEmpty
          ? null
          : _nombreController.text.trim();
      especieFinal = _especie == 'Otro'
          ? _especiePersonalizadaController.text.trim()
          : _especie;
      mascotaIdFinal = null;
    }

    try {
      final repo = ref.read(mascotaExtraviadaRepositoryProvider);
      final usuarioIdSupabase = await repo.obtenerUsuarioIdSupabase();
      final reporteId = const Uuid().v4();
      final fotoUrl = await repo.subirFoto(
        usuarioId: usuarioIdSupabase,
        reporteId: reporteId,
        rutaLocal: _fotoPath!,
      );
      if (!mounted) {
        return;
      }

      final reporte = MascotaExtraviadaModel(
        id: reporteId,
        usuarioId: usuarioIdSupabase,
        mascotaId: mascotaIdFinal,
        mascotaNombre: nombreFinal,
        mascotaEspecie: especieFinal,
        mascotaFotoUrl: fotoUrl,
        ubicacionLat: _ubicacionLat,
        ubicacionLng: _ubicacionLng,
        // Solo con dirección manual — con GPS no hay estos datos.
        pais: _usarUbicacionActual ? null : _paisController.text.trim(),
        ciudad: _usarUbicacionActual ? null : _ciudadController.text.trim(),
        comuna: _usarUbicacionActual || _comunaController.text.trim().isEmpty
            ? null
            : _comunaController.text.trim(),
        recompensa: _esPerdido && _tieneRecompensa
            ? double.parse(_recompensaController.text.trim())
            : 0,
        tipo: widget.tipo,
        contactoEmergencia: _contactoController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        fechaPublicacion: DateTime.now(),
      );

      await ref
          .read(mascotaExtraviadaProvider.notifier)
          .publicarReporte(reporte);

      if (!mounted) {
        return;
      }
      // Diálogo, no SnackBar: se cierra esta pantalla enseguida después de
      // esto y un SnackBar quedaría anclado a ella, sin llegar a verse
      // (mismo motivo que en nueva_contrasena_screen.dart).
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(l10n.reporteAgradecimientoAviso),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.avisoMapaEntendido),
            ),
          ],
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      // Falla al crear/usar la sesión anónima de Supabase (ver
      // obtenerUsuarioIdSupabase) — nada que ver con la conexión del
      // dispositivo, así que usa un mensaje propio en vez del genérico
      // "revisa tu conexión". Encontrado en producción: se debía a que
      // "Anonymous Sign-ins" había quedado deshabilitado en el proyecto de
      // Supabase (código anonymous_provider_disabled).
      debugPrint(
        'DEBUG publicarReporte AuthException: code=${e is AuthApiException ? e.statusCode : '?'} message=${e.message}',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorAutenticacionReporte)));
    } on StorageException catch (e) {
      debugPrint(
        'DEBUG publicarReporte StorageException: statusCode=${e.statusCode} message=${e.message}',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorSubirFoto)));
    } on PostgrestException catch (e) {
      // TEMPORAL — diagnóstico del bug "sale error de conexión aunque sí
      // hay conexión" (2026-08-19): imprime el error real en el log para
      // ver qué está pasando de verdad, en vez de asumir a ciegas.
      debugPrint(
        'DEBUG publicarReporte PostgrestException: code=${e.code} message=${e.message} details=${e.details}',
      );
      if (!mounted) {
        return;
      }
      // P0001 es el código por defecto de un `raise exception` propio en
      // Postgres — acá es el trigger de límite de reportes activos (ver
      // TablaMaestraAppVetMovil1.sql). El mensaje que devuelve la base está
      // fijo en español (no puede usar AppLocalizations), así que se
      // reemplaza por uno propio ya traducido en vez de mostrar el texto
      // crudo de Postgres.
      final mensaje = e.code == 'P0001'
          ? l10n.errorLimiteReportesActivos
          : l10n.errorPublicarReporte;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (e) {
      // TEMPORAL — mismo diagnóstico, para cualquier error que no sea
      // PostgrestException (ej. fallo al crear la sesión anónima).
      debugPrint('DEBUG publicarReporte error genérico: $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorPublicarReporte)));
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _esPerdido
              ? l10n.reportarMascotaPerdidaLabel
              : l10n.reportarMascotaEncontradaLabel,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _elegirFoto,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: _fotoPath != null
                          ? FileImage(File(_fotoPath!))
                          : null,
                      child: _fotoPath == null
                          ? const Icon(Icons.pets, size: 48)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fotoPath == null
                          ? l10n.campoFotoObligatoria
                          : l10n.fotoCambiar,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_mascotaRegistrada)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.pets),
                title: Text(widget.mascota!.nombre),
                subtitle: Text(especieMostrar(context, widget.mascota!)),
              )
            else ...[
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: _esPerdido
                      ? l10n.campoNombreObligatorio
                      : l10n.campoNombreMascotaOpcional,
                ),
                validator: (valor) {
                  if (_esPerdido && (valor == null || valor.trim().isEmpty)) {
                    return l10n.errorNombreObligatorio;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _especie,
                decoration: InputDecoration(labelText: l10n.campoEspecie),
                items: especiesDisponibles
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(especieValorMostrar(l10n, e)),
                      ),
                    )
                    .toList(),
                onChanged: (valor) => setState(
                  () => _especie = valor ?? especiesDisponibles.first,
                ),
              ),
              if (_especie == 'Otro') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _especiePersonalizadaController,
                  decoration: InputDecoration(
                    labelText: l10n.campoEspecificaEspecie,
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return l10n.errorNombreObligatorio;
                    }
                    return null;
                  },
                ),
              ],
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.usarUbicacionActualSwitch),
              value: _usarUbicacionActual,
              onChanged: (valor) {
                setState(() => _usarUbicacionActual = valor);
                // Mismo criterio que initState(): activar el switch no
                // debería exigir un segundo toque aparte en "Obtener
                // ubicación" — solo se salta si ya se tiene una ubicación
                // cargada de antes (ej. el usuario lo prendió, apagó y
                // volvió a prender sin cambiar de posición).
                if (valor && _ubicacionLat == null) {
                  _obtenerUbicacion();
                }
              },
            ),
            if (_usarUbicacionActual)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _ubicacionLat != null
                      ? Icons.check_circle
                      : Icons.location_on_outlined,
                  color: _ubicacionLat != null ? Colors.green : null,
                ),
                title: Text(
                  _ubicacionLat != null
                      ? l10n.ubicacionObtenidaLabel
                      : l10n.sinUbicacionLabel,
                ),
                trailing: _obteniendoUbicacion
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _obtenerUbicacion,
                        child: Text(l10n.obtenerUbicacionActual),
                      ),
              )
            else ...[
              TextFormField(
                controller: _paisController,
                decoration: InputDecoration(labelText: l10n.campoPais),
                validator: (valor) {
                  if (!_usarUbicacionActual &&
                      (valor == null || valor.trim().isEmpty)) {
                    return l10n.errorPaisObligatorio;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ciudadController,
                decoration: InputDecoration(labelText: l10n.campoCiudad),
                validator: (valor) {
                  if (!_usarUbicacionActual &&
                      (valor == null || valor.trim().isEmpty)) {
                    return l10n.errorCiudadObligatoria;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _comunaController,
                decoration: InputDecoration(
                  labelText: l10n.campoComunaOpcional,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                  labelText: l10n.campoDireccion,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: Text(l10n.ayudaDireccionEstimada),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(l10n.avisoMapaEntendido),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                onFieldSubmitted: (_) => _buscarDireccion(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _direccionConfirmada != null
                      ? Icons.check_circle
                      : Icons.location_on_outlined,
                  color: _direccionConfirmada != null ? Colors.green : null,
                ),
                title: Text(_direccionConfirmada ?? l10n.sinUbicacionLabel),
                trailing: _buscandoDireccion
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _buscarDireccion,
                        child: Text(l10n.buscarDireccionBoton),
                      ),
              ),
              if (_sugerenciasDireccion.isNotEmpty)
                TarjetaClara(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final resultado in _sugerenciasDireccion)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(resultado['display_name'] as String),
                          onTap: () => _seleccionarDireccion(resultado),
                        ),
                    ],
                  ),
                ),
            ],
            if (_esPerdido) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.campoRecompensaSwitch),
                value: _tieneRecompensa,
                onChanged: (valor) => setState(() => _tieneRecompensa = valor),
              ),
              if (_tieneRecompensa)
                TextFormField(
                  controller: _recompensaController,
                  decoration: InputDecoration(
                    labelText: l10n.campoRecompensaMonto,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (valor) {
                    if (!_tieneRecompensa) {
                      return null;
                    }
                    if (valor == null ||
                        valor.trim().isEmpty ||
                        double.tryParse(valor.trim()) == null) {
                      return l10n.errorRecompensaInvalida;
                    }
                    return null;
                  },
                ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactoController,
              decoration: InputDecoration(
                labelText: l10n.campoContactoEmergenciaObligatorio,
                helperText: l10n.avisoContactoEmergencia,
                helperMaxLines: 2,
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return l10n.errorContactoEmergenciaObligatorio;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: l10n.campoDescripcionObligatoria,
              ),
              maxLines: 3,
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return l10n.errorDescripcionObligatoria;
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _guardando ? null : _publicarReporte,
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.accionGuardar),
            ),
          ],
        ),
      ),
    );
  }
}
