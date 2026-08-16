import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:patas_al_dia/data/models/agenda_evento_model.dart';
import 'package:patas_al_dia/data/models/documento_model.dart';
import 'package:patas_al_dia/data/models/medicamento_evento_model.dart';
import 'package:patas_al_dia/providers/agenda_evento_provider.dart';
import 'package:patas_al_dia/providers/documento_provider.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';
import 'package:patas_al_dia/providers/medicamento_evento_provider.dart';
import 'package:patas_al_dia/services/notificacion_service.dart';

const _opcionesRecordatorio = {
  24: '1 día antes',
  12: '12 horas antes',
  6: '6 horas antes',
  1: '1 hora antes',
};

const _tiposPresentacion = [
  'Comprimido',
  'Líquido',
  'Inyectable',
  'Pomada/crema',
  'Gotas',
  'Pipeta',
  'Otro',
];

const _tiposDocumento = ['Receta', 'Examen', 'Certificado', 'Boleta', 'Otro'];

class FormularioAgendaEventoScreen extends ConsumerStatefulWidget {
  final AgendaEventoModel? eventoExistente;
  final String? mascotaIdInicial;
  // Solo se usa al crear (eventoExistente == null): limita el selector de
  // fecha a futuro o pasado y define el título de la pantalla.
  final bool esEventoPasado;

  const FormularioAgendaEventoScreen({
    super.key,
    this.eventoExistente,
    this.mascotaIdInicial,
    this.esEventoPasado = false,
  });

  @override
  ConsumerState<FormularioAgendaEventoScreen> createState() =>
      _FormularioAgendaEventoScreenState();
}

