import 'package:flutter/material.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';

/// La especie se guarda en la base de datos como texto fijo en español
/// (ej. "Perro"), sin importar el idioma de la app — es un valor interno,
/// no algo que el usuario escribe. Esta función lo traduce solo para
/// mostrarlo en pantalla, según el idioma activo.
String especieMostrar(BuildContext context, MascotaModel mascota) {
  final l10n = AppLocalizations.of(context);
  if (mascota.especie == 'Otro' && mascota.especiePersonalizada != null) {
    return mascota.especiePersonalizada!;
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
  return etiquetas[mascota.especie] ?? l10n.noEspecificada;
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
/// español; el texto libre de "Otro" nunca se traduce).
String tipoEventoMostrar(AppLocalizations l10n, String? tipoEvento) {
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
