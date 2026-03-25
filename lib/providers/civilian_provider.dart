import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/civilian_report.dart';
import '../models/escalation_phase.dart';
import '../services/civilian_report_service.dart';

/// State provider for the civilian mobile app.
///
/// Manages:
///   - Current escalation phase (received from war room)
///   - Active warnings for user's location
///   - Crowd-sourced civilian reports (for map display)
///   - Report submission
///   - User location tracking
class CivilianProvider extends ChangeNotifier {
  final CivilianReportService _reportService;

  // ── STATE ────────────────────────────────────────────────────────

  EscalationPhase _currentPhase = EscalationPhase(
    level: PhaseLevel.baseline,
    enteredAt: DateTime.now(),
  );

  List<CivilianWarning> _activeWarnings = [];
  List<CivilianReport> _recentReports = [];

  // User location
  double? _currentLatitude;
  double? _currentLongitude;

  // Connection
  bool _isConnected = false;
  String? _error;

  Timer? _warningPollTimer;
  StreamSubscription<CivilianReport>? _reportSubscription;

  // ── GETTERS ──────────────────────────────────────────────────────

  EscalationPhase get currentPhase => _currentPhase;
  List<CivilianWarning> get activeWarnings => _activeWarnings;
  List<CivilianReport> get recentReports => _recentReports;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  bool get isConnected => _isConnected;
  String? get error => _error;

  int get reportCount => _recentReports.length;
  int get confirmedCount => _recentReports
      .where((r) => r.validationStatus == ValidationStatus.confirmed)
      .length;

  // ── CONSTRUCTOR ──────────────────────────────────────────────────

  CivilianProvider({
    required CivilianReportService reportService,
  }) : _reportService = reportService;

  // ── INITIALIZATION ───────────────────────────────────────────────

  /// Start the civilian app services.
  void initialize() {
    // Poll for warnings based on user location
    _startWarningPolling();

    // Listen for incoming civilian reports (for the map)
    _reportSubscription = _reportService.reportStream.listen((report) {
      _recentReports.insert(0, report);
      // Keep only last 200 reports in memory
      if (_recentReports.length > 200) {
        _recentReports = _recentReports.sublist(0, 200);
      }
      notifyListeners();
    });

    _isConnected = true;
    notifyListeners();
  }

  // ── LOCATION ─────────────────────────────────────────────────────

  /// Update user's current GPS location.
  void updateLocation(double latitude, double longitude) {
    _currentLatitude = latitude;
    _currentLongitude = longitude;
    notifyListeners();
  }

  // ── WARNINGS ─────────────────────────────────────────────────────

  void _startWarningPolling() {
    _fetchWarnings();
    _warningPollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchWarnings(),
    );
  }

  Future<void> _fetchWarnings() async {
    if (_currentLatitude == null || _currentLongitude == null) return;

    try {
      _activeWarnings = await _reportService.getWarningsForLocation(
        _currentLatitude!,
        _currentLongitude!,
      );
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch warnings: $e';
      notifyListeners();
    }
  }

  // ── ESCALATION PHASE ────────────────────────────────────────────

  /// Update escalation phase (received from server push).
  void updatePhase(EscalationPhase phase) {
    _currentPhase = phase;
    notifyListeners();
  }

  // ── REPORT SUBMISSION ────────────────────────────────────────────

  /// Submit a civilian report from the mobile app.
  Future<bool> submitReport({
    required ReportType type,
    DamageLevel? damageLevel,
    String? description,
  }) async {
    if (_currentLatitude == null || _currentLongitude == null) {
      _error = 'Location required to submit report';
      notifyListeners();
      return false;
    }

    final report = CivilianReport(
      id: '', // server-assigned
      reporterDeviceHash: _deviceHash(),
      timestamp: DateTime.now(),
      type: type,
      latitude: _currentLatitude!,
      longitude: _currentLongitude!,
      locationAccuracyMeters: 10.0, // from GPS provider
      damageLevel: damageLevel,
      description: description,
    );

    final id = await _reportService.submitReport(report);
    if (id != null) {
      // Add to local list immediately for responsive UI
      final submitted = CivilianReport(
        id: id,
        reporterDeviceHash: report.reporterDeviceHash,
        timestamp: report.timestamp,
        type: report.type,
        latitude: report.latitude,
        longitude: report.longitude,
        locationAccuracyMeters: report.locationAccuracyMeters,
        damageLevel: report.damageLevel,
        description: report.description,
      );
      _recentReports.insert(0, submitted);
      notifyListeners();
      return true;
    }

    _error = 'Failed to submit report';
    notifyListeners();
    return false;
  }

  /// Upload a photo for the most recently submitted report.
  Future<bool> uploadPhoto(List<int> imageBytes) async {
    if (_recentReports.isEmpty) return false;
    final reportId = _recentReports.first.id;
    final url = await _reportService.uploadPhoto(reportId, imageBytes);
    return url != null;
  }

  // ── HELPERS ──────────────────────────────────────────────────────

  String _deviceHash() {
    // In production: hash of device ID + installation ID
    // Anonymized — no PII stored
    return 'device_${DateTime.now().millisecondsSinceEpoch.hashCode.toRadixString(16)}';
  }

  // ── CLEANUP ──────────────────────────────────────────────────────

  @override
  void dispose() {
    _warningPollTimer?.cancel();
    _reportSubscription?.cancel();
    super.dispose();
  }
}
