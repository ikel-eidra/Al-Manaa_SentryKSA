import 'package:flutter/material.dart';
import '../engines/threat_triangulation_engine.dart';

/// Bottom panel showing live strike statistics, economic impact, and prescriptive advice.
/// Fully data-driven from ThreatProvider aggregates.
class AnalyticsPanel extends StatelessWidget {
  final int totalStrikes;
  final double interceptRate;
  final double brentDelta;
  final double worstCaseBrent;
  final int criticalAssets;
  final int assetsUnderThreat;
  final double totalDailyLoss;
  final List<ThreatAssessment> criticalAssessments;

  const AnalyticsPanel({
    super.key,
    required this.totalStrikes,
    required this.interceptRate,
    required this.brentDelta,
    required this.worstCaseBrent,
    required this.criticalAssets,
    required this.assetsUnderThreat,
    required this.totalDailyLoss,
    required this.criticalAssessments,
  });

  @override
  Widget build(BuildContext context) {
    final isElevated = criticalAssets > 0 || assetsUnderThreat > 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xF01A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isElevated
                ? Colors.red.withOpacity(0.4)
                : Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          // Primary stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(
                '$totalStrikes',
                'Strikes',
                Colors.white,
              ),
              _statItem(
                '${interceptRate.toStringAsFixed(0)}%',
                'Intercept',
                interceptRate > 85 ? Colors.greenAccent : Colors.orange,
              ),
              _statItem(
                '+\$${brentDelta.toStringAsFixed(1)}',
                'Brent Δ',
                brentDelta > 10 ? Colors.red : Colors.amber,
              ),
              _statItem(
                '$criticalAssets',
                'CRITICAL',
                criticalAssets > 0 ? Colors.red : Colors.greenAccent,
              ),
            ],
          ),

          const SizedBox(height: 8),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          const SizedBox(height: 8),

          // Secondary row: economic + threat summary
          Row(
            children: [
              // Intercept gauge
              _miniGauge(interceptRate / 100, isElevated),
              const SizedBox(width: 12),

              // Summary text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Posture line
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isElevated ? Colors.red : Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isElevated
                              ? 'THREAT POSTURE: ELEVATED'
                              : 'DEFENSE POSTURE: STRONG',
                          style: TextStyle(
                            color:
                                isElevated ? Colors.red : Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Economic summary
                    Text(
                      _economicSummary(),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 9,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 3),

                    // Prescriptive advice
                    Text(
                      _generateAdvice(),
                      style: TextStyle(
                        color: Colors.greenAccent.withOpacity(0.7),
                        fontSize: 9,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Critical asset ticker (if any)
          if (criticalAssessments.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 24,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: criticalAssessments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final a = criticalAssessments[i];
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${a.assetName} ${a.formattedEta}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _economicSummary() {
    final lossBillions = totalDailyLoss / 1000000000;
    if (lossBillions < 0.001) {
      return 'Brent \$${worstCaseBrent.toStringAsFixed(1)}/bbl | $assetsUnderThreat assets monitored';
    }
    return 'Projected loss: \$${lossBillions.toStringAsFixed(1)}B/day | '
        'Brent \$${worstCaseBrent.toStringAsFixed(1)}/bbl | '
        '$assetsUnderThreat assets under threat';
  }

  String _generateAdvice() {
    if (criticalAssets > 2) {
      return 'ADVICE: Activate strategic reserves. OPEC+ emergency protocol. '
          'Relocate all non-essential personnel.';
    } else if (criticalAssets > 0) {
      return 'ADVICE: Harden critical infrastructure. Deploy Patriot batteries '
          'to forward positions. Activate backup systems.';
    } else if (assetsUnderThreat > 0) {
      return 'ADVICE: Maintain heightened surveillance. Pre-position repair '
          'crews. Hardened storage online.';
    }
    return 'ADVICE: Continue routine monitoring. All systems nominal. '
        'Patriot readiness: GREEN.';
  }

  Widget _statItem(String value, String label, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey[600],
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _miniGauge(double percent, bool isElevated) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 3,
            backgroundColor: Colors.red.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
              isElevated ? Colors.orange : Colors.greenAccent,
            ),
          ),
          Text(
            '${(percent * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
