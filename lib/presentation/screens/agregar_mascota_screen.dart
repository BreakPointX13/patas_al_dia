import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';

class AgregarMascotaScreen extends ConsumerStatefulWidget {
  const AgregarMascotaScreen({super.key});

  @override
  ConsumerState<AgregarMascotaScreen> createState() =>
      _AgregarMascotaScreenState();
}

class _AgregarMascotaScreenState extends ConsumerState<AgregarMascotaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _especieController = TextEditingController();
  final _razaController = TextEditingController();
  final _pesoController = TextEditingController();

  String? _sexo;
  DateTime? _fechaNacimiento;

  @override
  void dispose() {
    _nombreController.dispose();
    _especieController.dispose();
    _razaController.dispose();
    _pesoController.dispose();
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
      id: const Uuid().v4(),
      usuarioId: usuarioId,
      nombre: _nombreController.text.trim(),
      especie: _especieController.text.trim().isEmpty
          ? null
          : _especieController.text.trim(),
      raza: _razaController.text.trim().isEmpty
          ? null
          : _razaController.text.trim(),
      sexo: _sexo,
      fechaNacimiento: _fechaNacimiento,
      pesoActual: peso,
    );

    await ref.read(mascotasProvider.notifier).agregarMascota(mascota);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar mascota')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
