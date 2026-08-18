import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/documento_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/detalle_documento_screen.dart';
import 'package:patas_al_dia/presentation/screens/formulario_documento_screen.dart';
import 'package:patas_al_dia/presentation/utils/etiquetas_localizadas.dart';
import 'package:patas_al_dia/presentation/widgets/separador_seccion_ficha.dart';
import 'package:patas_al_dia/presentation/widgets/tarjeta_clara.dart';
import 'package:patas_al_dia/providers/documento_provider.dart';

// Igual que en `SeparadorSeccionFicha`, el ícono de cada separador queda
// fijo (no necesita variante oscura); el texto que lo acompaña sí, porque va
// directo sobre el fondo de la pantalla, sin tarjeta detrás.
Color _colorTextoSeparador(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFFFF7EC)
    : const Color(0xFF7A4A22);

IconData _iconoTipoDocumento(String tipo) {
  switch (tipo) {
    case 'Carnet de vacunación':
      return Icons.vaccines;
    case 'Receta':
      return Icons.medication;
    case 'Examen':
      return Icons.biotech;
    case 'Certificado':
      return Icons.verified;
    case 'Boleta':
      return Icons.receipt_long;
    default:
      return Icons.folder_open;
  }
}

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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accionDocumentos)),
      body: documentos.isEmpty
          ? Center(child: Text(l10n.sinDocumentosAdjuntos))
          : ListView(
              children: [
                for (final tipo in tiposDocumentoDisponibles)
                  ..._seccionTipo(
                    context,
                    l10n,
                    tipo,
                    documentos.where((d) => d.tipoDocumento == tipo).toList(),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irAAgregarDocumento,
        icon: const Icon(Icons.add),
        label: Text(l10n.agregarDocumentoLabel),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  List<Widget> _seccionTipo(
    BuildContext context,
    AppLocalizations l10n,
    String tipo,
    List<DocumentoModel> documentosDelTipo,
  ) {
    if (documentosDelTipo.isEmpty) {
      return const [];
    }
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SeparadorSeccionFicha(
          icono: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconoTipoDocumento(tipo),
                color: const Color(0xFFD06D1F),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                tipoDocumentoMostrar(l10n, tipo),
                style: TextStyle(
                  color: _colorTextoSeparador(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      for (final documento in documentosDelTipo) _tileDocumento(l10n, documento),
    ];
  }

  Widget _tileDocumento(AppLocalizations l10n, DocumentoModel documento) {
    final tipo =
        documento.tipoDocumento == 'Otro' &&
            documento.tipoDocumentoPersonalizado != null
        ? documento.tipoDocumentoPersonalizado!
        : tipoDocumentoMostrar(l10n, documento.tipoDocumento);

    return TarjetaClara(
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
