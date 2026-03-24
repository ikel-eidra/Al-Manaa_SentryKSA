import 'package:flutter/material.dart';
import '../models/threat_event.dart';
import '../engines/threat_triangulation_engine.dart';

/// Animated overlay showing incoming threat trajectories with ETA countdowns.
/// Floats over the map as semi-transparent intelligence cards.
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

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: inbound.take(3).map((event) {
            return _buildThreatCard(event, _pulseAnimation.value);
          }).toList(),
        );
      },
    );
  }

  Widget _buildThreatCard(ThreatEvent event, double pulse) {
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.88),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.7), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25 * pulse),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Threat type icon
            Text(event.typeIcon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),

            // Threat info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${event.type.name.toUpperCase()} INBOUND',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${event.sourceFlag} ${event.source} | Sev ${event.severityScore}/10',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // ETA countdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                etaStr,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
