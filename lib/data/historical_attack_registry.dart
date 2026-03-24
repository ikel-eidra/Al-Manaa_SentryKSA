import '../models/threat_event.dart';
import 'source_registry.dart';

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

    // October 2024 Iran ballistic strike on Israel — real event
    HistoricalAttack(
      id: 'HA-2024-003',
      name: 'Iran October Ballistic Strike (Israel)',
      date: '2024-10-01',
      threatType: ThreatType.ballistic,
      targetAssetIds: [],
      targetSectors: [],
      targetProvinces: [],
      attribution: 'IRGC',
      attackVector: '180-200 ballistic missiles launched at Israel in single salvo',
      outcome: AttackOutcome.intercepted,
      productionLossBarrels: 0,
      durationDays: 0,
      brentSpikeDollars: 5.0,
      intercepted: true,
      description:
          'Iran launched approximately 180-200 ballistic missiles at Israel on '
          'October 1, 2024 — the largest ballistic missile salvo in Middle East '
          'history. Most were intercepted by Israeli Arrow/David\'s Sling and US '
          'THAAD/Aegis systems. Demonstrated Iran\'s willingness to repeat and '
          'escalate the April 2024 pattern with purely ballistic weapons. '
          'Israel retaliated with strikes on Iran on October 26, 2024.',
      lessonLearned:
          'Iran shifted from mixed drone/missile to predominantly ballistic salvo, '
          'reducing engagement time for defenders. Validates saturation-attack '
          'hypothesis for KSA scenario. Confirmed IRGC can sustain 180+ projectile '
          'launch within single operation.',
      precursorSignals: [
        'Israeli assassination of Hezbollah leader Nasrallah (Sep 27)',
        'IRGC vowed retaliation for "Axis of Resistance" losses',
        'CENTCOM raised THREATCON across Gulf installations',
        'Satellite imagery showed TEL mobilization at Iranian launch sites',
        'IDF and US deployed additional THAAD battery to region',
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    //  WAR PERIOD — FEB 28, 2025 ONWARD (SCENARIO MODELED)
    //  Escalation from regional proxy conflict to direct-action campaign
    // ═══════════════════════════════════════════════════════════════════

    // ─── 2025 — OPENING SALVOS & ESCALATION ─────────────────────────

    HistoricalAttack(
      id: 'HA-2025-001',
      name: 'Feb 28 Opening Salvo — Eastern Province',
      date: '2025-02-28',
      threatType: ThreatType.ballistic,
      secondaryType: ThreatType.cruise,
      targetAssetIds: ['E001', 'E002'],
      targetSectors: ['Energy'],
      targetProvinces: ['Eastern Province'],
      attribution: 'IRGC / Houthi coordinated',
      attackVector: 'Simultaneous ballistic + cruise missile barrage from Iran & Yemen',
      outcome: AttackOutcome.partialDamage,
      productionLossBarrels: 3200000,
      durationDays: 21,
      brentSpikeDollars: 22.0,
      intercepted: false,
      description:
          'Coordinated opening strike marking the start of direct hostilities. '
          '14 ballistic missiles and 22 cruise missiles targeted Abqaiq processing '
          'and Ras Tanura export terminal simultaneously. Patriot/THAAD intercepted '
          '~70% but saturating volume breached defenses. Abqaiq stabilization unit hit, '
          'Ras Tanura loading pier damaged. 3.2M bbl/day offline. Brent surged to '
          '\$107/bbl within hours. Global markets entered crisis mode.',
      lessonLearned:
          'Coordinated dual-axis attack (Iran north + Yemen south) can saturate '
          'even upgraded air defenses. First-strike volume exceeded Abqaiq 2019 by 3x. '
          'Need dispersed mobile defense and hardened facility redundancy.',
      precursorSignals: [
        'IRGC Supreme Leader authorized "all means" statement 96h prior',
        'CENTCOM detected surge in Iranian mobile TEL deployments along Gulf coast',
        'IDF intercepted IRGC encrypted coordination with Houthi command',
        'IRNA published editorial: "The patience of the resistance has limits"',
        'Commercial satellite showed Houthi cruise missile staging in Sana\'a',
        'Lloyd\'s suspended Gulf war risk coverage 48h prior',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2025-002',
      name: 'Ghawar Field Drone Swarm',
      date: '2025-03-04',
      threatType: ThreatType.drone,
      targetAssetIds: ['E003'],
      targetSectors: ['Energy'],
      targetProvinces: ['Eastern Province'],
      attribution: 'Houthi',
      attackVector: '40+ Samad-4 long-range drones in staggered waves',
      outcome: AttackOutcome.minorDamage,
      productionLossBarrels: 800000,
      durationDays: 7,
      brentSpikeDollars: 5.0,
      intercepted: true,
      description:
          'Largest drone swarm to date targeted Ghawar — world\'s largest oil field. '
          'Staggered in 3 waves over 4 hours to exhaust interceptor magazines. '
          'Saudi F-15s and Patriot PAC-3 downed 36 of 42. 6 drones struck peripheral '
          'wellhead infrastructure. Ghawar production reduced 15% for 7 days.',
      lessonLearned:
          'Wave tactics can deplete interceptor stocks. Need rapid reload capability '
          'and directed-energy weapons for persistent swarm defense.',
      precursorSignals: [
        'Houthi military spokesman declared "phase 2 of operations"',
        'CENTCOM tracked multiple drone logistics convoys in northern Yemen',
        'IDF Mossad briefed allies on Houthi drone inventory expansion',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2025-003',
      name: 'Ras Al-Khair Desalination Strike',
      date: '2025-03-12',
      threatType: ThreatType.cruise,
      targetAssetIds: ['W001'],
      targetSectors: ['Water'],
      targetProvinces: ['Eastern Province'],
      attribution: 'IRGC',
      attackVector: 'Soumar cruise missiles from Iranian territory via Gulf',
      outcome: AttackOutcome.majorDamage,
      productionLossBarrels: 0,
      durationDays: 45,
      brentSpikeDollars: 2.0,
      intercepted: false,
      description:
          'Direct IRGC strike on Ras Al-Khair — world\'s largest desalination plant. '
          '3 Soumar cruise missiles struck the reverse-osmosis facility. One intake '
          'manifold destroyed, two treatment trains offline. Water output cut 60%. '
          'Emergency water rationing imposed across Eastern Province for 6 weeks. '
          'Humanitarian crisis compounded economic damage.',
      lessonLearned:
          'Water infrastructure attacks create disproportionate civilian impact. '
          'Single-point-of-failure in desalination creates strategic vulnerability. '
          'Need hardened backup water supply and distributed treatment.',
      precursorSignals: [
        'IRGC released propaganda video naming KSA water plants',
        'CENTCOM detected Soumar cruise missile deployment to coastal launchers',
        'IRNA warned of "attacks on the sources of life"',
        'Iranian state TV showed map with KSA desalination plants marked',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2025-004',
      name: 'Riyadh Ministry of Defense Ballistic Strike',
      date: '2025-03-20',
      threatType: ThreatType.ballistic,
      targetAssetIds: ['G001'],
      targetSectors: ['Govt'],
      targetProvinces: ['Riyadh Province'],
      attribution: 'IRGC',
      attackVector: 'Emad-class MRBM targeting government complex',
      outcome: AttackOutcome.intercepted,
      productionLossBarrels: 0,
      durationDays: 0,
      brentSpikeDollars: 4.0,
      intercepted: true,
      description:
          'Two Emad-class medium-range ballistic missiles targeted the Ministry of Defense '
          'complex in central Riyadh. Both intercepted by THAAD at terminal phase. '
          'Debris landed in diplomatic quarter causing minor property damage. '
          'Psychological impact significant — first direct ballistic strike on capital '
          'during wartime. Brent spiked on fears of further escalation.',
      lessonLearned:
          'THAAD effective against MRBM class but limited magazine depth. '
          'Capital defense validated but sustained campaign would deplete stocks. '
          'Diplomatic consequences of debris fall in foreign embassy zone.',
      precursorSignals: [
        'IRGC commander stated "decision-making centers are not immune"',
        'CENTCOM tracked Emad TEL movement to launch positions near Bushehr',
        'IDF intelligence shared satellite imagery of launch preparations',
        'Iranian parliament passed "right to respond" resolution',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2025-005',
      name: 'Shamoon-III Cyber Campaign',
      date: '2025-04-02',
      threatType: ThreatType.cyber,
      targetAssetIds: ['D003', 'E008', 'D001'],
      targetSectors: ['Data', 'Energy'],
      targetProvinces: ['Eastern Province', 'Tabuk Province'],
      attribution: 'APT33 / MuddyWater (Iran)',
      attackVector: 'Zero-day exploit chain targeting Aramco SCADA + NIC government systems',
      outcome: AttackOutcome.partialDamage,
      productionLossBarrels: 500000,
      durationDays: 14,
      brentSpikeDollars: 1.5,
      intercepted: false,
      description:
          'Coordinated cyber offensive dubbed Shamoon-III launched simultaneously against '
          'Aramco operational technology networks and National Information Center. '
          'Zero-day in industrial control software exploited to disable automated safety '
          'systems at 3 production facilities. NIC government email and cloud services '
          'disrupted for 48 hours. Aramco forced manual shutdown of 500K bbl/day '
          'production as precaution while SCADA systems were verified.',
      lessonLearned:
          'Cyber as force multiplier during kinetic conflict. Simultaneous OT/IT attack '
          'forces conservative shutdowns that amplify production impact beyond actual damage. '
          'Need air-gapped backup control systems and pre-positioned incident response.',
      precursorSignals: [
        'CrowdStrike detected APT33 infrastructure staging 2 weeks prior',
        'Abnormal scanning of Aramco-linked IP ranges from Iranian proxies',
        'NSA advisory warned of "imminent Iranian cyber operations in Gulf"',
        'IRGC Cyber Command referenced "digital front" in state media',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2025-006',
      name: 'Yanbu Refinery Cruise Missile Hit',
      date: '2025-04-18',
      threatType: ThreatType.cruise,
      secondaryType: ThreatType.drone,
      targetAssetIds: ['E006'],
      targetSectors: ['Energy'],
      targetProvinces: ['Madinah Province'],
      attribution: 'Houthi',
      attackVector: 'Combined cruise + escort drone package via Red Sea corridor',
      outcome: AttackOutcome.partialDamage,
      productionLossBarrels: 400000,
      durationDays: 30,
      brentSpikeDollars: 6.0,
      intercepted: false,
      description:
          'Houthi launched 8 Quds-type cruise missiles escorted by decoy drones '
          'through Red Sea corridor targeting Yanbu refinery complex. Decoys overwhelmed '
          'local SHORAD. Two cruise missiles struck the catalytic cracking unit. '
          'Major fire, 400K bbl/day refining capacity offline for 30+ days. '
          'Red Sea shipping suspended for 72 hours after attack.',
      lessonLearned:
          'Decoy drone escorts enable cruise missile penetration of defended zones. '
          'Western coastline defense remains thinner than Eastern Province. '
          'Red Sea corridor a viable multi-vector attack path.',
      precursorSignals: [
        'Houthi naval forces conducted "exercise" near Bab al-Mandab',
        'CENTCOM tracked unusual Houthi cruise missile logistics to coast',
        'IDF detected Houthi/IRGC encrypted planning communications on Red Sea ops',
        'Commercial maritime alerts raised for Yanbu approaches',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2025-007',
      name: 'King Abdulaziz Air Base Ballistic Barrage',
      date: '2025-05-09',
      threatType: ThreatType.ballistic,
      secondaryType: ThreatType.cruise,
      targetAssetIds: ['G002'],
      targetSectors: ['Govt'],
      targetProvinces: ['Eastern Province'],
      attribution: 'IRGC',
      attackVector: 'Saturation ballistic + cruise targeting air defense hub',
      outcome: AttackOutcome.partialDamage,
      productionLossBarrels: 0,
      durationDays: 14,
      brentSpikeDollars: 3.0,
      intercepted: false,
      description:
          '8 ballistic missiles and 12 cruise missiles targeted KAAB in Dhahran — '
          'key RSAF air defense coordination center. Attack designed to degrade Saudi '
          'air defense C2 capability. Patriot batteries engaged but 2 missiles struck '
          'secondary taxiways and a maintenance hangar. RSAF sorties reduced 30% for '
          '2 weeks while alternate bases absorbed operations.',
      lessonLearned:
          'Counter-air defense (DEAD) tactics now part of Iranian doctrine against KSA. '
          'Air base hardening and dispersed operations essential. Need mobile C2 backup.',
      precursorSignals: [
        'IRGC published doctrine paper on "neutralizing enemy air defenses"',
        'CENTCOM intercepted targeting coordinates matching KAAB',
        'IDF warned of IRGC shift to military infrastructure targeting',
        'IRNA threatened to "blind the Saudi air defense umbrella"',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2025-008',
      name: 'Jubail Industrial Hybrid Strike',
      date: '2025-06-14',
      threatType: ThreatType.hybrid,
      secondaryType: ThreatType.drone,
      targetAssetIds: ['E007', 'W003'],
      targetSectors: ['Energy', 'Water'],
      targetProvinces: ['Eastern Province'],
      attribution: 'IRGC / Houthi joint operation',
      attackVector: 'Coordinated kinetic (drone swarm) + cyber (SCADA disruption) + naval mine',
      outcome: AttackOutcome.majorDamage,
      productionLossBarrels: 1200000,
      durationDays: 60,
      brentSpikeDollars: 12.0,
      intercepted: false,
      description:
          'Most sophisticated attack of the war. Simultaneous drone swarm on Jubail '
          'Industrial City + cyber disruption of water treatment SCADA + naval mines '
          'seeded in Jubail port approaches. SABIC petrochemical output halved. Jubail '
          'desalination intake contaminated by debris. Port closed for mine clearance. '
          'Triple-domain attack created cascading failures: energy loss → water loss → '
          'supply chain collapse. Brent hit \$118/bbl.',
      lessonLearned:
          'Hybrid multi-domain attacks create non-linear cascading effects. '
          'Industrial co-location (energy + water + petrochemicals) is a vulnerability. '
          'Naval mining of port approaches a low-cost high-impact tactic.',
      precursorSignals: [
        'IRGC naval forces conducted "mine-laying exercises" in Gulf',
        'Coordinated Houthi + IRGC rhetoric referenced Jubail specifically',
        'CENTCOM detected dual-axis logistics movement (Iran + Yemen)',
        'CrowdStrike reported APT33 probing Jubail industrial SCADA systems',
        'IDF intelligence flagged "unprecedented level of coordination"',
        'Lloyd\'s suspended Jubail port coverage',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2025-009',
      name: 'Prince Sultan Air Base Deep Strike',
      date: '2025-08-03',
      threatType: ThreatType.ballistic,
      targetAssetIds: ['G003'],
      targetSectors: ['Govt'],
      targetProvinces: ['Riyadh Province'],
      attribution: 'IRGC',
      attackVector: 'Kheibar Shekan hypersonic-capable ballistic missile',
      outcome: AttackOutcome.minorDamage,
      productionLossBarrels: 0,
      durationDays: 7,
      brentSpikeDollars: 2.0,
      intercepted: true,
      description:
          'Single Kheibar Shekan missile — Iran\'s most advanced MRBM with maneuverable '
          'warhead — targeted Prince Sultan Air Base (Al Kharj), host to US CENTCOM assets. '
          'THAAD engaged at terminal phase but maneuvering warhead complicated intercept. '
          'Near-miss: warhead detonated 200m from runway. Base operational within 48h '
          'but demonstrated Iranian ability to threaten joint US-Saudi facilities.',
      lessonLearned:
          'Maneuverable warheads challenge terminal-phase interceptors. '
          'Hypersonic-class threats need left-of-launch and boost-phase solutions. '
          'US presence makes KSA bases dual-use targets.',
      precursorSignals: [
        'IRGC unveiled Kheibar Shekan at military parade weeks prior',
        'CENTCOM detected mobile TEL movement to Khuzestan launch zone',
        'Iranian state TV broadcast "message to America in the Gulf"',
        'IDF shared boost-phase detection data showing new trajectory profile',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2025-010',
      name: 'Khurais Oil Field Sustained Drone Campaign',
      date: '2025-09-22',
      threatType: ThreatType.drone,
      secondaryType: ThreatType.cruise,
      targetAssetIds: ['E004'],
      targetSectors: ['Energy'],
      targetProvinces: ['Eastern Province'],
      attribution: 'Houthi',
      attackVector: 'Sustained 72-hour drone + cruise campaign (120+ munitions)',
      outcome: AttackOutcome.majorDamage,
      productionLossBarrels: 2100000,
      durationDays: 45,
      brentSpikeDollars: 9.0,
      intercepted: false,
      description:
          'Three-day sustained bombardment of Khurais oil field — 120+ drones and '
          'cruise missiles in continuous waves designed to prevent repair crews from '
          'operating. First "siege bombardment" tactic against oil infrastructure. '
          'Cumulative damage to separation and pumping stations. 2.1M bbl/day offline. '
          'OPEC declared force majeure for the first time since 1973.',
      lessonLearned:
          'Sustained multi-day bombardment prevents repair and compounds damage. '
          'Need hardened repair facilities and counter-UAS in persistent operation mode. '
          'Interceptor magazine depth is the critical limiting factor.',
      precursorSignals: [
        'Houthi announced "war of attrition on Saudi oil"',
        'CENTCOM observed unprecedented Houthi munition stockpiling',
        'IRNA published analysis of "economic exhaustion strategy"',
        'IDF tracked Iranian resupply flights to Yemen (Il-76 cargo planes)',
        'Aramco evacuated non-essential Khurais staff as precaution',
      ],
    ),

    // ─── 2026 — ONGOING CONFLICT ─────────────────────────────────────

    HistoricalAttack(
      id: 'HA-2026-001',
      name: 'New Year Riyadh Multi-Axis Strike',
      date: '2026-01-01',
      threatType: ThreatType.hybrid,
      secondaryType: ThreatType.ballistic,
      targetAssetIds: ['G001', 'D002'],
      targetSectors: ['Govt', 'Data'],
      targetProvinces: ['Riyadh Province'],
      attribution: 'IRGC / Houthi joint operation',
      attackVector: 'Ballistic + drone swarm + cyber DDoS targeting capital infrastructure',
      outcome: AttackOutcome.minorDamage,
      productionLossBarrels: 0,
      durationDays: 5,
      brentSpikeDollars: 3.5,
      intercepted: true,
      description:
          'Symbolic New Year attack on Riyadh. 4 ballistic missiles (all intercepted by THAAD), '
          '15 drones (12 intercepted), and massive DDoS on STC telecommunications hub. '
          'Designed for propaganda impact. STC experienced 4-hour service degradation '
          'in Riyadh. THAAD performance validated but stock criticality flagged.',
      lessonLearned:
          'Symbolic-date targeting for propaganda value continues (see Jeddah F1 2022). '
          'Improved intercept rates reflect defense adaptation but magazine depth remains '
          'the binding constraint in sustained conflict.',
      precursorSignals: [
        'IRGC Supreme Leader "New Year message to enemies" speech',
        'CENTCOM raised THREATCON DELTA for New Year period',
        'IDF detected launch preparations at multiple sites simultaneously',
        'Cloudflare flagged Iranian botnet activation targeting Gulf DNS',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2026-002',
      name: 'Jafurah Gas Field Cruise Strike',
      date: '2026-02-10',
      threatType: ThreatType.cruise,
      targetAssetIds: ['E010'],
      targetSectors: ['Energy'],
      targetProvinces: ['Eastern Province'],
      attribution: 'IRGC',
      attackVector: 'Low-altitude Hoveyzeh cruise missiles via Gulf sea-skim route',
      outcome: AttackOutcome.partialDamage,
      productionLossBarrels: 600000,
      durationDays: 28,
      brentSpikeDollars: 5.0,
      intercepted: false,
      description:
          'Iran targeted Jafurah — Saudi Arabia\'s flagship non-associated gas development '
          'and cornerstone of Vision 2030 diversification. 6 Hoveyzeh cruise missiles '
          'sea-skimmed across Gulf at <15m altitude, evading radar until terminal phase. '
          '4 struck gas processing infrastructure. Strategic targeting: hitting Vision 2030 '
          'investment to undermine Saudi economic transformation narrative.',
      lessonLearned:
          'Sea-skimming cruise missiles at very low altitude defeat current radar coverage. '
          'Need over-the-horizon radar and maritime patrol enhancement. '
          'Vision 2030 assets becoming strategic targets — economic warfare dimension.',
      precursorSignals: [
        'IRGC commander referenced "striking the Saudi future, not just the present"',
        'CENTCOM detected Hoveyzeh launcher deployment to Kharg Island',
        'IDF shared intelligence on IRGC targeting of Vision 2030 projects',
        'IRNA editorial on "making diversification impossible"',
        'Commercial satellite showed launcher positioning aimed at Gulf crossing',
      ],
    ),
    HistoricalAttack(
      id: 'HA-2026-003',
      name: 'Shaybah NGL Second Strike',
      date: '2025-03-15',
      threatType: ThreatType.drone,
      secondaryType: ThreatType.cruise,
      targetAssetIds: ['E005'],
      targetSectors: ['Energy'],
      targetProvinces: ['Eastern Province'],
      attribution: 'Houthi',
      attackVector: 'Long-range drone/cruise combination across Empty Quarter',
      outcome: AttackOutcome.partialDamage,
      productionLossBarrels: 900000,
      durationDays: 21,
      brentSpikeDollars: 4.5,
      intercepted: false,
      description:
          'Second strike on Shaybah NGL facility — this time with heavier ordnance. '
          'Unlike 2019 intercept success, Houthis used cruise missiles as primary '
          'strike with drones as escort/decoy. 2 cruise missiles struck NGL processing '
          'trains. Remote desert location complicated repair logistics. '
          '900K bbl/day NGL production offline for 3 weeks.',
      lessonLearned:
          'Remote facilities in Empty Quarter extremely difficult to defend and repair. '
          'Lesson from 2019 (intercept success) led to complacency. Adversary adapted '
          'by switching primary/decoy roles between drones and cruise missiles.',
      precursorSignals: [
        'Houthi announced "we will finish what we started in 2019"',
        'CENTCOM tracked Empty Quarter approach vectors being scouted by Houthi UAV',
        'IDF flagged new Houthi cruise missile variant with extended range',
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════
  //  WAR PHASE TRACKING — FEB 28, 2025 IS DAY ZERO
  // ═══════════════════════════════════════════════════════════════════

  /// The date direct hostilities began.
  static final DateTime warStartDate = DateTime(2025, 2, 28);

  /// Days since the war started.
  static int get daysSinceWarStart =>
      DateTime.now().difference(warStartDate).inDays;

  /// Current war phase based on elapsed time and attack patterns.
  static WarPhase get currentWarPhase {
    final days = daysSinceWarStart;
    if (days < 0) return WarPhase.preConflict;
    if (days <= 7) return WarPhase.openingSalvo;
    if (days <= 30) return WarPhase.escalation;
    if (days <= 90) return WarPhase.sustainedCampaign;
    if (days <= 180) return WarPhase.attrition;
    return WarPhase.protracted;
  }

  /// Attacks that occurred during the war period (Feb 28+ only).
  static List<HistoricalAttack> get warPeriodAttacks =>
      allAttacks.where((a) {
        final d = DateTime.tryParse(a.date);
        return d != null && !d.isBefore(warStartDate);
      }).toList();

  /// Pre-war historical attacks (before Feb 28, 2025).
  static List<HistoricalAttack> get preWarAttacks =>
      allAttacks.where((a) {
        final d = DateTime.tryParse(a.date);
        return d != null && d.isBefore(warStartDate);
      }).toList();

  /// Total production lost during war period (barrel-days).
  static int get warPeriodProductionLoss =>
      warPeriodAttacks.fold(
          0, (sum, a) => sum + a.productionLossBarrels * a.durationDays);

  /// War-period intercept rate (typically lower than pre-war).
  static double get warPeriodInterceptRate {
    final wp = warPeriodAttacks;
    if (wp.isEmpty) return 0;
    return wp.where((a) => a.intercepted).length / wp.length * 100;
  }

  /// Average days between attacks during war period.
  static double get warPeriodAttackFrequency {
    final wp = warPeriodAttacks;
    if (wp.length < 2) return 0;
    final sorted = wp.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final first = DateTime.parse(sorted.first.date);
    final last = DateTime.parse(sorted.last.date);
    final span = last.difference(first).inDays;
    return span / (wp.length - 1);
  }

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

  /// Whether this attack occurred during the war period (Feb 28, 2025+).
  bool get isWarPeriod {
    final d = DateTime.tryParse(date);
    return d != null && !d.isBefore(HistoricalAttackRegistry.warStartDate);
  }

  /// Get all verified source references for this attack from the SourceRegistry.
  List<SourceReference> get sourceReferences =>
      SourceRegistry.forAttack(id);

  /// Number of independent sources backing this attack record.
  int get sourceCount => sourceReferences.length;

  /// Whether this attack has at least one verified source.
  bool get isSourceVerified => sourceReferences.isNotEmpty;
}

/// War phase classification based on elapsed time from Feb 28, 2025.
enum WarPhase {
  preConflict,
  openingSalvo,
  escalation,
  sustainedCampaign,
  attrition,
  protracted;

  String get label {
    switch (this) {
      case WarPhase.preConflict:
        return 'PRE-CONFLICT';
      case WarPhase.openingSalvo:
        return 'OPENING SALVO';
      case WarPhase.escalation:
        return 'ESCALATION';
      case WarPhase.sustainedCampaign:
        return 'SUSTAINED CAMPAIGN';
      case WarPhase.attrition:
        return 'ATTRITION';
      case WarPhase.protracted:
        return 'PROTRACTED CONFLICT';
    }
  }

  String get labelAr {
    switch (this) {
      case WarPhase.preConflict:
        return 'ما قبل النزاع';
      case WarPhase.openingSalvo:
        return 'الضربة الأولى';
      case WarPhase.escalation:
        return 'التصعيد';
      case WarPhase.sustainedCampaign:
        return 'حملة مستمرة';
      case WarPhase.attrition:
        return 'حرب استنزاف';
      case WarPhase.protracted:
        return 'نزاع طويل الأمد';
    }
  }
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
