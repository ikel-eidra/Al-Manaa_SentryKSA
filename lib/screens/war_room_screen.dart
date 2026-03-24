import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/threat_provider.dart';
import '../providers/map_provider.dart';
import '../data/asset_inventory.dart';
import '../widgets/warning_panel.dart';
import '../widgets/analytics_panel.dart';
import '../widgets/asset_detail_sheet.dart';
import '../widgets/threat_trajectory_overlay.dart';
import '../widgets/live_threat_ticker.dart';
import '../widgets/map_legend_overlay.dart';
import '../models/strategic_asset.dart';

/// Main War Room Dashboard — the primary command screen of SentryKSA.
///
/// Layers (bottom to top):
///   1. Google Maps satellite/hybrid base
///   2. Risk heat zones (8/16/24 km circles per asset)
///   3. Economic impact blast radii (purple rings)
///   4. Threat event origin circles (red/orange)
///   5. Trajectory polylines (dashed arcs from origin → target)
///   6. Asset markers (color-coded by alert level)
///   7. Threat event origin markers
///   8. Live intelligence ticker (top bar)
///   9. Inbound threat overlay (top-left cards with ETA)
///  10. Emergency countdown panel (center-top, only during imminent threat)
///  11. Map layer controls + legend (right side)
///  12. Analytics & economic impact panel (bottom)
class WarRoomScreen extends StatefulWidget {
  const WarRoomScreen({super.key});

  @override
  State<WarRoomScreen> createState() => _WarRoomScreenState();
}

