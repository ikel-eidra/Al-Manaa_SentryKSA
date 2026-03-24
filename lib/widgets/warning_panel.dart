import 'package:flutter/material.dart';
import '../data/historical_attack_registry.dart';

/// Emergency countdown warning panel with probability meter and historical
/// precedent context. Displayed during active threats.
class WarningPanel extends StatefulWidget {
  final String countdown;
  final String threatType;
  final String targetCorridor;
  final double? probability;
  final String? probabilityLabel;
  final HistoricalAttack? historicalPrecedent;
  final List<String> matchedPrecursors;
  final VoidCallback? onShelter;
  final VoidCallback? onEvacuate;
  final VoidCallback? onShare;

  const WarningPanel({
    super.key,
    required this.countdown,
    required this.threatType,
    required this.targetCorridor,
    this.probability,
    this.probabilityLabel,
    this.historicalPrecedent,
    this.matchedPrecursors = const [],
    this.onShelter,
    this.onEvacuate,
    this.onShare,
  });

  @override
  State<WarningPanel> createState() => _WarningPanelState();
}

class _WarningPanelState extends State<WarningPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _borderPulse;
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _borderPulse = Tween(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowPulse = Tween(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.94),
            border: Border.all(
              color: Colors.red,
              width: _borderPulse.value,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(_glowPulse.value),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Threat type header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.red.withOpacity(0.6 + _glowPulse.value),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'IMMINENT THREAT: ${widget.threatType}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Countdown timer
              Text(
                widget.countdown,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'monospace',
                  letterSpacing: 6,
                  shadows: [
                    Shadow(
                      color: Colors.red.withOpacity(_glowPulse.value),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),

              // Target corridor
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gps_fixed, color: Colors.grey[600], size: 11),
                  const SizedBox(width: 4),
                  Text(
                    'Target: ${widget.targetCorridor}',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── PROBABILITY METER ──────────────────────────────
              if (widget.probability != null) _buildProbabilityMeter(),

              // ── HISTORICAL PRECEDENT ───────────────────────────
              if (widget.historicalPrecedent != null) ...[
                const SizedBox(height: 8),
                _buildPrecedentBanner(),
              ],

              // ── MATCHED PRECURSOR SIGNALS ──────────────────────
              if (widget.matchedPrecursors.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildPrecursorSignals(),
              ],

              const SizedBox(height: 10),

              // Action bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionChip('SHELTER', Colors.orange, Icons.home,
                      widget.onShelter),
                  _actionChip('EVACUATE', Colors.red, Icons.directions_run,
                      widget.onEvacuate),
                  _actionChip('SHARE', Colors.blue, Icons.share,
                      widget.onShare),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProbabilityMeter() {
    final prob = widget.probability!;
    final color = prob >= 80
        ? Colors.red
        : prob >= 60
            ? Colors.orange
            : prob >= 40
                ? Colors.amber
                : Colors.yellow;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STRIKE PROBABILITY',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.probabilityLabel ?? '',
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${prob.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Probability bar
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: prob / 100,
            minHeight: 6,
            backgroundColor: Colors.grey[900],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPrecedentBanner() {
    final p = widget.historicalPrecedent!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.amber, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MATCHES: ${p.name} (${p.date})',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${p.attribution} | ${p.outcomeLabel} | Brent +\$${p.brentSpikeDollars.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecursorSignals() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRECURSOR SIGNALS MATCHED (${widget.matchedPrecursors.length})',
            style: TextStyle(
              color: Colors.orange[300],
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 3),
          ...widget.matchedPrecursors.take(3).map((signal) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('  ', style: TextStyle(
                      color: Colors.orange[300], fontSize: 8)),
                    Expanded(
                      child: Text(
                        signal,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 8,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _actionChip(
      String label, Color color, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 11),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
