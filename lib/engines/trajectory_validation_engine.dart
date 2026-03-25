import 'dart:math';
import '../models/civilian_report.dart';
import '../models/strategic_asset.dart';
import '../models/threat_event.dart';

/// Engine that cross-references civilian crowd reports with classified
/// trajectory projections to validate, refine, or invalidate strike data.
///
/// Core concept: When a missile/drone is projected to hit a location,
/// civilian reports from the ground either CONFIRM or CONTRADICT the
/// projection. Multiple independent civilian reports from the same area
/// create high-confidence "ground truth" that can:
///   1. Validate the war room's trajectory model
///   2. Reveal missed impacts (civilian saw explosion, war room had no track)
///   3. Correct trajectory errors (impact was 5km NE of projected point)
///   4. Generate crowd-sourced damage heatmaps in real time
class TrajectoryValidationEngine {
  TrajectoryValidationEngine();

  /// Validate a projected threat event against civilian reports.
  /// Returns a validation result with confidence and corrected coordinates.
  TrajectoryValidation validate({
    required ThreatEvent projectedEvent,
    required List<CivilianReport> nearbyReports,
    required List<StrategicAsset> assets,
  }) {
    if (nearbyReports.isEmpty) {
      return TrajectoryValidation(
        threatEventId: projectedEvent.id,
        result: ValidationResult.noData,
        confidence: 0.0,
        reportCount: 0,
        message: 'No civilian reports near projected impact zone',
      );
    }

    // Filter to impact-relevant reports (not all-clear or siren-only)
    final impactReports = nearbyReports
        .where((r) =>
            r.type == ReportType.impact ||
            r.type == ReportType.fire ||
            r.type == ReportType.debris ||
            r.type == ReportType.smoke)
        .toList();

    final allClearReports =
        nearbyReports.where((r) => r.type == ReportType.allClear).toList();

    // If mostly all-clear reports near projected impact → likely miss or intercept
    if (allClearReports.length > impactReports.length * 2 &&
        allClearReports.length >= 3) {
      return TrajectoryValidation(
        threatEventId: projectedEvent.id,
        result: ValidationResult.likelyIntercepted,
        confidence: _clusterConfidence(allClearReports),
        reportCount: nearbyReports.length,
        message:
            '${allClearReports.length} all-clear reports suggest intercept or miss',
      );
    }

    if (impactReports.isEmpty) {
      return TrajectoryValidation(
        threatEventId: projectedEvent.id,
        result: ValidationResult.inconclusive,
        confidence: 0.3,
        reportCount: nearbyReports.length,
        message: 'Reports present but no impact indicators',
      );
    }

    // Compute the crowd-sourced impact centroid
    final centroid = _computeCentroid(impactReports);

    // Distance from projected impact to crowd-sourced centroid
    final projectedLat = projectedEvent.latitude;
    final projectedLng = projectedEvent.longitude;
    double? deviationKm;

    if (projectedLat != null && projectedLng != null) {
      deviationKm = _haversineKm(
        projectedLat,
        projectedLng,
        centroid.latitude,
        centroid.longitude,
      );
    }

    // Find nearest asset to the crowd centroid
    StrategicAsset? nearestAsset;
    double nearestDist = double.infinity;
    for (final asset in assets) {
      final dist = _haversineKm(
        centroid.latitude,
        centroid.longitude,
        asset.latitude,
        asset.longitude,
      );
      if (dist < nearestDist) {
        nearestDist = dist;
        nearestAsset = asset;
      }
    }

    final confidence = _clusterConfidence(impactReports);

    // Classify the validation result
    ValidationResult result;
    String message;

    if (deviationKm != null && deviationKm <= 2.0) {
      result = ValidationResult.confirmed;
      message =
          'Impact confirmed ${deviationKm.toStringAsFixed(1)}km from projection '
          'by ${impactReports.length} civilian reports';
    } else if (deviationKm != null && deviationKm <= 10.0) {
      result = ValidationResult.confirmedWithDeviation;
      message =
          'Impact confirmed but ${deviationKm.toStringAsFixed(1)}km from projection — '
          'trajectory model needs correction';
    } else {
      result = ValidationResult.newImpact;
      message =
          'Civilian reports indicate impact at unexpected location '
          '(${deviationKm?.toStringAsFixed(1) ?? "unknown"}km from nearest projection)';
    }

    return TrajectoryValidation(
      threatEventId: projectedEvent.id,
      result: result,
      confidence: confidence,
      reportCount: nearbyReports.length,
      impactReportCount: impactReports.length,
      correctedLatitude: centroid.latitude,
      correctedLongitude: centroid.longitude,
      deviationFromProjectionKm: deviationKm,
      nearestAssetId: nearestAsset?.id,
      nearestAssetDistanceKm: nearestDist,
      message: message,
    );
  }

