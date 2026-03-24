import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/threat_event.dart';
import '../models/strategic_asset.dart';
import '../models/impact_report.dart';
import '../engines/economic_engine.dart';
import '../engines/threat_triangulation_engine.dart';
import '../services/threat_feed_service.dart';
import '../services/websocket_service.dart';

/// Central state provider for threat intelligence and economic impact.
class ThreatProvider extends ChangeNotifier {
  final ThreatFeedService _feedService;
  final WebSocketService _wsService;
  final EconomicEngine _economicEngine = EconomicEngine();
  final ThreatTriangulationEngine _triangulationEngine =
      ThreatTriangulationEngine();

  // State
  List<ThreatEvent> _events = [];
  Map<String, ThreatAssessment> _assessments = {};
  Map<String, ImpactReport> _impactReports = {};
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  bool _isLoading = false;
  String? _error;

  // Countdown state
  Duration? _activeCountdown;
  String? _activeTargetCorridor;
  String? _activeThreatType;
  Timer? _countdownTimer;

  // Getters
  List<ThreatEvent> get events => _events;
  Map<String, ThreatAssessment> get assessments => _assessments;
  Map<String, ImpactReport> get impactReports => _impactReports;
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Duration? get activeCountdown => _activeCountdown;
  String? get activeTargetCorridor => _activeTargetCorridor;
  String? get activeThreatType => _activeThreatType;

  bool get hasActiveThreat => _activeCountdown != null;

  String get countdownDisplay {
    if (_activeCountdown == null) return '--:--:--';
    final d = _activeCountdown!;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  List<ThreatAssessment> get criticalAssessments => _assessments.values
      .where((a) => a.alertLevel == AlertLevel.critical)
      .toList();

  ThreatProvider({
    required ThreatFeedService feedService,
    required WebSocketService wsService,
  })  : _feedService = feedService,
        _wsService = wsService {
    _initialize();
  }

  void _initialize() {
    // Listen to HTTP feed events
    _feedService.eventStream.listen(_onNewEvent);

    // Listen to WebSocket events
    _wsService.eventStream.listen(_onNewEvent);

    // Track connection status
    _wsService.statusStream.listen((status) {
      _connectionStatus = status;
      notifyListeners();
    });
  }

  /// Start monitoring all intelligence sources.
  void startMonitoring() {
    _feedService.startMonitoring();
    _wsService.connect();
  }

  /// Fetch initial data and run triangulation.
  Future<void> loadInitialData(List<StrategicAsset> assets) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _feedService.fetchAllRecent();
      _runTriangulation(assets);
      _calculateAllImpacts(assets);
    } catch (e) {
      _error = 'Failed to load threat data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onNewEvent(ThreatEvent event) {
    _events.insert(0, event);

    // Keep only last 500 events
    if (_events.length > 500) {
      _events = _events.sublist(0, 500);
    }

    // Check for active countdown
    if (event.isActive && event.estimatedTimeToImpact != null) {
      _startCountdown(event);
    }

    notifyListeners();
  }

  void _startCountdown(ThreatEvent event) {
    _countdownTimer?.cancel();
    _activeCountdown = event.estimatedTimeToImpact;
    _activeTargetCorridor = event.targetCorridor;
    _activeThreatType =
        '${event.type.name.toUpperCase()} (${event.source})';

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeCountdown != null && _activeCountdown!.inSeconds > 0) {
        _activeCountdown = _activeCountdown! - const Duration(seconds: 1);
        notifyListeners();
      } else {
        _countdownTimer?.cancel();
        _activeCountdown = null;
        notifyListeners();
      }
    });
  }

  /// Re-run triangulation with current events.
  void _runTriangulation(List<StrategicAsset> assets) {
    _assessments = _triangulationEngine.triangulate(_events, assets);
  }

  /// Calculate economic impact for all assets.
  void _calculateAllImpacts(List<StrategicAsset> assets) {
    for (final asset in assets) {
      _impactReports[asset.id] = _economicEngine.calculateImpact(asset);
    }
  }

  /// Get impact report for a specific asset.
  ImpactReport? getImpactReport(String assetId) => _impactReports[assetId];

  /// Get threat assessment for a specific asset.
  ThreatAssessment? getAssessment(String assetId) => _assessments[assetId];

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _feedService.dispose();
    _wsService.dispose();
    super.dispose();
  }
}
