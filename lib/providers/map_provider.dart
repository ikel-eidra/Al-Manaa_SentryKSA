import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../config/map_styles.dart';
import '../models/strategic_asset.dart';
import '../models/threat_event.dart';
import '../models/impact_report.dart';
import '../engines/threat_triangulation_engine.dart';

/// State provider for GIS heatmap, threat trajectories, and map interactions.
///
/// Uses MapLibre GL's style-based rendering: GeoJSON sources + style layers.
/// Layers persist on the map; only the source data changes on refresh.
class MapProvider extends ChangeNotifier {
  MaplibreMapController? _mapController;
  String _currentStyle = MapStyles.warRoomDark;
  double _zoom = 5.5;
  LatLng _center = const LatLng(24.7, 46.6); // KSA center
  String? _selectedAssetId;

  // Layer visibility toggles
  bool _showHeatZones = true;
  bool _showThreatArcs = true;
  bool _showImpactSites = true;
  bool _showAssetLabels = true;
  int _heatZoneFilter = 0; // 0 = all, 1/2/3 = specific level

  bool _sourcesInitialized = false;

  // Getters
  MaplibreMapController? get mapController => _mapController;
  String get currentStyle => _currentStyle;
  double get zoom => _zoom;
  LatLng get center => _center;
  String? get selectedAssetId => _selectedAssetId;
  bool get showHeatZones => _showHeatZones;
  bool get showThreatArcs => _showThreatArcs;
  bool get showImpactSites => _showImpactSites;
  bool get showAssetLabels => _showAssetLabels;

  /// Called when MapLibreMap is created. Sets up all GeoJSON sources and layers.
  Future<void> setMapController(MaplibreMapController controller) async {
    _mapController = controller;
    notifyListeners();
  }

  /// Initialize all GeoJSON sources and style layers on the map.
  /// Must be called after style is loaded (from onStyleLoadedCallback).
  Future<void> initializeLayers() async {
    final c = _mapController;
    if (c == null) return;

    _sourcesInitialized = false;

    // ── Register marker icons ──────────────────────────────────────
    await _registerMarkerIcons(c);

    // ── Add empty GeoJSON sources ──────────────────────────────────
    const empty = <String, dynamic>{
      'type': 'FeatureCollection',
      'features': [],
    };
    await c.addGeoJsonSource('heat-zones-source', empty);
    await c.addGeoJsonSource('impact-sites-source', empty);
    await c.addGeoJsonSource('threat-circles-source', empty);
    await c.addGeoJsonSource('trajectories-source', empty);
    await c.addGeoJsonSource('asset-markers-source', empty);
    await c.addGeoJsonSource('threat-markers-source', empty);

    // ── Add layers in Z-order (bottom → top) ───────────────────────

    // Layer 1-2: Heat zone fills
    await c.addFillLayer('heat-zones-source', 'heat-zones-fill', FillLayerProperties(
      fillColor: ['get', 'color'],
      fillOpacity: ['get', 'opacity'],
    ));
    await c.addLineLayer('heat-zones-source', 'heat-zones-stroke', LineLayerProperties(
      lineColor: ['get', 'strokeColor'],
      lineWidth: ['get', 'strokeWidth'],
    ));

    // Layer 3: Impact site fills (purple/magenta economic blast radii)
    await c.addFillLayer('impact-sites-source', 'impact-sites-fill', FillLayerProperties(
      fillColor: ['get', 'color'],
      fillOpacity: ['get', 'opacity'],
    ));
    await c.addLineLayer('impact-sites-source', 'impact-sites-stroke', LineLayerProperties(
      lineColor: ['get', 'strokeColor'],
      lineWidth: 2,
      lineOpacity: 0.53,
    ));

    // Layer 4: Threat event origin circles
    await c.addCircleLayer('threat-circles-source', 'threat-circles-layer', CircleLayerProperties(
      circleRadius: ['get', 'radius'],
      circleColor: ['get', 'color'],
      circleOpacity: ['get', 'opacity'],
      circleStrokeColor: ['get', 'strokeColor'],
      circleStrokeWidth: ['get', 'strokeWidth'],
    ));

    // Layer 5: Trajectory polylines (dashed arcs from origin → target)
    await c.addLineLayer('trajectories-source', 'trajectories-layer', LineLayerProperties(
      lineColor: ['get', 'color'],
      lineWidth: ['get', 'width'],
      lineDasharray: [20.0, 10.0],
    ));

    // Layer 6: Asset markers (symbol layer with colored icons)
    await c.addSymbolLayer('asset-markers-source', 'asset-markers-layer', SymbolLayerProperties(
      iconImage: ['get', 'icon'],
      iconSize: 1.0,
      iconAllowOverlap: true,
      symbolSortKey: ['get', 'zIndex'],
      textField: ['get', 'label'],
      textSize: 10,
      textOffset: ['literal', [0.0, 1.8]],
      textColor: '#FFFFFF',
      textHaloColor: '#000000',
      textHaloWidth: 1,
    ));

    // Layer 7: Threat event markers
    await c.addSymbolLayer('threat-markers-source', 'threat-markers-layer', SymbolLayerProperties(
      iconImage: ['get', 'icon'],
      iconSize: 1.0,
      iconAllowOverlap: true,
      iconOpacity: ['get', 'opacity'],
      symbolSortKey: ['get', 'zIndex'],
    ));

    // ── 3D buildings (rendered at high zoom from base style) ───────
    try {
      await c.addFillExtrusionLayer('composite', '3d-buildings', FillExtrusionLayerProperties(
        fillExtrusionColor: '#1a1a2e',
        fillExtrusionHeight: ['get', 'height'],
        fillExtrusionBase: ['get', 'min_height'],
        fillExtrusionOpacity: 0.6,
      ), sourceLayer: 'building');
    } catch (_) {
      // Base style may not include building source layer — safe to skip
    }

    _sourcesInitialized = true;
    notifyListeners();
  }

