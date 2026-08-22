import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';
import 'package:patas_al_dia/presentation/screens/agenda_screen.dart';
import 'package:patas_al_dia/presentation/screens/documentos_screen.dart';
import 'package:patas_al_dia/presentation/screens/formulario_mascota_screen.dart';
import 'package:patas_al_dia/presentation/screens/formulario_reporte_mascota_extraviada_screen.dart';
import 'package:patas_al_dia/presentation/utils/etiquetas_localizadas.dart';
import 'package:patas_al_dia/presentation/widgets/dialogo_confirmacion.dart';
import 'package:patas_al_dia/presentation/widgets/separador_seccion_ficha.dart';
import 'package:patas_al_dia/presentation/widgets/tarjeta_clara.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';

// Confirma y borra la mascota (soft-delete, con cascada a sus datos).
Future<void> _eliminarMascota(
  BuildContext context,
  WidgetRef ref,
  MascotaModel mascota,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmar = await confirmarAccion(
    context,
    titulo: l10n.eliminarMascotaTitulo,
    contenido: l10n.eliminarMascotaContenido(mascota.nombre),
    textoConfirmar: l10n.accionEliminar,
    destructivo: true,
  );

  if (confirmar != true || !context.mounted) {
    return;
  }

  await ref.read(mascotasProvider.notifier).eliminarMascota(mascota.id);

  if (context.mounted) {
    Navigator.of(context).pop();
  }
}

// Ficha completa de una mascota: datos, accesos a agenda/documentos y reporte de pérdida.
class DetalleMascotaScreen extends ConsumerWidget {
  final String mascotaId;
  const DetalleMascotaScreen({super.key, required this.mascotaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mascotas = ref.watch(mascotasProvider);
    MascotaModel? mascotaEncontrada;
    for (final m in mascotas) {
      if (m.id == mascotaId) {
        mascotaEncontrada = m;
        break;
      }
    }
    if (mascotaEncontrada == null) {
      // Puede pasar si la mascota se borró (o se cerró sesión) justo
      // mientras esta pantalla seguía abierta — no hay nada que mostrar.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mascota = mascotaEncontrada;

    final grupoMascota = [
      ListTile(
        title: Text(l10n.campoEspecie),
        subtitle: Text(especieMostrar(context, mascota)),
      ),
      ListTile(
        title: Text(l10n.campoRaza),
        subtitle: Text(mascota.raza ?? l10n.noEspecificada),
      ),
    ];

    final grupoIdentificacion = [
      ListTile(
        title: Text(l10n.rutMascotaLabel),
        subtitle: Text(mascota.rutMascota ?? l10n.noEspecificado),
      ),
      ListTile(
        title: Text(l10n.campoNumeroChip),
        subtitle: Text(mascota.numeroChip ?? l10n.noEspecificado),
      ),
    ];

    final grupoDatos = [
      ListTile(
        title: Text(l10n.campoSexo),
        subtitle: Text(sexoMostrar(context, mascota.sexo)),
      ),
      ListTile(
        title: Text(l10n.campoColores),
        subtitle: Text(mascota.colores ?? l10n.noEspecificado),
      ),
      ListTile(
        title: Text(l10n.pesoLabel),
        subtitle: Text(
          mascota.pesoActual == null
              ? l10n.noEspecificado
              : '${mascota.pesoActual} kg',
        ),
      ),
      ListTile(
        title: Text(l10n.campoEsterilizado),
        subtitle: Text(mascota.esterilizado ? l10n.valorSi : l10n.valorNo),
      ),
      ListTile(
        title: Text(
          mascota.fechaEstimada
              ? l10n.edadEstimadaLabel
              : l10n.fechaNacimientoLabel,
        ),
        subtitle: Text(
          mascota.fechaNacimiento == null
              ? l10n.noEspecificada
              : mascota.fechaEstimada
              ? l10n.aniosCantidad(
                  DateTime.now().year - mascota.fechaNacimiento!.year,
                )
              : '${mascota.fechaNacimiento!.day}/'
                    '${mascota.fechaNacimiento!.month}/'
                    '${mascota.fechaNacimiento!.year}',
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(mascota.nombre)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 56,
              backgroundImage: mascota.fotoUrl != null
                  ? FileImage(File(mascota.fotoUrl!))
                  : null,
              child: mascota.fotoUrl == null
                  ? const Icon(Icons.pets, size: 56)
                  : null,
            ),
          ),
          SeparadorSeccionFicha.mascota(),
          for (final tile in grupoMascota) TarjetaClara(child: tile),
          SeparadorSeccionFicha.identificacion(),
          for (final tile in grupoIdentificacion) TarjetaClara(child: tile),
          SeparadorSeccionFicha.datos(),
          for (final tile in grupoDatos) TarjetaClara(child: tile),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(l10n.accionEditar),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      FormularioMascotaScreen(mascotaExistente: mascota),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_note),
            title: Text(l10n.accionAgenda),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      AgendaScreen(mascotaIdInicial: mascotaId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(l10n.accionDocumentos),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DocumentosScreen(mascotaId: mascotaId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_outlined),
            title: Text(l10n.reportarMascotaPerdidaLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      FormularioReporteMascotaExtraviadaScreen(
                        mascota: mascota,
                        tipo: 'perdido',
                      ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text(
              l10n.eliminarMascotaTitulo,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => _eliminarMascota(context, ref, mascota),
          ),
        ],
      ),
    );
  }
}
