/// Model representing a KSA Strategic Asset (Energy, Water, Govt, Data).
class StrategicAsset {
  final String id;
  final String name;
  final String sector; // Energy, Water, Govt, Data
  final double latitude;
  final double longitude;
  final int riskLevel; // 1: Low, 2: Medium, 3: High
  final double outputValue; // Barrels/day (Energy) or m³/day (Water)
  final int repairTier; // 1: Superficial (14d), 2: Component (180d), 3: Structural (540d)
  final String province;

  const StrategicAsset({
    required this.id,
    required this.name,
    required this.sector,
    required this.latitude,
    required this.longitude,
    required this.riskLevel,
    required this.outputValue,
    required this.repairTier,
    this.province = '',
  });

  /// Estimated Repair Duration in days based on repair tier.
  int get estimatedRepairDays {
    switch (repairTier) {
      case 1:
        return 14;
      case 2:
        return 180;
      case 3:
        return 540;
      default:
        return 0;
    }
  }

  String get repairTierLabel {
    switch (repairTier) {
      case 1:
        return 'Superficial';
      case 2:
        return 'Component';
      case 3:
        return 'Structural';
      default:
        return 'Unknown';
    }
  }

  String get sectorIcon {
    switch (sector) {
      case 'Energy':
        return '⚡';
      case 'Water':
        return '💧';
      case 'Govt':
        return '🏛️';
      case 'Military':
        return '🎖️';
      case 'Transport':
        return '🚢';
      case 'Power':
        return '🔌';
      case 'Financial':
        return '🏦';
      case 'Data':
        return '🖥️';
      default:
        return '📍';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sector': sector,
        'latitude': latitude,
        'longitude': longitude,
        'riskLevel': riskLevel,
        'outputValue': outputValue,
        'repairTier': repairTier,
        'province': province,
      };

  factory StrategicAsset.fromJson(Map<String, dynamic> json) => StrategicAsset(
        id: json['id'] as String,
        name: json['name'] as String,
        sector: json['sector'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        riskLevel: json['riskLevel'] as int,
        outputValue: (json['outputValue'] as num).toDouble(),
        repairTier: json['repairTier'] as int,
        province: json['province'] as String? ?? '',
      );
}
