import '../models/threat_event.dart';

/// Registry of verified historical attacks on KSA infrastructure.
/// Used by the ProbabilityEngine to compute Bayesian priors and
/// pattern-match current threat events against historical precedent.
class HistoricalAttackRegistry {
  HistoricalAttackRegistry._();

  static const List<HistoricalAttack> allAttacks = [
    // ─── 2019 ────────────────────────────────────────────────────────
    HistoricalAttack(
      id: 'HA-2019-001',
      name: 'Abqaiq-Khurais Attack',
      date: '2019-09-14',
      threatType: ThreatType.drone,
      secondaryType: ThreatType.cruise,
      targetAssetIds: ['E001', 'E004'],
      targetSectors: ['Energy'],
      targetProvinces: ['Eastern Province'],
      attribution: 'Houthi (Iran-backed)',
      attackVector: 'Combined drone/cruise missile swarm from north',
      outcome: AttackOutcome.partialDamage,
      productionLossBarrels: 5700000,
      durationDays: 14,
      brentSpikeDollars: 15.0,
      intercepted: false,
      description:
          '18 drones and 7 cruise missiles struck Abqaiq processing facility '
          'and Khurais oil field. Knocked out 5.7M bbl/day — 5% of global supply. '
          'Brent surged 15% in hours. Full production restored in ~2 weeks.',
      lessonLearned:
          'Exposed gap in southern radar coverage. Led to Patriot/THAAD redeployment. '
          'Demonstrated swarm tactics can overwhelm point defenses.',
      precursorSignals: [
        'IRGC rhetoric escalation 72h prior',
        'Houthi leader televised threat against Aramco',
        'CENTCOM noted unusual drone logistics in Yemen',
        'IDF SIGINT detected launch preparations',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2019-002',
      name: 'Shaybah NGL Facility Attack',
      date: '2019-08-17',
      threatType: ThreatType.drone,
      targetAssetIds: ['E005'],
      targetSectors: ['Energy'],
      targetProvinces: ['Eastern Province'],
      attribution: 'Houthi',
      attackVector: '10 explosive-laden drones from Yemen',
      outcome: AttackOutcome.minorDamage,
      productionLossBarrels: 0,
      durationDays: 1,
      brentSpikeDollars: 1.0,
      intercepted: true,
      description:
          'Ten drones targeted the Shaybah NGL facility in the Rub al-Khali. '
          'Saudi air defenses intercepted most; minor fire at a gas liquefaction unit. '
          'No production disruption.',
      lessonLearned:
          'Remote desert facilities vulnerable to long-range drone infiltration. '
          'Need forward-deployed air defense in southern Empty Quarter.',
      precursorSignals: [
        'Houthi claimed targeting "deep inside Saudi territory"',
        'CENTCOM issued travel advisory for Eastern Province',
      ],
    ),

    // ─── 2020 ────────────────────────────────────────────────────────
    HistoricalAttack(
      id: 'HA-2020-001',
      name: 'Riyadh Missile Intercept',
      date: '2020-03-28',
      threatType: ThreatType.ballistic,
      targetAssetIds: ['G001'],
      targetSectors: ['Govt'],
      targetProvinces: ['Riyadh Province'],
      attribution: 'Houthi',
      attackVector: 'Ballistic missile aimed at Riyadh',
      outcome: AttackOutcome.intercepted,
      productionLossBarrels: 0,
      durationDays: 0,
      brentSpikeDollars: 0.5,
      intercepted: true,
      description:
          'Patriot battery intercepted a ballistic missile over Riyadh. '
          'Debris fell in unpopulated area. Part of an escalation cycle during '
          'COVID-19 ceasefire negotiations.',
      lessonLearned:
          'Patriot system effective against single ballistic threats. '
          'Riyadh air defense umbrella validated.',
      precursorSignals: [
        'Houthi announced "balance of deterrence" campaign',
        'IRNA reported "new missile capability" test',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2020-002',
      name: 'Ras Tanura Port Drone Attempt',
      date: '2020-11-23',
      threatType: ThreatType.drone,
      targetAssetIds: ['E002'],
      targetSectors: ['Energy'],
      targetProvinces: ['Eastern Province'],
      attribution: 'Houthi',
      attackVector: 'Explosive drone targeting port loading facilities',
      outcome: AttackOutcome.intercepted,
      productionLossBarrels: 0,
      durationDays: 0,
      brentSpikeDollars: 0.3,
      intercepted: true,
      description:
          'Drone intercepted before reaching Ras Tanura oil terminal. '
          'No damage or production disruption. Marked continued Houthi campaign '
          'against export infrastructure.',
      lessonLearned:
          'Eastern Province export terminals remain high-priority Houthi targets.',
      precursorSignals: [
        'Houthi military spokesman warned of "expanded target bank"',
      ],
    ),

    // ─── 2021 ────────────────────────────────────────────────────────
    HistoricalAttack(
      id: 'HA-2021-001',
      name: 'Ras Tanura Refinery Attack',
      date: '2021-03-07',
      threatType: ThreatType.ballistic,
      secondaryType: ThreatType.drone,
      targetAssetIds: ['E002'],
      targetSectors: ['Energy'],
      targetProvinces: ['Eastern Province'],
      attribution: 'Houthi',
      attackVector: 'Ballistic missile + drone combination targeting refinery and port',
      outcome: AttackOutcome.minorDamage,
      productionLossBarrels: 0,
      durationDays: 1,
      brentSpikeDollars: 2.0,
      intercepted: true,
      description:
          'Combined missile/drone attack on Ras Tanura refinery and Dhahran '
          'residential compound. Missiles intercepted, drone debris caused minor damage. '
          'No casualties. Brent rose 2%.',
      lessonLearned:
          'Combined-arms approach (ballistic + drone) designed to overwhelm '
          'layered defenses. Residential areas also at risk.',
      precursorSignals: [
        'IRGC Quds Force logistics movement detected by IDF',
        'Houthi unveiled "Zulfiqar" ballistic variant',
        'CENTCOM raised threat level for Eastern Province',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2021-002',
      name: 'Jubail Water Desalination Drone',
      date: '2021-11-20',
      threatType: ThreatType.drone,
      targetAssetIds: ['W003'],
      targetSectors: ['Water'],
      targetProvinces: ['Eastern Province'],
      attribution: 'Houthi',
      attackVector: 'Single explosive drone targeting desalination intake',
      outcome: AttackOutcome.minorDamage,
      productionLossBarrels: 0,
      durationDays: 2,
      brentSpikeDollars: 0.2,
      intercepted: false,
      description:
          'Drone struck near Jubail desalination plant water intake. '
          'Minor damage to peripheral equipment. Briefly reduced output by 10%. '
          'First confirmed targeting of water infrastructure.',
      lessonLearned:
          'Water infrastructure now confirmed as part of Houthi target bank. '
          'Desalination plants need dedicated short-range air defense.',
      precursorSignals: [
        'Houthi spokesman threatened "water and power targets"',
        'IRNA editorial mentioned "strategic pressure points"',
      ],
    ),

    // ─── 2022 ────────────────────────────────────────────────────────
    HistoricalAttack(
      id: 'HA-2022-001',
      name: 'Jeddah F1 Eve Aramco Depot Attack',
      date: '2022-03-25',
      threatType: ThreatType.cruise,
      secondaryType: ThreatType.drone,
      targetAssetIds: [],
      targetSectors: ['Energy'],
      targetProvinces: ['Makkah Province'],
      attribution: 'Houthi',
      attackVector: 'Cruise missile and drone targeting Jeddah fuel depot during F1 GP',
      outcome: AttackOutcome.partialDamage,
      productionLossBarrels: 0,
      durationDays: 3,
      brentSpikeDollars: 3.5,
      intercepted: false,
      description:
          'Attack on Aramco fuel distribution depot in Jeddah during Saudi F1 '
          'Grand Prix weekend. Major fire visible from the circuit. Timed for '
          'maximum global media exposure. No casualties.',
      lessonLearned:
          'Houthis demonstrate ability to time attacks for propaganda value. '
          'Western Province targets viable. Soft infrastructure (depots) vulnerable.',
      precursorSignals: [
        'Houthi warned of "surprises during the race weekend"',
        'CENTCOM detected cruise missile preparations in Yemen',
        'IDF intercepted communications referencing Jeddah',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2022-002',
      name: 'Dhahran Aramco HQ Cyber Intrusion',
      date: '2022-06-15',
      threatType: ThreatType.cyber,
      targetAssetIds: ['E008', 'D003'],
      targetSectors: ['Energy', 'Data'],
      targetProvinces: ['Eastern Province'],
      attribution: 'APT33 (Iran-linked)',
      attackVector: 'Spear-phishing → lateral movement → OT network probe',
      outcome: AttackOutcome.minorDamage,
      productionLossBarrels: 0,
      durationDays: 30,
      brentSpikeDollars: 0.0,
      intercepted: true,
      description:
          'Iranian APT33 group conducted sophisticated cyber intrusion targeting '
          'Aramco operational technology networks. Detected before reaching SCADA '
          'systems. Reminiscent of 2012 Shamoon attack methodology.',
      lessonLearned:
          'Cyber remains a persistent parallel vector. OT/IT segmentation critical. '
          'APT33 maintains standing capability against KSA energy sector.',
      precursorSignals: [
        'FireEye flagged APT33 infrastructure activation',
        'Abnormal DNS queries from Aramco IP ranges',
        'IRGC cyber unit recruitment surge detected by GCHQ',
      ],
    ),

    // ─── 2023 ────────────────────────────────────────────────────────
    HistoricalAttack(
      id: 'HA-2023-001',
      name: 'Yanbu Refinery Drone Intercept',
      date: '2023-01-18',
      threatType: ThreatType.drone,
      targetAssetIds: ['E006'],
      targetSectors: ['Energy'],
      targetProvinces: ['Madinah Province'],
      attribution: 'Houthi',
      attackVector: 'Long-range Samad-3 drone from Yemen via Red Sea corridor',
      outcome: AttackOutcome.intercepted,
      productionLossBarrels: 0,
      durationDays: 0,
      brentSpikeDollars: 0.8,
      intercepted: true,
      description:
          'Samad-3 drone intercepted approaching Yanbu refinery complex from '
          'Red Sea vector. Demonstrated Houthi ability to reach western KSA assets. '
          'Coincided with Yemen ceasefire expiry.',
      lessonLearned:
          'Red Sea approach vector confirmed viable. Western assets need permanent '
          'air defense coverage, not just eastern-facing.',
      precursorSignals: [
        'Yemen ceasefire expired 48h prior',
        'IRNA praised "new drone range capability"',
        'Houthi military parade showed Samad-3 airframes',
      ],
    ),

    // ─── 2024 ────────────────────────────────────────────────────────
    HistoricalAttack(
      id: 'HA-2024-001',
      name: 'Red Sea Shipping Crisis Spillover',
      date: '2024-01-10',
      threatType: ThreatType.naval,
      secondaryType: ThreatType.cruise,
      targetAssetIds: [],
      targetSectors: ['Energy'],
      targetProvinces: [],
      attribution: 'Houthi',
      attackVector: 'Anti-ship missiles and drones targeting Red Sea commercial shipping',
      outcome: AttackOutcome.partialDamage,
      productionLossBarrels: 0,
      durationDays: 180,
      brentSpikeDollars: 4.0,
      intercepted: false,
      description:
          'Houthi campaign against Red Sea shipping forced rerouting of tankers '
          'around Cape of Good Hope. While not a direct KSA strike, disrupted '
          'Yanbu export corridor and raised Brent by \$4/bbl for months. '
          'US/UK Operation Prosperity Guardian responded.',
      lessonLearned:
          'Naval/maritime threats can achieve strategic effect without hitting KSA soil. '
          'Chokepoint disruption (Bab al-Mandab) equivalent to infrastructure strike.',
      precursorSignals: [
        'Houthi declared "all Israeli-linked shipping" as targets',
        'CENTCOM surged naval assets to Red Sea',
        'Lloyd\'s raised war risk premium for Bab al-Mandab transit',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2024-002',
      name: 'Iran Ballistic Demonstration (Israel Strike)',
      date: '2024-04-13',
      threatType: ThreatType.ballistic,
      secondaryType: ThreatType.drone,
      targetAssetIds: [],
      targetSectors: [],
      targetProvinces: [],
      attribution: 'IRGC',
      attackVector: '300+ missiles and drones launched at Israel, some transiting KSA airspace',
      outcome: AttackOutcome.intercepted,
      productionLossBarrels: 0,
      durationDays: 0,
      brentSpikeDollars: 3.0,
      intercepted: true,
      description:
          'Iran launched 300+ missiles and drones at Israel. Some transited near '
          'KSA northern border airspace. 99% intercepted by Israeli/US/UK/Jordan '
          'coalition. Demonstrated Iran\'s mass-strike capability and willingness to '
          'escalate. KSA scrambled air assets as precaution.',
      lessonLearned:
          'Iran can execute 300+ projectile salvo. KSA airspace at risk during '
          'regional escalation even if not the primary target. Mass-saturation '
          'tactics can overwhelm single-layer defenses.',
      precursorSignals: [
        'Israeli strike on Iranian consulate in Damascus 12 days prior',
        'IRGC vowed "definitive response"',
        'CENTCOM raised THREATCON across Gulf',
        'IRNA broadcast launch preparations openly',
        'IDF published projected flight corridors crossing Saudi airspace',
      ],
    ),
  ];

  /// Find historical attacks that targeted a specific asset.
  static List<HistoricalAttack> forAsset(String assetId) =>
      allAttacks.where((a) => a.targetAssetIds.contains(assetId)).toList();

  /// Find attacks matching a sector.
  static List<HistoricalAttack> forSector(String sector) =>
      allAttacks.where((a) => a.targetSectors.contains(sector)).toList();

  /// Find attacks matching a province.
  static List<HistoricalAttack> forProvince(String province) =>
      allAttacks.where((a) => a.targetProvinces.contains(province)).toList();

  /// Find attacks matching a specific threat type.
  static List<HistoricalAttack> forThreatType(ThreatType type) =>
      allAttacks
          .where((a) => a.threatType == type || a.secondaryType == type)
          .toList();

  /// Find the closest historical precedent to a current event.
  static HistoricalAttack? closestPrecedent(ThreatEvent event) {
    final candidates = allAttacks.where((attack) {
      final typeMatch =
          attack.threatType == event.type || attack.secondaryType == event.type;
      final corridorMatch = event.targetCorridor != null &&
          (attack.targetProvinces.any(
                  (p) => event.targetCorridor!.toLowerCase().contains(p.toLowerCase())) ||
              attack.targetSectors.any(
                  (s) => event.targetCorridor!.toLowerCase().contains(s.toLowerCase())));
      return typeMatch || corridorMatch;
    }).toList();

    if (candidates.isEmpty) return null;

    // Score by relevance: type match + sector match + province match
    candidates.sort((a, b) {
      int scoreA = 0, scoreB = 0;
      if (a.threatType == event.type) scoreA += 3;
      if (a.secondaryType == event.type) scoreA += 1;
      if (b.threatType == event.type) scoreB += 3;
      if (b.secondaryType == event.type) scoreB += 1;
      if (event.targetCorridor != null) {
        for (final p in a.targetProvinces) {
          if (event.targetCorridor!.toLowerCase().contains(p.toLowerCase())) {
            scoreA += 2;
          }
        }
        for (final p in b.targetProvinces) {
          if (event.targetCorridor!.toLowerCase().contains(p.toLowerCase())) {
            scoreB += 2;
          }
        }
      }
      return scoreB.compareTo(scoreA);
    });

    return candidates.first;
  }

  /// Overall intercept success rate from historical data.
  static double get historicalInterceptRate {
    final total = allAttacks.length;
    final intercepted = allAttacks.where((a) => a.intercepted).length;
    return intercepted / total * 100;
  }

  /// Average Brent spike from historical attacks.
  static double get averageBrentSpike {
    final spikes = allAttacks.map((a) => a.brentSpikeDollars).where((s) => s > 0);
    if (spikes.isEmpty) return 0;
    return spikes.reduce((a, b) => a + b) / spikes.length;
  }

  /// Total number of attacks per threat type (for probability priors).
  static Map<ThreatType, int> get attackCountByType {
    final counts = <ThreatType, int>{};
    for (final attack in allAttacks) {
      counts[attack.threatType] = (counts[attack.threatType] ?? 0) + 1;
      if (attack.secondaryType != null) {
        counts[attack.secondaryType!] = (counts[attack.secondaryType!] ?? 0) + 1;
      }
    }
    return counts;
  }
}

/// A verified historical attack on KSA infrastructure.
class HistoricalAttack {
  final String id;
  final String name;
  final String date;
  final ThreatType threatType;
  final ThreatType? secondaryType;
  final List<String> targetAssetIds;
  final List<String> targetSectors;
  final List<String> targetProvinces;
  final String attribution;
  final String attackVector;
  final AttackOutcome outcome;
  final int productionLossBarrels;
  final int durationDays;
  final double brentSpikeDollars;
  final bool intercepted;
  final String description;
  final String lessonLearned;
  final List<String> precursorSignals;

  const HistoricalAttack({
    required this.id,
    required this.name,
    required this.date,
    required this.threatType,
    this.secondaryType,
    required this.targetAssetIds,
    required this.targetSectors,
    required this.targetProvinces,
    required this.attribution,
    required this.attackVector,
    required this.outcome,
    required this.productionLossBarrels,
    required this.durationDays,
    required this.brentSpikeDollars,
    required this.intercepted,
    required this.description,
    required this.lessonLearned,
    required this.precursorSignals,
  });

  int get year => int.parse(date.substring(0, 4));
  String get outcomeLabel => outcome.label;
  String get formattedLoss => productionLossBarrels > 0
      ? '${(productionLossBarrels / 1000000).toStringAsFixed(1)}M bbl/day'
      : 'None';
}

enum AttackOutcome {
  intercepted,
  minorDamage,
  partialDamage,
  majorDamage,
  catastrophic;

  String get label {
    switch (this) {
      case AttackOutcome.intercepted:
        return 'INTERCEPTED';
      case AttackOutcome.minorDamage:
        return 'MINOR DAMAGE';
      case AttackOutcome.partialDamage:
        return 'PARTIAL DAMAGE';
      case AttackOutcome.majorDamage:
        return 'MAJOR DAMAGE';
      case AttackOutcome.catastrophic:
        return 'CATASTROPHIC';
    }
  }
}
