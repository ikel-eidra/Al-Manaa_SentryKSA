import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/strategic_asset.dart';
import '../models/threat_event.dart';
import '../models/impact_report.dart';
import '../engines/threat_triangulation_engine.dart';

/// State provider for GIS heatmap, threat trajectories, and map interactions.
class MapProvider extends ChangeNotifier {
  GoogleMapController? _mapController;
  MapType _mapType = MapType.hybrid;
  double _zoom = 5.5;
  LatLng _center = const LatLng(24.7, 46.6); // KSA center
  String? _selectedAssetId;

  // Layer visibility toggles
  bool _showHeatZones = true;
  bool _showThreatArcs = true;
  bool _showImpactSites = true;
  bool _showAssetLabels = true;
  int _heatZoneFilter = 0; // 0 = all, 1/2/3 = specific level

  // Getters
  GoogleMapController? get mapController => _mapController;
  MapType get mapType => _mapType;
  double get zoom => _zoom;
  LatLng get center => _center;
  String? get selectedAssetId => _selectedAssetId;
  bool get showHeatZones => _showHeatZones;
  bool get showThreatArcs => _showThreatArcs;
  bool get showImpactSites => _showImpactSites;
  bool get showAssetLabels => _showAssetLabels;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    notifyListeners();
  }

  void setMapType(MapType type) {
    _mapType = type;
    notifyListeners();
  }

  void toggleHeatZones() {
    _showHeatZones = !_showHeatZones;
    notifyListeners();
  }

  void toggleThreatArcs() {
    _showThreatArcs = !_showThreatArcs;
    notifyListeners();
  }

  void toggleImpactSites() {
    _showImpactSites = !_showImpactSites;
    notifyListeners();
  }

  void toggleAssetLabels() {
    _showAssetLabels = !_showAssetLabels;
    notifyListeners();
  }

  void setHeatZoneFilter(int level) {
    _heatZoneFilter = level;
    notifyListeners();
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

  // ─── HEAT ZONES ──────────────────────────────────────────────────

  /// Generate circles for the 3-level risk zone heatmap around each asset.
  Set<Circle> buildHeatZones(
    List<StrategicAsset> assets,
    Map<String, ThreatAssessment>? assessments,
  ) {
    if (!_showHeatZones) return {};

    final circles = <Circle>{};

    for (final asset in assets) {
      if (_heatZoneFilter != 0 && asset.riskLevel != _heatZoneFilter) continue;

      final assessment = assessments?[asset.id];
      final isUnderThreat = assessment != null &&
          (assessment.alertLevel == AlertLevel.critical ||
              assessment.alertLevel == AlertLevel.high);
      final isCritical =
          assessment != null && assessment.alertLevel == AlertLevel.critical;

      // Outer zone (Yellow) - 24km radius
      circles.add(Circle(
        circleId: CircleId('${asset.id}_yellow'),
        center: LatLng(asset.latitude, asset.longitude),
        radius: 24000,
        fillColor: const Color(0x20FFEB3B),
        strokeWidth: 0,
      ));

      // Middle zone (Orange) - 16km radius
      circles.add(Circle(
        circleId: CircleId('${asset.id}_orange'),
        center: LatLng(asset.latitude, asset.longitude),
        radius: 16000,
        fillColor: const Color(0x30FF9800),
        strokeWidth: 0,
      ));

      // Inner zone (Red) - scaled by risk level, brighter if under active threat
      circles.add(Circle(
        circleId: CircleId('${asset.id}_red'),
        center: LatLng(asset.latitude, asset.longitude),
        radius: asset.riskLevel * 8000.0,
        fillColor: isCritical
            ? const Color(0xA0F44336) // Intense red - critical
            : isUnderThreat
                ? const Color(0x80F44336)
                : asset.riskLevel == 3
                    ? const Color(0x55F44336)
                    : const Color(0x35FF9800),
        strokeWidth: isCritical ? 3 : isUnderThreat ? 2 : 1,
        strokeColor: isCritical
            ? const Color(0xFFFF0000)
            : isUnderThreat
                ? const Color(0xCCFF0000)
                : const Color(0x30FFFFFF),
      ));
    }

    return circles;
  }

  // ─── IMPACT SITE CIRCLES ─────────────────────────────────────────

  /// Generate economic impact blast radii - larger = bigger GDP loss.
  Set<Circle> buildImpactSites(
    List<StrategicAsset> assets,
    Map<String, ImpactReport> impactReports,
    Map<String, ThreatAssessment>? assessments,
  ) {
    if (!_showImpactSites) return {};

    final circles = <Circle>{};

    for (final asset in assets) {
      final impact = impactReports[asset.id];
      final assessment = assessments?[asset.id];
      if (impact == null) continue;
      if (assessment == null || assessment.alertLevel == AlertLevel.low) continue;

      // Scale radius by economic impact (1B = 5km, capped at 40km)
      final impactBillions = impact.dailyRevenueLoss / 1000000000;
      final radius = (impactBillions * 5000).clamp(2000.0, 40000.0);

      // Purple/magenta impact ring
      circles.add(Circle(
        circleId: CircleId('impact_${asset.id}'),
        center: LatLng(asset.latitude, asset.longitude),
        radius: radius,
        fillColor: const Color(0x18E040FB),
        strokeWidth: 2,
        strokeColor: const Color(0x88E040FB),
      ));
    }

    return circles;
  }

  // ─── THREAT EVENT CIRCLES ────────────────────────────────────────

  /// Generate circles showing detected threat event origins on the map.
  Set<Circle> buildThreatEventCircles(List<ThreatEvent> events) {
    if (!_showThreatArcs) return {};

    final circles = <Circle>{};

    for (final event in events) {
      if (!event.hasLocation) continue;

      final color = event.isActive
          ? const Color(0xCCFF1744) // Active = bright red
          : const Color(0x66FF6E40); // Historical = dim orange

      // Pulsing detection circle
      circles.add(Circle(
        circleId: CircleId('threat_${event.id}'),
        center: LatLng(event.latitude!, event.longitude!),
        radius: event.isActive ? 15000 : 8000,
        fillColor: Color.fromARGB(
          (event.confidence * 60).toInt(),
          (color.value >> 16) & 0xFF,
          (color.value >> 8) & 0xFF,
          color.value & 0xFF,
        ),
        strokeWidth: event.isActive ? 2 : 1,
        strokeColor: color,
      ));
    }

    return circles;
  }

  // ─── THREAT TRAJECTORY POLYLINES ─────────────────────────────────

  /// Generate trajectory lines from threat event origins to nearest target assets.
  Set<Polyline> buildThreatTrajectories(
    List<ThreatEvent> events,
    List<StrategicAsset> assets,
  ) {
    if (!_showThreatArcs) return {};

    final polylines = <Polyline>{};

    for (final event in events) {
      if (!event.hasLocation || !event.isActive) continue;

      // Find the closest high-risk asset as the likely target
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

      final trajectoryColor = event.severityScore >= 7
          ? const Color(0xDDFF1744)
          : event.severityScore >= 4
              ? const Color(0xBBFF9100)
              : const Color(0x88FFEA00);

      // Build trajectory arc with intermediate points for curvature
      final points = _buildArc(
        LatLng(event.latitude!, event.longitude!),
        LatLng(target.latitude, target.longitude),
        segments: 20,
      );

      polylines.add(Polyline(
        polylineId: PolylineId('traj_${event.id}'),
        points: points,
        color: trajectoryColor,
        width: event.severityScore >= 7 ? 4 : 2,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ));
    }

    return polylines;
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

  // ─── ASSET MARKERS ───────────────────────────────────────────────

  /// Generate markers for strategic assets with dynamic coloring.
  Set<Marker> buildMarkers(
    List<StrategicAsset> assets,
    Map<String, ThreatAssessment>? assessments,
    void Function(StrategicAsset) onTap,
  ) {
    return assets.map((asset) {
      final assessment = assessments?[asset.id];
      final isCritical =
          assessment != null && assessment.alertLevel == AlertLevel.critical;
      final isHigh =
          assessment != null && assessment.alertLevel == AlertLevel.high;

      return Marker(
        markerId: MarkerId(asset.id),
        position: LatLng(asset.latitude, asset.longitude),
        infoWindow: InfoWindow(
          title: '${asset.sectorIcon} ${asset.name}',
          snippet: _markerSnippet(asset, assessment),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isCritical
              ? BitmapDescriptor.hueRed
              : isHigh
                  ? BitmapDescriptor.hueOrange
                  : asset.riskLevel == 3
                      ? BitmapDescriptor.hueRose
                      : asset.riskLevel == 2
                          ? BitmapDescriptor.hueOrange
                          : BitmapDescriptor.hueYellow,
        ),
        onTap: () => onTap(asset),
        zIndex: isCritical ? 10 : isHigh ? 5 : 1,
      );
    }).toSet();
  }

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

  /// Generate markers for threat event origins (red pulsing dots on map).
  Set<Marker> buildThreatEventMarkers(List<ThreatEvent> events) {
    if (!_showThreatArcs) return {};

    return events
        .where((e) => e.hasLocation)
        .map((event) => Marker(
              markerId: MarkerId('evt_${event.id}'),
              position: LatLng(event.latitude!, event.longitude!),
              infoWindow: InfoWindow(
                title: '${event.sourceFlag} ${event.type.name.toUpperCase()}',
                snippet:
                    '${event.headline} | Severity: ${event.severityScore}/10',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                event.isActive
                    ? BitmapDescriptor.hueViolet
                    : BitmapDescriptor.hueCyan,
              ),
              alpha: event.confidence.clamp(0.5, 1.0),
              zIndex: event.isActive ? 15 : 2,
            ))
        .toSet();
  }
}
