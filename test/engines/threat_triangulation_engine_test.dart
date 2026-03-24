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

  group('ThreatTriangulationEngine', () {
    test('returns empty map when no events provided', () {
      final result = engine.triangulate([], [testAsset]);
      expect(result, isEmpty);
    });

    test('returns assessments keyed by asset ID', () {
      final events = [
        ThreatEvent(
          id: 'evt-1',
          type: ThreatType.ballistic,
          source: 'CENTCOM',
          latitude: 26.0,
          longitude: 49.7,
          timestamp: DateTime.now(),
          confidence: 0.92,
          targetCorridor: 'Eastern Province',
          isActive: true,
        ),
      ];

      final result = engine.triangulate(events, [testAsset]);
      expect(result.containsKey('E001'), isTrue);
    });

    test('produces higher score with multiple corroborating sources', () {
      final now = DateTime.now();
      final singleSourceEvents = [
        ThreatEvent(
          id: 'evt-1',
          type: ThreatType.ballistic,
          source: 'CENTCOM',
          latitude: 26.0,
          longitude: 49.7,
          timestamp: now,
          confidence: 0.90,
          targetCorridor: 'Eastern Province',
          isActive: true,
        ),
      ];

      final multiSourceEvents = [
        ThreatEvent(
          id: 'evt-1',
          type: ThreatType.ballistic,
          source: 'CENTCOM',
          latitude: 26.0,
          longitude: 49.7,
          timestamp: now,
          confidence: 0.90,
          targetCorridor: 'Eastern Province',
          isActive: true,
        ),
        ThreatEvent(
          id: 'evt-2',
          type: ThreatType.ballistic,
          source: 'IDF',
          latitude: 26.0,
          longitude: 49.7,
          timestamp: now,
          confidence: 0.85,
          targetCorridor: 'Eastern Province',
          isActive: true,
        ),
      ];

      final singleResult = engine.triangulate(singleSourceEvents, [testAsset]);
      final multiResult = engine.triangulate(multiSourceEvents, [testAsset]);

      expect(
        multiResult['E001']!.score,
        greaterThan(singleResult['E001']!.score),
      );
    });

    test('alert level is critical for high scores', () {
      final events = [
        ThreatEvent(
          id: 'evt-1',
          type: ThreatType.ballistic,
          source: 'CENTCOM',
          latitude: 25.94,
          longitude: 49.68,
          timestamp: DateTime.now(),
          confidence: 0.98,
          targetCorridor: 'Eastern Province',
          isActive: true,
        ),
        ThreatEvent(
          id: 'evt-2',
          type: ThreatType.ballistic,
          source: 'IDF',
          latitude: 25.94,
          longitude: 49.68,
          timestamp: DateTime.now(),
          confidence: 0.95,
          targetCorridor: 'Eastern Province',
          isActive: true,
        ),
        ThreatEvent(
          id: 'evt-3',
          type: ThreatType.cruise,
          source: 'IRNA',
          latitude: 25.95,
          longitude: 49.69,
          timestamp: DateTime.now(),
          confidence: 0.65,
          targetCorridor: 'Eastern Province',
          isActive: true,
        ),
      ];

      final result = engine.triangulate(events, [testAsset]);
      expect(result['E001']!.alertLevel, equals(AlertLevel.critical));
    });
  });
}