class _FormularioAgendaEventoScreenState
    extends ConsumerState<FormularioAgendaEventoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _tipoEventoController = TextEditingController();
  final _observacionesController = TextEditingController();

  String? _mascotaId;
  DateTime? _fechaProgramada;
  bool _recordatorioActivo = false;
  Set<int> _recordatorioHorasSeleccionadas = {24};
  bool _proximaConsultaActiva = false;
  DateTime? _proximaConsultaFecha;

  // El id del evento se fija desde el arranque (no solo al guardar), para
  // que los medicamentos y documentos que se vayan agregando puedan
  // referenciarlo aunque el evento todavía no exista en la base de datos.
  late final String _eventoId = widget.eventoExistente?.id ?? const Uuid().v4();
  final ImagePicker _picker = ImagePicker();
  List<MedicamentoEventoModel> _medicamentos = [];
  List<MedicamentoEventoModel> _medicamentosOriginales = [];
  List<DocumentoModel> _documentos = [];
  List<DocumentoModel> _documentosOriginales = [];

  // La segunda mitad del formulario (observaciones, próxima consulta,
  // medicamentos, documentos) se habilita sola una vez que la fecha
  // programada ya pasó — no hace falta un campo aparte para distinguir
  // "evento pasado" de "evento futuro ya ocurrido". Si el evento ya se
  // marcó como realizado (desde DetalleAgendaEventoScreen), se trata igual
  // que si la fecha ya hubiera pasado, aunque fechaProgramada siga técnicamente
  // en el futuro — el usuario ya confirmó que ocurrió.
  bool get _esFechaFutura {
    if (widget.eventoExistente?.fechaRealizada != null) {
      return false;
    }
    return _fechaProgramada != null && _fechaProgramada!.isAfter(DateTime.now());
  }
  bool get _segundaMitadVisible {
    // Al crear un evento pasado, toda la información (medicamentos,
    // documentos, etc.) está disponible desde el principio — no tiene
    // sentido esperar a elegir la fecha para poder completarla, ya que el
    // usuario ya sabe que está registrando algo que ocurrió.
    if (widget.eventoExistente == null && widget.esEventoPasado) {
      return true;
    }
    return _fechaProgramada != null && !_esFechaFutura;
  }

  String get _tituloAppBar {
    if (widget.eventoExistente != null) {
      return 'Editar evento';
    }
    return widget.esEventoPasado ? 'Agregar evento pasado' : 'Agregar evento futuro';
  }

  @override
  void initState() {
    super.initState();
    final evento = widget.eventoExistente;
    if (evento != null) {
      _mascotaId = evento.mascotaId;
      _tituloController.text = evento.titulo;
      _tipoEventoController.text = evento.tipoEvento ?? '';
      _observacionesController.text = evento.observaciones ?? '';
      _fechaProgramada = evento.fechaProgramada;
      _recordatorioActivo = evento.recordatorioHorasAntes.isNotEmpty;
      if (_recordatorioActivo) {
        _recordatorioHorasSeleccionadas = evento.recordatorioHorasAntes.toSet();
      }
      _cargarMedicamentosExistentes();
      _cargarDocumentosExistentes();
    } else {
      _mascotaId = widget.mascotaIdInicial;
    }
  }

  Future<void> _cargarMedicamentosExistentes() async {
    final repo = ref.read(medicamentoEventoRepositoryProvider);
    final lista = await repo.obtenerMedicamentosPorEvento(_eventoId);
    if (!mounted) {
      return;
    }
    setState(() {
      _medicamentos = lista;
      _medicamentosOriginales = lista;
    });
  }

  Future<void> _cargarDocumentosExistentes() async {
    final repo = ref.read(documentoRepositoryProvider);
    final lista = await repo.obtenerDocumentosPorEvento(_eventoId);
    if (!mounted) {
      return;
    }
    setState(() {
      _documentos = lista;
      _documentosOriginales = lista;
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _tipoEventoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaHora() async {
    final ahora = DateTime.now();
    final esCreacionPasado =
        widget.eventoExistente == null && widget.esEventoPasado;
    final esCreacionFuturo =
        widget.eventoExistente == null && !widget.esEventoPasado;

    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaProgramada ?? ahora,
      firstDate: esCreacionFuturo ? ahora : DateTime(2000),
      lastDate: esCreacionPasado ? ahora : DateTime(2100),
    );
    if (fecha == null || !mounted) {
      return;
    }

    if (!mounted) {
      return;
    }
    final hora = await showTimePicker(
      context: context,
      initialTime: _fechaProgramada != null
          ? TimeOfDay.fromDateTime(_fechaProgramada!)
          : TimeOfDay.now(),
    );
    if (hora == null) {
      return;
    }

    final fechaHora = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );

    // showDatePicker limita el día a "hoy o antes" en un evento pasado, pero
    // showTimePicker no tiene forma de limitar la hora — si se elige "hoy"
    // con una hora posterior a la actual, el resultado quedaría técnicamente
    // en el futuro sin que el usuario lo note.
    if (esCreacionPasado && fechaHora.isAfter(DateTime.now())) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La hora elegida todavía no pasó. Elige una hora anterior a la actual.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _fechaProgramada = fechaHora;
    });
  }

  Future<void> _seleccionarFechaProximaConsulta() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _proximaConsultaFecha ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() => _proximaConsultaFecha = fecha);
    }
  }

  Future<void> _abrirDialogoMedicamento({
    MedicamentoEventoModel? existente,
  }) async {
    final nombreController = TextEditingController(
      text: existente?.nombre ?? '',
    );
    final observacionesController = TextEditingController(
      text: existente?.observaciones ?? '',
    );
    String tipo = existente?.tipoPresentacion ?? _tiposPresentacion.first;

    final resultado = await showDialog<MedicamentoEventoModel>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialogo) => AlertDialog(
          title: Text(
            existente == null ? 'Agregar medicamento' : 'Editar medicamento',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Presentación'),
                  items: _tiposPresentacion
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t)),
                      )
                      .toList(),
                  onChanged: (valor) =>
                      setStateDialogo(() => tipo = valor ?? tipo),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: observacionesController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nombreController.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  MedicamentoEventoModel(
                    id: existente?.id ?? const Uuid().v4(),
                    agendaEventoId: _eventoId,
                    tipoPresentacion: tipo,
                    nombre: nombreController.text.trim(),
                    observaciones: observacionesController.text.trim().isEmpty
                        ? null
                        : observacionesController.text.trim(),
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (resultado == null) {
      return;
    }
    setState(() {
      final indiceExistente = _medicamentos.indexWhere(
        (m) => m.id == resultado.id,
      );
      if (indiceExistente >= 0) {
        _medicamentos[indiceExistente] = resultado;
      } else {
        _medicamentos.add(resultado);
      }
    });
  }

  Future<void> _abrirSelectorDocumento() async {
    if (_mascotaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una mascota primero')),
      );
      return;
    }

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

    if (rutaArchivo == null || !mounted) {
      return;
    }
    await _abrirDialogoDatosDocumento(rutaArchivo);
  }

  Future<void> _abrirDialogoDatosDocumento(
    String filePath, {
    DocumentoModel? existente,
  }) async {
    final tituloController = TextEditingController(
      text: existente?.titulo ?? '',
    );
    String tipo = existente?.tipoDocumento ?? _tiposDocumento.first;

    final resultado = await showDialog<DocumentoModel>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialogo) => AlertDialog(
          title: const Text('Datos del documento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(labelText: 'Título *'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: _tiposDocumento
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t)),
                      )
                      .toList(),
                  onChanged: (valor) =>
                      setStateDialogo(() => tipo = valor ?? tipo),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (tituloController.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  DocumentoModel(
                    id: existente?.id ?? const Uuid().v4(),
                    mascotaId: _mascotaId!,
                    eventoId: _eventoId,
                    titulo: tituloController.text.trim(),
                    tipoDocumento: tipo,
                    filePath: existente?.filePath ?? filePath,
                    fileExtension: (existente?.filePath ?? filePath)
                        .split('.')
                        .last,
                    fechaSubida: existente?.fechaSubida ?? DateTime.now(),
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (resultado == null) {
      return;
    }
    setState(() {
      final indiceExistente = _documentos.indexWhere(
        (d) => d.id == resultado.id,
      );
      if (indiceExistente >= 0) {
        _documentos[indiceExistente] = resultado;
      } else {
        _documentos.add(resultado);
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_mascotaId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una mascota')));
      return;
    }
    if (_fechaProgramada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fecha y hora')),
      );
      return;
    }

    final evento = AgendaEventoModel(
      id: _eventoId,
      mascotaId: _mascotaId!,
      tipoEvento: _tipoEventoController.text.trim().isEmpty
          ? null
          : _tipoEventoController.text.trim(),
      titulo: _tituloController.text.trim(),
      observaciones: _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
      fechaProgramada: _fechaProgramada!,
      fechaRealizada: widget.eventoExistente == null && widget.esEventoPasado
          ? _fechaProgramada
          : widget.eventoExistente?.fechaRealizada,
      recordatorioHorasAntes: _esFechaFutura && _recordatorioActivo
          ? (_recordatorioHorasSeleccionadas.toList()..sort((a, b) => b.compareTo(a)))
          : const [],
    );

    if (widget.eventoExistente == null) {
      await ref.read(agendaEventosProvider.notifier).agregarAgendaEvento(evento);
    } else {
      await ref
          .read(agendaEventosProvider.notifier)
          .actualizarAgendaEvento(evento);
    }
    await NotificacionService.instance.cancelarRecordatorio(evento.id);
    await NotificacionService.instance.programarRecordatorio(evento);

    final medicamentoNotifier = ref.read(medicamentoEventoProvider.notifier);
    final idsOriginales = _medicamentosOriginales.map((m) => m.id).toSet();
    final idsActuales = _medicamentos.map((m) => m.id).toSet();
    for (final medicamento in _medicamentos) {
      if (idsOriginales.contains(medicamento.id)) {
        await medicamentoNotifier.actualizarMedicamentoEvento(medicamento);
      } else {
        await medicamentoNotifier.agregarMedicamentoEvento(medicamento);
      }
    }
    for (final original in _medicamentosOriginales) {
      if (!idsActuales.contains(original.id)) {
        await medicamentoNotifier.eliminarMedicamentoEvento(original.id);
      }
    }

    final documentoNotifier = ref.read(documentosProvider.notifier);
    final idsDocumentosOriginales = _documentosOriginales
        .map((d) => d.id)
        .toSet();
    final idsDocumentosActuales = _documentos.map((d) => d.id).toSet();
    for (final documento in _documentos) {
      if (idsDocumentosOriginales.contains(documento.id)) {
        await documentoNotifier.actualizarDocumento(documento);
      } else {
        await documentoNotifier.agregarDocumento(documento);
      }
    }
    for (final original in _documentosOriginales) {
      if (!idsDocumentosActuales.contains(original.id)) {
        await documentoNotifier.eliminarDocumento(original.id);
      }
    }

    if (_proximaConsultaActiva && _proximaConsultaFecha != null) {
      final horaOriginal = TimeOfDay.fromDateTime(evento.fechaProgramada);
      final seguimiento = AgendaEventoModel(
        id: const Uuid().v4(),
        mascotaId: evento.mascotaId,
        tipoEvento: evento.tipoEvento,
        titulo: evento.titulo,
        fechaProgramada: DateTime(
          _proximaConsultaFecha!.year,
          _proximaConsultaFecha!.month,
          _proximaConsultaFecha!.day,
          horaOriginal.hour,
          horaOriginal.minute,
        ),
        recordatorioHorasAntes: const [24],
      );
      await ref
          .read(agendaEventosProvider.notifier)
          .agregarAgendaEvento(seguimiento);
      await NotificacionService.instance.programarRecordatorio(seguimiento);
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mascotas = ref.watch(mascotasProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_tituloAppBar)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _mascotaId,
              decoration: const InputDecoration(labelText: 'Mascota *'),
              items: mascotas
                  .map(
                    (m) =>
                        DropdownMenuItem(value: m.id, child: Text(m.nombre)),
                  )
                  .toList(),
              onChanged: (valor) => setState(() => _mascotaId = valor),
              validator: (valor) =>
                  valor == null ? 'Selecciona una mascota' : null,
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
            TextFormField(
              controller: _tipoEventoController,
              decoration: const InputDecoration(
                labelText: 'Tipo de evento',
                hintText: 'Vacuna, control, desparasitación...',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _fechaProgramada == null
                    ? 'Fecha y hora no seleccionadas'
                    : 'Fecha: ${_fechaProgramada!.day}/'
                          '${_fechaProgramada!.month}/${_fechaProgramada!.year} '
                          '${_fechaProgramada!.hour.toString().padLeft(2, '0')}:'
                          '${_fechaProgramada!.minute.toString().padLeft(2, '0')}',
              ),
              trailing: TextButton(
                onPressed: _seleccionarFechaHora,
                child: const Text('Elegir'),
              ),
            ),
            if (_esFechaFutura) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recordatorio'),
                value: _recordatorioActivo,
                onChanged: (valor) => setState(() => _recordatorioActivo = valor),
              ),
              if (_recordatorioActivo) ...[
                Text('Avisar', style: Theme.of(context).textTheme.bodySmall),
                for (final opcion in _opcionesRecordatorio.entries)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(opcion.value),
                    value: _recordatorioHorasSeleccionadas.contains(
                      opcion.key,
                    ),
                    onChanged: (marcado) {
                      setState(() {
                        if (marcado ?? false) {
                          _recordatorioHorasSeleccionadas.add(opcion.key);
                        } else {
                          _recordatorioHorasSeleccionadas.remove(opcion.key);
                        }
                      });
                    },
                  ),
              ],
            ],
            if (_segundaMitadVisible) ...[
              const Divider(height: 32),
              TextFormField(
                controller: _observacionesController,
                decoration: const InputDecoration(labelText: 'Observaciones'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Medicamentos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: () => _abrirDialogoMedicamento(),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              if (_medicamentos.isEmpty)
                const Text('Sin medicamentos registrados')
              else
                for (final medicamento in _medicamentos)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(medicamento.nombre),
                    subtitle: Text(medicamento.tipoPresentacion),
                    onTap: () =>
                        _abrirDialogoMedicamento(existente: medicamento),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(
                        () => _medicamentos.removeWhere(
                          (m) => m.id == medicamento.id,
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Documentos adjuntos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _abrirSelectorDocumento,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              if (_documentos.isEmpty)
                const Text('Sin documentos adjuntos')
              else
                for (final documento in _documentos)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      documento.fileExtension == 'pdf'
                          ? Icons.picture_as_pdf
                          : Icons.image,
                    ),
                    title: Text(documento.titulo),
                    subtitle: Text(documento.tipoDocumento),
                    onTap: () => _abrirDialogoDatosDocumento(
                      documento.filePath,
                      existente: documento,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(
                        () => _documentos.removeWhere(
                          (d) => d.id == documento.id,
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Programar próxima consulta'),
                value: _proximaConsultaActiva,
                onChanged: (valor) =>
                    setState(() => _proximaConsultaActiva = valor),
              ),
              if (_proximaConsultaActiva)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _proximaConsultaFecha == null
                        ? 'Elige el día'
                        : '${_proximaConsultaFecha!.day}/'
                              '${_proximaConsultaFecha!.month}/${_proximaConsultaFecha!.year}',
                  ),
                  trailing: TextButton(
                    onPressed: _seleccionarFechaProximaConsulta,
                    child: const Text('Elegir fecha'),
                  ),
                ),
            ] else if (_esFechaFutura)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'El resto de la información (observaciones, medicamentos, '
                  'documentos) se habilita cuando llegue la fecha del evento.',
                  style: Theme.of(context).textTheme.bodySmall,
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
