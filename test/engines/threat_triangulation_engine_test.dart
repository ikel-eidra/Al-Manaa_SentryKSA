import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_ksa/engines/threat_triangulation_engine.dart';
import 'package:sentry_ksa/models/threat_event.dart';
import 'package:sentry_ksa/models/strategic_asset.dart';

void main() {
  late ThreatTriangulationEngine engine;

  setUp(() {
    engine = ThreatTriangulationEngine();
  });

  const testAsset = StrategicAsset(
    id: 'E001',
    name: 'Abqaiq Processing Facility',
    sector: 'Energy',
    latitude: 25.9394,
    longitude: 49.6802,
    riskLevel: 3,
    outputValue: 7000000,
    repairTier: 3,
    province: 'Eastern Province',
  );

  ThreatEvent makeEvent({
    required String id,
    required String source,
    ThreatType type = ThreatType.ballistic,
    int severityScore = 8,
    double confidence = 0.90,
    String? targetCorridor = 'Eastern Province',
    Duration? eta = const Duration(minutes: 12),
    DateTime? timestamp,
  }) {
    return ThreatEvent(
      id: id,
      source: source,
      headline: 'Test event $id',
      timestamp: timestamp ?? DateTime.now(),
      type: type,
      severityScore: severityScore,
      confidence: confidence,
      targetCorridor: targetCorridor,
      estimatedTimeToImpact: eta,
      latitude: 26.0,
      longitude: 49.7,
    );
  }

  group('ThreatTriangulationEngine', () {
    test('returns empty map when no events provided', () {
      final result = engine.triangulate([], [testAsset]);
      expect(result, isEmpty);
    });

    test('returns assessments keyed by asset ID', () {
      final events = [makeEvent(id: 'evt-1', source: 'CENTCOM')];
      final result = engine.triangulate(events, [testAsset]);
      expect(result.containsKey('E001'), isTrue);
    });

    test('produces higher score with multiple corroborating sources', () {
      final now = DateTime.now();
      final singleSourceEvents = [
        makeEvent(id: 'evt-1', source: 'CENTCOM', timestamp: now),
      ];

      final multiSourceEvents = [
        makeEvent(id: 'evt-1', source: 'CENTCOM', timestamp: now),
        makeEvent(
          id: 'evt-2',
          source: 'IDF',
          confidence: 0.85,
          timestamp: now,
        ),
      ];

      final singleResult =
          engine.triangulate(singleSourceEvents, [testAsset]);
      final multiResult =
          engine.triangulate(multiSourceEvents, [testAsset]);

      expect(
        multiResult['E001']!.threatScore,
        greaterThan(singleResult['E001']!.threatScore),
      );
    });

    test('alert level is critical for high scores', () {
      final now = DateTime.now();
      final events = [
        makeEvent(
          id: 'evt-1',
          source: 'CENTCOM',
          confidence: 0.98,
          severityScore: 9,
          timestamp: now,
        ),
        makeEvent(
          id: 'evt-2',
          source: 'IDF',
          confidence: 0.95,
          severityScore: 9,
          timestamp: now,
        ),
        makeEvent(
          id: 'evt-3',
          source: 'IRNA',
          type: ThreatType.cruise,
          confidence: 0.65,
          severityScore: 8,
          timestamp: now,
        ),
      ];

      final result = engine.triangulate(events, [testAsset]);
      expect(result['E001']!.alertLevel, equals(AlertLevel.critical));
    });
  });
}
