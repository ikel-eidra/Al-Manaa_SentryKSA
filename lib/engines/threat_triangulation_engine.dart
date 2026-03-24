import '../models/threat_event.dart';
import '../models/strategic_asset.dart';
import 'dart:math';

/// Threat Triangulation Engine.
/// Monitors trigger events from US (CENTCOM), Israel (IDF), and Iran (IRNA)
/// to predict KSA impact windows through pattern analysis.
class ThreatTriangulationEngine {
  // Weighted source reliability scores
  static const Map<String, double> sourceReliability = {
    'CENTCOM': 0.92,
    'IDF': 0.85,
    'IRNA': 0.65,
  };

  // Threat type flight times to KSA (minutes) from Iran
  static const Map<ThreatType, int> flightTimeMinutes = {
    ThreatType.ballistic: 12,
    ThreatType.cruise: 90,
    ThreatType.drone: 480,
    ThreatType.cyber: 0,
    ThreatType.naval: 2880, // 48 hours
    ThreatType.hybrid: 30,
  };

  // Correlation decay: events older than this are discounted
  static const Duration correlationWindow = Duration(hours: 6);

  /// Analyze a stream of events and produce a threat score (0-100)
  /// for each KSA strategic asset.
  Map<String, ThreatAssessment> triangulate(
    List<ThreatEvent> events,
    List<StrategicAsset> assets,
  ) {
    final now = DateTime.now();
    final activeEvents = events.where((e) {
      final age = now.difference(e.timestamp);
      return age < correlationWindow;
    }).toList();

    final assessments = <String, ThreatAssessment>{};

    for (final asset in assets) {
      double threatScore = 0;
      ThreatEvent? primaryThreat;
      final contributingEvents = <ThreatEvent>[];

      for (final event in activeEvents) {
        final relevance = _calculateRelevance(event, asset);
        final reliability = sourceReliability[event.source] ?? 0.5;
        final recency = _recencyFactor(event.timestamp, now);

        final contribution = relevance * reliability * recency *
            event.severityScore / 10.0 * 100;

        if (contribution > 5) {
          contributingEvents.add(event);
          threatScore += contribution;
        }

        if (primaryThreat == null || contribution > threatScore * 0.5) {
          primaryThreat = event;
        }
      }

      // Multi-source corroboration bonus
      final uniqueSources =
          contributingEvents.map((e) => e.source).toSet().length;
      if (uniqueSources >= 2) {
        threatScore *= 1.3; // 30% boost for corroboration
      }
      if (uniqueSources >= 3) {
        threatScore *= 1.2; // Additional 20% for triple-source
      }

      threatScore = threatScore.clamp(0, 100);

      Duration? eta;
      if (primaryThreat != null && primaryThreat.isActive) {
        eta = primaryThreat.estimatedTimeToImpact;
      } else if (primaryThreat != null) {
        final flightTime = flightTimeMinutes[primaryThreat.type] ?? 30;
        eta = Duration(minutes: flightTime);
      }

      assessments[asset.id] = ThreatAssessment(
        assetId: asset.id,
        assetName: asset.name,
        threatScore: threatScore,
        alertLevel: _alertLevel(threatScore),
        estimatedTimeToImpact: eta,
        primaryThreat: primaryThreat,
        contributingEvents: contributingEvents,
        assessedAt: now,
      );
    }

    return assessments;
  }

  /// Calculate how relevant an event is to a specific asset.
  double _calculateRelevance(ThreatEvent event, StrategicAsset asset) {
    double relevance = 0.3; // Base relevance

    // Corridor matching
    if (event.targetCorridor != null) {
      final corridor = event.targetCorridor!.toLowerCase();
      if (corridor.contains(asset.province.toLowerCase())) {
        relevance += 0.4;
      }
      if (corridor.contains(asset.sector.toLowerCase())) {
        relevance += 0.2;
      }
      if (corridor.contains('oil') && asset.sector == 'Energy') {
        relevance += 0.3;
      }
      if (corridor.contains('water') && asset.sector == 'Water') {
        relevance += 0.3;
      }
    }

    // High-value target bonus
    if (asset.riskLevel == 3) {
      relevance += 0.1;
    }

    return relevance.clamp(0.0, 1.0);
  }

  /// Events lose influence over time within the correlation window.
  double _recencyFactor(DateTime eventTime, DateTime now) {
    final ageMinutes = now.difference(eventTime).inMinutes;
    final windowMinutes = correlationWindow.inMinutes;
    return max(0, 1.0 - (ageMinutes / windowMinutes));
  }

  AlertLevel _alertLevel(double score) {
    if (score >= 75) return AlertLevel.critical;
    if (score >= 50) return AlertLevel.high;
    if (score >= 25) return AlertLevel.elevated;
    return AlertLevel.low;
  }
}

class ThreatAssessment {
  final String assetId;
  final String assetName;
  final double threatScore;
  final AlertLevel alertLevel;
  final Duration? estimatedTimeToImpact;
  final ThreatEvent? primaryThreat;
  final List<ThreatEvent> contributingEvents;
  final DateTime assessedAt;

  const ThreatAssessment({
    required this.assetId,
    required this.assetName,
    required this.threatScore,
    required this.alertLevel,
    this.estimatedTimeToImpact,
    this.primaryThreat,
    required this.contributingEvents,
    required this.assessedAt,
  });

  String get formattedEta {
    if (estimatedTimeToImpact == null) return '--:--:--';
    final d = estimatedTimeToImpact!;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  bool get isImminent =>
      estimatedTimeToImpact != null &&
      estimatedTimeToImpact!.inMinutes < 15;
}

enum AlertLevel {
  low,
  elevated,
  high,
  critical,
}
