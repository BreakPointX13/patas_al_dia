import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_al_dia/data/models/agenda_evento_model.dart';
import 'package:patas_al_dia/data/models/documento_model.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/data/models/medicamento_evento_model.dart';
import 'package:patas_al_dia/providers/agenda_evento_provider.dart';
import 'package:patas_al_dia/providers/documento_provider.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';
import 'package:patas_al_dia/providers/medicamento_evento_provider.dart';
import 'package:patas_al_dia/providers/sync_provider.dart';
import 'package:patas_al_dia/providers/usuario_provider.dart';
import 'package:patas_al_dia/services/almacenamiento_local_service.dart';

// Sync (Fase 6 de Supabase, 2026-08-20) — dos sentidos, automático mas no
// instantáneo (ver main.dart para los disparadores), solo para usuarios
// registrados. Gana el cambio más reciente en un conflicto (por
// `actualizado_en`), sin merge manual. Ver decisiones_arquitectura.md.
//
// Orden de las 4 entidades — Mascota → AgendaEvento → MedicamentoEvento →
// Documento — es el mismo tanto al empujar como al traer: es el orden
// seguro para los FK del schema (un hijo nunca llega antes que su padre).
class SyncService {
  SyncService(this._ref);

  final Ref _ref;

  // Punto de entrada público: valida guardas y evita corridas superpuestas.
  Future<void> sincronizar() async {
    final usuario = _ref.read(usuarioProvider);
    if (usuario == null || usuario.esInvitado) {
      return;
    }
    if (_ref.read(sincronizandoProvider)) {
      return; // ya hay una corrida en curso
    }

    final bandera = _ref.read(sincronizandoProvider.notifier);
    bandera.establecer(true);
    try {
      await _sincronizarInterno(usuario.id, usuario.ultimaSincronizacion);
    } finally {
      bandera.establecer(false);
    }
  }

  Future<void> _sincronizarInterno(String usuarioId, DateTime? desde) async {
    final client = Supabase.instance.client;

    // Paso 0, obligatorio: satisface el FK de `mascotas.usuario_id` hacia
    // `public.usuarios` — tabla que Login real dejó sin poblar a propósito
    // (ver decisiones_arquitectura.md, entrada del 2026-08-20). Upsert
    // parcial: no toca tema/idioma/escala_texto, no es sincronizar
    // preferencias, solo lo mínimo para que el FK no rechace la mascota.
    try {
      final usuario = _ref.read(usuarioProvider);
      await client.from('usuarios').upsert({
        'id': usuarioId,
        'email': usuario?.email,
        'es_invitado': false,
      });
    } catch (e) {
      debugPrint('DEBUG sync: no se pudo preparar usuarios, se aborta: $e');
      return;
    }

    var huboError = false;
    try {
      await _sincronizarMascotas(usuarioId, desde);
    } catch (e) {
      debugPrint('DEBUG sync mascotas: $e');
      huboError = true;
    }
    try {
      await _sincronizarAgendaEventos(usuarioId, desde);
    } catch (e) {
      debugPrint('DEBUG sync agenda_eventos: $e');
      huboError = true;
    }
    try {
      await _sincronizarMedicamentosEvento(usuarioId, desde);
    } catch (e) {
      debugPrint('DEBUG sync medicamentos_evento: $e');
      huboError = true;
    }
    try {
      await _sincronizarDocumentos(usuarioId, desde);
    } catch (e) {
      debugPrint('DEBUG sync documentos: $e');
      huboError = true;
    }

    // Si algo falló, no avanza el reloj — la ventana completa se reintenta
    // la próxima vez (seguro: upsert + gana-el-más-reciente son idempotentes).
    if (huboError) {
      return;
    }

    final usuarioActual = _ref.read(usuarioProvider);
    if (usuarioActual == null) {
      return;
    }
    await _ref
        .read(usuarioProvider.notifier)
        .actualizarUsuario(
          usuarioActual.copyWith(ultimaSincronizacion: DateTime.now().toUtc()),
        );

    // HomeScreen/AgendaScreen viven en un IndexedStack (se construyen una
    // sola vez, ver navegacion_principal_screen.dart) y no se refrescan
    // solas — sin esto, un cambio traído por sync quedaría invisible hasta
    // reiniciar la app. DocumentosScreen/DetalleAgendaEventoScreen no lo
    // necesitan: se instancian de nuevo cada vez que se navega a ellas.
    await _ref.read(mascotasProvider.notifier).cargarMascotas(usuarioId);
    final mascotaIds = _ref
        .read(mascotasProvider)
        .map((m) => m.id)
        .toList();
    await _ref
        .read(agendaEventosProvider.notifier)
        .cargarAgendaEventosDeMascotas(mascotaIds);
  }

  // --- Mascota ---

