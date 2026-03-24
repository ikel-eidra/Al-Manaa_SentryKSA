import 'package:flutter/material.dart';

/// Emergency countdown warning panel displayed during active threats.
class WarningPanel extends StatelessWidget {
  final String countdown;
  final String threatType;
  final String targetCorridor;

  const WarningPanel({
    super.key,
    required this.countdown,
    required this.threatType,
    required this.targetCorridor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.92),
        border: Border.all(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
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
              const Icon(Icons.warning_amber, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Text(
                'IMMINENT THREAT: $threatType',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Countdown timer
          Text(
            countdown,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'monospace',
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 6),

          // Target corridor
          Text(
            'Target Corridor: $targetCorridor',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Action bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionChip('SHELTER', Colors.orange),
              _actionChip('EVACUATE', Colors.red),
              _actionChip('SHARE', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
