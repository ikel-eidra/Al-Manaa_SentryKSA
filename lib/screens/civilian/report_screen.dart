import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/civilian_report.dart';
import '../../providers/civilian_provider.dart';

/// Impact report submission screen — the citizen sensor mesh input.
///
/// Designed for speed under stress:
///   - One-tap damage type selection (big icons, no typing required)
///   - Auto-captures GPS location (just turn on location services)
///   - Camera button for photo evidence
///   - Submit in under 10 seconds
///
/// Every submitted report feeds the war room's trajectory validation
/// engine and generates crowd-sourced damage heatmaps.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportType? _selectedType;
  DamageLevel? _selectedDamage;
  final _descController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e1a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'SUBMIT REPORT',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _submitted ? _buildConfirmation() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── LOCATION STATUS ──────────────────────────────
          Consumer<CivilianProvider>(
            builder: (_, provider, __) {
              final hasLocation = provider.currentLatitude != null;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasLocation
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasLocation
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasLocation ? Icons.gps_fixed : Icons.gps_off,
                      color: hasLocation ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasLocation
                            ? 'Location acquired — ${provider.currentLatitude!.toStringAsFixed(4)}, '
                              '${provider.currentLongitude!.toStringAsFixed(4)}'
                            : 'Turn on location services for accurate reporting',
                        style: TextStyle(
                          color: hasLocation ? Colors.green : Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // ── WHAT DID YOU SEE? ────────────────────────────
          _sectionLabel('WHAT DID YOU OBSERVE?'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReportType.values.map((type) {
              final isSelected = _selectedType == type;
              return _TypeChip(
                type: type,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedType = type),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // ── DAMAGE LEVEL ─────────────────────────────────
          _sectionLabel('DAMAGE LEVEL (if visible)'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DamageLevel.values.map((level) {
              final isSelected = _selectedDamage == level;
              return _DamageChip(
                level: level,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedDamage = level),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // ── PHOTO ────────────────────────────────────────
          _sectionLabel('PHOTO EVIDENCE (optional)'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Colors.grey[500], size: 32),
                  const SizedBox(height: 6),
                  Text(
                    'TAP TO TAKE PHOTO',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── OPTIONAL DESCRIPTION ─────────────────────────
          _sectionLabel('BRIEF DESCRIPTION (optional)'),
          const SizedBox(height: 10),
          TextField(
            controller: _descController,
            maxLines: 2,
            maxLength: 200,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'What happened? Any details that might help...',
              hintStyle: TextStyle(color: Colors.grey[700]),
              filled: true,
              fillColor: const Color(0xFF1a1a2e),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              counterStyle: TextStyle(color: Colors.grey[700]),
            ),
          ),

          const SizedBox(height: 24),

          // ── SUBMIT ───────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  _selectedType != null && !_submitting ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                disabledBackgroundColor: Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'SUBMIT REPORT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),
          Center(
            child: Text(
              'Your location is anonymized. Reports help protect everyone.',
              style: TextStyle(color: Colors.grey[700], fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 64),
          const SizedBox(height: 16),
          const Text(
            'REPORT SUBMITTED',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you. Your report will help protect lives.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => setState(() {
              _submitted = false;
              _selectedType = null;
              _selectedDamage = null;
              _descController.clear();
            }),
            child: const Text(
              'SUBMIT ANOTHER REPORT',
              style: TextStyle(
                color: Colors.cyan,
                letterSpacing: 1,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Future<void> _takePhoto() async {
    // TODO: Integrate image_picker for camera access
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera integration pending'),
        backgroundColor: Color(0xFF1a1a2e),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedType == null) return;

    setState(() => _submitting = true);

    final provider = context.read<CivilianProvider>();
    await provider.submitReport(
      type: _selectedType!,
      damageLevel: _selectedDamage,
      description:
          _descController.text.isNotEmpty ? _descController.text : null,
    );

    if (mounted) {
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    }
  }
}

// ─── CHIP WIDGETS ──────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final ReportType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  String get _label {
    switch (type) {
      case ReportType.impact:
        return '💥 Impact';
      case ReportType.fire:
        return '🔥 Fire';
      case ReportType.debris:
        return '🧱 Debris';
      case ReportType.smoke:
        return '💨 Smoke';
      case ReportType.siren:
        return '🚨 Siren';
      case ReportType.allClear:
        return '✅ All Clear';
      case ReportType.casualty:
        return '🏥 Casualties';
      case ReportType.infrastructure:
        return '🏗️ Infra Damage';
      case ReportType.military:
        return '🎖️ Military';
      case ReportType.unknown:
        return '❓ Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.redAccent.withOpacity(0.2)
              : const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.redAccent : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          _label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DamageChip extends StatelessWidget {
  final DamageLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  const _DamageChip({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  String get _label {
    switch (level) {
      case DamageLevel.catastrophic:
        return 'Catastrophic';
      case DamageLevel.severe:
        return 'Severe';
      case DamageLevel.moderate:
        return 'Moderate';
      case DamageLevel.minor:
        return 'Minor';
      case DamageLevel.none:
        return 'None / Near-miss';
    }
  }

  Color get _color {
    switch (level) {
      case DamageLevel.catastrophic:
        return Colors.red;
      case DamageLevel.severe:
        return Colors.deepOrange;
      case DamageLevel.moderate:
        return Colors.amber;
      case DamageLevel.minor:
        return Colors.lightGreen;
      case DamageLevel.none:
        return Colors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _color.withOpacity(0.2) : const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _color : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          _label,
          style: TextStyle(
            color: isSelected ? _color : Colors.grey[400],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
