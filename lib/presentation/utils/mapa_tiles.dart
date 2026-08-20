import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

// CARTO Basemaps (Positron/Dark Matter) — pareja de estilos pensada para
// verse coherente entre claro y oscuro, gratis y sin API key. Reemplaza a
// los tiles "crudos" de tile.openstreetmap.org (visualmente muy básicos)
// sin salir del criterio de costo cero que ya se usó para elegir
// flutter_map por sobre google_maps_flutter (ver decisiones_arquitectura.md).
String urlTilesSegunTema(BuildContext context) {
  final esOscuro = Theme.of(context).brightness == Brightness.dark;
  return esOscuro
      ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
      : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
}

// Los tiles de CARTO están construidos sobre datos de OpenStreetMap, más el
// estilo propio de CARTO — la política de atribución de ambos exige
// mencionarlos, no solo a OpenStreetMap.
final atribucionMapa = RichAttributionWidget(
  attributions: [
    TextSourceAttribution('© OpenStreetMap contributors', onTap: () {}),
    TextSourceAttribution('© CARTO', onTap: () {}),
  ],
);
