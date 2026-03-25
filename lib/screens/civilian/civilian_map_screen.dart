import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/civilian_report.dart';
import '../../providers/civilian_provider.dart';

/// Civilian impact map — crowd-sourced ground truth visualization.
///
/// Shows:
///   - Validated impact locations (from citizen reports)
///   - Damage heatmap overlay (aggregated from crowd data)
///   - Safe corridors (routes away from impact zones)
///   - Shelter locations
///   - User's current position relative to threats
///
/// This is the civilian counterpart to the classified war room map.
/// It shows ONLY declassified, validated information — no trajectory
/// projections, no source intelligence, no asset locations.
class CivilianMapScreen extends StatelessWidget {
  const CivilianMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e1a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'IMPACT MAP',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.layers, color: Colors.white54),
            onPressed: () => _showLayerPicker(context),
          ),
        ],
      ),
      body: Consumer<CivilianProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              // ── MAP PLACEHOLDER ──────────────────────────────
              // In production: Google Maps / Mapbox with heatmap overlay
              _MapPlaceholder(provider: provider),

              // ── LEGEND ───────────────────────────────────────
              Positioned(
                top: 12,
                right: 12,
                child: _MapLegend(),
              ),

              // ── REPORT COUNT BADGE ───────────────────────────
              Positioned(
                top: 12,
                left: 12,
                child: _ReportCountBadge(
                  total: provider.reportCount,
                  confirmed: provider.confirmedCount,
                ),
              ),

              // ── BOTTOM INFO PANEL ────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomInfoPanel(provider: provider),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLayerPicker(BuildContext context) {
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
              'MAP LAYERS',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            _layerToggle('Impact Reports', Icons.location_on, Colors.red, true),
            _layerToggle('Damage Heatmap', Icons.gradient, Colors.orange, true),
            _layerToggle('Safe Corridors', Icons.route, Colors.green, false),
            _layerToggle('Shelter Locations', Icons.home, Colors.blue, false),
            _layerToggle('All-Clear Zones', Icons.check_circle, Colors.cyan, false),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _layerToggle(String name, IconData icon, Color color, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(enabled ? 1.0 : 0.3), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: enabled ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (_) {},
            activeColor: color,
          ),
        ],
      ),
    );
  }
}

// ─── MAP PLACEHOLDER ─────────────────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  final CivilianProvider provider;
  const _MapPlaceholder({required this.provider});

  @override
  Widget build(BuildContext context) {
    // In production, this would be a Google Maps / Mapbox widget
    // with heatmap tile overlay from TrajectoryValidationEngine.generateDamageHeatmap()
    return Container(
      color: const Color(0xFF0d1117),
      child: Stack(
        children: [
          // Grid lines to simulate map
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(),
          ),

          // Plot civilian reports as dots
          ...provider.recentReports.map((report) {
            // Simplified — in production, project lat/lng to screen coords
            return Positioned(
              left: _lngToX(report.longitude, context),
              top: _latToY(report.latitude, context),
              child: _ReportDot(report: report),
            );
          }),

          // Center label
          if (provider.recentReports.isEmpty)
            const Center(
              child: Text(
                'MAP VIEW\n\nGoogle Maps / Mapbox integration\nwith crowd-sourced damage heatmap',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // Simplified coordinate projection (placeholder)
  double _lngToX(double lng, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Center on KSA (lng ~45)
    return ((lng - 38.0) / 14.0 * width).clamp(0, width - 20);
  }

  double _latToY(double lat, BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    // Center on KSA (lat ~24)
    return (((30.0 - lat) / 12.0) * height).clamp(0, height - 100);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReportDot extends StatelessWidget {
  final CivilianReport report;
  const _ReportDot({required this.report});

  @override
  Widget build(BuildContext context) {
    final color = Color(report.damageColorValue);
    final size = report.isHighValue ? 16.0 : 10.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.6),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8),
        ],
      ),
      child: report.isHighValue
          ? Center(
              child: Text(
                report.typeIcon,
                style: const TextStyle(fontSize: 8),
              ),
            )
          : null,
    );
  }
}

// ─── OVERLAY WIDGETS ─────────────────────────────────────────────────

class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendRow(Colors.red, 'Catastrophic'),
          _legendRow(Colors.orange, 'Severe'),
          _legendRow(Colors.amber, 'Moderate'),
          _legendRow(Colors.lightGreen, 'Minor'),
          _legendRow(Colors.cyan, 'No damage'),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _ReportCountBadge extends StatelessWidget {
  final int total;
  final int confirmed;

  const _ReportCountBadge({required this.total, required this.confirmed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people, color: Colors.cyan, size: 14),
          const SizedBox(width: 6),
          Text(
            '$total reports',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$confirmed confirmed',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomInfoPanel extends StatelessWidget {
  final CivilianProvider provider;
  const _BottomInfoPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFF0a0e1a),
            const Color(0xFF0a0e1a).withOpacity(0.0),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Latest report summary
          if (provider.recentReports.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e).withOpacity(0.95),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'LATEST REPORT',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(provider.recentReports.first.timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        provider.recentReports.first.typeIcon,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.recentReports.first.description ??
                              provider.recentReports.first.type.name
                                  .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
