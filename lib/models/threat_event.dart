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

  const ThreatEvent({
    required this.id,
    required this.source,
    required this.headline,
    required this.timestamp,
    required this.type,
    required this.severityScore,
    this.targetCorridor,
    this.estimatedTimeToImpact,
  });

  bool get isActive => estimatedTimeToImpact != null;

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'headline': headline,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'severityScore': severityScore,
        'targetCorridor': targetCorridor,
        'estimatedTimeToImpact': estimatedTimeToImpact?.inSeconds,
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