  /// Register colored marker icons for asset and threat symbols.
  Future<void> _registerMarkerIcons(MaplibreMapController c) async {
    const markerColors = <String, Color>{
      'marker-red': Color(0xFFF44336),
      'marker-orange': Color(0xFFFF9800),
      'marker-yellow': Color(0xFFFFEB3B),
      'marker-rose': Color(0xFFE91E63),
      'marker-violet': Color(0xFF9C27B0),
      'marker-cyan': Color(0xFF00BCD4),
    };

    for (final entry in markerColors.entries) {
      final bytes = await _renderMarkerIcon(entry.value);
      await c.addImage(entry.key, bytes);
    }
  }

  /// Render a colored circle marker to PNG bytes for use as a symbol icon.
  Future<Uint8List> _renderMarkerIcon(Color color, {int size = 48}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 2;

    // Filled circle
    canvas.drawCircle(center, radius, Paint()..color = color);
    // White border
    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  STYLE & CAMERA
  // ═══════════════════════════════════════════════════════════════════

  /// Switch between map styles (dark, streets, satellite).
  void setMapStyle(String styleUrl) {
    _currentStyle = styleUrl;
    // Style change will trigger onStyleLoadedCallback → re-initialize layers
    notifyListeners();
  }

  /// Toggle between dark (war room) and street (reference) styles.
  void toggleMapStyle() {
    setMapStyle(
      _currentStyle == MapStyles.warRoomDark
          ? MapStyles.streets
          : MapStyles.warRoomDark,
    );
  }

  void selectAsset(String? assetId) {
    _selectedAssetId = assetId;
    notifyListeners();
  }

  /// Fly to a specific asset on the map.
  Future<void> focusAsset(StrategicAsset asset) async {
    _selectedAssetId = asset.id;
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(asset.latitude, asset.longitude),
        12.0,
      ),
    );
    notifyListeners();
  }

  /// Reset camera to full KSA view.
  Future<void> resetView() async {
    _selectedAssetId = null;
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(const LatLng(24.7, 46.6), 5.5),
    );
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  LAYER VISIBILITY TOGGLES
  // ═══════════════════════════════════════════════════════════════════

  void toggleHeatZones() {
    _showHeatZones = !_showHeatZones;
    _setLayerVisibility('heat-zones-fill', _showHeatZones);
    _setLayerVisibility('heat-zones-stroke', _showHeatZones);
    notifyListeners();
  }

  void toggleThreatArcs() {
    _showThreatArcs = !_showThreatArcs;
    _setLayerVisibility('threat-circles-layer', _showThreatArcs);
    _setLayerVisibility('trajectories-layer', _showThreatArcs);
    _setLayerVisibility('threat-markers-layer', _showThreatArcs);
    notifyListeners();
  }

  void toggleImpactSites() {
    _showImpactSites = !_showImpactSites;
    _setLayerVisibility('impact-sites-fill', _showImpactSites);
    _setLayerVisibility('impact-sites-stroke', _showImpactSites);
    notifyListeners();
  }

  void toggleAssetLabels() {
    _showAssetLabels = !_showAssetLabels;
    _setLayerVisibility('asset-markers-layer', _showAssetLabels);
    notifyListeners();
  }

  void setHeatZoneFilter(int level) {
    _heatZoneFilter = level;
    notifyListeners();
  }

  void _setLayerVisibility(String layerId, bool visible) {
    try {
      _mapController?.setLayerProperties(
        layerId,
        visible ? {'visibility': 'visible'} : {'visibility': 'none'},
      );
    } catch (_) {
      // Layer may not exist yet if style hasn't loaded
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DATA UPDATE METHODS (push new GeoJSON to existing sources)
  // ═══════════════════════════════════════════════════════════════════

  /// Update heat zone circles (3-level risk rings around each asset).
  Future<void> updateHeatZones(
    List<StrategicAsset> assets,
    Map<String, ThreatAssessment>? assessments,
  ) async {
    if (!_sourcesInitialized) return;

    final features = <Map<String, dynamic>>[];

    for (final asset in assets) {
      if (_heatZoneFilter != 0 && asset.riskLevel != _heatZoneFilter) continue;

      final assessment = assessments?[asset.id];
      final isUnderThreat = assessment != null &&
          (assessment.alertLevel == AlertLevel.critical ||
              assessment.alertLevel == AlertLevel.high);
      final isCritical =
          assessment != null && assessment.alertLevel == AlertLevel.critical;

      // Outer zone (Yellow) - 24km
      features.add(_circleFeature(
        asset.latitude, asset.longitude, 24000,
        color: '#FFEB3B', opacity: 0.125,
        strokeColor: 'transparent', strokeWidth: 0,
      ));

      // Middle zone (Orange) - 16km
      features.add(_circleFeature(
        asset.latitude, asset.longitude, 16000,
        color: '#FF9800', opacity: 0.19,
        strokeColor: 'transparent', strokeWidth: 0,
      ));

      // Inner zone (Red) - scaled by risk level
      final innerRadius = asset.riskLevel * 8000.0;
      final innerOpacity = isCritical ? 0.63 : isUnderThreat ? 0.50 : asset.riskLevel == 3 ? 0.33 : 0.21;
      final innerColor = (isCritical || isUnderThreat || asset.riskLevel == 3) ? '#F44336' : '#FF9800';
      final innerStrokeColor = isCritical ? '#FF0000' : isUnderThreat ? '#FF0000' : '#FFFFFF';
      final innerStrokeWidth = isCritical ? 3.0 : isUnderThreat ? 2.0 : 1.0;
      final innerStrokeOpacity = isCritical ? 1.0 : isUnderThreat ? 0.8 : 0.19;

      features.add(_circleFeature(
        asset.latitude, asset.longitude, innerRadius,
        color: innerColor, opacity: innerOpacity,
        strokeColor: innerStrokeColor, strokeWidth: innerStrokeWidth,
        strokeOpacity: innerStrokeOpacity,
      ));
    }

    await _mapController?.setGeoJsonSource('heat-zones-source', {
      'type': 'FeatureCollection',
      'features': features,
    });
  }

  /// Update economic impact blast radii.
  Future<void> updateImpactSites(
    List<StrategicAsset> assets,
    Map<String, ImpactReport> impactReports,
    Map<String, ThreatAssessment>? assessments,
  ) async {
    if (!_sourcesInitialized) return;

    final features = <Map<String, dynamic>>[];

    for (final asset in assets) {
      final impact = impactReports[asset.id];
      final assessment = assessments?[asset.id];
      if (impact == null) continue;
      if (assessment == null || assessment.alertLevel == AlertLevel.low) continue;

      final impactBillions = impact.dailyRevenueLoss / 1000000000;
      final radius = (impactBillions * 5000).clamp(2000.0, 40000.0);

      features.add(_circleFeature(
        asset.latitude, asset.longitude, radius,
        color: '#E040FB', opacity: 0.09,
        strokeColor: '#E040FB', strokeWidth: 2, strokeOpacity: 0.53,
      ));
    }

    await _mapController?.setGeoJsonSource('impact-sites-source', {
      'type': 'FeatureCollection',
      'features': features,
    });
  }

  /// Update threat event origin circles.
  Future<void> updateThreatEventCircles(List<ThreatEvent> events) async {
    if (!_sourcesInitialized) return;

    final features = <Map<String, dynamic>>[];

    for (final event in events) {
      if (!event.hasLocation) continue;

      final color = event.isActive ? '#FF1744' : '#FF6E40';
      final fillOpacity = event.confidence * 0.23;

      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [event.longitude!, event.latitude!],
        },
        'properties': {
          'radius': event.isActive ? 12.0 : 7.0, // screen pixels
          'color': color,
          'opacity': fillOpacity,
          'strokeColor': color,
          'strokeWidth': event.isActive ? 2.0 : 1.0,
        },
      });
    }

    await _mapController?.setGeoJsonSource('threat-circles-source', {
      'type': 'FeatureCollection',
      'features': features,
    });
  }

  /// Update trajectory arcs from threat origins to nearest target assets.
  Future<void> updateTrajectories(
    List<ThreatEvent> events,
    List<StrategicAsset> assets,
  ) async {
    if (!_sourcesInitialized) return;

    final features = <Map<String, dynamic>>[];

    for (final event in events) {
      if (!event.hasLocation || !event.isActive) continue;

      // Find closest high-risk asset as likely target
      StrategicAsset? target;
      double minDist = double.infinity;
      for (final asset in assets.where((a) => a.riskLevel >= 2)) {
        final dist = _distance(
          event.latitude!, event.longitude!,
          asset.latitude, asset.longitude,
        );
        if (dist < minDist) {
          minDist = dist;
          target = asset;
        }
      }
      if (target == null) continue;

      final color = event.severityScore >= 7
          ? '#FF1744'
          : event.severityScore >= 4
              ? '#FF9100'
              : '#FFEA00';
      final width = event.severityScore >= 7 ? 4.0 : 2.0;

      final arcPoints = _buildArc(
        LatLng(event.latitude!, event.longitude!),
        LatLng(target.latitude, target.longitude),
        segments: 20,
      );

      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': arcPoints.map((p) => [p.longitude, p.latitude]).toList(),
        },
        'properties': {
          'color': color,
          'width': width,
        },
      });
    }

    await _mapController?.setGeoJsonSource('trajectories-source', {
      'type': 'FeatureCollection',
      'features': features,
    });
  }

  /// Update asset markers (symbols with colored icons).
  Future<void> updateAssetMarkers(
    List<StrategicAsset> assets,
    Map<String, ThreatAssessment>? assessments,
  ) async {
    if (!_sourcesInitialized) return;

    final features = <Map<String, dynamic>>[];

    for (final asset in assets) {
      final assessment = assessments?[asset.id];
      final isCritical =
          assessment != null && assessment.alertLevel == AlertLevel.critical;
      final isHigh =
          assessment != null && assessment.alertLevel == AlertLevel.high;

      final iconName = isCritical
          ? 'marker-red'
          : isHigh
              ? 'marker-orange'
              : asset.riskLevel == 3
                  ? 'marker-rose'
                  : asset.riskLevel == 2
                      ? 'marker-orange'
                      : 'marker-yellow';

      final label = '${asset.sectorIcon} ${asset.name}';
      final zIndex = isCritical ? 10.0 : isHigh ? 5.0 : 1.0;

      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [asset.longitude, asset.latitude],
        },
        'properties': {
          'id': asset.id,
          'icon': iconName,
          'label': label,
          'zIndex': zIndex,
          'snippet': _markerSnippet(asset, assessment),
        },
      });
    }

    await _mapController?.setGeoJsonSource('asset-markers-source', {
      'type': 'FeatureCollection',
      'features': features,
    });
  }

  /// Update threat event markers (origin indicators).
  Future<void> updateThreatEventMarkers(List<ThreatEvent> events) async {
    if (!_sourcesInitialized) return;

    final features = <Map<String, dynamic>>[];

    for (final event in events) {
      if (!event.hasLocation) continue;

      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [event.longitude!, event.latitude!],
        },
        'properties': {
          'id': 'evt_${event.id}',
          'icon': event.isActive ? 'marker-violet' : 'marker-cyan',
          'opacity': event.confidence.clamp(0.5, 1.0),
          'zIndex': event.isActive ? 15.0 : 2.0,
          'headline': '${event.sourceFlag} ${event.type.name.toUpperCase()}',
          'snippet': '${event.headline} | Severity: ${event.severityScore}/10',
        },
      });
    }

    await _mapController?.setGeoJsonSource('threat-markers-source', {
      'type': 'FeatureCollection',
      'features': features,
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════

  String _markerSnippet(StrategicAsset asset, ThreatAssessment? assessment) {
    final parts = <String>['Risk: ${asset.riskLevel}/3 | ${asset.sector}'];
    if (assessment != null && assessment.threatScore > 10) {
      parts.add('Threat: ${assessment.threatScore.toStringAsFixed(0)}/100');
    }
    if (assessment != null && assessment.estimatedTimeToImpact != null) {
      parts.add('ETA: ${assessment.formattedEta}');
    }
    return parts.join(' | ');
  }

  /// Build a curved arc between two points (great circle approximation).
  List<LatLng> _buildArc(LatLng from, LatLng to, {int segments = 20}) {
    final points = <LatLng>[];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final lat = from.latitude + (to.latitude - from.latitude) * t;
      final lng = from.longitude + (to.longitude - from.longitude) * t;
      // Add curvature bulge perpendicular to the line
      final bulge = 0.8 * (t * (1 - t) * 4); // max at midpoint
      final dlat = to.latitude - from.latitude;
      final dlng = to.longitude - from.longitude;
      // Perpendicular offset (rotate 90 degrees)
      final perpLat = -dlng * bulge;
      final perpLng = dlat * bulge;
      points.add(LatLng(lat + perpLat, lng + perpLng));
    }
    return points;
  }

  double _distance(double lat1, double lng1, double lat2, double lng2) {
    final dlat = lat2 - lat1;
    final dlng = lng2 - lng1;
    return dlat * dlat + dlng * dlng; // Euclidean approximation for sorting
  }

  /// Generate a GeoJSON Polygon ring approximating a circle on the earth.
  Map<String, dynamic> _circleFeature(
    double lat, double lng, double radiusMeters, {
    required String color,
    required double opacity,
    required String strokeColor,
    required double strokeWidth,
    double strokeOpacity = 1.0,
    int points = 64,
  }) {
    final coords = <List<double>>[];
    for (int i = 0; i <= points; i++) {
      final bearing = (i * 360.0 / points) * pi / 180.0;
      final latRad = lat * pi / 180.0;
      final lngRad = lng * pi / 180.0;
      final d = radiusMeters / 6371000.0; // angular distance
      final newLat = asin(sin(latRad) * cos(d) + cos(latRad) * sin(d) * cos(bearing));
      final newLng = lngRad + atan2(
        sin(bearing) * sin(d) * cos(latRad),
        cos(d) - sin(latRad) * sin(newLat),
      );
      coords.add([newLng * 180.0 / pi, newLat * 180.0 / pi]);
    }

    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [coords],
      },
      'properties': {
        'color': color,
        'opacity': opacity,
        'strokeColor': strokeColor,
        'strokeWidth': strokeWidth,
        'strokeOpacity': strokeOpacity,
      },
    };
  }
}
