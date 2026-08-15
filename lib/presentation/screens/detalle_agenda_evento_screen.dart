import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/agenda_evento_model.dart';
import 'package:patas_al_dia/presentation/screens/formulario_agenda_evento_screen.dart';
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

  Future<void> _alternarRealizado(AgendaEventoModel evento) async {
    final eventoActualizado = evento.copyWith(
      fechaRealizada: evento.fechaRealizada == null ? DateTime.now() : null,
    );
    await ref
        .read(agendaEventosProvider.notifier)
        .actualizarAgendaEvento(eventoActualizado);
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
    final evento = ref
        .watch(agendaEventosProvider)
        .firstWhere((e) => e.id == widget.eventoId);
    final mascotas = ref.watch(mascotasProvider);
    final nombreMascota = mascotas
        .firstWhere((m) => m.id == evento.mascotaId)
        .nombre;
    final medicamentos = ref.watch(medicamentoEventoProvider);
    final documentos = ref.watch(documentosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(evento.titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar evento',
            onPressed: () => _eliminarEvento(evento),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: const Text('Mascota'), subtitle: Text(nombreMascota)),
          ListTile(
            title: const Text('Tipo de evento'),
            subtitle: Text(evento.tipoEvento ?? 'No especificado'),
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
              evento.recordatorioHorasAntes == null
                  ? 'Sin recordatorio'
                  : '${evento.recordatorioHorasAntes} horas antes',
            ),
          ),
          const Divider(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Marcar como realizado'),
            subtitle: evento.fechaRealizada != null
                ? Text(
                    'Realizado el ${evento.fechaRealizada!.day}/'
                    '${evento.fechaRealizada!.month}/${evento.fechaRealizada!.year}',
                  )
                : null,
            value: evento.fechaRealizada != null,
            onChanged: (_) => _alternarRealizado(evento),
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
        ],
      ),
    );
  }
}
