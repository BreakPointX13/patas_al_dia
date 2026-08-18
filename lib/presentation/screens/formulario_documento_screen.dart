import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:patas_al_dia/data/models/documento_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/utils/etiquetas_localizadas.dart';
import 'package:patas_al_dia/providers/documento_provider.dart';

const tiposDocumentoDisponibles = [
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

  String _tipoDocumento = tiposDocumentoDisponibles.first;
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
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(l10n.elegirPdf),
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
        SnackBar(content: Text(AppLocalizations.of(context).eligeFotoOPdf)),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.documentoExistente == null
              ? l10n.agregarDocumentoLabel
              : l10n.editarDocumentoLabel,
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
                _filePath == null ? l10n.sinArchivoElegido : l10n.archivoElegido,
              ),
              trailing: TextButton(
                onPressed: _elegirArchivo,
                child: Text(_filePath == null ? l10n.accionElegir : l10n.accionCambiar),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tituloController,
              decoration: InputDecoration(labelText: l10n.campoTituloObligatorio),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return l10n.errorTituloObligatorio;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _tipoDocumento,
              decoration: InputDecoration(labelText: l10n.campoTipo),
              items: tiposDocumentoDisponibles
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(tipoDocumentoMostrar(l10n, t)),
                    ),
                  )
                  .toList(),
              onChanged: (valor) =>
                  setState(() => _tipoDocumento = valor ?? tiposDocumentoDisponibles.first),
            ),
            if (_tipoDocumento == 'Otro') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _tipoPersonalizadoController,
                decoration: InputDecoration(
                  labelText: l10n.campoEspecificaElTipo,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _fechaEmision == null
                    ? l10n.fechaEmisionNoEspecificada
                    : l10n.fechaEmitidaConValor(
                        '${_fechaEmision!.day}/'
                        '${_fechaEmision!.month}/${_fechaEmision!.year}',
                      ),
              ),
              trailing: TextButton(
                onPressed: () => _seleccionarFecha(esVencimiento: false),
                child: Text(l10n.accionElegir),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _fechaVencimiento == null
                    ? l10n.fechaVencimientoOpcional
                    : l10n.fechaVenceConValor(
                        '${_fechaVencimiento!.day}/'
                        '${_fechaVencimiento!.month}/${_fechaVencimiento!.year}',
                      ),
              ),
              trailing: TextButton(
                onPressed: () => _seleccionarFecha(esVencimiento: true),
                child: Text(l10n.accionElegir),
              ),
            ),
            if (_fechaVencimiento != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.recordatorioVencimientoLabel),
                subtitle: Text(l10n.recordatorioVencimientoAviso),
                value: _recordatorioVencimiento,
                onChanged: (valor) =>
                    setState(() => _recordatorioVencimiento = valor),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notasController,
              decoration: InputDecoration(labelText: l10n.campoNotas),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _guardar, child: Text(l10n.accionGuardar)),
          ],
        ),
      ),
    );
  }
}
