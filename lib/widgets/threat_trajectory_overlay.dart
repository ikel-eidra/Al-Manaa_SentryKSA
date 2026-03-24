import 'package:flutter/material.dart';
import '../models/threat_event.dart';
import '../engines/threat_triangulation_engine.dart';

/// Animated overlay showing incoming threat trajectories with ETA countdowns
/// and per-event probability badges from historical pattern matching.
class ThreatTrajectoryOverlay extends StatefulWidget {
  final List<ThreatEvent> activeEvents;
  final Map<String, ThreatAssessment> assessments;

  const ThreatTrajectoryOverlay({
    super.key,
    required this.activeEvents,
    required this.assessments,
  });

  @override
  State<ThreatTrajectoryOverlay> createState() =>
      _ThreatTrajectoryOverlayState();
}

class _ThreatTrajectoryOverlayState extends State<ThreatTrajectoryOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 0.6, end: 1.0).animate(
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
    final inbound = widget.activeEvents.where((e) => e.isActive).toList();
    if (inbound.isEmpty) return const SizedBox.shrink();

    // Find the highest probability assessment for context
    double? maxProb;
    for (final a in widget.assessments.values) {
      if (a.attackProbability != null) {
        if (maxProb == null || a.probability > maxProb) {
          maxProb = a.probability;
        }
      }
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: inbound.take(3).map((event) {
            return _buildThreatCard(event, _pulseAnimation.value, maxProb);
          }).toList(),
        );
      },
    );
  }

  Widget _buildThreatCard(ThreatEvent event, double pulse, double? maxProb) {
    final severity = event.severityScore;
    final color = severity >= 8
        ? Colors.red
        : severity >= 5
            ? Colors.orange
            : Colors.amber;

    final eta = event.estimatedTimeToImpact;
    final etaStr = eta != null
        ? '${eta.inMinutes.toString().padLeft(2, '0')}:${(eta.inSeconds % 60).toString().padLeft(2, '0')}'
        : '--:--';

    return Opacity(
      opacity: pulse,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.90),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.7), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2 * pulse),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: icon + info + ETA
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(event.typeIcon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${event.type.name.toUpperCase()} INBOUND',
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${event.sourceFlag} ${event.source} | Sev ${event.severityScore}/10',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                // ETA countdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    etaStr,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),

            // Probability bar (if available)
            if (maxProb != null && maxProb > 5) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'P(STRIKE)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (maxProb / 100).clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: Colors.grey[900],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          maxProb >= 60 ? Colors.red : Colors.orange,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${maxProb.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: maxProb >= 60 ? Colors.red : Colors.orange,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
