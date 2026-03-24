/// Result model from the Economic & Recovery Impact calculation.
class ImpactReport {
  final String assetId;
  final String assetName;
  final double dailyRevenueLoss;
  final double supplyShockPercent;
  final double brentPriceSurge;
  final double projectedBrentPrice;
  final int estimatedRepairDays;
  final String repairTierLabel;
  final String advice;
  final PetrochemImpact petrochemImpact;
  final DateTime calculatedAt;

  const ImpactReport({
    required this.assetId,
    required this.assetName,
    required this.dailyRevenueLoss,
    required this.supplyShockPercent,
    required this.brentPriceSurge,
    required this.projectedBrentPrice,
    required this.estimatedRepairDays,
    required this.repairTierLabel,
    required this.advice,
    required this.petrochemImpact,
    required this.calculatedAt,
  });

  String get formattedDailyLoss =>
      '\$${(dailyRevenueLoss / 1000000).toStringAsFixed(1)}M / Day';

  String get formattedBrentSurge =>
      '+${brentPriceSurge.toStringAsFixed(2)}% Brent';

  String get formattedRecovery => '$estimatedRepairDays Days ($repairTierLabel)';
}

/// Impact on downstream petrochemical and fertilizer supply chains.
class PetrochemImpact {
  final double ethyleneDisruptionPercent;
  final double ureaDisruptionPercent;
  final double polymerDisruptionPercent;
  final List<String> affectedTradeRoutes;

  const PetrochemImpact({
    required this.ethyleneDisruptionPercent,
    required this.ureaDisruptionPercent,
    required this.polymerDisruptionPercent,
    required this.affectedTradeRoutes,
  });
}
