/// The escalation timeline from rhetoric to impact.
///
/// Models the real-world progression that SentryKSA tracks:
///   RHETORIC → SIMMERING → MOBILIZATION → 0-HOUR → IMPACT → AFTERMATH
///
/// Each phase has distinct characteristics that inform both the classified
/// war room and the civilian mobile app differently:
///   - War room: Probability calculations, force posture, asset hardening
///   - Mobile app: Warning level, shelter guidance, reporting prompts
class EscalationPhase {
  final PhaseLevel level;
  final DateTime enteredAt;
  final DateTime? projectedNextPhaseAt;
  final double confidenceInProjection; // 0.0-1.0
  final List<String> activeIndicators;
  final String civilianGuidance;
  final String classifiedAssessment;

  const EscalationPhase({
    required this.level,
    required this.enteredAt,
    this.projectedNextPhaseAt,
    this.confidenceInProjection = 0.0,
    this.activeIndicators = const [],
    this.civilianGuidance = '',
    this.classifiedAssessment = '',
  });

  /// Time remaining until projected next phase.
  Duration? get timeToNextPhase => projectedNextPhaseAt != null
      ? projectedNextPhaseAt!.difference(DateTime.now())
      : null;

  bool get isPreKinetic =>
      level == PhaseLevel.rhetoric ||
      level == PhaseLevel.simmering ||
      level == PhaseLevel.mobilization;

  bool get isKinetic =>
      level == PhaseLevel.zeroHour || level == PhaseLevel.impact;

  /// Color for the mobile app warning banner.
  int get warningColorValue {
    switch (level) {
      case PhaseLevel.baseline:
        return 0xFF4CAF50; // green
      case PhaseLevel.rhetoric:
        return 0xFF2196F3; // blue
      case PhaseLevel.simmering:
        return 0xFFFFC107; // amber
      case PhaseLevel.mobilization:
        return 0xFFFF9800; // orange
      case PhaseLevel.zeroHour:
        return 0xFFF44336; // red
      case PhaseLevel.impact:
        return 0xFF9C27B0; // purple — active strike
      case PhaseLevel.aftermath:
        return 0xFF607D8B; // grey — recovery
    }
  }

  /// Civilian-facing label (Arabic-ready).
  String get civilianLabel {
    switch (level) {
      case PhaseLevel.baseline:
        return 'ALL CLEAR';
      case PhaseLevel.rhetoric:
        return 'MONITOR';
      case PhaseLevel.simmering:
        return 'ELEVATED ALERT';
      case PhaseLevel.mobilization:
        return 'HIGH ALERT';
      case PhaseLevel.zeroHour:
        return 'IMMINENT THREAT';
      case PhaseLevel.impact:
        return 'TAKE SHELTER NOW';
      case PhaseLevel.aftermath:
        return 'REPORT & RECOVER';
    }
  }

  /// Icon for the mobile app.
  String get phaseIcon {
    switch (level) {
      case PhaseLevel.baseline:
        return '🟢';
      case PhaseLevel.rhetoric:
        return '🔵';
      case PhaseLevel.simmering:
        return '🟡';
      case PhaseLevel.mobilization:
        return '🟠';
      case PhaseLevel.zeroHour:
        return '🔴';
      case PhaseLevel.impact:
        return '🟣';
      case PhaseLevel.aftermath:
        return '⚪';
    }
  }

  /// Whether civilian reporting should be actively solicited.
  bool get shouldPromptReports =>
      level == PhaseLevel.impact || level == PhaseLevel.aftermath;

  /// Whether shelter-in-place guidance is active.
  bool get shelterInPlace =>
      level == PhaseLevel.zeroHour || level == PhaseLevel.impact;

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'enteredAt': enteredAt.toIso8601String(),
        'projectedNextPhaseAt': projectedNextPhaseAt?.toIso8601String(),
        'confidenceInProjection': confidenceInProjection,
        'activeIndicators': activeIndicators,
        'civilianGuidance': civilianGuidance,
      };

  factory EscalationPhase.fromJson(Map<String, dynamic> json) =>
      EscalationPhase(
        level: PhaseLevel.values.byName(json['level'] as String),
        enteredAt: DateTime.parse(json['enteredAt'] as String),
        projectedNextPhaseAt: json['projectedNextPhaseAt'] != null
            ? DateTime.parse(json['projectedNextPhaseAt'] as String)
            : null,
        confidenceInProjection:
            (json['confidenceInProjection'] as num?)?.toDouble() ?? 0.0,
        activeIndicators:
            (json['activeIndicators'] as List<dynamic>?)?.cast<String>() ??
                const [],
        civilianGuidance: json['civilianGuidance'] as String? ?? '',
      );
}

/// The 7-phase escalation ladder.
///
/// Real-world mapping:
///   baseline      → Normal peacetime operations
///   rhetoric      → Political threats, inflammatory speeches (e.g. Khamenei rhetoric)
///   simmering     → Jan-Feb 2025: Insurance spikes, military exercises, deployments
///   mobilization  → TEL deployment, force posture changes, THREATCON elevation
///   zeroHour      → Launch detected, missiles in flight, 12-90 min to impact
///   impact        → Strikes hitting, explosions confirmed, damage ongoing
///   aftermath     → Fires burning, rescue ops, damage assessment, crowd reporting
enum PhaseLevel {
  baseline,
  rhetoric,
  simmering,
  mobilization,
  zeroHour,
  impact,
  aftermath,
}
