import 'package:flutter/material.dart';

/// Bottom panel showing strike statistics, interception rates, and policy advice.
class AnalyticsPanel extends StatelessWidget {
  final int totalStrikes;
  final double interceptRate;
  final double brentImpact;
  final int criticalAssets;

  const AnalyticsPanel({
    super.key,
    required this.totalStrikes,
    required this.interceptRate,
    required this.brentImpact,
    required this.criticalAssets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
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
          const SizedBox(height: 14),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Strikes (Feb 28)', '$totalStrikes'),
              _statItem('Intercept Rate', '${interceptRate.toStringAsFixed(0)}%'),
              _statItem('Brent Impact', '+\$${brentImpact.toStringAsFixed(2)}'),
              _statItem('Critical HVTs', '$criticalAssets'),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 12),

          // Infographic summary
          Row(
            children: [
              _miniChart(interceptRate / 100),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEFENSE POSTURE: ${interceptRate > 85 ? "STRONG" : "DEGRADED"}',
                      style: TextStyle(
                        color: interceptRate > 85
                            ? Colors.greenAccent
                            : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ADVICE: Hardened storage online. Move workers to Safe Zone 4. '
                      'Maintain Patriot battery readiness.',
                      style: TextStyle(
                        color: Colors.greenAccent.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  /// Mini circular progress chart for interception rate.
  Widget _miniChart(double percent) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 3,
            backgroundColor: Colors.red.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              percent > 0.85 ? Colors.greenAccent : Colors.orange,
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
