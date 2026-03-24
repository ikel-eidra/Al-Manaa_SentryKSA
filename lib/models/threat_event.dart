/// Model representing a Trigger Event from a monitored source.
class ThreatEvent {
  final String id;
  final String source; // 'CENTCOM', 'IDF', 'IRNA'
  final String headline;
  final DateTime timestamp;
  final ThreatType type;
  final int severityScore; // 1-10
  final String? targetCorridor;
  final Duration? estimatedTimeToImpact;

  // Geospatial fields for map plotting
  final double? latitude;
  final double? longitude;
  final double confidence; // 0.0 - 1.0 source confidence

  const ThreatEvent({
    required this.id,
    required this.source,
    required this.headline,
    required this.timestamp,
    required this.type,
    required this.severityScore,
    this.targetCorridor,
    this.estimatedTimeToImpact,
    this.latitude,
    this.longitude,
    this.confidence = 0.5,
  });

  bool get isActive => estimatedTimeToImpact != null;
  bool get hasLocation => latitude != null && longitude != null;

  String get sourceFlag {
    switch (source) {
      case 'CENTCOM':
        return '🇺🇸';
      case 'IDF':
        return '🇮🇱';
      case 'IRNA':
        return '🇮🇷';
      default:
        return '🌐';
    }
  }

  /// Icon glyph for threat type.
  String get typeIcon {
    switch (type) {
      case ThreatType.ballistic:
        return '🚀';
      case ThreatType.cruise:
        return '✈️';
      case ThreatType.drone:
        return '🛸';
      case ThreatType.cyber:
        return '💻';
      case ThreatType.naval:
        return '🚢';
      case ThreatType.hybrid:
        return '⚔️';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'headline': headline,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'severityScore': severityScore,
        'targetCorridor': targetCorridor,
        'estimatedTimeToImpact': estimatedTimeToImpact?.inSeconds,
        'latitude': latitude,
        'longitude': longitude,
        'confidence': confidence,
      };

  factory ThreatEvent.fromJson(Map<String, dynamic> json) => ThreatEvent(
        id: json['id'] as String,
        source: json['source'] as String,
        headline: json['headline'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: ThreatType.values.byName(json['type'] as String),
        severityScore: json['severityScore'] as int,
        targetCorridor: json['targetCorridor'] as String?,
        estimatedTimeToImpact: json['estimatedTimeToImpact'] != null
            ? Duration(seconds: json['estimatedTimeToImpact'] as int)
            : null,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      );
}

enum ThreatType {
  ballistic,
  cruise,
  drone,
  cyber,
  naval,
  hybrid,
}
