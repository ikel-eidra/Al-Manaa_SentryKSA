import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../../config/map_styles.dart';
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
class CivilianMapScreen extends StatefulWidget {
  const CivilianMapScreen({super.key});

  @override
  State<CivilianMapScreen> createState() => _CivilianMapScreenState();
}

class _CivilianMapScreenState extends State<CivilianMapScreen> {
  MaplibreMapController? _mapController;
  bool _layersInitialized = false;

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  Future<void> _onMapCreated(MaplibreMapController controller) async {
    _mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    final c = _mapController;
    if (c == null) return;

    // ── Add civilian report points as GeoJSON source ──────────────
    await c.addGeoJsonSource('civilian-reports', const {
      'type': 'FeatureCollection',
      'features': [],
    });

    // ── Heatmap layer for damage density ──────────────────────────
    await c.addHeatmapLayer('civilian-reports', 'damage-heatmap', HeatmapLayerProperties(
      heatmapWeight: ['get', 'intensity'],
      heatmapRadius: 30,
      heatmapColor: [
        'interpolate', ['linear'], ['heatmap-density'],
        0, 'rgba(0,0,0,0)',
        0.2, 'rgba(0,255,255,0.3)',
        0.4, 'rgba(255,235,59,0.5)',
        0.6, 'rgba(255,152,0,0.7)',
        0.8, 'rgba(244,67,54,0.8)',
        1.0, 'rgba(213,0,0,0.9)',
      ],
    ));

    // ── Circle layer for individual report dots ───────────────────
    await c.addCircleLayer('civilian-reports', 'reports-circles', CircleLayerProperties(
      circleColor: ['get', 'color'],
      circleRadius: ['get', 'size'],
      circleOpacity: 0.6,
      circleStrokeColor: ['get', 'color'],
      circleStrokeWidth: 1.5,
    ));

    _layersInitialized = true;
    _updateReportData();
  }

  void _updateReportData() {
    if (!_layersInitialized || _mapController == null) return;

    final provider = context.read<CivilianProvider>();
    final features = provider.recentReports.map((report) {
      final color = _damageColor(report);
      final size = report.isHighValue ? 8.0 : 5.0;
      final intensity = report.isHighValue ? 1.0 : 0.5;

      return {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [report.longitude, report.latitude],
        },
        'properties': {
          'color': color,
          'size': size,
          'intensity': intensity,
        },
      };
    }).toList();

    _mapController?.setGeoJsonSource('civilian-reports', {
      'type': 'FeatureCollection',
      'features': features,
    });
  }

  String _damageColor(CivilianReport report) {
    switch (report.damageLevel) {
      case DamageLevel.catastrophic:
        return '#F44336';
      case DamageLevel.severe:
        return '#FF9800';
      case DamageLevel.moderate:
        return '#FFC107';
      case DamageLevel.minor:
        return '#8BC34A';
      case DamageLevel.none:
        return '#00BCD4';
    }
  }

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
          // Update map data when provider changes
          if (_layersInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _updateReportData());
          }

          return Stack(
            children: [
              // ── MAPLIBRE GL MAP ────────────────────────────────
              MaplibreMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(24.7, 46.6),
                  zoom: 6.0,
                ),
                styleString: MapStyles.warRoomDark,
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: _onStyleLoaded,
                myLocationEnabled: true,
                myLocationTrackingMode: MyLocationTrackingMode.none,
                compassEnabled: true,
                tiltGesturesEnabled: true,
              ),

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
