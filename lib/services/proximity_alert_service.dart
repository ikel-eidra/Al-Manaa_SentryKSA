import 'dart:async';
import 'dart:math';
import 'package:logger/logger.dart';
import '../models/strategic_asset.dart';
import '../engines/threat_triangulation_engine.dart';

/// GPS-linked proximity alert service.
/// Triggers sirens if a user is within 15km of an HVT during active countdown.
class ProximityAlertService {
  static const double alertRadiusKm = 15.0;
  static const double warningRadiusKm = 50.0;

  final Logger _log = Logger();
  final _alertController = StreamController<ProximityAlert>.broadcast();
  Stream<ProximityAlert> get alerts => _alertController.stream;

  Timer? _checkTimer;

  /// Start continuous proximity monitoring.
  void startMonitoring({
    required Stream<UserLocation> locationStream,
    required List<StrategicAsset> assets,
    required Map<String, ThreatAssessment> Function() getAssessments,
  }) {
    _log.i('Proximity alert service started');

    locationStream.listen((location) {
      _checkProximity(location, assets, getAssessments());
    });
  }

  void _checkProximity(
    UserLocation location,
    List<StrategicAsset> assets,
    Map<String, ThreatAssessment> assessments,
  ) {
    for (final asset in assets) {
      final distance = _haversineKm(
        location.latitude,
        location.longitude,
        asset.latitude,
        asset.longitude,
      );

      final assessment = assessments[asset.id];
      if (assessment == null) continue;

      // Only alert if there's an active threat to this asset
      if (assessment.alertLevel == AlertLevel.critical ||
          assessment.alertLevel == AlertLevel.high) {
        if (distance <= alertRadiusKm) {
          _alertController.add(ProximityAlert(
            asset: asset,
            distanceKm: distance,
            level: ProximityAlertLevel.siren,
            message:
                'EVACUATE: You are ${distance.toStringAsFixed(1)}km from '
                '${asset.name}. Active threat detected.',
            assessment: assessment,
          ));
        } else if (distance <= warningRadiusKm) {
          _alertController.add(ProximityAlert(
            asset: asset,
            distanceKm: distance,
            level: ProximityAlertLevel.warning,
            message:
                'WARNING: ${asset.name} under threat. '
                'Distance: ${distance.toStringAsFixed(1)}km. Move to safe zone.',
            assessment: assessment,
          ));
        }
      }
    }
  }

  /// Haversine formula for distance between two lat/lng points.
  double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  void dispose() {
    _checkTimer?.cancel();
    _alertController.close();
  }
}

class UserLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

class ProximityAlert {
  final StrategicAsset asset;
  final double distanceKm;
  final ProximityAlertLevel level;
  final String message;
  final ThreatAssessment assessment;

  const ProximityAlert({
    required this.asset,
    required this.distanceKm,
    required this.level,
    required this.message,
    required this.assessment,
  });
}

enum ProximityAlertLevel {
  info,
  warning,
  siren,
}