class _WarRoomScreenState extends State<WarRoomScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final threatProvider = context.read<ThreatProvider>();
      threatProvider.loadInitialData(AssetInventory.allAssets);
      threatProvider.startMonitoring();
    });
  }

  void _onAssetTapped(StrategicAsset asset) {
    final mapProvider = context.read<MapProvider>();
    mapProvider.selectAsset(asset.id);
    mapProvider.focusAsset(asset);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ThreatProvider>(),
        child: AssetDetailSheet(asset: asset),
      ),
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
          final impactReports = threatProvider.impactReports;
          final events = threatProvider.events;

          // ── Build all map overlays ──────────────────────────────

          // Heat zones (risk level circles)
          final heatZones = mapProvider.buildHeatZones(assets, assessments);

          // Economic impact blast radii
          final impactCircles = mapProvider.buildImpactSites(
            assets, impactReports, assessments,
          );

          // Threat event detection circles
          final threatCircles = mapProvider.buildThreatEventCircles(events);

          // Merge all circles
          final allCircles = <Circle>{
            ...heatZones,
            ...impactCircles,
            ...threatCircles,
          };

          // Trajectory polylines
          final trajectories = mapProvider.buildThreatTrajectories(
            events, assets,
          );

          // Asset markers (color by alert level)
          final assetMarkers = mapProvider.buildMarkers(
            assets, assessments, _onAssetTapped,
          );

          // Threat event origin markers
          final eventMarkers = mapProvider.buildThreatEventMarkers(events);

          // Merge all markers
          final allMarkers = <Marker>{
            ...assetMarkers,
            ...eventMarkers,
          };

          return Stack(
            children: [
              // ── LAYER 1-7: GOOGLE MAP ──────────────────────────
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(24.7, 46.6),
                  zoom: 5.5,
                ),
                mapType: mapProvider.mapType,
                onMapCreated: mapProvider.setMapController,
                circles: allCircles,
                markers: allMarkers,
                polylines: trajectories,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
                mapToolbarEnabled: false,
                padding: const EdgeInsets.only(bottom: 180, top: 32),
              ),

              // ── LAYER 8: LIVE INTELLIGENCE TICKER ──────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: LiveThreatTicker(events: threatProvider.recentEvents),
                ),
              ),

              // ── CONNECTION STATUS ──────────────────────────────
              Positioned(
                top: 40,
                right: 16,
                child: SafeArea(
                  bottom: false,
                  child: _buildConnectionIndicator(threatProvider),
                ),
              ),

              // ── LAYER 9: INBOUND THREAT OVERLAY ────────────────
              Positioned(
                top: 80,
                left: 12,
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    width: 260,
                    child: ThreatTrajectoryOverlay(
                      activeEvents: threatProvider.activeInboundEvents,
                      assessments: assessments,
                    ),
                  ),
                ),
              ),

              // ── LAYER 10: EMERGENCY COUNTDOWN ──────────────────
              if (threatProvider.hasActiveThreat)
                Positioned(
                  top: 44,
                  left: 40,
                  right: 40,
                  child: SafeArea(
                    bottom: false,
                    child: WarningPanel(
                      countdown: threatProvider.countdownDisplay,
                      threatType:
                          threatProvider.activeThreatType ?? 'UNKNOWN',
                      targetCorridor:
                          threatProvider.activeTargetCorridor ?? 'Unknown',
                    ),
                  ),
                ),

              // ── LAYER 11: MAP CONTROLS + LEGEND ────────────────
              Positioned(
                right: 12,
                bottom: 210,
                child: MapLegendOverlay(
                  showHeatZones: mapProvider.showHeatZones,
                  showThreatArcs: mapProvider.showThreatArcs,
                  showImpactSites: mapProvider.showImpactSites,
                  showAssetLabels: mapProvider.showAssetLabels,
                  onToggleHeatZones: mapProvider.toggleHeatZones,
                  onToggleThreatArcs: mapProvider.toggleThreatArcs,
                  onToggleImpactSites: mapProvider.toggleImpactSites,
                  onToggleAssetLabels: mapProvider.toggleAssetLabels,
                  onToggleMapType: () => mapProvider.setMapType(
                    mapProvider.mapType == MapType.hybrid
                        ? MapType.normal
                        : MapType.hybrid,
                  ),
                ),
              ),

              // ── RESET VIEW BUTTON ──────────────────────────────
              Positioned(
                left: 12,
                bottom: 210,
                child: _buildResetButton(mapProvider),
              ),

              // ── ASSET COUNT BADGE ──────────────────────────────
              Positioned(
                left: 12,
                bottom: 260,
                child: _buildAssetCountBadge(
                  threatProvider.assetsUnderThreat,
                  assets.length,
                ),
              ),

              // ── LAYER 12: ANALYTICS PANEL ──────────────────────
              Align(
                alignment: Alignment.bottomCenter,
                child: AnalyticsPanel(
                  totalStrikes: events.length,
                  interceptRate: threatProvider.interceptRate,
                  brentDelta: threatProvider.brentDelta,
                  worstCaseBrent: threatProvider.worstCaseBrent,
                  criticalAssets:
                      threatProvider.criticalAssessments.length,
                  assetsUnderThreat: threatProvider.assetsUnderThreat,
                  totalDailyLoss: threatProvider.totalDailyLoss,
                  criticalAssessments:
                      threatProvider.criticalAssessments,
                ),
              ),

              // ── LOADING OVERLAY ────────────────────────────────
              if (threatProvider.isLoading)
                Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.red,
                        strokeWidth: 2,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'LOADING INTELLIGENCE...',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── HELPER WIDGETS ─────────────────────────────────────────────

  Widget _buildConnectionIndicator(ThreatProvider provider) {
    Color color;
    String label;
    IconData icon;

    switch (provider.connectionStatus) {
      case ConnectionStatus.connected:
        color = Colors.greenAccent;
        label = 'LIVE';
        icon = Icons.wifi;
        break;
      case ConnectionStatus.connecting:
        color = Colors.amber;
        label = 'SYNC';
        icon = Icons.sync;
        break;
      case ConnectionStatus.error:
      case ConnectionStatus.failed:
        color = Colors.red;
        label = 'OFFLINE';
        icon = Icons.wifi_off;
        break;
      default:
        color = Colors.grey;
        label = 'IDLE';
        icon = Icons.wifi_lock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(MapProvider mapProvider) {
    return GestureDetector(
      onTap: mapProvider.resetView,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: const Icon(Icons.zoom_out_map, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildAssetCountBadge(int underThreat, int total) {
    final color = underThreat > 0 ? Colors.orange : Colors.greenAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$underThreat/$total',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'THREAT',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 7,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
