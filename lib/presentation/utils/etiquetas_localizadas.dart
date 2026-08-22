import 'package:flutter/material.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';

/// La especie se guarda en la base de datos como texto fijo en español
/// (ej. "Perro"), sin importar el idioma de la app — es un valor interno,
/// no algo que el usuario escribe. Esta función lo traduce solo para
/// mostrarlo en pantalla, según el idioma activo.
///
/// Separada de `especieMostrar` (que exige una `MascotaModel` completa) para
/// que también pueda usarse en pantallas que no tienen una mascota real de
/// por medio — ej. el formulario de reporte de mascota extraviada, cuando
/// el usuario tipea la especie a mano en vez de elegir una mascota
/// registrada. Ver `formularioReporteMascotaExtraviadaScreen.md`.
String especieValorMostrar(
  AppLocalizations l10n,
  String? especie, [
  String? especiePersonalizada,
]) {
  if (especie == 'Otro' && especiePersonalizada != null) {
    return especiePersonalizada;
  }
  final etiquetas = {
    'Perro': l10n.especiePerro,
    'Gato': l10n.especieGato,
    'Conejo': l10n.especieConejo,
    'Hamster': l10n.especieHamster,
    'Cobaya': l10n.especieCobaya,
    'Jerbo': l10n.especieJerbo,
    'Rata': l10n.especieRata,
    'Chinchilla': l10n.especieChinchilla,
    'Erizo': l10n.especieErizo,
    'Pez': l10n.especiePez,
    'Tortuga': l10n.especieTortuga,
    'Hurón': l10n.especieHuron,
    'Ave': l10n.especieAve,
    'Otro': l10n.especieOtro,
  };
  if (especie == null) {
    return l10n.noEspecificada;
  }
  // Un valor no nulo que no está en el mapa es texto libre (ej. una especie
  // "Otro" guardada directo, sin el par especie/especiePersonalizada — ver
  // MascotaExtraviadaModel) — se muestra tal cual, no como "no especificada".
  return etiquetas[especie] ?? especie;
}

/// Fecha y hora corta, en formato `d/M/y H:mm` con hora y minuto rellenados
/// a dos dígitos (ej. "5/3/2026 09:07"). No usa `intl`/`DateFormat` a
/// propósito — no hay nombres de mes ni nada que traducir, un simple string
/// numérico es igual de claro en los tres idiomas de la app.
String fechaHoraCorta(DateTime fecha) {
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '${fecha.day}/${fecha.month}/${fecha.year} $hora:$minuto';
}

// Atajo de especieValorMostrar cuando ya tienes la MascotaModel completa.
String especieMostrar(BuildContext context, MascotaModel mascota) {
  return especieValorMostrar(
    AppLocalizations.of(context),
    mascota.especie,
    mascota.especiePersonalizada,
  );
}

/// Mismo criterio que `especieMostrar`: "Macho"/"Hembra" se guardan fijos
/// en español, se traducen solo para mostrar.
String sexoMostrar(BuildContext context, String? sexo) {
  final l10n = AppLocalizations.of(context);
  if (sexo == 'Macho') {
    return l10n.sexoMacho;
  }
  if (sexo == 'Hembra') {
    return l10n.sexoHembra;
  }
  return l10n.noEspecificado;
}

/// Mismo criterio, para el tipo de evento de agenda (guardado fijo en
/// español; el texto libre de "Otro" nunca se traduce). Mismo patrón que
/// `especieValorMostrar`: si `tipoEvento == 'Otro'` y hay un
/// `tipoEventoPersonalizado`, se muestra ese texto libre tal cual, en vez de
/// la etiqueta genérica "Otro".
String tipoEventoMostrar(
  AppLocalizations l10n,
  String? tipoEvento, [
  String? tipoEventoPersonalizado,
]) {
  if (tipoEvento == 'Otro' && tipoEventoPersonalizado != null) {
    return tipoEventoPersonalizado;
  }
  final etiquetas = {
    'Vacuna': l10n.tipoEventoVacuna,
    'Desparasitación': l10n.tipoEventoDesparasitacion,
    'Peluquería': l10n.tipoEventoPeluqueria,
    'Operación': l10n.tipoEventoOperacion,
    'Control': l10n.tipoEventoControl,
    'Examen': l10n.tipoEventoExamen,
    'Otro': l10n.valorOtro,
  };
  return etiquetas[tipoEvento] ?? l10n.valorOtro;
}

/// Mismo criterio, para el tipo de documento (usado tanto en documentos
/// adjuntos a un evento de agenda como en la sección Documentos).
String tipoDocumentoMostrar(AppLocalizations l10n, String? tipoDocumento) {
  final etiquetas = {
    'Carnet de vacunación': l10n.tipoDocumentoCarnetVacunacion,
    'Receta': l10n.tipoDocumentoReceta,
    'Examen': l10n.tipoDocumentoExamen,
    'Certificado': l10n.tipoDocumentoCertificado,
    'Boleta': l10n.tipoDocumentoBoleta,
    'Otro': l10n.valorOtro,
  };
  return etiquetas[tipoDocumento] ?? l10n.valorOtro;
}

/// Mismo criterio, para la presentación de un medicamento.
String tipoPresentacionMostrar(AppLocalizations l10n, String tipoPresentacion) {
  final etiquetas = {
    'Comprimido': l10n.tipoPresentacionComprimido,
    'Líquido': l10n.tipoPresentacionLiquido,
    'Inyectable': l10n.tipoPresentacionInyectable,
    'Pomada/crema': l10n.tipoPresentacionPomada,
    'Gotas': l10n.tipoPresentacionGotas,
    'Pipeta': l10n.tipoPresentacionPipeta,
    'Otro': l10n.valorOtro,
  };
  return etiquetas[tipoPresentacion] ?? l10n.valorOtro;
}
