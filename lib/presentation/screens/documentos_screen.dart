import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/documento_model.dart';
import 'package:patas_al_dia/presentation/screens/detalle_documento_screen.dart';
import 'package:patas_al_dia/presentation/screens/formulario_documento_screen.dart';
import 'package:patas_al_dia/providers/documento_provider.dart';

class DocumentosScreen extends ConsumerStatefulWidget {
  final String mascotaId;
  const DocumentosScreen({super.key, required this.mascotaId});

  @override
  ConsumerState<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends ConsumerState<DocumentosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref
          .read(documentosProvider.notifier)
          .cargarDocumentos(widget.mascotaId),
    );
  }

  void _irAAgregarDocumento() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            FormularioDocumentoScreen(mascotaId: widget.mascotaId),
      ),
    );
  }

  void _abrirDetalle(String documentoId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            DetalleDocumentoScreen(documentoId: documentoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final documentos = ref.watch(documentosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Documentos')),
      body: documentos.isEmpty
          ? const Center(child: Text('Sin documentos adjuntos'))
          : ListView.builder(
              itemCount: documentos.length,
              itemBuilder: (context, index) {
                final documento = documentos[index];
                return _tileDocumento(documento);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irAAgregarDocumento,
        icon: const Icon(Icons.add),
        label: const Text('Agregar documento'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _tileDocumento(DocumentoModel documento) {
    final tipo =
        documento.tipoDocumento == 'Otro' &&
            documento.tipoDocumentoPersonalizado != null
        ? documento.tipoDocumentoPersonalizado!
        : documento.tipoDocumento;

    return Card(
      child: ListTile(
        leading: Icon(
          documento.fileExtension == 'pdf'
              ? Icons.picture_as_pdf
              : Icons.image,
        ),
        title: Text(documento.titulo),
        subtitle: Text(tipo),
        trailing: documento.eventoId == null
            ? null
            : const Icon(Icons.link, size: 18),
        onTap: () => _abrirDetalle(documento.id),
      ),
    );
  }
}
