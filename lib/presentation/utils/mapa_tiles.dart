import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

// CARTO Basemaps (Positron/Dark Matter) — pareja de estilos pensada para
// verse coherente entre claro y oscuro. Reemplaza a los tiles "crudos" de
// tile.openstreetmap.org (visualmente muy básicos) sin salir del criterio
// de costo cero que ya se usó para elegir flutter_map por sobre
// google_maps_flutter (ver decisiones_arquitectura.md).
//
// `?key=...` (2026-09-27): CARTO empezó a exigir una API key hasta para
// este uso gratuito — sin ella, cada tile sale con un watermark grande de
// "API KEY REQUIRED" tapando el mapa. La key en sí no es un secreto (viaja
// en cada request de tile, visible para cualquiera que inspeccione el
// tráfico de la app) — mismo criterio que la anon key de Supabase en
// supabase_config.dart, por eso va como constante acá, no en un .env.
// Plan gratis: 1M tiles/mes (uso comercial) o 5M (no comercial) — de sobra
// para el tamaño actual de la app. Ver decisiones_arquitectura.md.
const _cartoApiKey = 'cb1_3zzg_1_d8e00375eeb097e260802202';

String urlTilesSegunTema(BuildContext context) {
  final esOscuro = Theme.of(context).brightness == Brightness.dark;
  return esOscuro
      ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png?key=$_cartoApiKey'
      : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png?key=$_cartoApiKey';
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
