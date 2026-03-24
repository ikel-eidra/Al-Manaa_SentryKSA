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
  List<StrategicAsset> _monitoredAssets = [];
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
  List<StrategicAsset> get monitoredAssets => _monitoredAssets;
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Duration? get activeCountdown => _activeCountdown;
  String? get activeTargetCorridor => _activeTargetCorridor;
  String? get activeThreatType => _activeThreatType;

  bool get hasActiveThreat => _activeCountdown != null;

  /// Active inbound events (those with an active ETA).
  List<ThreatEvent> get activeInboundEvents =>
      _events.where((e) => e.isActive).toList();

  /// Recent events for the ticker (last 50).
  List<ThreatEvent> get recentEvents =>
      _events.take(50).toList();

  /// Total economic impact across all monitored assets.
  double get totalDailyLoss =>
      _impactReports.values.fold(0.0, (sum, r) => sum + r.dailyRevenueLoss);

  /// Worst-case Brent projection.
  double get worstCaseBrent {
    if (_impactReports.isEmpty) return EconomicEngine.brentBasePrice;
    return _economicEngine.worstCaseBrent(_impactReports.values.toList());
  }

  /// Brent price surge delta.
  double get brentDelta => worstCaseBrent - EconomicEngine.brentBasePrice;

  /// Number of assets under active high/critical threat.
  int get assetsUnderThreat => _assessments.values
      .where((a) =>
          a.alertLevel == AlertLevel.critical ||
          a.alertLevel == AlertLevel.high)
      .length;

  /// Average intercept readiness (simulated from threat scores).
  double get interceptRate {
    if (_assessments.isEmpty) return 95.0;
    final avgThreat = _assessments.values
        .map((a) => a.threatScore)
        .reduce((a, b) => a + b) /
        _assessments.length;
    // Higher avg threat = lower intercept confidence
    return (98.0 - avgThreat * 0.4).clamp(50.0, 99.0);
  }

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

  /// Highest attack probability across all assets.
  double get maxProbability {
    double maxP = 0;
    for (final a in _assessments.values) {
      if (a.attackProbability != null && a.probability > maxP) {
        maxP = a.probability;
      }
    }
    return maxP;
  }

  /// Asset with the highest attack probability.
  ThreatAssessment? get highestProbabilityAsset {
    ThreatAssessment? best;
    for (final a in _assessments.values) {
      if (a.attackProbability != null) {
        if (best == null || a.probability > best.probability) {
          best = a;
        }
      }
    }
    return best;
  }

  /// Assets sorted by threat score descending (for the intel feed).
  List<MapEntry<StrategicAsset, ThreatAssessment>> get rankedThreats {
    final entries = <MapEntry<StrategicAsset, ThreatAssessment>>[];
    for (final asset in _monitoredAssets) {
      final assessment = _assessments[asset.id];
      if (assessment != null && assessment.threatScore > 10) {
        entries.add(MapEntry(asset, assessment));
      }
    }
    entries.sort((a, b) => b.value.threatScore.compareTo(a.value.threatScore));
    return entries;
  }

  ThreatProvider({
    required ThreatFeedService feedService,
    required WebSocketService wsService,
  })  : _feedService = feedService,
        _wsService = wsService {
    _initialize();
  }

  void _initialize() {
    _feedService.eventStream.listen(_onNewEvent);
    _wsService.eventStream.listen(_onNewEvent);
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
    _monitoredAssets = assets;
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

    if (_events.length > 500) {
      _events = _events.sublist(0, 500);
    }

    // Re-triangulate on new data
    if (_monitoredAssets.isNotEmpty) {
      _runTriangulation(_monitoredAssets);
      _calculateAllImpacts(_monitoredAssets);
    }

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

  void _runTriangulation(List<StrategicAsset> assets) {
    _assessments = _triangulationEngine.triangulate(_events, assets);
  }

  void _calculateAllImpacts(List<StrategicAsset> assets) {
    for (final asset in assets) {
      _impactReports[asset.id] = _economicEngine.calculateImpact(asset);
    }
  }

  ImpactReport? getImpactReport(String assetId) => _impactReports[assetId];
  ThreatAssessment? getAssessment(String assetId) => _assessments[assetId];

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _feedService.dispose();
    _wsService.dispose();
    super.dispose();
  }
}