  Future<void> _sincronizarMascotas(String usuarioId, DateTime? desde) async {
    final client = Supabase.instance.client;
    final repo = _ref.read(mascotaRepositoryProvider);

    final locales = await repo.obtenerPendientesDePush(usuarioId);
    final aEmpujar = <MascotaModel>[];
    for (var m in locales) {
      // Sube la foto una sola vez (si hay foto local y todavía no se subió
      // nunca) — no en cada sync, para no volver a subir el mismo archivo
      // solo porque se editó otro campo de la mascota. Una foto
      // reemplazada más tarde no se vuelve a detectar automáticamente,
      // limitación conocida y aceptada por simplicidad.
      if (m.fotoUrl != null && m.fotoRutaNube == null) {
        try {
          final ruta = await repo.subirFoto(
            usuarioId: usuarioId,
            mascotaId: m.id,
            rutaLocal: m.fotoUrl!,
          );
          m = m.copyWith(fotoRutaNube: ruta);
          await repo.actualizarFotoRutaNube(m.id, ruta);
        } catch (e) {
          debugPrint('DEBUG sync: no se pudo subir foto de mascota ${m.id}: $e');
        }
      }
      aEmpujar.add(m);
    }
    if (aEmpujar.isNotEmpty) {
      final payload = aEmpujar.map((m) {
        final mapa = Map<String, dynamic>.from(m.toMap());
        // Local-only, nunca viaja — ver mascota_model.dart.
        mapa.remove('foto_url');
        // Postgres espera boolean real, no el 0/1 que usa SQLite.
        mapa['esterilizado'] = m.esterilizado;
        mapa['fecha_estimada'] = m.fechaEstimada;
        mapa['eliminado'] = m.eliminado;
        return mapa;
      }).toList();
      await client.from('mascotas').upsert(payload);
      await repo.marcarComoSincronizadas(aEmpujar.map((m) => m.id).toList());
    }

    final remotas = desde == null
        ? await client.from('mascotas').select().eq('usuario_id', usuarioId)
        : await client
              .from('mascotas')
              .select()
              .eq('usuario_id', usuarioId)
              .gt('actualizado_en', desde.toIso8601String());

    for (final fila in remotas) {
      final remoto = MascotaModel.fromMap(fila);
      final local = await repo.obtenerMascotaPorId(remoto.id);
      if (_ganaElLocal(local?.actualizadoEn, remoto.actualizadoEn)) {
        continue;
      }
      // foto_url es local-only — se preserva la del dispositivo si ya
      // existe; si no hay ninguna todavía y la fila remota trae una foto
      // subida, se descarga acá.
      var fotoUrlLocal = local?.fotoUrl;
      if (remoto.fotoRutaNube != null && fotoUrlLocal == null) {
        try {
          final bytes = await repo.descargarFoto(remoto.fotoRutaNube!);
          final ext = remoto.fotoRutaNube!.split('.').last;
          final nombre = AlmacenamientoLocalService.nombreArchivo(
            entidadId: remoto.id,
            ext: ext,
          );
          final rutaLocal = await AlmacenamientoLocalService.rutaFotosMascotas(
            nombre,
          );
          await File(rutaLocal).writeAsBytes(bytes);
          fotoUrlLocal = rutaLocal;
        } catch (e) {
          debugPrint(
            'DEBUG sync: no se pudo descargar foto de mascota ${remoto.id}: $e',
          );
        }
      }
      await repo.guardarDesdeSync(remoto.copyWith(fotoUrl: fotoUrlLocal));
    }
  }

  // --- AgendaEvento ---

  Future<void> _sincronizarAgendaEventos(
    String usuarioId,
    DateTime? desde,
  ) async {
    final client = Supabase.instance.client;
    final repo = _ref.read(agendaEventoRepositoryProvider);

    final locales = await repo.obtenerPendientesDePush(usuarioId);
    if (locales.isNotEmpty) {
      final payload = locales.map((e) {
        final mapa = Map<String, dynamic>.from(e.toMap());
        mapa['eliminado'] = e.eliminado;
        return mapa;
      }).toList();
      await client.from('agenda_eventos').upsert(payload);
      await repo.marcarComoSincronizadas(locales.map((e) => e.id).toList());
    }

    // Sin filtro por usuario acá — RLS de Supabase ya solo devuelve lo que
    // es del usuario actual (vía join a mascotas), no hay usuario_id
    // directo en esta tabla.
    final remotas = desde == null
        ? await client.from('agenda_eventos').select()
        : await client
              .from('agenda_eventos')
              .select()
              .gt('actualizado_en', desde.toIso8601String());

    for (final fila in remotas) {
      final remoto = AgendaEventoModel.fromMap(fila);
      final local = await repo.obtenerAgendaEventoPorId(remoto.id);
      if (_ganaElLocal(local?.actualizadoEn, remoto.actualizadoEn)) {
        continue;
      }
      await repo.guardarDesdeSync(remoto);
    }
  }

  // --- MedicamentoEvento ---

