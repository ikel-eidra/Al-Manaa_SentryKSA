/// Centralized map style and tile source configuration for MapLibre GL.
///
/// Tile providers (in order of recommendation for immediate use):
///   1. OpenFreeMap — completely free, no API key, no usage limits
///   2. MapTiler free tier — 100K tiles/month, requires key, has satellite
///   3. Self-hosted (martin / tileserver-gl / PMTiles on S3)
///
/// To switch providers later, only this file needs to change.
class MapStyles {
  MapStyles._();

  // ── STREET / DARK STYLES ───────────────────────────────────────────

  /// Dark style optimized for the war room — high contrast, low distraction.
  static const String warRoomDark =
      'https://tiles.openfreemap.org/styles/dark';

  /// Standard street map for civilian app and general reference.
  static const String streets =
      'https://tiles.openfreemap.org/styles/liberty';

  /// Bright style for print/export contexts.
  static const String bright =
      'https://tiles.openfreemap.org/styles/bright';

  // ── SATELLITE / HYBRID ─────────────────────────────────────────────
  // OpenFreeMap does not serve satellite imagery.
  // Uncomment and set your MapTiler key for satellite/hybrid views:
  //
  // static const String satellite =
  //     'https://api.maptiler.com/maps/hybrid/style.json?key=YOUR_MAPTILER_KEY';
  //
  // For now, fallback to the dark style when "satellite" is requested.
  static const String satellite = warRoomDark;

  // ── 3D TERRAIN DEM ─────────────────────────────────────────────────

  /// Terrain elevation tiles for 3D relief rendering.
  static const String terrainDem =
      'https://demotiles.maplibre.org/terrain-tiles/tiles.json';

  /// Terrain exaggeration factor (1.0 = real scale, 1.5 = enhanced).
  static const double terrainExaggeration = 1.5;
}
