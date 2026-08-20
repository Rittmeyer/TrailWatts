import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The one basemap every map screen uses, so tiles, attribution and cache
/// behaviour stay identical across screens 02a2, 04 and 05.
///
/// Standard OSM tiles are used for development. The OSM Foundation's tile
/// usage policy does not allow a production app to hit tile.openstreetmap.org,
/// so shipping means pointing [urlTemplate] at a paid or self-hosted tile
/// source - the same P0 "map/road data source" decision tracked in
/// DECISIONS_REQUIRED.md.
/// Override at build time:
/// `flutter run --dart-define=TRAILWATT_TILE_URL=https://tiles.internal/{z}/{x}/{y}.png`
const trailwattTileUrl = String.fromEnvironment(
  'TRAILWATT_TILE_URL',
  defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
);

TileLayer trailwattTileLayer({String urlTemplate = trailwattTileUrl}) {
  return TileLayer(
    urlTemplate: urlTemplate,
    userAgentPackageName: 'app.trailwatt',
    maxNativeZoom: 19,
    tileProvider: NetworkTileProvider(),
  );
}

/// Attribution required by the OSM licence whenever OSM tiles are shown.
Widget trailwattAttribution() {
  return const RichAttributionWidget(
    alignment: AttributionAlignment.bottomLeft,
    attributions: [TextSourceAttribution('OpenStreetMap contributors')],
  );
}

/// Shown over a map whenever the drawn path is NOT matched to real roads,
/// so a straight-line estimate is never mistaken for a road-accurate route.
class MapDegradedBanner extends StatelessWidget {
  final String message;

  const MapDegradedBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        border: Border.all(color: const Color(0xFFF0D4B0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: AppColors.warnText),
          const SizedBox(width: 6),
          Expanded(
            child: Text(message,
                style: AppTextStyles.label
                    .copyWith(fontSize: 9, color: AppColors.warnText)),
          ),
        ],
      ),
    );
  }
}
