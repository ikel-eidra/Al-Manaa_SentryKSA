import '../models/strategic_asset.dart';

/// Static inventory of KSA strategic assets monitored by SentryKSA.
/// Includes energy infrastructure, water desalination, government facilities,
/// and data centers across Saudi provinces.
class AssetInventory {
  AssetInventory._();

  static const List<StrategicAsset> allAssets = [
    // ─── ENERGY SECTOR ───────────────────────────────────────────────
    StrategicAsset(
      id: 'E001',
      name: 'Abqaiq Processing Facility',
      sector: 'Energy',
      latitude: 25.9394,
      longitude: 49.6802,
      riskLevel: 3,
      outputValue: 7000000, // 7M bbl/day processing capacity
      repairTier: 3,
      province: 'Eastern Province',
    ),
    StrategicAsset(
      id: 'E002',
      name: 'Ras Tanura Refinery & Terminal',
      sector: 'Energy',
      latitude: 26.6441,
      longitude: 50.1610,
      riskLevel: 3,
      outputValue: 550000,
      repairTier: 3,
      province: 'Eastern Province',
    ),
    StrategicAsset(
      id: 'E003',
      name: 'Ghawar Oil Field',
      sector: 'Energy',
      latitude: 24.9000,
      longitude: 49.2500,
      riskLevel: 3,
      outputValue: 3800000, // largest conventional oil field
      repairTier: 2,
      province: 'Eastern Province',
    ),
    StrategicAsset(
      id: 'E004',
      name: 'Khurais Oil Field',
      sector: 'Energy',
      latitude: 24.1640,
      longitude: 48.1880,
      riskLevel: 2,
      outputValue: 1500000,
      repairTier: 2,
      province: 'Eastern Province',
    ),
    StrategicAsset(
      id: 'E005',
      name: 'Shaybah Oil Field',
      sector: 'Energy',
      latitude: 22.5150,
      longitude: 54.0290,
      riskLevel: 2,
      outputValue: 1000000,
      repairTier: 2,
      province: 'Eastern Province',
    ),
    StrategicAsset(
      id: 'E006',
      name: 'Yanbu Refinery Complex',
      sector: 'Energy',
      latitude: 24.0231,
      longitude: 38.0612,
      riskLevel: 2,
      outputValue: 400000,
      repairTier: 2,
      province: 'Madinah Province',
    ),
    StrategicAsset(
      id: 'E007',
      name: 'Jubail Industrial City',
      sector: 'Energy',
      latitude: 27.0046,
      longitude: 49.6220,
      riskLevel: 3,
      outputValue: 350000,
      repairTier: 3,
      province: 'Eastern Province',
    ),
    StrategicAsset(
      id: 'E008',
      name: 'Dhahran Aramco HQ & R&D',
      sector: 'Energy',
      latitude: 26.2867,
      longitude: 50.1135,
      riskLevel: 2,
      outputValue: 0, // command & control, not production
      repairTier: 1,
      province: 'Eastern Province',
    ),
    StrategicAsset(
      id: 'E009',
      name: 'SATORP Jubail Refinery',
      sector: 'Energy',
      latitude: 27.0100,
      longitude: 49.6600,
      riskLevel: 2,
      outputValue: 400000,
      repairTier: 2,
      province: 'Eastern Province',
    ),
    StrategicAsset(
      id: 'E010',
      name: 'Jafurah Gas Field',
      sector: 'Energy',
      latitude: 24.4500,
      longitude: 49.8500,
      riskLevel: 1,
      outputValue: 200000,
      repairTier: 1,
      province: 'Eastern Province',
    ),

    // ─── WATER SECTOR ────────────────────────────────────────────────
    StrategicAsset(
      id: 'W001',
      name: 'Ras Al-Khair Desalination',
      sector: 'Water',
      latitude: 27.4800,
      longitude: 49.2200,
      riskLevel: 3,
      outputValue: 1025000, // m³/day - largest in the world
      repairTier: 3,
      province: 'Eastern Province',
    ),
    StrategicAsset(
      id: 'W002',
      name: 'Shoaiba Desalination Plant',
      sector: 'Water',
      latitude: 20.6900,
      longitude: 39.5100,
      riskLevel: 2,
      outputValue: 880000,
      repairTier: 2,
      province: 'Makkah Province',
    ),
    StrategicAsset(
      id: 'W003',
      name: 'Jubail Desalination Plant',
      sector: 'Water',
      latitude: 26.9700,
      longitude: 49.5700,
      riskLevel: 2,
      outputValue: 800000,
      repairTier: 2,
      province: 'Eastern Province',
    ),
    StrategicAsset(
      id: 'W004',
      name: 'Yanbu Desalination Plant',
      sector: 'Water',
      latitude: 24.0200,
      longitude: 38.0500,
      riskLevel: 1,
      outputValue: 450000,
      repairTier: 1,
      province: 'Madinah Province',
    ),
    StrategicAsset(
      id: 'W005',
      name: 'Al Khobar Desalination Plant',
      sector: 'Water',
      latitude: 26.2200,
      longitude: 50.2000,
      riskLevel: 1,
      outputValue: 330000,
      repairTier: 1,
      province: 'Eastern Province',
    ),

    // ─── GOVERNMENT SECTOR ───────────────────────────────────────────
    StrategicAsset(
      id: 'G001',
      name: 'Ministry of Defense (Riyadh)',
      sector: 'Govt',
      latitude: 24.6502,
      longitude: 46.7100,
      riskLevel: 3,
      outputValue: 0,
      repairTier: 2,
      province: 'Riyadh Province',
    ),
    StrategicAsset(
      id: 'G002',
      name: 'King Abdulaziz Air Base',
      sector: 'Govt',
      latitude: 26.2653,
      longitude: 50.1522,
      riskLevel: 3,
      outputValue: 0,
      repairTier: 3,
      province: 'Eastern Province',
    ),
    StrategicAsset(
      id: 'G003',
      name: 'Prince Sultan Air Base',
      sector: 'Govt',
      latitude: 24.0627,
      longitude: 47.5805,
      riskLevel: 2,
      outputValue: 0,
      repairTier: 2,
      province: 'Riyadh Province',
    ),
    StrategicAsset(
      id: 'G004',
      name: 'King Khalid Military City',
      sector: 'Govt',
      latitude: 27.9050,
      longitude: 45.5300,
      riskLevel: 2,
      outputValue: 0,
      repairTier: 2,
      province: 'Northern Borders',
    ),
    StrategicAsset(
      id: 'G005',
      name: 'Royal Saudi Naval Forces HQ',
      sector: 'Govt',
      latitude: 21.3891,
      longitude: 39.8579,
      riskLevel: 2,
      outputValue: 0,
      repairTier: 2,
      province: 'Makkah Province',
    ),

    // ─── DATA SECTOR ─────────────────────────────────────────────────
    StrategicAsset(
      id: 'D001',
      name: 'NEOM Tech Hub Data Center',
      sector: 'Data',
      latitude: 26.5500,
      longitude: 36.0700,
      riskLevel: 1,
      outputValue: 0,
      repairTier: 1,
      province: 'Tabuk Province',
    ),
    StrategicAsset(
      id: 'D002',
      name: 'STC Riyadh Data Center',
      sector: 'Data',
      latitude: 24.7136,
      longitude: 46.6753,
      riskLevel: 2,
      outputValue: 0,
      repairTier: 1,
      province: 'Riyadh Province',
    ),
    StrategicAsset(
      id: 'D003',
      name: 'Aramco Dhahran Cloud Center',
      sector: 'Data',
      latitude: 26.2700,
      longitude: 50.1200,
      riskLevel: 2,
      outputValue: 0,
      repairTier: 1,
      province: 'Eastern Province',
    ),
    StrategicAsset(
      id: 'D004',
      name: 'NIC National Information Center',
      sector: 'Data',
      latitude: 24.6883,
      longitude: 46.7225,
      riskLevel: 3,
      outputValue: 0,
      repairTier: 2,
      province: 'Riyadh Province',
    ),
  ];

  /// Assets filtered by sector.
  static List<StrategicAsset> bySector(String sector) =>
      allAssets.where((a) => a.sector == sector).toList();

  /// Assets filtered by risk level.
  static List<StrategicAsset> byRiskLevel(int level) =>
      allAssets.where((a) => a.riskLevel == level).toList();

  /// Assets filtered by province.
  static List<StrategicAsset> byProvince(String province) =>
      allAssets.where((a) => a.province == province).toList();

  /// All critical (risk level 3) assets.
  static List<StrategicAsset> get criticalAssets => byRiskLevel(3);

  /// Lookup a single asset by ID.
  static StrategicAsset? findById(String id) {
    try {
      return allAssets.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
