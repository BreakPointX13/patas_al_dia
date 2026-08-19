import 'package:patas_al_dia/data/models/mascota_extraviada_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        .eq('estado', 'perdido')
        .order('fecha_publicacion', ascending: false);

    return maps.map(MascotaExtraviadaModel.fromMap).toList();
  }

  Future<MascotaExtraviadaModel?> obtenerReportePorId(String id) async {
    final client = Supabase.instance.client;
    final map = await client
        .from('mascotas_extraviadas')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (map == null) {
      return null;
    }
    return MascotaExtraviadaModel.fromMap(map);
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

  Future<void> eliminarReporte(String id) async {
    final client = Supabase.instance.client;
    await client.from('mascotas_extraviadas').delete().eq('id', id);
  }
}