  Future<void> _sincronizarMedicamentosEvento(
    String usuarioId,
    DateTime? desde,
  ) async {
    final client = Supabase.instance.client;
    final repo = _ref.read(medicamentoEventoRepositoryProvider);

    final locales = await repo.obtenerPendientesDePush(usuarioId);
    if (locales.isNotEmpty) {
      final payload = locales.map((m) {
        final mapa = Map<String, dynamic>.from(m.toMap());
        mapa['eliminado'] = m.eliminado;
        return mapa;
      }).toList();
      await client.from('medicamentos_evento').upsert(payload);
      await repo.marcarComoSincronizadas(locales.map((m) => m.id).toList());
    }

    final remotas = desde == null
        ? await client.from('medicamentos_evento').select()
        : await client
              .from('medicamentos_evento')
              .select()
              .gt('actualizado_en', desde.toIso8601String());

    for (final fila in remotas) {
      final remoto = MedicamentoEventoModel.fromMap(fila);
      // Mismo criterio que las otras 3 entidades (2026-08-21, corrige un
      // hallazgo real — ver decisiones_arquitectura.md): sin esta
      // comparación, un medicamento editado localmente y todavía sin subir
      // se perdía sin aviso ante un pull, sin ninguna forma de reintentar.
      final local = await repo.obtenerMedicamentoEventoPorId(remoto.id);
      if (_ganaElLocal(local?.actualizadoEn, remoto.actualizadoEn)) {
        continue;
      }
      await repo.guardarDesdeSync(remoto);
    }
  }

  // --- Documento ---

  Future<void> _sincronizarDocumentos(
    String usuarioId,
    DateTime? desde,
  ) async {
    final client = Supabase.instance.client;
    final repo = _ref.read(documentoRepositoryProvider);

    final locales = await repo.obtenerPendientesDePush(usuarioId);
    final aEmpujar = <DocumentoModel>[];
    for (var d in locales) {
      // Sube el archivo una sola vez — mismo criterio y misma limitación
      // conocida que la foto de mascota, ver _sincronizarMascotas.
      if (d.filePath != null && d.archivoRutaNube == null) {
        try {
          final ruta = await repo.subirArchivo(
            usuarioId: usuarioId,
            documentoId: d.id,
            rutaLocal: d.filePath!,
          );
          d = d.copyWith(archivoRutaNube: ruta);
          await repo.actualizarArchivoRutaNube(d.id, ruta);
        } catch (e) {
          debugPrint(
            'DEBUG sync: no se pudo subir archivo de documento ${d.id}: $e',
          );
        }
      }
      aEmpujar.add(d);
    }
    if (aEmpujar.isNotEmpty) {
      final payload = aEmpujar.map((d) {
        final mapa = Map<String, dynamic>.from(d.toMap());
        // Local-only, nunca viaja — ver documento_model.dart.
        mapa.remove('file_path');
        mapa['recordatorio_vencimiento'] = d.recordatorioVencimiento;
        mapa['eliminado'] = d.eliminado;
        return mapa;
      }).toList();
      await client.from('documentos').upsert(payload);
      await repo.marcarComoSincronizadas(aEmpujar.map((d) => d.id).toList());
    }

    final remotas = desde == null
        ? await client.from('documentos').select()
        : await client
              .from('documentos')
              .select()
              .gt('actualizado_en', desde.toIso8601String());

    for (final fila in remotas) {
      final remoto = DocumentoModel.fromMap(fila);
      final local = await repo.obtenerDocumentoPorId(remoto.id);
      if (_ganaElLocal(local?.actualizadoEn, remoto.actualizadoEn)) {
        continue;
      }
      // filePath es local-only — se preserva el del dispositivo si ya
      // existe; si no, y la fila remota trae un archivo subido, se
      // descarga acá.
      var filePathLocal = local?.filePath;
      if (remoto.archivoRutaNube != null && filePathLocal == null) {
        try {
          final bytes = await repo.descargarArchivo(remoto.archivoRutaNube!);
          final ext = remoto.archivoRutaNube!.split('.').last;
          final nombre = AlmacenamientoLocalService.nombreArchivo(
            entidadId: remoto.id,
            ext: ext,
          );
          final rutaLocal =
              await AlmacenamientoLocalService.rutaArchivosDocumentos(
                nombre,
              );
          await File(rutaLocal).writeAsBytes(bytes);
          filePathLocal = rutaLocal;
        } catch (e) {
          debugPrint(
            'DEBUG sync: no se pudo descargar archivo de documento ${remoto.id}: $e',
          );
        }
      }
      await repo.guardarDesdeSync(remoto.copyWith(filePath: filePathLocal));
    }
  }

  // Gana el cambio más reciente: si el local es igual o más nuevo que el
  // remoto, no hay nada que pisar. `localEn == null` (fila nueva, nunca
  // vista acá) siempre pierde frente a cualquier remoto.
  bool _ganaElLocal(DateTime? localEn, DateTime? remotoEn) {
    if (localEn == null || remotoEn == null) {
      return false;
    }
    return !remotoEn.isAfter(localEn);
  }
}
