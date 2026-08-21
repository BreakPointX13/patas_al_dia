import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Sync (2026-08-20) — directorio local persistente para fotos/documentos
// descargados de otro dispositivo (o copiados al elegirlos, ver
// formulario_mascota_screen.dart/formulario_documento_screen.dart). A
// diferencia de las rutas que da `image_picker`/`file_picker` (caché
// temporal, que en iOS el sistema puede limpiar sola — ver
// pendientes_ios.md, punto 1), `getApplicationDocumentsDirectory()` es un
// directorio que persiste hasta que el usuario desinstale la app.
//
// Mismo esquema de carpetas que la ruta dentro del bucket de Storage
// correspondiente (ver mascota_repository.dart/documento_repository.dart) —
// una sola función arma el nombre de archivo para los dos lados.
class AlmacenamientoLocalService {
  static String nombreArchivo({required String entidadId, required String ext}) =>
      '$entidadId.$ext';

  static Future<String> rutaFotosMascotas(String nombreArchivo) async {
    return _rutaEnCarpeta('fotos_mascotas', nombreArchivo);
  }

  static Future<String> rutaArchivosDocumentos(String nombreArchivo) async {
    return _rutaEnCarpeta('archivos_documentos', nombreArchivo);
  }

  static Future<String> _rutaEnCarpeta(
    String carpeta,
    String nombreArchivo,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final subdir = Directory(p.join(dir.path, carpeta));
    if (!await subdir.exists()) {
      await subdir.create(recursive: true);
    }
    return p.join(subdir.path, nombreArchivo);
  }

  // Copia un archivo recién elegido (ruta de caché de image_picker/
  // file_picker) al directorio persistente. Devuelve la ruta nueva.
  static Future<String> copiarAPersistente({
    required String rutaOrigen,
    required String rutaDestino,
  }) async {
    final archivo = File(rutaOrigen);
    await archivo.copy(rutaDestino);
    return rutaDestino;
  }
}
