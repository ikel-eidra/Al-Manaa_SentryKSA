import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_ksa/engines/economic_engine.dart';
import 'package:sentry_ksa/models/strategic_asset.dart';

void main() {
  late EconomicEngine engine;

  setUp(() {
    engine = EconomicEngine();
  });

  const energyAsset = StrategicAsset(
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

  const waterAsset = StrategicAsset(
    id: 'W001',
    name: 'Ras Al-Khair Desalination',
    sector: 'Water',
    latitude: 27.4800,
    longitude: 49.2200,
    riskLevel: 3,
    outputValue: 1025000,
    repairTier: 3,
    province: 'Eastern Province',
  );

  group('EconomicEngine', () {
    test('calculateImpact returns valid report for energy asset', () {
      final report = engine.calculateImpact(energyAsset);

      expect(report.assetId, equals('E001'));
      expect(report.dailyRevenueLoss, greaterThan(0));
      expect(report.supplyShockPercent, greaterThan(0));
      expect(report.projectedBrent, greaterThan(85.0)); // above baseline
    });

    test('calculateImpact returns valid report for water asset', () {
      final report = engine.calculateImpact(waterAsset);

      expect(report.assetId, equals('W001'));
      // Water assets should have lower oil-specific impact
      expect(report.supplyShockPercent, lessThanOrEqualTo(
        engine.calculateImpact(energyAsset).supplyShockPercent,
      ));
    });

    test('multi-strike impact aggregates correctly', () {
      final assets = [energyAsset, waterAsset];
      final reports = assets.map((a) => engine.calculateImpact(a)).toList();

      final totalLoss = reports.fold<double>(
        0,
        (sum, r) => sum + r.dailyRevenueLoss,
      );

      expect(totalLoss, greaterThan(reports[0].dailyRevenueLoss));
    });

    test('higher output assets produce larger economic impact', () {
      const smallAsset = StrategicAsset(
        id: 'E010',
        name: 'Jafurah Gas Field',
        sector: 'Energy',
        latitude: 24.4500,
        longitude: 49.8500,
        riskLevel: 1,
        outputValue: 200000,
        repairTier: 1,
        province: 'Eastern Province',
      );

      final bigImpact = engine.calculateImpact(energyAsset);
      final smallImpact = engine.calculateImpact(smallAsset);

      expect(bigImpact.dailyRevenueLoss, greaterThan(smallImpact.dailyRevenueLoss));
    });
  });
}
