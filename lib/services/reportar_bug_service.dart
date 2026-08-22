import 'package:supabase_flutter/supabase_flutter.dart';

/// Envía un reporte de bug al correo del desarrollador vía la Edge Function
/// `reportar-bug` (ver decisiones_arquitectura.md). Sin sesión/JWT — un
/// usuario invitado también tiene que poder reportar un bug, coherente con
/// que ninguna función core de la app exige registro.
class ReportarBugService {
  Future<void> enviarReporte({
    required String descripcion,
    String? imagenBase64,
    String? imagenNombre,
  }) async {
    await Supabase.instance.client.functions.invoke(
      'reportar-bug',
      body: {
        'descripcion': descripcion,
        'imagenBase64': ?imagenBase64,
        'imagenNombre': ?imagenNombre,
      },
    );
  }
}
