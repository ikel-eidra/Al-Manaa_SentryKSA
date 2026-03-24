import 'package:flutter/material.dart';

/// Map legend and layer control panel.
/// Toggles visibility of heat zones, threat arcs, impact sites, and labels.
class MapLegendOverlay extends StatefulWidget {
  final bool showHeatZones;
  final bool showThreatArcs;
  final bool showImpactSites;
  final bool showAssetLabels;
  final VoidCallback onToggleHeatZones;
  final VoidCallback onToggleThreatArcs;
  final VoidCallback onToggleImpactSites;
  final VoidCallback onToggleAssetLabels;
  final VoidCallback onToggleMapType;

  const MapLegendOverlay({
    super.key,
    required this.showHeatZones,
    required this.showThreatArcs,
    required this.showImpactSites,
    required this.showAssetLabels,
    required this.onToggleHeatZones,
    required this.onToggleThreatArcs,
    required this.onToggleImpactSites,
    required this.onToggleAssetLabels,
    required this.onToggleMapType,
  });

  @override
  State<MapLegendOverlay> createState() => _MapLegendOverlayState();
}

class _MapLegendOverlayState extends State<MapLegendOverlay> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expand/collapse button
        _controlButton(
          _expanded ? Icons.close : Icons.layers,
          () => setState(() => _expanded = !_expanded),
          tooltip: 'Layers',
        ),

        if (_expanded) ...[
          const SizedBox(height: 6),

          // Layer toggles
          _layerToggle(
            Icons.blur_on,
            'Heat Zones',
            widget.showHeatZones,
            widget.onToggleHeatZones,
            Colors.red,
          ),
          const SizedBox(height: 4),
          _layerToggle(
            Icons.show_chart,
            'Threat Arcs',
            widget.showThreatArcs,
            widget.onToggleThreatArcs,
            Colors.orange,
          ),
          const SizedBox(height: 4),
          _layerToggle(
            Icons.radar,
            'Impact Sites',
            widget.showImpactSites,
            widget.onToggleImpactSites,
            Colors.purple,
          ),
          const SizedBox(height: 4),
          _layerToggle(
            Icons.label,
            'Labels',
            widget.showAssetLabels,
            widget.onToggleAssetLabels,
            Colors.cyan,
          ),
          const SizedBox(height: 8),
          _controlButton(Icons.map, widget.onToggleMapType, tooltip: 'Map Style'),
          const SizedBox(height: 4),

          // Legend
          _buildLegend(),
        ],
      ],
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap, {String? tooltip}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
    );
  }

  Widget _layerToggle(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : Colors.black87,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color.withOpacity(0.5) : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? color : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? color : Colors.grey,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LEGEND',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          _legendItem(Colors.red, 'Critical (75+)'),
          _legendItem(Colors.orange, 'High (50-74)'),
          _legendItem(Colors.amber, 'Elevated (25-49)'),
          _legendItem(Colors.green, 'Low (<25)'),
          const SizedBox(height: 4),
          _legendItem(Colors.purple, 'Economic Impact'),
          _legendItem(Colors.cyan, 'Threat Origin'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 8),
          ),
        ],
      ),
    );
  }
}
