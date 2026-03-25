import 'dart:convert';
import 'package:crypto/crypto.dart';

/// A crowd-sourced report from a civilian mobile app user.
///
/// Citizens become a distributed sensor mesh — millions of phones reporting
/// impact locations, damage photos, and ground truth that validates or
/// corrects the war room's projected trajectories.
///
/// Data flow:
///   Mobile App → API → War Room Dashboard (classified overlay)
///   War Room validates → updates trajectory projections → pushes refined
///   warnings back to mobile app users in affected corridors.
class CivilianReport {
  final String id;
  final String reporterDeviceHash; // anonymized device fingerprint
  final DateTime timestamp;
  final ReportType type;
  final double latitude;
  final double longitude;
  final double locationAccuracyMeters;
  final String? description;
  final List<String> photoUrls; // uploaded to secure CDN
  final DamageLevel? damageLevel;
  final String? impactType; // 'explosion', 'fire', 'debris', 'smoke', 'siren'
  final ValidationStatus validationStatus;
  final double trustScore; // 0.0-1.0, computed from reporter history
  final String? matchedThreatEventId; // cross-ref to classified ThreatEvent
  final String? matchedAssetId; // cross-ref to nearest StrategicAsset
  final double? distanceToNearestAssetKm;

  const CivilianReport({
    required this.id,
    required this.reporterDeviceHash,
    required this.timestamp,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.locationAccuracyMeters,
    this.description,
    this.photoUrls = const [],
    this.damageLevel,
    this.impactType,
    this.validationStatus = ValidationStatus.pending,
    this.trustScore = 0.5,
    this.matchedThreatEventId,
    this.matchedAssetId,
    this.distanceToNearestAssetKm,
  });

  /// Cryptographic hash for deduplication and tamper detection.
  String get contentHash {
    final input = '$reporterDeviceHash|$timestamp|$latitude|$longitude|$type';
    return sha256.convert(utf8.encode(input)).toString().substring(0, 16);
  }

  bool get hasPhotos => photoUrls.isNotEmpty;
  bool get isValidated => validationStatus == ValidationStatus.confirmed;
  bool get isNearAsset =>
      distanceToNearestAssetKm != null && distanceToNearestAssetKm! <= 15.0;

  /// Whether this report is high-value intelligence (near asset + photo + confirmed).
  bool get isHighValue =>
      isNearAsset && hasPhotos && trustScore >= 0.7;

  /// Icon for report type display.
  String get typeIcon {
    switch (type) {
      case ReportType.impact:
        return '💥';
      case ReportType.fire:
        return '🔥';
      case ReportType.debris:
        return '🧱';
      case ReportType.smoke:
        return '💨';
      case ReportType.siren:
        return '🚨';
      case ReportType.allClear:
        return '✅';
      case ReportType.casualty:
        return '🏥';
      case ReportType.infrastructure:
        return '🏗️';
      case ReportType.military:
        return '🎖️';
      case ReportType.unknown:
        return '❓';
    }
  }

  /// Damage severity color for map display.
  int get damageColorValue {
    switch (damageLevel) {
      case DamageLevel.catastrophic:
        return 0xFFFF0000; // red
      case DamageLevel.severe:
        return 0xFFFF6600; // orange
      case DamageLevel.moderate:
        return 0xFFFFCC00; // yellow
      case DamageLevel.minor:
        return 0xFF66FF66; // green
      case DamageLevel.none:
        return 0xFF00CCFF; // blue
      case null:
        return 0xFF999999; // grey
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reporterDeviceHash': reporterDeviceHash,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'latitude': latitude,
        'longitude': longitude,
        'locationAccuracyMeters': locationAccuracyMeters,
        'description': description,
        'photoUrls': photoUrls,
        'damageLevel': damageLevel?.name,
        'impactType': impactType,
        'validationStatus': validationStatus.name,
        'trustScore': trustScore,
        'matchedThreatEventId': matchedThreatEventId,
        'matchedAssetId': matchedAssetId,
        'distanceToNearestAssetKm': distanceToNearestAssetKm,
      };

  factory CivilianReport.fromJson(Map<String, dynamic> json) =>
      CivilianReport(
        id: json['id'] as String,
        reporterDeviceHash: json['reporterDeviceHash'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: ReportType.values.byName(json['type'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        locationAccuracyMeters:
            (json['locationAccuracyMeters'] as num).toDouble(),
        description: json['description'] as String?,
        photoUrls: (json['photoUrls'] as List<dynamic>?)
                ?.cast<String>() ??
            const [],
        damageLevel: json['damageLevel'] != null
            ? DamageLevel.values.byName(json['damageLevel'] as String)
            : null,
        impactType: json['impactType'] as String?,
        validationStatus: json['validationStatus'] != null
            ? ValidationStatus.values
                .byName(json['validationStatus'] as String)
            : ValidationStatus.pending,
        trustScore: (json['trustScore'] as num?)?.toDouble() ?? 0.5,
        matchedThreatEventId: json['matchedThreatEventId'] as String?,
        matchedAssetId: json['matchedAssetId'] as String?,
        distanceToNearestAssetKm:
            (json['distanceToNearestAssetKm'] as num?)?.toDouble(),
      );
}

/// What the civilian is reporting.
enum ReportType {
  impact,          // explosion / strike impact observed
  fire,            // fire visible
  debris,          // debris / shrapnel found
  smoke,           // smoke plume visible
  siren,           // air raid siren heard
  allClear,        // area appears safe
  casualty,        // injured people observed
  infrastructure,  // infrastructure damage (roads, buildings, utilities)
  military,        // military vehicle / activity observed
  unknown,         // something unusual but unidentified
}

/// Assessed damage severity at the reported location.
enum DamageLevel {
  catastrophic, // total destruction, large crater, structure collapse
  severe,       // major structural damage, large fires
  moderate,     // partial damage, contained fires
  minor,        // cosmetic damage, broken windows, small debris
  none,         // no visible damage (false alarm or near-miss)
}

/// Server-side validation status of the report.
enum ValidationStatus {
  pending,       // awaiting cross-reference
  confirmed,     // corroborated by 2+ independent reports or classified data
  probable,      // single report but consistent with projected trajectory
  unconfirmed,   // cannot validate, insufficient corroboration
  rejected,      // inconsistent with all data, likely false report
  duplicate,     // same event already reported by another user
}
