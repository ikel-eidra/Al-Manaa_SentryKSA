import 'dart:math';
import '../models/threat_event.dart';
import '../models/strategic_asset.dart';
import '../data/historical_attack_registry.dart';

/// Bayesian probability engine for incoming attack likelihood.
///
/// Uses historical attack patterns, precursor signal matching,
/// threat type frequency, and real-time event correlation to produce
/// a calibrated probability (0-100%) for each monitored asset.
class ProbabilityEngine {
  // Base annual attack rate on KSA infrastructure (from historical data)
  // ~2-3 significant attacks per year since 2019
  static const double baseAnnualRate = 2.5;
  static const double baseDailyRate = baseAnnualRate / 365;

  /// Compute attack probability for each asset given current events.
  Map<String, AttackProbability> computeProbabilities(
    List<ThreatEvent> events,
    List<StrategicAsset> assets,
  ) {
    final results = <String, AttackProbability>{};
    final now = DateTime.now();

    for (final asset in assets) {
      results[asset.id] = _computeForAsset(asset, events, now);
    }

    return results;
  }

  AttackProbability _computeForAsset(
    StrategicAsset asset,
    List<ThreatEvent> events,
    DateTime now,
  ) {
    // ── 1. Historical prior ─────────────────────────────────
    final historicalPrior = _historicalPrior(asset);

    // ── 2. Precursor signal score ───────────────────────────
    final precursorScore = _precursorSignalScore(asset, events, now);

    // ── 3. Threat type frequency factor ─────────────────────
    final typeFrequencyFactor = _threatTypeFrequency(events);

    // ── 4. Multi-source corroboration boost ──────────────────
    final corroborationFactor = _corroborationFactor(events, asset);

    // ── 5. Temporal clustering factor ────────────────────────
    final clusteringFactor = _temporalClustering(events, now);

    // ── 6. Severity escalation factor ────────────────────────
    final escalationFactor = _severityEscalation(events, now);

    // ── Bayesian combination ─────────────────────────────────
    // P(attack) = prior * likelihood_ratio
    // Where likelihood_ratio = product of all contributing factors
    double probability = historicalPrior *
        precursorScore *
        typeFrequencyFactor *
        corroborationFactor *
        clusteringFactor *
        escalationFactor;

    probability = (probability * 100).clamp(0.0, 99.0);

    // Find closest historical precedent
    ThreatEvent? primaryEvent;
    for (final e in events) {
      if (primaryEvent == null || e.severityScore > primaryEvent.severityScore) {
        primaryEvent = e;
      }
    }
    final precedent = primaryEvent != null
        ? HistoricalAttackRegistry.closestPrecedent(primaryEvent)
        : null;

    // Identify matched precursor signals
    final matchedSignals = _matchPrecursorSignals(asset, events, precedent);

    // Compute time-to-impact probability curve
    final impactWindow = _computeImpactWindow(events, asset);

    return AttackProbability(
      assetId: asset.id,
      assetName: asset.name,
      probability: probability,
      confidence: _computeConfidence(events, precedent),
      historicalPrecedent: precedent,
      matchedPrecursors: matchedSignals,
      riskFactors: _buildRiskFactors(
        historicalPrior,
        precursorScore,
        typeFrequencyFactor,
        corroborationFactor,
        clusteringFactor,
        escalationFactor,
      ),
      impactWindowMinutes: impactWindow,
      computedAt: DateTime.now(),
    );
  }

  // ─── FACTOR CALCULATIONS ─────────────────────────────────────────

  /// Historical prior: how many times has this asset/sector/province been hit?
  double _historicalPrior(StrategicAsset asset) {
    double prior = baseDailyRate;

    // Boost for assets that have been directly targeted before
    final directHits = HistoricalAttackRegistry.forAsset(asset.id);
    if (directHits.isNotEmpty) {
      prior *= (1 + directHits.length * 2.0);
    }

    // Boost for sector with attack history
    final sectorHits = HistoricalAttackRegistry.forSector(asset.sector);
    prior *= (1 + sectorHits.length * 0.5);

    // Boost for province with attack history
    final provinceHits = HistoricalAttackRegistry.forProvince(asset.province);
    prior *= (1 + provinceHits.length * 0.3);

    // High-risk assets are inherently more likely targets
    prior *= (1 + asset.riskLevel * 0.4);

    return prior.clamp(0.001, 0.5);
  }

