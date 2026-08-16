import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:patas_al_dia/data/models/documento_model.dart';
import 'package:patas_al_dia/providers/documento_provider.dart';

const _tiposDocumento = [
  'Carnet de vacunación',
  'Receta',
  'Examen',
  'Certificado',
  'Boleta',
  'Otro',
];

class FormularioDocumentoScreen extends ConsumerStatefulWidget {
  final String mascotaId;
  final DocumentoModel? documentoExistente;

  const FormularioDocumentoScreen({
    super.key,
    required this.mascotaId,
    this.documentoExistente,
  });

  @override
  ConsumerState<FormularioDocumentoScreen> createState() =>
      _FormularioDocumentoScreenState();
}

class _FormularioDocumentoScreenState
    extends ConsumerState<FormularioDocumentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _tipoPersonalizadoController = TextEditingController();
  final _notasController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _tipoDocumento = _tiposDocumento.first;
  String? _filePath;
  String? _fileExtension;
  DateTime? _fechaEmision;
  DateTime? _fechaVencimiento;
  bool _recordatorioVencimiento = false;

  @override
  void initState() {
    super.initState();
    final documento = widget.documentoExistente;
    if (documento != null) {
      _tituloController.text = documento.titulo;
      _tipoDocumento = documento.tipoDocumento;
      _tipoPersonalizadoController.text =
          documento.tipoDocumentoPersonalizado ?? '';
      _notasController.text = documento.notasAsociadas ?? '';
      _filePath = documento.filePath;
      _fileExtension = documento.fileExtension;
      _fechaEmision = documento.fechaEmision;
      _fechaVencimiento = documento.fechaVencimiento;
      _recordatorioVencimiento = documento.recordatorioVencimiento;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _tipoPersonalizadoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _elegirArchivo() async {
    final opcion = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop('camara'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir imagen de galería'),
              onTap: () => Navigator.of(context).pop('galeria'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Elegir PDF'),
              onTap: () => Navigator.of(context).pop('pdf'),
            ),
          ],
        ),
      ),
    );

    if (opcion == null || !mounted) {
      return;
    }

    String? rutaArchivo;
    switch (opcion) {
      case 'camara':
        final foto = await _picker.pickImage(source: ImageSource.camera);
        rutaArchivo = foto?.path;
      case 'galeria':
        final foto = await _picker.pickImage(source: ImageSource.gallery);
        rutaArchivo = foto?.path;
      case 'pdf':
        final resultado = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        rutaArchivo = resultado?.path;
    }

    if (rutaArchivo == null) {
      return;
    }
    setState(() {
      _filePath = rutaArchivo;
      _fileExtension = rutaArchivo!.split('.').last;
    });
  }

  Future<void> _seleccionarFecha({required bool esVencimiento}) async {
    final actual = esVencimiento ? _fechaVencimiento : _fechaEmision;
    final fecha = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (fecha == null) {
      return;
    }
    setState(() {
      if (esVencimiento) {
        _fechaVencimiento = fecha;
      } else {
        _fechaEmision = fecha;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige una foto o un PDF')),
      );
      return;
    }

    final documento = DocumentoModel(
      id: widget.documentoExistente?.id ?? const Uuid().v4(),
      mascotaId: widget.mascotaId,
      eventoId: widget.documentoExistente?.eventoId,
      titulo: _tituloController.text.trim(),
      tipoDocumento: _tipoDocumento,
      tipoDocumentoPersonalizado: _tipoDocumento == 'Otro'
          ? (_tipoPersonalizadoController.text.trim().isEmpty
                ? null
                : _tipoPersonalizadoController.text.trim())
          : null,
      filePath: _filePath!,
      fileExtension: _fileExtension,
      fechaEmision: _fechaEmision,
      fechaVencimiento: _fechaVencimiento,
      recordatorioVencimiento: _recordatorioVencimiento,
      fechaSubida: widget.documentoExistente?.fechaSubida ?? DateTime.now(),
      notasAsociadas: _notasController.text.trim().isEmpty
          ? null
          : _notasController.text.trim(),
    );

    if (widget.documentoExistente == null) {
      await ref.read(documentosProvider.notifier).agregarDocumento(documento);
    } else {
      await ref
          .read(documentosProvider.notifier)
          .actualizarDocumento(documento);
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
          widget.documentoExistente == null
              ? 'Agregar documento'
              : 'Editar documento',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _fileExtension == 'pdf' ? Icons.picture_as_pdf : Icons.image,
              ),
              title: Text(
                _filePath == null ? 'Sin archivo elegido' : 'Archivo elegido',
              ),
              trailing: TextButton(
                onPressed: _elegirArchivo,
                child: Text(_filePath == null ? 'Elegir' : 'Cambiar'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título *'),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'El título es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _tipoDocumento,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: _tiposDocumento
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (valor) =>
                  setState(() => _tipoDocumento = valor ?? _tiposDocumento.first),
            ),
            if (_tipoDocumento == 'Otro') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _tipoPersonalizadoController,
                decoration: const InputDecoration(
                  labelText: 'Especifica el tipo',
                ),
              ),
            ],
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _fechaEmision == null
                    ? 'Fecha de emisión no especificada'
                    : 'Emitido: ${_fechaEmision!.day}/'
                          '${_fechaEmision!.month}/${_fechaEmision!.year}',
              ),
              trailing: TextButton(
                onPressed: () => _seleccionarFecha(esVencimiento: false),
                child: const Text('Elegir'),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _fechaVencimiento == null
                    ? 'Fecha de vencimiento (opcional)'
                    : 'Vence: ${_fechaVencimiento!.day}/'
                          '${_fechaVencimiento!.month}/${_fechaVencimiento!.year}',
              ),
              trailing: TextButton(
                onPressed: () => _seleccionarFecha(esVencimiento: true),
                child: const Text('Elegir'),
              ),
            ),
            if (_fechaVencimiento != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recordatorio de vencimiento'),
                subtitle: const Text(
                  'Por ahora solo queda guardado como dato, todavía no '
                  'envía una notificación.',
                ),
                value: _recordatorioVencimiento,
                onChanged: (valor) =>
                    setState(() => _recordatorioVencimiento = valor),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notasController,
              decoration: const InputDecoration(labelText: 'Notas'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}
