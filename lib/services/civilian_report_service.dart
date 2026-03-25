import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/civilian_report.dart';

/// Service for submitting and receiving civilian crowd-sourced reports.
///
/// Two-way data flow:
///   SUBMIT: Mobile app → API → War room ingests for trajectory validation
///   STREAM: War room pushes validated alerts → API → Mobile app displays
///
/// Reports are anonymized (device hash only), deduplicated server-side,
/// and cross-referenced against classified ThreatEvent data in the war room.
class CivilianReportService {
  final String baseUrl;
  final http.Client _client;
  final Logger _log = Logger();

  // Incoming report stream (for war room dashboard)
  final _reportController = StreamController<CivilianReport>.broadcast();
  Stream<CivilianReport> get reportStream => _reportController.stream;

  // Validated reports cache
  final List<CivilianReport> _reports = [];
  List<CivilianReport> get reports => List.unmodifiable(_reports);

  Timer? _pollTimer;

  CivilianReportService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  // ─── MOBILE APP: SUBMIT REPORT ───────────────────────────────────

  /// Submit a new civilian report from the mobile app.
  /// Returns the server-assigned report ID, or null on failure.
  Future<String?> submitReport(CivilianReport report) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/civilian/reports'),
        headers: {
          'Content-Type': 'application/json',
          'X-Device-Hash': report.reporterDeviceHash,
        },
        body: jsonEncode(report.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _log.i('Report submitted: ${data['id']}');
        return data['id'] as String?;
      } else if (response.statusCode == 429) {
        _log.w('Rate limited — too many reports from this device');
        return null;
      } else {
        _log.e('Submit failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _log.e('Submit error: $e');
      return null;
    }
  }

  /// Upload a photo for an existing report.
  Future<String?> uploadPhoto(String reportId, List<int> imageBytes) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/v1/civilian/reports/$reportId/photos'),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        imageBytes,
        filename: 'impact_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      final response = await request.send();
      if (response.statusCode == 201) {
        final body = await response.stream.bytesToString();
        final data = jsonDecode(body) as Map<String, dynamic>;
        return data['photoUrl'] as String?;
      }
      return null;
    } catch (e) {
      _log.e('Photo upload error: $e');
      return null;
    }
  }

  // ─── MOBILE APP: RECEIVE WARNINGS ────────────────────────────────

  /// Fetch current warnings for a specific location (mobile app pulls).
  Future<List<CivilianWarning>> getWarningsForLocation(
    double latitude,
    double longitude, {
    double radiusKm = 50.0,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '$baseUrl/v1/civilian/warnings'
          '?lat=$latitude&lng=$longitude&radius=$radiusKm',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((j) => CivilianWarning.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      _log.e('Fetch warnings error: $e');
      return [];
    }
  }

  // ─── WAR ROOM: INGEST REPORTS ────────────────────────────────────

  /// Start polling for new civilian reports (war room dashboard).
  void startIngesting({Duration interval = const Duration(seconds: 10)}) {
    _log.i('Starting civilian report ingestion');
    _fetchReports();
    _pollTimer = Timer.periodic(interval, (_) => _fetchReports());
  }

  /// Fetch recent civilian reports for the war room overlay.
  Future<void> _fetchReports() async {
    try {
      final since = _reports.isNotEmpty
          ? _reports.last.timestamp.toIso8601String()
          : DateTime.now()
              .subtract(const Duration(hours: 6))
              .toIso8601String();

      final response = await _client.get(
        Uri.parse('$baseUrl/v1/warroom/civilian-reports?since=$since'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        for (final item in data) {
          final report =
              CivilianReport.fromJson(item as Map<String, dynamic>);

          // Deduplicate by content hash
          if (!_reports.any((r) => r.contentHash == report.contentHash)) {
            _reports.add(report);
            _reportController.add(report);
          }
        }
      }
    } catch (e) {
      _log.e('Fetch civilian reports error: $e');
    }
  }

  /// Get reports clustered near a specific asset (for trajectory validation).
  List<CivilianReport> reportsNearAsset(
    String assetId, {
    double radiusKm = 20.0,
  }) {
    return _reports
        .where((r) =>
            r.matchedAssetId == assetId ||
            (r.distanceToNearestAssetKm != null &&
                r.distanceToNearestAssetKm! <= radiusKm))
        .toList();
  }

  /// Get all confirmed impact reports (highest intelligence value).
  List<CivilianReport> get confirmedImpacts => _reports
      .where((r) =>
          r.validationStatus == ValidationStatus.confirmed &&
          r.type == ReportType.impact)
      .toList();

  /// Reports with photos (useful for damage assessment).
  List<CivilianReport> get reportsWithPhotos =>
      _reports.where((r) => r.hasPhotos).toList();

  void dispose() {
    _pollTimer?.cancel();
    _reportController.close();
    _client.close();
  }
}

/// A push warning sent from the war room to civilian mobile apps.
class CivilianWarning {
  final String id;
  final DateTime issuedAt;
  final WarningLevel level;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  final double? threatLatitude;
  final double? threatLongitude;
  final double? affectedRadiusKm;
  final String? shelterGuidance;
  final Duration? estimatedTimeToImpact;
  final String? threatType;

  const CivilianWarning({
    required this.id,
    required this.issuedAt,
    required this.level,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    this.threatLatitude,
    this.threatLongitude,
    this.affectedRadiusKm,
    this.shelterGuidance,
    this.estimatedTimeToImpact,
    this.threatType,
  });

  bool get hasLocation => threatLatitude != null && threatLongitude != null;

  factory CivilianWarning.fromJson(Map<String, dynamic> json) =>
      CivilianWarning(
        id: json['id'] as String,
        issuedAt: DateTime.parse(json['issuedAt'] as String),
        level: WarningLevel.values.byName(json['level'] as String),
        titleEn: json['titleEn'] as String,
        titleAr: json['titleAr'] as String,
        bodyEn: json['bodyEn'] as String,
        bodyAr: json['bodyAr'] as String,
        threatLatitude: (json['threatLatitude'] as num?)?.toDouble(),
        threatLongitude: (json['threatLongitude'] as num?)?.toDouble(),
        affectedRadiusKm: (json['affectedRadiusKm'] as num?)?.toDouble(),
        shelterGuidance: json['shelterGuidance'] as String?,
        estimatedTimeToImpact: json['estimatedTimeToImpact'] != null
            ? Duration(seconds: json['estimatedTimeToImpact'] as int)
            : null,
        threatType: json['threatType'] as String?,
      );
}

/// Warning severity pushed to civilians.
enum WarningLevel {
  info,       // awareness only
  advisory,   // elevated risk, stay alert
  warning,    // significant threat, prepare shelter
  emergency,  // imminent strike, take shelter now
  allClear,   // threat has passed
}
