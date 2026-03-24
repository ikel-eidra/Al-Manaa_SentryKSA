import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_ksa/data/asset_inventory.dart';

void main() {
  group('AssetInventory', () {
    test('allAssets is not empty', () {
      expect(AssetInventory.allAssets, isNotEmpty);
    });

    test('all assets have unique IDs', () {
      final ids = AssetInventory.allAssets.map((a) => a.id).toSet();
      expect(ids.length, equals(AssetInventory.allAssets.length));
    });

    test('all assets have valid coordinates', () {
      for (final asset in AssetInventory.allAssets) {
        expect(asset.latitude, inInclusiveRange(15.0, 32.0),
            reason: '${asset.name} latitude out of KSA range');
        expect(asset.longitude, inInclusiveRange(34.0, 56.0),
            reason: '${asset.name} longitude out of KSA range');
      }
    });

    test('all assets have valid risk levels (1-3)', () {
      for (final asset in AssetInventory.allAssets) {
        expect(asset.riskLevel, inInclusiveRange(1, 3));
      }
    });

    test('all assets have valid repair tiers (1-3)', () {
      for (final asset in AssetInventory.allAssets) {
        expect(asset.repairTier, inInclusiveRange(1, 3));
      }
    });

    test('bySector filters correctly', () {
      final energyAssets = AssetInventory.bySector('Energy');
      expect(energyAssets, isNotEmpty);
      for (final asset in energyAssets) {
        expect(asset.sector, equals('Energy'));
      }
    });

    test('byRiskLevel filters correctly', () {
      final critical = AssetInventory.byRiskLevel(3);
      expect(critical, isNotEmpty);
      for (final asset in critical) {
        expect(asset.riskLevel, equals(3));
      }
    });

    test('findById returns correct asset', () {
      final asset = AssetInventory.findById('E001');
      expect(asset, isNotNull);
      expect(asset!.name, contains('Abqaiq'));
    });

    test('findById returns null for unknown ID', () {
      final asset = AssetInventory.findById('UNKNOWN');
      expect(asset, isNull);
    });

    test('contains all four sectors', () {
      final sectors = AssetInventory.allAssets.map((a) => a.sector).toSet();
      expect(sectors, containsAll(['Energy', 'Water', 'Govt', 'Data']));
    });
  });
}
