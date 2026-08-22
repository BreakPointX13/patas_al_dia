import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:patas_al_dia/presentation/widgets/separador_seccion_ficha.dart';
import 'package:patas_al_dia/services/almacenamiento_local_service.dart';

const especiesDisponibles = [
  'Perro',
  'Gato',
  'Conejo',
  'Hamster',
  'Cobaya',
  'Jerbo',
  'Rata',
  'Chinchilla',
  'Erizo',
  'Pez',
  'Tortuga',
  'Hurón',
  'Ave',
  'Otro',
];

class FormularioMascotaScreen extends ConsumerStatefulWidget {
  final MascotaModel? mascotaExistente;
  const FormularioMascotaScreen({super.key, this.mascotaExistente});

  @override
  ConsumerState<FormularioMascotaScreen> createState() =>
      _FormularioMascotaScreenState();
}

class _FormularioMascotaScreenState
    extends ConsumerState<FormularioMascotaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;

  final _nombreController = TextEditingController();
  final _especiePersonalizadaController = TextEditingController();
  final _razaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _rutController = TextEditingController();
  final _coloresController = TextEditingController();
  final _numeroChipController = TextEditingController();
  final _edadEstimadaController = TextEditingController();

  String _especie = especiesDisponibles.first;
  String? _sexo;
  DateTime? _fechaNacimiento;
  bool _esterilizado = false;
  bool _fechaEstimada = false;

  final ImagePicker _picker = ImagePicker();
  String? _fotoPath;

  Future<void> _elegirFoto() async {
    // maxWidth/imageQuality (2026-08-20, Sync — ver decisiones_arquitectura.md):
    // es la única foto de mascota que ahora sube a Storage, mismo criterio
    // de compresión que ya usa la foto de reporte del módulo Mapa.
    final imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (imagen != null) {
      setState(() {
        _fotoPath = imagen.path;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final mascota = widget.mascotaExistente;
    if (mascota != null) {
      _nombreController.text = mascota.nombre;
      if (mascota.especie != null && especiesDisponibles.contains(mascota.especie)) {
        _especie = mascota.especie!;
      } else if (mascota.especie != null) {
        _especie = 'Otro';
        _especiePersonalizadaController.text = mascota.especie!;
      }
      if (_especie == 'Otro' && mascota.especiePersonalizada != null) {
        _especiePersonalizadaController.text = mascota.especiePersonalizada!;
      }
      _razaController.text = mascota.raza ?? '';
      _pesoController.text = mascota.pesoActual?.toString() ?? '';
      _rutController.text = mascota.rutMascota ?? '';
      _coloresController.text = mascota.colores ?? '';
      _numeroChipController.text = mascota.numeroChip ?? '';
      _sexo = mascota.sexo;
      _fechaNacimiento = mascota.fechaNacimiento;
      _esterilizado = mascota.esterilizado;
      _fotoPath = mascota.fotoUrl;
      _fechaEstimada = mascota.fechaEstimada;
      if (_fechaEstimada && mascota.fechaNacimiento != null) {
        final anios = DateTime.now().year - mascota.fechaNacimiento!.year;
        _edadEstimadaController.text = anios.toString();
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _especiePersonalizadaController.dispose();
    _razaController.dispose();
    _pesoController.dispose();
    _rutController.dispose();
    _coloresController.dispose();
    _numeroChipController.dispose();
    _edadEstimadaController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        _fechaNacimiento = fecha;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _guardando = true);
    try {
      final usuarioId = ref.read(usuarioProvider)!.id;
      final peso = double.tryParse(_pesoController.text.trim());
      final fechaNacimientoFinal = _fechaEstimada
          ? DateTime(
              DateTime.now().year -
                  (int.tryParse(_edadEstimadaController.text.trim()) ?? 0),
              DateTime.now().month,
              DateTime.now().day,
            )
          : _fechaNacimiento;
      final mascotaId = widget.mascotaExistente?.id ?? const Uuid().v4();

      // Copia la foto elegida a un directorio persistente (2026-08-20, Sync)
      // — image_picker devuelve una ruta de caché que en iOS el sistema
      // puede limpiar sola (ver pendientes_ios.md, punto 1), y Sync necesita
      // un archivo estable para poder subirlo. Solo si la foto realmente
      // cambió (comparado contra la que ya tenía al editar) — si no, ya está
      // en el directorio persistente de una vez anterior.
      final fotoCambio =
          _fotoPath != null && _fotoPath != widget.mascotaExistente?.fotoUrl;
      var fotoPathFinal = _fotoPath;
      if (fotoCambio) {
        final ext = _fotoPath!.split('.').last;
        final nombre = AlmacenamientoLocalService.nombreArchivo(
          entidadId: mascotaId,
          ext: ext,
        );
        final rutaPersistente =
            await AlmacenamientoLocalService.rutaFotosMascotas(nombre);
        fotoPathFinal = await AlmacenamientoLocalService.copiarAPersistente(
          rutaOrigen: _fotoPath!,
          rutaDestino: rutaPersistente,
        );
      }

      final mascota = MascotaModel(
        id: mascotaId,
        usuarioId: usuarioId,
        nombre: _nombreController.text.trim(),
        especie: _especie,
        especiePersonalizada:
            _especie == 'Otro' &&
                _especiePersonalizadaController.text.trim().isNotEmpty
            ? _especiePersonalizadaController.text.trim()
            : null,
        raza: _razaController.text.trim().isEmpty
            ? null
            : _razaController.text.trim(),
        rutMascota: _rutController.text.trim().isEmpty
            ? null
            : _rutController.text.trim(),
        colores: _coloresController.text.trim().isEmpty
            ? null
            : _coloresController.text.trim(),
        numeroChip: _numeroChipController.text.trim().isEmpty
            ? null
            : _numeroChipController.text.trim(),
        sexo: _sexo,
        esterilizado: _esterilizado,
        fechaNacimiento: fechaNacimientoFinal,
        fechaEstimada: _fechaEstimada,
        pesoActual: peso,
        fotoUrl: fotoPathFinal,
        // Si la foto cambió, se resetea a null a propósito — le indica al
        // motor de sync que tiene que volver a subirla (ver sync_service.dart,
        // que solo sube "una vez", si fotoRutaNube todavía es null). Si no
        // cambió, se preserva la ya subida para no forzar una re-subida
        // innecesaria en cada edición del resto de los campos.
        fotoRutaNube: fotoCambio
            ? null
            : widget.mascotaExistente?.fotoRutaNube,
      );

      if (widget.mascotaExistente == null) {
        await ref.read(mascotasProvider.notifier).agregarMascota(mascota);
      } else {
        await ref.read(mascotasProvider.notifier).actualizarMascota(mascota);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  static final Map<String, String Function(AppLocalizations)>
  _etiquetasEspecies = {
    'Perro': (l10n) => l10n.especiePerro,
    'Gato': (l10n) => l10n.especieGato,
    'Conejo': (l10n) => l10n.especieConejo,
    'Hamster': (l10n) => l10n.especieHamster,
    'Cobaya': (l10n) => l10n.especieCobaya,
    'Jerbo': (l10n) => l10n.especieJerbo,
    'Rata': (l10n) => l10n.especieRata,
    'Chinchilla': (l10n) => l10n.especieChinchilla,
    'Erizo': (l10n) => l10n.especieErizo,
    'Pez': (l10n) => l10n.especiePez,
    'Tortuga': (l10n) => l10n.especieTortuga,
    'Hurón': (l10n) => l10n.especieHuron,
    'Ave': (l10n) => l10n.especieAve,
    'Otro': (l10n) => l10n.especieOtro,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mascotaExistente == null
              ? l10n.homeAgregarMascota
              : l10n.formMascotaTituloEditar,
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
                    Text(_fotoPath == null ? l10n.fotoAnadir : l10n.fotoCambiar),
                  ],
                ),
              ),
            ),
            SeparadorSeccionFicha.mascota(),
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: l10n.campoNombreObligatorio),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
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
                      child: Text(_etiquetasEspecies[e]!(l10n)),
                    ),
                  )
                  .toList(),
              onChanged: (valor) =>
                  setState(() => _especie = valor ?? especiesDisponibles.first),
            ),
            if (_especie == 'Otro') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _especiePersonalizadaController,
                decoration: InputDecoration(
                  labelText: l10n.campoEspecificaEspecie,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _razaController,
              decoration: InputDecoration(labelText: l10n.campoRaza),
            ),
            SeparadorSeccionFicha.identificacion(),
            TextFormField(
              controller: _rutController,
              decoration: InputDecoration(labelText: l10n.formCampoRut),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numeroChipController,
              decoration: InputDecoration(labelText: l10n.campoNumeroChip),
            ),
            SeparadorSeccionFicha.datos(),
            DropdownButtonFormField<String>(
              initialValue: _sexo,
              decoration: InputDecoration(labelText: l10n.campoSexo),
              items: [
                DropdownMenuItem(value: 'Macho', child: Text(l10n.sexoMacho)),
                DropdownMenuItem(
                  value: 'Hembra',
                  child: Text(l10n.sexoHembra),
                ),
              ],
              onChanged: (valor) {
                setState(() {
                  _sexo = valor;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _coloresController,
              decoration: InputDecoration(labelText: l10n.campoColores),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pesoController,
              decoration: InputDecoration(labelText: l10n.campoPesoKg),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return null;
                }
                final peso = double.tryParse(valor.trim());
                if (peso == null || peso <= 0) {
                  return l10n.errorPesoInvalido;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.campoEsterilizado),
              value: _esterilizado,
              onChanged: (valor) => setState(() => _esterilizado = valor),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.campoFechaEstimadaSwitch),
              value: _fechaEstimada,
              onChanged: (valor) => setState(() => _fechaEstimada = valor),
            ),
            const SizedBox(height: 16),
            if (_fechaEstimada)
              TextFormField(
                controller: _edadEstimadaController,
                decoration: InputDecoration(
                  labelText: l10n.campoEdadEstimadaAnios,
                ),
                keyboardType: TextInputType.number,
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return l10n.errorEdadEstimadaVacia;
                  }
                  final anios = int.tryParse(valor.trim());
                  if (anios == null || anios <= 0 || anios > 30) {
                    return l10n.errorEdadEstimadaInvalida;
                  }
                  return null;
                },
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _fechaNacimiento == null
                      ? l10n.fechaNacimientoNoSeleccionada
                      : l10n.fechaNacimientoConValor(
                          '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                        ),
                ),
                trailing: TextButton(
                  onPressed: _seleccionarFecha,
                  child: Text(l10n.elegirFecha),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
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
