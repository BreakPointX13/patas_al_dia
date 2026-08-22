import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:patas_al_dia/data/models/documento_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/formulario_documento_screen.dart';
import 'package:patas_al_dia/presentation/screens/visor_imagen_screen.dart';
import 'package:patas_al_dia/presentation/utils/etiquetas_localizadas.dart';
import 'package:patas_al_dia/presentation/widgets/dialogo_confirmacion.dart';
import 'package:patas_al_dia/providers/agenda_evento_provider.dart';
import 'package:patas_al_dia/providers/documento_provider.dart';

// Ficha de un documento: vista previa, datos y evento vinculado si tiene.
class DetalleDocumentoScreen extends ConsumerStatefulWidget {
  final String documentoId;
  const DetalleDocumentoScreen({super.key, required this.documentoId});

  @override
  ConsumerState<DetalleDocumentoScreen> createState() =>
      _DetalleDocumentoScreenState();
}

class _DetalleDocumentoScreenState
    extends ConsumerState<DetalleDocumentoScreen> {
  String? _tituloEventoVinculado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarEventoVinculado());
  }

  // Si el documento está ligado a un evento de agenda, busca su título.
  Future<void> _cargarEventoVinculado() async {
    final documentos = ref.read(documentosProvider);
    DocumentoModel? documento;
    for (final d in documentos) {
      if (d.id == widget.documentoId) {
        documento = d;
        break;
      }
    }
    final eventoId = documento?.eventoId;
    if (eventoId == null) {
      return;
    }
    final repo = ref.read(agendaEventoRepositoryProvider);
    final evento = await repo.obtenerAgendaEventoPorId(eventoId);
    if (!mounted || evento == null) {
      return;
    }
    setState(() => _tituloEventoVinculado = evento.titulo);
  }

  // Abre el PDF con la app del sistema, o la imagen en el visor propio.
  Future<void> _abrirArchivo(DocumentoModel documento) async {
    // filePath es nullable desde Sync (2026-08-20) — una fila recién traída
    // de otro dispositivo puede no tener el archivo descargado todavía (ver
    // decisiones_arquitectura.md). Acá no hay nada que abrir hasta que
    // termine de bajar.
    final filePath = documento.filePath;
    if (filePath == null) {
      return;
    }
    if (documento.fileExtension == 'pdf') {
      await OpenFilex.open(filePath);
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            VisorImagenScreen(filePath: filePath, titulo: documento.titulo),
      ),
    );
  }

  // Confirma y borra el documento (soft-delete).
  Future<void> _eliminarDocumento(DocumentoModel documento) async {
    final l10n = AppLocalizations.of(context);
    final confirmar = await confirmarAccion(
      context,
      titulo: l10n.eliminarDocumentoTitulo,
      contenido: l10n.eliminarDocumentoContenido(documento.titulo),
      textoConfirmar: l10n.accionEliminar,
    );

    if (confirmar != true || !mounted) {
      return;
    }
    await ref.read(documentosProvider.notifier).eliminarDocumento(documento.id);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final documentos = ref.watch(documentosProvider);
    DocumentoModel? documentoEncontrado;
    for (final d in documentos) {
      if (d.id == widget.documentoId) {
        documentoEncontrado = d;
        break;
      }
    }
    if (documentoEncontrado == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final documento = documentoEncontrado;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(documento.titulo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (documento.fileExtension != 'pdf')
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => _abrirArchivo(documento),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 320,
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    // filePath nullable desde Sync — todavía sin descargar
                    // en este dispositivo, ver _abrirArchivo.
                    child: documento.filePath == null
                        ? const Center(child: Icon(Icons.cloud_download_outlined, size: 48))
                        : InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4,
                            child: Image.file(
                              File(documento.filePath!),
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ListTile(
            title: Text(l10n.campoTipo),
            subtitle: Text(
              documento.tipoDocumento == 'Otro' &&
                      documento.tipoDocumentoPersonalizado != null
                  ? documento.tipoDocumentoPersonalizado!
                  : tipoDocumentoMostrar(l10n, documento.tipoDocumento),
            ),
          ),
          ListTile(
            title: Text(l10n.fechaEmisionLabel),
            subtitle: Text(
              documento.fechaEmision == null
                  ? l10n.noEspecificada
                  : '${documento.fechaEmision!.day}/'
                        '${documento.fechaEmision!.month}/${documento.fechaEmision!.year}',
            ),
          ),
          ListTile(
            title: Text(l10n.fechaVencimientoLabel),
            subtitle: Text(
              documento.fechaVencimiento == null
                  ? l10n.noEspecificada
                  : '${documento.fechaVencimiento!.day}/'
                        '${documento.fechaVencimiento!.month}/${documento.fechaVencimiento!.year}'
                        '${documento.recordatorioVencimiento ? l10n.conRecordatorioSufijo : ''}',
            ),
          ),
          ListTile(
            title: Text(l10n.campoNotas),
            subtitle: Text(documento.notasAsociadas ?? l10n.sinNotas),
          ),
          if (_tituloEventoVinculado != null)
            ListTile(
              title: Text(l10n.vinculadoAlEventoLabel),
              subtitle: Text(_tituloEventoVinculado!),
            ),
          const Divider(height: 32),
          ListTile(
            leading: Icon(
              documento.fileExtension == 'pdf'
                  ? Icons.picture_as_pdf
                  : Icons.fullscreen,
            ),
            title: Text(
              documento.fileExtension == 'pdf'
                  ? l10n.abrirDocumentoLabel
                  : l10n.verPantallaCompletaLabel,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _abrirArchivo(documento),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(l10n.editarDocumentoLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FormularioDocumentoScreen(
                    mascotaId: documento.mascotaId,
                    documentoExistente: documento,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text(
              l10n.eliminarDocumentoTitulo,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => _eliminarDocumento(documento),
          ),
        ],
      ),
    );
  }
}
