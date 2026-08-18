import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:patas_al_dia/data/models/agenda_evento_model.dart';
import 'package:patas_al_dia/data/models/documento_model.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/formulario_agenda_evento_screen.dart';
import 'package:patas_al_dia/presentation/screens/visor_imagen_screen.dart';
import 'package:patas_al_dia/presentation/utils/etiquetas_localizadas.dart';
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

  String _nombreMascota(
    AppLocalizations l10n,
    List<MascotaModel> mascotas,
    String mascotaId,
  ) {
    for (final mascota in mascotas) {
      if (mascota.id == mascotaId) {
        return mascota.nombre;
      }
    }
    return l10n.mascotaFallback;
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
    final l10n = AppLocalizations.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.eliminarEventoTitulo),
        content: Text(l10n.eliminarEventoContenido(evento.titulo)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.accionCancelar),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.accionEliminar),
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
    final l10n = AppLocalizations.of(context);

    final mascotas = ref.watch(mascotasProvider);
    final nombreMascota = _nombreMascota(l10n, mascotas, evento.mascotaId);
    final medicamentos = ref.watch(medicamentoEventoProvider);
    final documentos = ref.watch(documentosProvider);

    return Scaffold(
      appBar: AppBar(title: Text(evento.titulo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(l10n.campoMascota),
            subtitle: Text(nombreMascota),
          ),
          ListTile(
            title: Text(l10n.campoTipoEvento),
            subtitle: Text(
              evento.tipoEvento == 'Otro' &&
                      evento.tipoEventoPersonalizado != null
                  ? evento.tipoEventoPersonalizado!
                  : tipoEventoMostrar(l10n, evento.tipoEvento),
            ),
          ),
          ListTile(
            title: Text(l10n.campoFechaProgramada),
            subtitle: Text(
              '${evento.fechaProgramada.day}/'
              '${evento.fechaProgramada.month}/${evento.fechaProgramada.year} '
              '${evento.fechaProgramada.hour.toString().padLeft(2, '0')}:'
              '${evento.fechaProgramada.minute.toString().padLeft(2, '0')}',
            ),
          ),
          ListTile(
            title: Text(l10n.campoObservaciones),
            subtitle: Text(evento.observaciones ?? l10n.sinObservaciones),
          ),
          ListTile(
            title: Text(l10n.campoRecordatorio),
            subtitle: Text(
              evento.recordatorioHorasAntes.isEmpty
                  ? l10n.sinRecordatorio
                  : evento.recordatorioHorasAntes
                        .map((h) => l10n.recordatorioHorasGenerico(h))
                        .join(', '),
            ),
          ),
          const Divider(height: 32),
          if (evento.fechaRealizada != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle),
              title: Text(l10n.realizadoLabel),
              subtitle: Text(
                '${evento.fechaRealizada!.day}/'
                '${evento.fechaRealizada!.month}/${evento.fechaRealizada!.year}',
              ),
            )
          else
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.marcarComoRealizado),
              value: false,
              onChanged: (_) => _marcarRealizado(evento),
            ),
          const Divider(height: 32),
          Text(l10n.medicamentosLabel, style: Theme.of(context).textTheme.titleMedium),
          if (medicamentos.isEmpty)
            Text(l10n.sinMedicamentosRegistrados)
          else
            for (final medicamento in medicamentos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(medicamento.nombre),
                subtitle: Text(
                  medicamento.observaciones == null
                      ? tipoPresentacionMostrar(l10n, medicamento.tipoPresentacion)
                      : '${tipoPresentacionMostrar(l10n, medicamento.tipoPresentacion)} · ${medicamento.observaciones}',
                ),
              ),
          const Divider(height: 32),
          Text(
            l10n.documentosAdjuntosLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (documentos.isEmpty)
            Text(l10n.sinDocumentosAdjuntos)
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
                subtitle: Text(tipoDocumentoMostrar(l10n, documento.tipoDocumento)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _abrirDocumento(documento),
              ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(l10n.accionEditar),
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
            title: Text(
              l10n.eliminarEventoTitulo,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => _eliminarEvento(evento),
          ),
        ],
      ),
    );
  }
}