  /// Generate a damage heatmap from civilian reports.
  /// Returns clustered grid cells with aggregated damage intensity.
  List<DamageHeatCell> generateDamageHeatmap(
    List<CivilianReport> reports, {
    double cellSizeKm = 1.0,
  }) {
    if (reports.isEmpty) return [];

    // Grid the reports into cells
    final cells = <String, _CellAccumulator>{};

    for (final report in reports) {
      // Quantize to grid cell
      final cellLat = (report.latitude / (cellSizeKm / 111.0)).round() *
          (cellSizeKm / 111.0);
      final cellLng = (report.longitude / (cellSizeKm / 111.0)).round() *
          (cellSizeKm / 111.0);
      final key = '${cellLat.toStringAsFixed(4)}_${cellLng.toStringAsFixed(4)}';

      cells.putIfAbsent(key, () => _CellAccumulator(cellLat, cellLng));
      cells[key]!.addReport(report);
    }

    return cells.values.map((cell) => cell.toHeatCell()).toList()
      ..sort((a, b) => b.intensity.compareTo(a.intensity));
  }

  /// Quick simulation: Given N civilian reports in a time window, estimate
  /// how many projectiles likely impacted and their probable origin azimuth.
  QuickSimulation runQuickSimulation(
    List<CivilianReport> impactReports, {
    Duration timeWindow = const Duration(minutes: 30),
  }) {
    if (impactReports.isEmpty) {
      return const QuickSimulation(
        estimatedProjectileCount: 0,
        estimatedOriginAzimuth: null,
        impactSpreadKm: 0,
        timeSpreadMinutes: 0,
        assessedThreatType: null,
      );
    }

    // Filter to time window
    final now = DateTime.now();
    final recent = impactReports
        .where((r) => now.difference(r.timestamp) <= timeWindow)
        .toList();

    if (recent.isEmpty) {
      return const QuickSimulation(
        estimatedProjectileCount: 0,
        estimatedOriginAzimuth: null,
        impactSpreadKm: 0,
        timeSpreadMinutes: 0,
        assessedThreatType: null,
      );
    }

    // Estimate projectile count from distinct impact clusters
    final clusters = _clusterReports(recent, thresholdKm: 2.0);
    final projectileCount = clusters.length;

    // Compute impact spread (max distance between any two reports)
    double maxSpread = 0;
    for (int i = 0; i < recent.length; i++) {
      for (int j = i + 1; j < recent.length; j++) {
        final dist = _haversineKm(
          recent[i].latitude,
          recent[i].longitude,
          recent[j].latitude,
          recent[j].longitude,
        );
        if (dist > maxSpread) maxSpread = dist;
      }
    }

    // Time spread
    recent.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final timeSpread = recent.last.timestamp.difference(recent.first.timestamp);

    // Assess threat type from spread pattern
    ThreatType? assessedType;
    if (maxSpread < 1.0 && projectileCount <= 2) {
      assessedType = ThreatType.ballistic; // tight cluster = precision strike
    } else if (maxSpread < 5.0 && projectileCount <= 5) {
      assessedType = ThreatType.cruise;
    } else if (projectileCount > 5) {
      assessedType = ThreatType.drone; // wide scatter = swarm
    }

    return QuickSimulation(
      estimatedProjectileCount: projectileCount,
      estimatedOriginAzimuth: null, // would need trajectory analysis
      impactSpreadKm: maxSpread,
      timeSpreadMinutes: timeSpread.inMinutes,
      assessedThreatType: assessedType,
    );
  }

  // ─── PRIVATE HELPERS ─────────────────────────────────────────────

  _LatLng _computeCentroid(List<CivilianReport> reports) {
    // Trust-weighted centroid
    double totalWeight = 0;
    double latSum = 0;
    double lngSum = 0;

    for (final r in reports) {
      final weight = r.trustScore * (r.hasPhotos ? 1.5 : 1.0);
      latSum += r.latitude * weight;
      lngSum += r.longitude * weight;
      totalWeight += weight;
    }

    return _LatLng(latSum / totalWeight, lngSum / totalWeight);
  }

