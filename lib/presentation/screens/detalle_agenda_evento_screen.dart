import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:patas_al_dia/data/models/agenda_evento_model.dart';
import 'package:patas_al_dia/data/models/documento_model.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/presentation/screens/formulario_agenda_evento_screen.dart';
import 'package:patas_al_dia/presentation/screens/visor_imagen_screen.dart';
import 'package:patas_al_dia/providers/agenda_evento_provider.dart';
import 'package:patas_al_dia/providers/documento_provider.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';
import 'package:patas_al_dia/providers/medicamento_evento_provider.dart';
import 'package:patas_al_dia/services/notificacion_service.dart';

class DetalleAgendaEventoScreen extends ConsumerStatefulWidget {
  final String eventoId;
  const DetalleAgendaEventoScreen({super.key, required this.eventoId});

  @override
  ConsumerState<DetalleAgendaEventoScreen> createState() =>
      _DetalleAgendaEventoScreenState();
}

class _DetalleAgendaEventoScreenState
    extends ConsumerState<DetalleAgendaEventoScreen> {
  @override
  void initState() {
    super.initState();
    ref
        .read(medicamentoEventoProvider.notifier)
        .cargarMedicamentosDeEvento(widget.eventoId);
    ref
        .read(documentosProvider.notifier)
        .cargarDocumentosDeEvento(widget.eventoId);
  }

  Future<void> _marcarRealizado(AgendaEventoModel evento) async {
    final eventoActualizado = evento.copyWith(fechaRealizada: DateTime.now());
    await ref
        .read(agendaEventosProvider.notifier)
        .actualizarAgendaEvento(eventoActualizado);
  }

  String _nombreMascota(List<MascotaModel> mascotas, String mascotaId) {
    for (final mascota in mascotas) {
      if (mascota.id == mascotaId) {
        return mascota.nombre;
      }
    }
    return 'Mascota';
  }

  Future<void> _abrirDocumento(DocumentoModel documento) async {
    if (documento.fileExtension == 'pdf') {
      await OpenFilex.open(documento.filePath);
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VisorImagenScreen(
          filePath: documento.filePath,
          titulo: documento.titulo,
        ),
      ),
    );
  }

  Future<void> _eliminarEvento(AgendaEventoModel evento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text(
          '¿Eliminar "${evento.titulo}"? Los medicamentos registrados se '
          'eliminan con el evento; los documentos adjuntos se conservan, '
          'solo pierden el vínculo con este evento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) {
      return;
    }

    await NotificacionService.instance.cancelarRecordatorio(evento.id);
    await ref.read(agendaEventosProvider.notifier).eliminarAgendaEvento(evento.id);

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final eventos = ref.watch(agendaEventosProvider);
    AgendaEventoModel? eventoEncontrado;
    for (final e in eventos) {
      if (e.id == widget.eventoId) {
        eventoEncontrado = e;
        break;
      }
    }
    if (eventoEncontrado == null) {
      // Puede pasar si el evento se borró (o el usuario cerró sesión) justo
      // mientras esta pantalla seguía abierta — no hay nada que mostrar.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final evento = eventoEncontrado;

    final mascotas = ref.watch(mascotasProvider);
    final nombreMascota = _nombreMascota(mascotas, evento.mascotaId);
    final medicamentos = ref.watch(medicamentoEventoProvider);
    final documentos = ref.watch(documentosProvider);

    return Scaffold(
      appBar: AppBar(title: Text(evento.titulo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: const Text('Mascota'), subtitle: Text(nombreMascota)),
          ListTile(
            title: const Text('Tipo de evento'),
            subtitle: Text(
              evento.tipoEvento == 'Otro' &&
                      evento.tipoEventoPersonalizado != null
                  ? evento.tipoEventoPersonalizado!
                  : evento.tipoEvento ?? 'No especificado',
            ),
          ),
          ListTile(
            title: const Text('Fecha programada'),
            subtitle: Text(
              '${evento.fechaProgramada.day}/'
              '${evento.fechaProgramada.month}/${evento.fechaProgramada.year} '
              '${evento.fechaProgramada.hour.toString().padLeft(2, '0')}:'
              '${evento.fechaProgramada.minute.toString().padLeft(2, '0')}',
            ),
          ),
          ListTile(
            title: const Text('Observaciones'),
            subtitle: Text(evento.observaciones ?? 'Sin observaciones'),
          ),
          ListTile(
            title: const Text('Recordatorio'),
            subtitle: Text(
              evento.recordatorioHorasAntes.isEmpty
                  ? 'Sin recordatorio'
                  : evento.recordatorioHorasAntes
                        .map((h) => '$h horas antes')
                        .join(', '),
            ),
          ),
          const Divider(height: 32),
          if (evento.fechaRealizada != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle),
              title: const Text('Realizado'),
              subtitle: Text(
                '${evento.fechaRealizada!.day}/'
                '${evento.fechaRealizada!.month}/${evento.fechaRealizada!.year}',
              ),
            )
          else
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Marcar como realizado'),
              value: false,
              onChanged: (_) => _marcarRealizado(evento),
            ),
          const Divider(height: 32),
          Text('Medicamentos', style: Theme.of(context).textTheme.titleMedium),
          if (medicamentos.isEmpty)
            const Text('Sin medicamentos registrados')
          else
            for (final medicamento in medicamentos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(medicamento.nombre),
                subtitle: Text(
                  medicamento.observaciones == null
                      ? medicamento.tipoPresentacion
                      : '${medicamento.tipoPresentacion} · ${medicamento.observaciones}',
                ),
              ),
          const Divider(height: 32),
          Text(
            'Documentos adjuntos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (documentos.isEmpty)
            const Text('Sin documentos adjuntos')
          else
            for (final documento in documentos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: documento.fileExtension == 'pdf'
                    ? const Icon(Icons.picture_as_pdf)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          File(documento.filePath),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                title: Text(documento.titulo),
                subtitle: Text(documento.tipoDocumento),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _abrirDocumento(documento),
              ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar evento'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      FormularioAgendaEventoScreen(eventoExistente: evento),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Eliminar evento',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _eliminarEvento(evento),
          ),
        ],
      ),
    );
  }
}
