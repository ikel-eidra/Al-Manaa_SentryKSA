import 'package:flutter/material.dart';

/// Emergency countdown warning panel displayed during active threats.
/// Features pulse animation and severity-based coloring.
class WarningPanel extends StatefulWidget {
  final String countdown;
  final String threatType;
  final String targetCorridor;
  final VoidCallback? onShelter;
  final VoidCallback? onEvacuate;
  final VoidCallback? onShare;

  const WarningPanel({
    super.key,
    required this.countdown,
    required this.threatType,
    required this.targetCorridor,
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
          padding: const EdgeInsets.all(16),
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
              // Threat type header with blinking indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.red.withOpacity(
                      0.6 + _glowPulse.value,
                    ),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'IMMINENT THREAT: ${widget.threatType}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Countdown timer - large monospace
              Text(
                widget.countdown,
                style: TextStyle(
                  fontSize: 52,
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
              const SizedBox(height: 4),

              // Target corridor
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gps_fixed, color: Colors.grey[600], size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Target Corridor: ${widget.targetCorridor}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

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

  Widget _actionChip(
      String label, Color color, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
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