  double _clusterConfidence(List<CivilianReport> reports) {
    if (reports.isEmpty) return 0.0;
    // Confidence increases with more independent reports and higher trust
    final count = reports.length;
    final avgTrust =
        reports.map((r) => r.trustScore).reduce((a, b) => a + b) / count;
    final photoBonus = reports.any((r) => r.hasPhotos) ? 0.15 : 0.0;

    // Diminishing returns: 1 report = low, 3+ = high
    final countFactor = 1.0 - (1.0 / (1.0 + count * 0.5));

    return (countFactor * 0.5 + avgTrust * 0.35 + photoBonus).clamp(0.0, 1.0);
  }

  List<List<CivilianReport>> _clusterReports(
    List<CivilianReport> reports, {
    double thresholdKm = 2.0,
  }) {
    // Simple distance-based clustering
    final clusters = <List<CivilianReport>>[];
    final assigned = <int>{};

    for (int i = 0; i < reports.length; i++) {
      if (assigned.contains(i)) continue;

      final cluster = [reports[i]];
      assigned.add(i);

      for (int j = i + 1; j < reports.length; j++) {
        if (assigned.contains(j)) continue;
        final dist = _haversineKm(
          reports[i].latitude,
          reports[i].longitude,
          reports[j].latitude,
          reports[j].longitude,
        );
        if (dist <= thresholdKm) {
          cluster.add(reports[j]);
          assigned.add(j);
        }
      }

      clusters.add(cluster);
    }

    return clusters;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;
}

// ─── RESULT MODELS ─────────────────────────────────────────────────

class _LatLng {
  final double latitude;
  final double longitude;
  const _LatLng(this.latitude, this.longitude);
}

/// Result of validating a projected trajectory against civilian reports.
class TrajectoryValidation {
  final String threatEventId;
  final ValidationResult result;
  final double confidence;
  final int reportCount;
  final int impactReportCount;
  final double? correctedLatitude;
  final double? correctedLongitude;
  final double? deviationFromProjectionKm;
  final String? nearestAssetId;
  final double? nearestAssetDistanceKm;
  final String message;

  const TrajectoryValidation({
    required this.threatEventId,
    required this.result,
    required this.confidence,
    required this.reportCount,
    this.impactReportCount = 0,
    this.correctedLatitude,
    this.correctedLongitude,
    this.deviationFromProjectionKm,
    this.nearestAssetId,
    this.nearestAssetDistanceKm,
    this.message = '',
  });
}

enum ValidationResult {
  confirmed,                // civilian reports match projected impact
  confirmedWithDeviation,   // confirmed but offset from projection
  newImpact,                // civilian reports reveal untracked impact
  likelyIntercepted,        // all-clear reports suggest intercept
  inconclusive,             // mixed or insufficient data
  noData,                   // no civilian reports in area
}

/// A grid cell in the crowd-sourced damage heatmap.
class DamageHeatCell {
  final double latitude;
  final double longitude;
  final double intensity; // 0.0-1.0
  final int reportCount;
  final DamageLevel maxDamage;
  final bool hasPhotos;

  const DamageHeatCell({
    required this.latitude,
    required this.longitude,
    required this.intensity,
    required this.reportCount,
    required this.maxDamage,
    required this.hasPhotos,
  });
}

/// Quick simulation result from crowd-sourced impact data.
class QuickSimulation {
  final int estimatedProjectileCount;
  final double? estimatedOriginAzimuth; // degrees from north
  final double impactSpreadKm;
  final int timeSpreadMinutes;
  final ThreatType? assessedThreatType;

  const QuickSimulation({
    required this.estimatedProjectileCount,
    required this.estimatedOriginAzimuth,
    required this.impactSpreadKm,
    required this.timeSpreadMinutes,
    required this.assessedThreatType,
  });
}

class _CellAccumulator {
  final double latitude;
  final double longitude;
  final List<CivilianReport> reports = [];

  _CellAccumulator(this.latitude, this.longitude);

  void addReport(CivilianReport report) => reports.add(report);

  DamageHeatCell toHeatCell() {
    DamageLevel maxDmg = DamageLevel.none;
    for (final r in reports) {
      if (r.damageLevel != null && r.damageLevel!.index < maxDmg.index) {
        maxDmg = r.damageLevel!;
      }
    }

    // Intensity based on report count and damage level
    final countFactor = (reports.length / 10.0).clamp(0.0, 1.0);
    final damageFactor = (4 - maxDmg.index) / 4.0;
    final intensity = (countFactor * 0.4 + damageFactor * 0.6).clamp(0.0, 1.0);

    return DamageHeatCell(
      latitude: latitude,
      longitude: longitude,
      intensity: intensity,
      reportCount: reports.length,
      maxDamage: maxDmg,
      hasPhotos: reports.any((r) => r.hasPhotos),
    );
  }
}