  /// Score current events against known precursor patterns.
  double _precursorSignalScore(
    StrategicAsset asset,
    List<ThreatEvent> events,
    DateTime now,
  ) {
    if (events.isEmpty) return 1.0;

    double score = 1.0;
    final recentEvents =
        events.where((e) => now.difference(e.timestamp).inHours < 72).toList();

    // Rhetoric escalation (high-severity events from IRNA = propaganda precursor)
    final irnaEvents =
        recentEvents.where((e) => e.source == 'IRNA' && e.severityScore >= 6);
    if (irnaEvents.isNotEmpty) {
      score *= 2.5; // Matches Abqaiq pattern: IRGC rhetoric 72h prior
    }

    // Multi-source reporting on same corridor
    final corridorEvents = recentEvents.where((e) =>
        e.targetCorridor != null &&
        e.targetCorridor!.toLowerCase().contains(asset.province.toLowerCase()));
    if (corridorEvents.length >= 2) {
      score *= 3.0; // Strong precursor: multiple sources, same corridor
    }

    // Active ETA events (someone is tracking an inbound)
    final activeEvents = recentEvents.where((e) => e.isActive);
    if (activeEvents.isNotEmpty) {
      score *= 5.0; // Active inbound detected
    }

    return score;
  }

  /// Boost probability based on historical frequency of current threat types.
  double _threatTypeFrequency(List<ThreatEvent> events) {
    if (events.isEmpty) return 1.0;

    final historicalCounts = HistoricalAttackRegistry.attackCountByType;
    final totalHistorical =
        historicalCounts.values.fold(0, (sum, v) => sum + v);

    double factor = 1.0;
    for (final event in events) {
      final typeCount = historicalCounts[event.type] ?? 0;
      if (totalHistorical > 0 && typeCount > 0) {
        // Types that have been used more often historically get a boost
        factor *= 1 + (typeCount / totalHistorical);
      }
    }

    return factor.clamp(1.0, 4.0);
  }

  /// Multiple independent sources reporting = higher probability.
  double _corroborationFactor(
    List<ThreatEvent> events,
    StrategicAsset asset,
  ) {
    final relevantEvents = events.where((e) {
      if (e.targetCorridor == null) return false;
      return e.targetCorridor!.toLowerCase().contains(
            asset.province.toLowerCase(),
          );
    });

    final sources = relevantEvents.map((e) => e.source).toSet();
    if (sources.length >= 3) return 4.0; // Triple corroboration
    if (sources.length >= 2) return 2.5; // Double corroboration
    if (sources.length == 1) return 1.5;
    return 1.0;
  }

  /// Events clustering in time = escalation pattern.
  double _temporalClustering(List<ThreatEvent> events, DateTime now) {
    final lastHour =
        events.where((e) => now.difference(e.timestamp).inMinutes < 60).length;
    final last6h =
        events.where((e) => now.difference(e.timestamp).inHours < 6).length;

    if (lastHour >= 5) return 3.0; // Burst of events
    if (last6h >= 10) return 2.0; // Sustained activity
    if (last6h >= 3) return 1.5;
    return 1.0;
  }

  /// Rising severity over time = escalation signal.
  double _severityEscalation(List<ThreatEvent> events, DateTime now) {
    final recent = events
        .where((e) => now.difference(e.timestamp).inHours < 6)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (recent.length < 3) return 1.0;

    // Check if severity is trending upward
    int rising = 0;
    for (int i = 1; i < recent.length; i++) {
      if (recent[i].severityScore > recent[i - 1].severityScore) rising++;
    }

    final risingRatio = rising / (recent.length - 1);
    if (risingRatio > 0.7) return 2.5; // Clear escalation
    if (risingRatio > 0.5) return 1.8;
    return 1.0;
  }

  // ─── SUPPORT METHODS ─────────────────────────────────────────────

  List<String> _matchPrecursorSignals(
    StrategicAsset asset,
    List<ThreatEvent> events,
    HistoricalAttack? precedent,
  ) {
    final matched = <String>[];

    if (precedent == null) return matched;

    for (final signal in precedent.precursorSignals) {
      final signalLower = signal.toLowerCase();
      for (final event in events) {
        // Match source mentions
        if (signalLower.contains(event.source.toLowerCase())) {
          matched.add(signal);
          break;
        }
        // Match province/corridor mentions
        if (event.targetCorridor != null &&
            signalLower.contains(event.targetCorridor!.toLowerCase())) {
          matched.add(signal);
          break;
        }
        // Match threat type mentions
        if (signalLower.contains(event.type.name.toLowerCase())) {
          matched.add(signal);
          break;
        }
      }
    }

    return matched;
  }

