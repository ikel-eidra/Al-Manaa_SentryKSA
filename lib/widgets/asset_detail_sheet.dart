import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/strategic_asset.dart';
import '../models/impact_report.dart';
import '../providers/threat_provider.dart';
import '../engines/threat_triangulation_engine.dart';

/// Bottom sheet showing detailed asset info, economic impact, and recovery timeline.
class AssetDetailSheet extends StatelessWidget {
  final StrategicAsset asset;

  const AssetDetailSheet({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThreatProvider>(
      builder: (context, provider, _) {
        final impact = provider.getImpactReport(asset.id);
        final assessment = provider.getAssessment(asset.id);

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Asset header
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // Threat assessment
                  if (assessment != null) _buildThreatSection(assessment),
                  const SizedBox(height: 16),

                  // Economic impact
                  if (impact != null) _buildImpactSection(impact),
                  const SizedBox(height: 16),

                  // Recovery timeline
                  _buildRecoverySection(impact),
                  const SizedBox(height: 16),

                  // Advice
                  if (impact != null) _buildAdviceSection(impact),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    final riskColor = asset.riskLevel == 3
        ? Colors.red
        : asset.riskLevel == 2
            ? Colors.orange
            : Colors.yellow;

    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: riskColor.withOpacity(0.4)),
          ),
          alignment: Alignment.center,
          child: Text(
            asset.sectorIcon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asset.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _chip(asset.sector, Colors.blue),
                  const SizedBox(width: 6),
                  _chip('Risk ${asset.riskLevel}/3', riskColor),
                  const SizedBox(width: 6),
                  _chip(asset.id, Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThreatSection(ThreatAssessment assessment) {
    final color = assessment.alertLevel == AlertLevel.critical
        ? Colors.red
        : assessment.alertLevel == AlertLevel.high
            ? Colors.orange
            : Colors.yellow;

    return _section(
      'THREAT ASSESSMENT',
      color,
      Column(
        children: [
          _row('Score', '${assessment.threatScore.toStringAsFixed(1)}/100'),
          _row('Alert Level', assessment.alertLevel.name.toUpperCase()),
          _row('ETA', assessment.formattedEta),
          if (assessment.primaryThreat != null)
            _row('Primary Source',
                '${assessment.primaryThreat!.sourceFlag} ${assessment.primaryThreat!.source}'),
          _row('Contributing Events',
              '${assessment.contributingEvents.length} sources'),
        ],
      ),
    );
  }

  Widget _buildImpactSection(ImpactReport impact) {
    return _section(
      'ECONOMIC IMPACT',
      Colors.amber,
      Column(
        children: [
          _row('Daily Revenue Loss', impact.formattedDailyLoss),
          _row('Supply Shock',
              '${impact.supplyShockPercent.toStringAsFixed(2)}% global'),
          _row('Brent Surge', impact.formattedBrentSurge),
          _row('Projected Brent',
              '\$${impact.projectedBrentPrice.toStringAsFixed(2)}/bbl'),
          if (impact.petrochemImpact.ethyleneDisruptionPercent > 0) ...[
            const SizedBox(height: 8),
            const Text(
              'SUPPLY CHAIN CASCADE',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            _row('Ethylene',
                '-${impact.petrochemImpact.ethyleneDisruptionPercent.toStringAsFixed(1)}%'),
            _row('Urea/Fertilizer',
                '-${impact.petrochemImpact.ureaDisruptionPercent.toStringAsFixed(1)}%'),
            _row('Polymers',
                '-${impact.petrochemImpact.polymerDisruptionPercent.toStringAsFixed(1)}%'),
          ],
        ],
      ),
    );
  }

  Widget _buildRecoverySection(ImpactReport? impact) {
    return _section(
      'DAY ZERO RECOVERY',
      Colors.cyan,
      Column(
        children: [
          _row('Damage Tier', asset.repairTierLabel),
          _row('Estimated Repair', '${asset.estimatedRepairDays} Days'),
          _row('Output Value',
              '${(asset.outputValue / 1000000).toStringAsFixed(1)}M units/day'),
          if (impact != null)
            _row('Total Recovery Cost',
                '\$${(impact.dailyRevenueLoss * asset.estimatedRepairDays / 1000000000).toStringAsFixed(1)}B'),
        ],
      ),
    );
  }

  Widget _buildAdviceSection(ImpactReport impact) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRESCRIPTIVE ADVICE',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            impact.advice,
            style: TextStyle(
              color: Colors.greenAccent.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Color color, Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
