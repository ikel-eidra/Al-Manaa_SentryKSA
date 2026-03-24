import '../models/strategic_asset.dart';
import '../models/impact_report.dart';

/// Economic & Recovery Intelligence Engine.
/// Calculates GDP loss, Brent oil price spikes, and supply chain disruptions
/// based on strike simulations against KSA strategic assets.
class EconomicEngine {
  // Baseline constants
  static const double brentBasePrice = 85.0; // USD per barrel
  static const double globalDailyDemand = 100000000.0; // 100M barrels/day
  static const double warVolatilityMultiplier = 5.2;
  static const double ksaDailyOutput = 10500000.0; // 10.5M barrels/day
  static const double ksaGdpDaily = 2739726027.4; // ~$1T annual GDP / 365

  // Petrochemical baseline outputs (tonnes/day)
  static const double ethyleneBaseline = 45000.0;
  static const double ureaBaseline = 30000.0;
  static const double polymerBaseline = 25000.0;

  /// Calculate full economic impact of a strike on a single asset.
  ImpactReport calculateImpact(StrategicAsset asset) {
    // Supply shock: what % of global demand this asset represents
    final supplyShock = (asset.outputValue / globalDailyDemand) * 100;

    // Brent price surge using war volatility multiplier
    final priceSurge = supplyShock * warVolatilityMultiplier;
    final projectedBrent = brentBasePrice * (1 + priceSurge / 100);

    // Daily revenue loss = output * base price (for energy assets)
    final dailyRevenueLoss = asset.sector == 'Energy'
        ? asset.outputValue * brentBasePrice
        : _calculateNonEnergyLoss(asset);

    // Petrochemical cascade impact
    final petrochemImpact = _calculatePetrochemImpact(asset);

    // Recovery timeline
    final repairDays = asset.estimatedRepairDays;

    // Generate prescriptive advice
    final advice = _generateAdvice(asset, supplyShock);

    return ImpactReport(
      assetId: asset.id,
      assetName: asset.name,
      dailyRevenueLoss: dailyRevenueLoss,
      supplyShockPercent: supplyShock,
      brentPriceSurge: priceSurge,
      projectedBrentPrice: projectedBrent,
      estimatedRepairDays: repairDays,
      repairTierLabel: asset.repairTierLabel,
      advice: advice,
      petrochemImpact: petrochemImpact,
      calculatedAt: DateTime.now(),
    );
  }

  /// Calculate aggregate impact from multiple simultaneous strikes.
  List<ImpactReport> calculateMultiStrikeImpact(List<StrategicAsset> assets) {
    return assets.map(calculateImpact).toList();
  }

  /// Aggregate GDP loss across all impacted assets.
  double totalDailyGdpLoss(List<ImpactReport> reports) {
    return reports.fold(0.0, (sum, r) => sum + r.dailyRevenueLoss);
  }

  /// Worst-case Brent projection from combined supply shock.
  double worstCaseBrent(List<ImpactReport> reports) {
    final totalShock =
        reports.fold(0.0, (sum, r) => sum + r.supplyShockPercent);
    return brentBasePrice * (1 + (totalShock * warVolatilityMultiplier) / 100);
  }

  double _calculateNonEnergyLoss(StrategicAsset asset) {
    switch (asset.sector) {
      case 'Water':
        // Cost of emergency water supply replacement
        return asset.outputValue * 0.5; // $0.50 per m³ emergency premium
      case 'Govt':
        // Operational disruption cost estimate
        return 50000000.0; // $50M/day for critical govt infrastructure
      case 'Data':
        // Digital infrastructure disruption
        return 25000000.0; // $25M/day for data center outage
      default:
        return 0.0;
    }
  }

  PetrochemImpact _calculatePetrochemImpact(StrategicAsset asset) {
    if (asset.sector != 'Energy') {
      return const PetrochemImpact(
        ethyleneDisruptionPercent: 0,
        ureaDisruptionPercent: 0,
        polymerDisruptionPercent: 0,
        affectedTradeRoutes: [],
      );
    }

    // Energy disruption cascades into petrochemical supply
    final energyDisruptionFactor = asset.outputValue / ksaDailyOutput;

    return PetrochemImpact(
      ethyleneDisruptionPercent: energyDisruptionFactor * 35, // 35% coupling
      ureaDisruptionPercent: energyDisruptionFactor * 28,
      polymerDisruptionPercent: energyDisruptionFactor * 22,
      affectedTradeRoutes: _getAffectedRoutes(asset),
    );
  }

  List<String> _getAffectedRoutes(StrategicAsset asset) {
    final routes = <String>[];
    if (asset.province == 'Eastern Province' || asset.latitude > 25.0) {
      routes.addAll([
        'Strait of Hormuz → Asia Pacific',
        'Ras Tanura → East Asia',
        'Jubail → India/SE Asia',
      ]);
    }
    if (asset.latitude < 25.0) {
      routes.addAll([
        'Yanbu → Mediterranean/Europe',
        'Red Sea → Suez Canal → Europe',
      ]);
    }
    return routes;
  }

  String _generateAdvice(StrategicAsset asset, double supplyShock) {
    if (supplyShock > 5.0) {
      return 'CRITICAL: Activate strategic petroleum reserves. '
          'Engage OPEC+ emergency protocol. '
          'Redirect output from Shaybah and Khurais spare capacity.';
    } else if (supplyShock > 1.0) {
      return 'HIGH: Deploy mobile repair units to ${asset.name}. '
          'Activate backup desalination if water sector affected. '
          'Relocate EW assets to secondary positions.';
    } else if (asset.sector == 'Water') {
      return 'Pivot to mobile aquifer units and activate emergency '
          'water distribution network. Relocate EW assets.';
    } else {
      return 'Monitor situation. Pre-position repair crews. '
          'Hardened storage online. Move workers to Safe Zone 4.';
    }
  }
}
