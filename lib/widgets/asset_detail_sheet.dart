import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/strategic_asset.dart';
import '../models/impact_report.dart';
import '../providers/threat_provider.dart';
import '../engines/threat_triangulation_engine.dart';
import '../engines/probability_engine.dart';
import '../data/historical_attack_registry.dart';

/// Bottom sheet showing detailed asset info, probability analysis,
/// historical attack precedents, economic impact, and recovery timeline.
class AssetDetailSheet extends StatelessWidget {
  final StrategicAsset asset;

  const AssetDetailSheet({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThreatProvider>(
      builder: (context, provider, _) {
        final impact = provider.getImpactReport(asset.id);
        final assessment = provider.getAssessment(asset.id);
        final prob = assessment?.attackProbability;
        final history = HistoricalAttackRegistry.forAsset(asset.id);
        final sectorHistory = HistoricalAttackRegistry.forSector(asset.sector);

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
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

                  _buildHeader(),
                  const SizedBox(height: 16),

                  // Probability analysis
                  if (prob != null) _buildProbabilitySection(prob),
                  if (prob != null) const SizedBox(height: 16),

                  // Threat assessment
                  if (assessment != null) _buildThreatSection(assessment),
                  const SizedBox(height: 16),

                  // Historical attacks on THIS asset
                  if (history.isNotEmpty) _buildHistorySection(
                    'ATTACK HISTORY: ${asset.name}',
                    history,
                    Colors.red,
                  ),
                  if (history.isNotEmpty) const SizedBox(height: 16),

                  // Historical attacks on this SECTOR
                  if (sectorHistory.isNotEmpty)
                    _buildHistorySection(
                      'SECTOR HISTORY: ${asset.sector.toUpperCase()}',
                      sectorHistory.where((a) => !history.contains(a)).toList(),
                      Colors.orange,
                    ),
                  if (sectorHistory.isNotEmpty) const SizedBox(height: 16),

                  // Economic impact
                  if (impact != null) _buildImpactSection(impact),
                  const SizedBox(height: 16),

                  // Recovery timeline
                  _buildRecoverySection(impact),
                  const SizedBox(height: 16),

                  // Advice
                  if (impact != null) _buildAdviceSection(impact),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── PROBABILITY SECTION ─────────────────────────────────────────

  Widget _buildProbabilitySection(AttackProbability prob) {
    final probColor = prob.probability >= 60
        ? Colors.red
        : prob.probability >= 40
            ? Colors.orange
            : prob.probability >= 20
                ? Colors.amber
                : Colors.green;

    return _section(
      'STRIKE PROBABILITY ANALYSIS',
      probColor,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main probability display
          Row(
            children: [
              // Large probability number
              Text(
                '${prob.probability.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: probColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prob.probabilityLabel,
                      style: TextStyle(
                        color: probColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      prob.formattedConfidence,
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Probability bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prob.probability / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[900],
              valueColor: AlwaysStoppedAnimation<Color>(probColor),
            ),
          ),
          const SizedBox(height: 12),

          // Risk factor breakdown
          if (prob.riskFactors.isNotEmpty) ...[
            Text(
              'CONTRIBUTING FACTORS',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            ...prob.riskFactors.map((f) => _buildRiskFactorRow(f)),
          ],

          // Historical precedent match
          if (prob.hasPrecedent) ...[
            const SizedBox(height: 10),
            _buildPrecedentCard(prob.historicalPrecedent!),
          ],

          // Matched precursor signals
          if (prob.matchedPrecursors.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'MATCHED PRECURSOR SIGNALS',
              style: TextStyle(
                color: Colors.orange[300],
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            ...prob.matchedPrecursors.map((s) => Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.radio_button_checked,
                          color: Colors.orange[300], size: 10),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskFactorRow(RiskFactor factor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${factor.contribution}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: factor.contribution / 35,
                minHeight: 4,
                backgroundColor: Colors.grey[900],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              factor.name,
              style: TextStyle(color: Colors.grey[400], fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecedentCard(HistoricalAttack attack) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.amber, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'CLOSEST PRECEDENT: ${attack.name}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${attack.date} | ${attack.attribution} | ${attack.outcomeLabel}',
            style: TextStyle(color: Colors.grey[500], fontSize: 9),
          ),
          if (attack.productionLossBarrels > 0)
            Text(
              'Production loss: ${attack.formattedLoss} for ${attack.durationDays} days',
              style: TextStyle(color: Colors.grey[500], fontSize: 9),
            ),
          if (attack.brentSpikeDollars > 0)
            Text(
              'Brent spike: +\$${attack.brentSpikeDollars.toStringAsFixed(1)}/bbl',
              style: TextStyle(color: Colors.grey[500], fontSize: 9),
            ),
        ],
      ),
    );
  }

  // ─── HISTORICAL ATTACKS SECTION ──────────────────────────────────

  Widget _buildHistorySection(
    String title,
    List<HistoricalAttack> attacks,
    Color color,
  ) {
    if (attacks.isEmpty) return const SizedBox.shrink();

    return _section(
      title,
      color,
      Column(
        children: attacks.map((attack) {
          final outcomeColor = attack.intercepted
              ? Colors.greenAccent
              : attack.outcome == AttackOutcome.partialDamage
                  ? Colors.orange
                  : Colors.yellow;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        attack.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _chip(attack.outcomeLabel, outcomeColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${attack.date} | ${attack.attribution} | ${attack.attackVector}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 9),
                ),
                const SizedBox(height: 4),
                Text(
                  attack.description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Colors.cyan[300], size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          attack.lessonLearned,
                          style: TextStyle(
                            color: Colors.cyan[300],
                            fontSize: 9,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (attack.productionLossBarrels > 0 ||
                    attack.brentSpikeDollars > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (attack.productionLossBarrels > 0)
                        _chip(attack.formattedLoss, Colors.red),
                      if (attack.productionLossBarrels > 0)
                        const SizedBox(width: 4),
                      if (attack.brentSpikeDollars > 0)
                        _chip(
                            'Brent +\$${attack.brentSpikeDollars.toStringAsFixed(1)}',
                            Colors.amber),
                      const SizedBox(width: 4),
                      _chip('${attack.durationDays}d recovery', Colors.cyan),
                    ],
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── EXISTING SECTIONS (unchanged logic) ─────────────────────────

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
          child: Text(asset.sectorIcon, style: const TextStyle(fontSize: 24)),
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
                  _chip(asset.province, Colors.grey),
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
          _row('Probability',
              '${assessment.probability.toStringAsFixed(1)}% (${assessment.probabilityLabel})'),
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

  // ─── SHARED WIDGETS ──────────────────────────────────────────────

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
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
