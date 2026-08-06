import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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

  final _nombreController = TextEditingController();
  final _especieController = TextEditingController();
  final _razaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _rutController = TextEditingController();
  final _coloresController = TextEditingController();
  final _numeroChipController = TextEditingController();

  String? _sexo;
  DateTime? _fechaNacimiento;
  bool _esterilizado = false;

  final ImagePicker _picker = ImagePicker();
  String? _fotoPath;

  Future<void> _elegirFoto() async {
    final imagen = await _picker.pickImage(source: ImageSource.gallery);
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
      _especieController.text = mascota.especie ?? '';
      _razaController.text = mascota.raza ?? '';
      _pesoController.text = mascota.pesoActual?.toString() ?? '';
      _rutController.text = mascota.rutMascota ?? '';
      _coloresController.text = mascota.colores ?? '';
      _numeroChipController.text = mascota.numeroChip ?? '';
      _sexo = mascota.sexo;
      _fechaNacimiento = mascota.fechaNacimiento;
      _esterilizado = mascota.esterilizado;
      _fotoPath = mascota.fotoUrl;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _especieController.dispose();
    _razaController.dispose();
    _pesoController.dispose();
    _rutController.dispose();
    _coloresController.dispose();
    _numeroChipController.dispose();
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

    final usuarioId = ref.read(usuarioProvider)!.id;
    final peso = double.tryParse(_pesoController.text.trim());

    final mascota = MascotaModel(
      id: widget.mascotaExistente?.id ?? const Uuid().v4(),
      usuarioId: usuarioId,
      nombre: _nombreController.text.trim(),
      especie: _especieController.text.trim().isEmpty
          ? null
          : _especieController.text.trim(),
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
      fechaNacimiento: _fechaNacimiento,
      pesoActual: peso,
      fotoUrl: _fotoPath,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mascotaExistente == null
              ? 'Agregar mascota'
              : 'Editar mascota',
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
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: _fotoPath != null
                      ? FileImage(File(_fotoPath!))
                      : null,
                  child: _fotoPath == null
                      ? const Icon(Icons.pets, size: 48)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _especieController,
              decoration: const InputDecoration(labelText: 'Especie'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _razaController,
              decoration: const InputDecoration(labelText: 'Raza'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rutController,
              decoration: const InputDecoration(labelText: 'Rut de la mascota'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _coloresController,
              decoration: const InputDecoration(labelText: 'Colores'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numeroChipController,
              decoration: const InputDecoration(labelText: 'Número de chip'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _sexo,
              decoration: const InputDecoration(labelText: 'Sexo'),
              items: const [
                DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                DropdownMenuItem(value: 'Hembra', child: Text('Hembra')),
              ],
              onChanged: (valor) {
                setState(() {
                  _sexo = valor;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pesoController,
              decoration: const InputDecoration(labelText: 'Peso (kg)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Esterilizado'),
              value: _esterilizado,
              onChanged: (valor) => setState(() => _esterilizado = valor),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _fechaNacimiento == null
                    ? 'Fecha de nacimiento no seleccionada'
                    : 'Fecha de nacimiento: '
                          '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
              ),
              trailing: TextButton(
                onPressed: _seleccionarFecha,
                child: const Text('Elegir fecha'),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}
