import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/escalation_phase.dart';
import '../../providers/civilian_provider.dart';

/// Main civilian warning screen — the first thing citizens see.
///
/// Shows:
///   - Current escalation phase (color-coded banner)
///   - Countdown to projected next phase
///   - Active warnings for user's location
///   - Shelter guidance when applicable
///   - Quick-action buttons: Report Impact, View Map, Emergency Contacts
///
/// Complements the government SMS warning system — provides richer
/// context and allows two-way information flow.
class CivilianWarningScreen extends StatelessWidget {
  const CivilianWarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CivilianProvider>(
      builder: (context, provider, _) {
        final phase = provider.currentPhase;
        final warnings = provider.activeWarnings;

        return Scaffold(
          backgroundColor: const Color(0xFF0a0e1a),
          body: SafeArea(
            child: Column(
              children: [
                // ── ESCALATION PHASE BANNER ────────────────────
                _EscalationBanner(phase: phase),

                // ── COUNTDOWN (if next phase projected) ────────
                if (phase.projectedNextPhaseAt != null)
                  _CountdownBar(phase: phase),

                // ── ACTIVE WARNINGS ────────────────────────────
                Expanded(
                  child: warnings.isEmpty
                      ? _NoWarningsPlaceholder(phase: phase)
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: warnings.length,
                          itemBuilder: (_, i) =>
                              _WarningCard(warning: warnings[i]),
                        ),
                ),

                // ── QUICK ACTIONS ──────────────────────────────
                _QuickActionBar(
                  phase: phase,
                  onReportTap: () =>
                      Navigator.pushNamed(context, '/report'),
                  onMapTap: () =>
                      Navigator.pushNamed(context, '/civilian-map'),
                  onEmergencyTap: () =>
                      _showEmergencyContacts(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEmergencyContacts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EMERGENCY CONTACTS',
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            _contactRow('Civil Defense', '998'),
            _contactRow('Saudi Red Crescent', '997'),
            _contactRow('Police', '999'),
            _contactRow('Ambulance', '997'),
            _contactRow('National Crisis Center', '911'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(String name, String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.phone, color: Colors.white54, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            number,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SUB-WIDGETS ─────────────────────────────────────────────────────

class _EscalationBanner extends StatelessWidget {
  final EscalationPhase phase;
  const _EscalationBanner({required this.phase});

  @override
  Widget build(BuildContext context) {
    final color = Color(phase.warningColorValue);
    final isCritical = phase.shelterInPlace;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.5))),
      ),
      child: Column(
        children: [
          Text(
            phase.phaseIcon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            phase.civilianLabel,
            style: TextStyle(
              color: color,
              fontSize: isCritical ? 28 : 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          if (phase.civilianGuidance.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              phase.civilianGuidance,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountdownBar extends StatelessWidget {
  final EscalationPhase phase;
  const _CountdownBar({required this.phase});

  @override
  Widget build(BuildContext context) {
    final remaining = phase.timeToNextPhase;
    if (remaining == null || remaining.isNegative) return const SizedBox();

    final color = Color(phase.warningColorValue);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            'EST. NEXT PHASE: ',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            '${hours.toString().padLeft(2, '0')}:'
            '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '(${(phase.confidenceInProjection * 100).toStringAsFixed(0)}% conf)',
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _NoWarningsPlaceholder extends StatelessWidget {
  final EscalationPhase phase;
  const _NoWarningsPlaceholder({required this.phase});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            phase.isKinetic ? Icons.warning_amber : Icons.shield,
            color: Colors.white24,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            phase.isKinetic
                ? 'Monitoring for threats in your area...'
                : 'No active warnings for your location',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Location-based alerts are active',
            style: TextStyle(color: Colors.grey[700], fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final dynamic warning; // CivilianWarning
  const _WarningCard({required this.warning});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warning.titleEn ?? 'Warning',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            warning.bodyEn ?? '',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          if (warning.shelterGuidance != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning.shelterGuidance!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionBar extends StatelessWidget {
  final EscalationPhase phase;
  final VoidCallback onReportTap;
  final VoidCallback onMapTap;
  final VoidCallback onEmergencyTap;

  const _QuickActionBar({
    required this.phase,
    required this.onReportTap,
    required this.onMapTap,
    required this.onEmergencyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          _actionButton(
            icon: Icons.camera_alt,
            label: 'REPORT',
            color: phase.shouldPromptReports
                ? Colors.redAccent
                : Colors.blueGrey,
            onTap: onReportTap,
            pulse: phase.shouldPromptReports,
          ),
          const SizedBox(width: 12),
          _actionButton(
            icon: Icons.map,
            label: 'MAP',
            color: Colors.cyan,
            onTap: onMapTap,
          ),
          const SizedBox(width: 12),
          _actionButton(
            icon: Icons.phone,
            label: 'EMERGENCY',
            color: Colors.red,
            onTap: onEmergencyTap,
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool pulse = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(pulse ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
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
      ),
    );
  }
}