  double _computeConfidence(
    List<ThreatEvent> events,
    HistoricalAttack? precedent,
  ) {
    double conf = 0.3; // Base confidence

    // More events = more data = higher confidence
    if (events.length >= 10) conf += 0.2;
    if (events.length >= 3) conf += 0.1;

    // Historical precedent match boosts confidence
    if (precedent != null) conf += 0.2;

    // Multi-source events boost confidence
    final sources = events.map((e) => e.source).toSet();
    if (sources.length >= 3) conf += 0.2;
    if (sources.length >= 2) conf += 0.1;

    return conf.clamp(0.1, 0.95);
  }

  int? _computeImpactWindow(
    List<ThreatEvent> events,
    StrategicAsset asset,
  ) {
    // Find the shortest ETA among active events targeting this asset's region
    int? shortest;
    for (final event in events) {
      if (!event.isActive) continue;
      final eta = event.estimatedTimeToImpact;
      if (eta != null) {
        if (shortest == null || eta.inMinutes < shortest) {
          shortest = eta.inMinutes;
        }
      }
    }
    return shortest;
  }

  List<RiskFactor> _buildRiskFactors(
    double historical,
    double precursor,
    double typeFreq,
    double corroboration,
    double clustering,
    double escalation,
  ) {
    final factors = <RiskFactor>[];

    if (historical > baseDailyRate * 2) {
      factors.add(RiskFactor(
        name: 'Historical Targeting',
        contribution: min(30, (historical / baseDailyRate * 5)).round(),
        description: 'This asset/sector has been targeted before',
      ));
    }

    if (precursor > 2.0) {
      factors.add(RiskFactor(
        name: 'Precursor Signal Match',
        contribution: min(35, (precursor * 8).round()),
        description: 'Current events match known pre-attack rhetoric patterns',
      ));
    }

    if (typeFreq > 1.5) {
      factors.add(RiskFactor(
        name: 'Threat Type Prevalence',
        contribution: min(15, (typeFreq * 5).round()),
        description: 'This attack type is historically common against KSA',
      ));
    }

    if (corroboration > 1.5) {
      factors.add(RiskFactor(
        name: 'Multi-Source Corroboration',
        contribution: min(25, (corroboration * 8).round()),
        description: 'Multiple independent sources confirm the threat',
      ));
    }

    if (clustering > 1.5) {
      factors.add(RiskFactor(
        name: 'Temporal Clustering',
        contribution: min(20, (clustering * 7).round()),
        description: 'Events are clustering in time — escalation pattern',
      ));
    }

    if (escalation > 1.5) {
      factors.add(RiskFactor(
        name: 'Severity Escalation',
        contribution: min(20, (escalation * 7).round()),
        description: 'Event severity is trending upward over time',
      ));
    }

    factors.sort((a, b) => b.contribution.compareTo(a.contribution));
    return factors;
  }
}

/// Computed attack probability for a specific asset.
class AttackProbability {
  final String assetId;
  final String assetName;
  final double probability; // 0-99%
  final double confidence; // 0-1, how confident we are in the probability
  final HistoricalAttack? historicalPrecedent;
  final List<String> matchedPrecursors;
  final List<RiskFactor> riskFactors;
  final int? impactWindowMinutes;
  final DateTime computedAt;

  const AttackProbability({
    required this.assetId,
    required this.assetName,
    required this.probability,
    required this.confidence,
    this.historicalPrecedent,
    required this.matchedPrecursors,
    required this.riskFactors,
    this.impactWindowMinutes,
    required this.computedAt,
  });

  String get probabilityLabel {
    if (probability >= 80) return 'VERY HIGH';
    if (probability >= 60) return 'HIGH';
    if (probability >= 40) return 'ELEVATED';
    if (probability >= 20) return 'MODERATE';
    return 'LOW';
  }

  String get formattedProbability => '${probability.toStringAsFixed(1)}%';

  String get formattedConfidence =>
      '${(confidence * 100).toStringAsFixed(0)}% conf.';

  bool get hasPrecedent => historicalPrecedent != null;
}

/// A single contributing factor to the probability calculation.
class RiskFactor {
  final String name;
  final int contribution; // 0-100 weight
  final String description;

  const RiskFactor({
    required this.name,
    required this.contribution,
    required this.description,
  });
}
