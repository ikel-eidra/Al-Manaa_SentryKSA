import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/threat_provider.dart';
import '../providers/map_provider.dart';
import '../data/asset_inventory.dart';
import '../widgets/warning_panel.dart';
import '../widgets/analytics_panel.dart';
import '../widgets/asset_detail_sheet.dart';
import '../models/strategic_asset.dart';

/// Main War Room Dashboard - the primary screen of SentryKSA.
class WarRoomScreen extends StatefulWidget {
  const WarRoomScreen({super.key});

  @override
  State<WarRoomScreen> createState() => _WarRoomScreenState();
}

class _WarRoomScreenState extends State<WarRoomScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial threat data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final threatProvider = context.read<ThreatProvider>();
      threatProvider.loadInitialData(AssetInventory.allAssets);
      threatProvider.startMonitoring();
    });
  }

  void _onAssetTapped(StrategicAsset asset) {
    final mapProvider = context.read<MapProvider>();
    mapProvider.selectAsset(asset.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AssetDetailSheet(asset: asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer2<ThreatProvider, MapProvider>(
        builder: (context, threatProvider, mapProvider, _) {
          final assets = AssetInventory.allAssets;
          final assessments = threatProvider.assessments;

          return Stack(
            children: [
              // GIS HEATMAP
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(24.7, 46.6),
                  zoom: 5.5,
                ),
                mapType: mapProvider.mapType,
                onMapCreated: mapProvider.setMapController,
                circles: mapProvider.buildHeatZones(assets, assessments),
                markers: mapProvider.buildMarkers(assets, _onAssetTapped),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
              ),

              // CONNECTION STATUS INDICATOR
              Positioned(
                top: 40,
                right: 16,
                child: _buildConnectionIndicator(threatProvider),
              ),

              // EMERGENCY COUNTDOWN OVERLAY
              if (threatProvider.hasActiveThreat)
                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: WarningPanel(
                    countdown: threatProvider.countdownDisplay,
                    threatType: threatProvider.activeThreatType ?? 'UNKNOWN',
                    targetCorridor:
                        threatProvider.activeTargetCorridor ?? 'Unknown',
                  ),
                ),

              // MAP CONTROLS
              Positioned(
                right: 16,
                bottom: 200,
                child: _buildMapControls(mapProvider),
              ),

              // ANALYTICS & INFOGRAPHICS (Bottom)
              Align(
                alignment: Alignment.bottomCenter,
                child: AnalyticsPanel(
                  totalStrikes: 42,
                  interceptRate: 92.0,
                  brentImpact: 14.20,
                  criticalAssets: threatProvider.criticalAssessments.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConnectionIndicator(ThreatProvider provider) {
    Color color;
    String label;

    switch (provider.connectionStatus) {
      case ConnectionStatus.connected:
        color = Colors.greenAccent;
        label = 'LIVE';
        break;
      case ConnectionStatus.connecting:
        color = Colors.amber;
        label = 'CONNECTING';
        break;
      case ConnectionStatus.error:
      case ConnectionStatus.failed:
        color = Colors.red;
        label = 'OFFLINE';
        break;
      default:
        color = Colors.grey;
        label = 'IDLE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls(MapProvider mapProvider) {
    return Column(
      children: [
        _mapControlButton(
          Icons.layers,
          () => mapProvider.setMapType(
            mapProvider.mapType == MapType.hybrid
                ? MapType.normal
                : MapType.hybrid,
          ),
        ),
        const SizedBox(height: 8),
        _mapControlButton(
          Icons.local_fire_department,
          mapProvider.toggleHeatZones,
        ),
        const SizedBox(height: 8),
        _mapControlButton(
          Icons.my_location,
          () => mapProvider.setMapController(mapProvider.mapController!),
        ),
      ],
    );
  }

  Widget _mapControlButton(IconData icon, VoidCallback onTap) {
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
}
