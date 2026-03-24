import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/strategic_asset.dart';
import '../engines/threat_triangulation_engine.dart';

/// State provider for GIS heatmap and map interactions.
class MapProvider extends ChangeNotifier {
  GoogleMapController? _mapController;
  MapType _mapType = MapType.hybrid;
  double _zoom = 5.5;
  LatLng _center = const LatLng(24.7, 46.6); // KSA center
  String? _selectedAssetId;
  bool _showHeatZones = true;
  int _heatZoneFilter = 0; // 0 = all, 1/2/3 = specific level

  // Getters
  GoogleMapController? get mapController => _mapController;
  MapType get mapType => _mapType;
  double get zoom => _zoom;
  LatLng get center => _center;
  String? get selectedAssetId => _selectedAssetId;
  bool get showHeatZones => _showHeatZones;

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

  /// Generate circles for the 3-level risk zone heatmap.
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

      // Outer zone (Yellow) - 24km radius
      circles.add(Circle(
        circleId: CircleId('${asset.id}_yellow'),
        center: LatLng(asset.latitude, asset.longitude),
        radius: 24000,
        fillColor: const Color(0x30FFEB3B),
        strokeWidth: 0,
      ));

      // Middle zone (Orange) - 16km radius
      circles.add(Circle(
        circleId: CircleId('${asset.id}_orange'),
        center: LatLng(asset.latitude, asset.longitude),
        radius: 16000,
        fillColor: const Color(0x40FF9800),
        strokeWidth: 0,
      ));

      // Inner zone (Red) - 8km radius, pulsing if under active threat
      circles.add(Circle(
        circleId: CircleId('${asset.id}_red'),
        center: LatLng(asset.latitude, asset.longitude),
        radius: asset.riskLevel * 8000.0,
        fillColor: isUnderThreat
            ? const Color(0x80F44336) // Brighter red under threat
            : asset.riskLevel == 3
                ? const Color(0x66F44336)
                : const Color(0x40FF9800),
        strokeWidth: isUnderThreat ? 2 : 1,
        strokeColor: isUnderThreat
            ? const Color(0xFFFF0000)
            : const Color(0x40FFFFFF),
      ));
    }

    return circles;
  }

  /// Generate markers for strategic assets.
  Set<Marker> buildMarkers(
    List<StrategicAsset> assets,
    void Function(StrategicAsset) onTap,
  ) {
    return assets.map((asset) {
      return Marker(
        markerId: MarkerId(asset.id),
        position: LatLng(asset.latitude, asset.longitude),
        infoWindow: InfoWindow(
          title: '${asset.sectorIcon} ${asset.name}',
          snippet: 'Risk: ${asset.riskLevel}/3 | ${asset.sector}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          asset.riskLevel == 3
              ? BitmapDescriptor.hueRed
              : asset.riskLevel == 2
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueYellow,
        ),
        onTap: () => onTap(asset),
      );
    }).toSet();
  }
}

// Color helper (since we can't import material in a pure provider)
class Color {
  final int value;
  const Color(this.value);
}
