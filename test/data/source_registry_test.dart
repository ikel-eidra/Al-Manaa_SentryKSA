import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_ksa/data/source_registry.dart';

void main() {
  group('SourceRegistry', () {
    test('allReferences is not empty', () {
      expect(SourceRegistry.allReferences, isNotEmpty);
    });

    test('all references have valid credibility scores', () {
      for (final ref in SourceRegistry.allReferences) {
        expect(ref.credibilityScore, inInclusiveRange(0.0, 1.0),
            reason: '${ref.headline} has invalid credibility');
      }
    });

    test('all references have non-empty hash', () {
      for (final ref in SourceRegistry.allReferences) {
        expect(ref.hash, isNotEmpty);
        expect(ref.hash.length, equals(16));
      }
    });

    test('all hashes are unique', () {
      final hashes = SourceRegistry.allReferences.map((r) => r.hash).toSet();
      expect(hashes.length, equals(SourceRegistry.allReferences.length));
    });

    test('hash verification passes for all references', () {
      for (final ref in SourceRegistry.allReferences) {
        expect(SourceRegistry.verifyHash(ref), isTrue,
            reason: '${ref.headline} hash mismatch');
      }
    });

    test('byHash returns correct reference', () {
      final first = SourceRegistry.allReferences.first;
      final found = SourceRegistry.byHash(first.hash);
      expect(found, isNotNull);
      expect(found!.headline, equals(first.headline));
    });

    test('scenario-modeled entries have lower credibility than verified', () {
      final modeled = SourceRegistry.scenarioModeledSources;
      expect(modeled, isNotEmpty);

      for (final ref in modeled) {
        expect(ref.credibilityScore, lessThanOrEqualTo(0.80),
            reason:
                'Scenario-modeled entry "${ref.headline}" should have reduced credibility');
        expect(ref.tags, contains('scenario-modeled'));
      }
    });

    test('late precursor events are from Jul-Dec 2024', () {
      final precursors = SourceRegistry.latePrecursorEvents;
      expect(precursors, isNotEmpty);

      for (final ref in precursors) {
        final date = DateTime.parse(ref.publishedDate);
        expect(date.year, equals(2024));
        expect(date.month, greaterThanOrEqualTo(7));
      }
    });

    test('pre-war simmering period covers Jan-Feb 2025', () {
      final simmering = SourceRegistry.preWarSimmeringPeriod;
      expect(simmering, isNotEmpty);

      for (final ref in simmering) {
        final date = DateTime.parse(ref.publishedDate);
        expect(date.year, equals(2025));
        expect(date.month, lessThanOrEqualTo(2));
      }
    });

    test('Oct 2024 Iran strike is in registry', () {
      final oct2024 = SourceRegistry.allReferences.where(
        (r) => r.publishedDate == '2024-10-01',
      );
      expect(oct2024.length, greaterThanOrEqualTo(2),
          reason: 'Should have multiple sources for Oct 1 Iran strike');
    });

    test('forAttack returns sources for known attack', () {
      final sources = SourceRegistry.forAttack('HA-2019-001');
      expect(sources.length, greaterThanOrEqualTo(3));
    });
  });
}
