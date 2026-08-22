import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:patas_al_dia/data/models/mascota_extraviada_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class MascotaExtraviadaRepository {
  // El módulo Mapa es el único que necesita una sesión de Supabase Auth
  // (aunque sea anónima) — el resto de la app funciona 100% offline sin
  // tocar Supabase para nada. Por eso la sesión se crea recién acá, cuando
  // hace falta, no al arrancar la app. Si ya existe una sesión (de una
  // publicación anterior), se reutiliza en vez de crear una nueva.
  Future<String> obtenerUsuarioIdSupabase() async {
    final client = Supabase.instance.client;
    final sesionActual = client.auth.currentSession;
    if (sesionActual != null) {
      return sesionActual.user.id;
    }
    final respuesta = await client.auth.signInAnonymously();
    return respuesta.user!.id;
  }

  // Sube la foto obligatoria del reporte a Supabase Storage (bucket
  // fotos_reportes, ver TablaMaestraAppVetMovil1.sql) y devuelve su URL
  // pública — la lectura del bucket es pública, así que esta URL sirve tal
  // cual para mostrar la imagen sin volver a autenticarse. La ruta dentro
  // del bucket (`usuarioId/reporteId.ext`) no tiene ningún efecto sobre
  // permisos (la política de subida solo exige estar autenticado, no
  // valida la ruta) — es simplemente para mantener las fotos ordenadas por
  // usuario y que el nombre de archivo no choque entre reportes distintos.
  Future<String> subirFoto({
    required String usuarioId,
    required String reporteId,
    required String rutaLocal,
  }) async {
    final client = Supabase.instance.client;
    final extension = rutaLocal.split('.').last;
    final rutaStorage = '$usuarioId/$reporteId.$extension';
    await client.storage
        .from('fotos_reportes')
        .upload(rutaStorage, File(rutaLocal));
    return client.storage.from('fotos_reportes').getPublicUrl(rutaStorage);
  }

  Future<MascotaExtraviadaModel> crearReporte(
    MascotaExtraviadaModel reporte,
  ) async {
    final client = Supabase.instance.client;

    await client.from('mascotas_extraviadas').insert(reporte.toMap());

    return reporte;
  }

  Future<List<MascotaExtraviadaModel>> obtenerReportesActivos() async {
    final client = Supabase.instance.client;
    final maps = await client
        .from('mascotas_extraviadas')
        .select()
        .eq('resuelto', false)
        .order('fecha_publicacion', ascending: false);

    return maps.map(MascotaExtraviadaModel.fromMap).toList();
  }

  Future<int> actualizarReporte(MascotaExtraviadaModel reporte) async {
    final client = Supabase.instance.client;

    final filasActualizadas = await client
        .from('mascotas_extraviadas')
        .update(reporte.toMap())
        .eq('id', reporte.id)
        .select();

    return filasActualizadas.length;
  }

  // Recibe el reporte completo, no solo el id — necesita `mascotaFotoUrl`
  // para poder borrar también la foto del bucket `fotos_reportes` (2026-08-20,
  // ver decisiones_arquitectura.md). Antes de esto, borrar un reporte solo
  // borraba la fila de la base; la foto quedaba huérfana en Storage para
  // siempre, ocupando espacio sin que nada la use.
  //
  // El borrado de la foto es "best effort": si falla (sin conexión, foto ya
  // borrada, etc.) no bloquea el borrado del reporte en sí — es la acción
  // principal que el usuario pidió, la limpieza del bucket es secundaria.
  Future<void> eliminarReporte(MascotaExtraviadaModel reporte) async {
    final client = Supabase.instance.client;
    if (reporte.mascotaFotoUrl != null) {
      try {
        final extension = reporte.mascotaFotoUrl!.split('.').last;
        final rutaStorage = '${reporte.usuarioId}/${reporte.id}.$extension';
        await client.storage.from('fotos_reportes').remove([rutaStorage]);
      } catch (e) {
        debugPrint('DEBUG eliminarReporte: no se pudo borrar la foto del bucket: $e');
      }
    }
    await client.from('mascotas_extraviadas').delete().eq('id', reporte.id);
  }

  // Sin motivo de texto libre (decisión del usuario) — solo registra "quién
  // denunció qué reporte". `unique (reporte_id, usuario_id)` en la base
  // evita que el mismo usuario denuncie el mismo reporte más de una vez;
  // acá se ignora silenciosamente un intento repetido (código '23505',
  // violación de restricción única en Postgres) en vez de mostrar un error
  // — para quien denuncia, el resultado ya deseado (que quede denunciado)
  // se cumple igual, no hace falta que se entere de si era la primera vez.
  Future<void> denunciarReporte(String reporteId) async {
    final client = Supabase.instance.client;
    final usuarioId = await obtenerUsuarioIdSupabase();
    try {
      await client.from('denuncias_reportes').insert({
        'id': const Uuid().v4(),
        'reporte_id': reporteId,
        'usuario_id': usuarioId,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') {
        rethrow;
      }
    }
  }
}
