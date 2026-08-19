import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:patas_al_dia/data/models/mascota_extraviada_model.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/utils/etiquetas_localizadas.dart';
import 'package:patas_al_dia/providers/mascota_extraviada_provider.dart';

class FormularioReporteMascotaExtraviadaScreen extends ConsumerStatefulWidget {
  final MascotaModel mascota;

  const FormularioReporteMascotaExtraviadaScreen({
    super.key,
    required this.mascota,
  });

  @override
  ConsumerState<FormularioReporteMascotaExtraviadaScreen> createState() =>
      _FormularioReporteMascotaExtraviadaScreenState();
}

class _FormularioReporteMascotaExtraviadaScreenState
    extends ConsumerState<FormularioReporteMascotaExtraviadaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _calleController = TextEditingController();
  final _numeroController = TextEditingController();
  final _recompensaController = TextEditingController();
  final _contactoController = TextEditingController();
  final _descripcionController = TextEditingController();

  bool _usarUbicacionActual = true;
  double? _ubicacionLat;
  double? _ubicacionLng;
  bool _obteniendoUbicacion = false;
  bool _tieneRecompensa = false;
  bool _guardando = false;

  @override
  void dispose() {
    _calleController.dispose();
    _numeroController.dispose();
    _recompensaController.dispose();
    _contactoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

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

  // Convierte "Calle + Número" en coordenadas vía Nominatim (el servicio de
  // geocodificación de OpenStreetMap) — gratis, sin API key, mismo
  // ecosistema que flutter_map. No se restringe a ningún país en la
  // consulta: mismo criterio que el resto de los campos de la app (RUT,
  // número de chip), pensado para no cerrarle la puerta a un usuario fuera
  // de Chile. Si no encuentra la dirección, el reporte igual se publica —
  // la ubicación es opcional en toda esta pantalla.
  Future<void> _geocodificarDireccion() async {
    final l10n = AppLocalizations.of(context);
    final calle = _calleController.text.trim();
    final numero = _numeroController.text.trim();
    if (calle.isEmpty && numero.isEmpty) {
      return;
    }
    final direccion = [calle, numero].where((s) => s.isNotEmpty).join(' ');
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': direccion,
      'format': 'json',
      'limit': '1',
    });
    try {
      final respuesta = await http.get(
        uri,
        headers: {'User-Agent': 'PatasAlDia-App/1.0'},
      );
      final resultados = jsonDecode(respuesta.body) as List;
      if (resultados.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.errorGeocodificacion)));
        }
        return;
      }
      final primero = resultados.first as Map<String, dynamic>;
      _ubicacionLat = double.parse(primero['lat'] as String);
      _ubicacionLng = double.parse(primero['lon'] as String);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeocodificacion)));
      }
    }
  }

  Future<void> _publicarReporte() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _guardando = true);

    if (!_usarUbicacionActual) {
      await _geocodificarDireccion();
      if (!mounted) {
        return;
      }
    }

    final mascota = widget.mascota;
    // Se guarda el valor canónico (español, o el texto libre de "Otro"), no
    // la versión traducida al idioma actual — el reporte lo puede ver
    // cualquier usuario, con cualquier idioma. Mismo criterio que el resto
    // de los valores guardados de la app (ver sistemaIdiomas.md, punto 3).
    final especieDenormalizada = mascota.especie == 'Otro'
        ? (mascota.especiePersonalizada ?? mascota.especie)
        : mascota.especie;

    try {
      final repo = ref.read(mascotaExtraviadaRepositoryProvider);
      final usuarioIdSupabase = await repo.obtenerUsuarioIdSupabase();

      final reporte = MascotaExtraviadaModel(
        id: const Uuid().v4(),
        usuarioId: usuarioIdSupabase,
        mascotaId: mascota.id,
        mascotaNombre: mascota.nombre,
        mascotaEspecie: especieDenormalizada,
        ubicacionLat: _ubicacionLat,
        ubicacionLng: _ubicacionLng,
        recompensa: _tieneRecompensa
            ? double.parse(_recompensaController.text.trim())
            : 0,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reportePublicadoAviso)));
      Navigator.of(context).pop();
    } on PostgrestException catch (e) {
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
    final mascota = widget.mascota;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportarMascotaPerdidaLabel)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.pets),
              title: Text(mascota.nombre),
              subtitle: Text(especieMostrar(context, mascota)),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.usarUbicacionActualSwitch),
              value: _usarUbicacionActual,
              onChanged: (valor) =>
                  setState(() => _usarUbicacionActual = valor),
            ),
            if (_usarUbicacionActual)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
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
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _calleController,
                      decoration: InputDecoration(
                        labelText: l10n.campoCalle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _numeroController,
                      decoration: InputDecoration(
                        labelText: l10n.campoNumero,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
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
