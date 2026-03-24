import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import '../models/threat_event.dart';
import '../data/source_registry.dart';

/// OSINT news scraper and parser service.
///
/// Continuously scrapes, parses, and ingests intelligence from multiple
/// trusted sources. Every ingested item gets a SHA-256 provenance hash
/// and is cross-referenced against the SourceRegistry for ground truth.
///
/// Feed categories:
///   1. Wire services (Reuters, AP, AFP) — fastest breaking news
///   2. Government/military (CENTCOM, SPA, IDF) — official statements
///   3. Adversary media (IRNA, Tasnim, Al-Masirah) — rhetoric monitoring
///   4. OSINT aggregators (Bellingcat, satellite imagery feeds)
///   5. Market signals (Brent futures, Lloyd's war risk, shipping AIS)
///   6. Cyber threat intel (CrowdStrike, Mandiant, NSA advisories)
class NewsScraperService {
  final Logger _log = Logger(printer: SimplePrinter(colors: false));
  final String _baseUrl;
  final http.Client _client;

  // Polling intervals per source tier (in seconds)
  static const Map<SourceTier, int> _pollIntervals = {
    SourceTier.criticalBreaking: 15,    // Wire services: every 15s
    SourceTier.officialStatements: 30,   // Government: every 30s
    SourceTier.adversaryRhetoric: 45,    // Iran/Houthi media: every 45s
    SourceTier.osintAnalysis: 120,       // OSINT: every 2 min
    SourceTier.marketSignals: 60,        // Market data: every 60s
    SourceTier.cyberIntel: 90,           // Cyber feeds: every 90s
  };

  final _eventController = StreamController<ScrapedIntelItem>.broadcast();
  final _scraperTimers = <Timer>[];
  final _ingestedHashes = <String>{};  // Dedup: track already-processed items

  Stream<ScrapedIntelItem> get intelStream => _eventController.stream;

  /// All registered feed endpoints.
  static final List<IntelFeed> feeds = [
    // ── WIRE SERVICES ────────────────────────────────────────────
    IntelFeed(
      id: 'reuters-mideast',
      name: 'Reuters Middle East',
      endpoint: '/feeds/reuters/middle-east',
      outlet: SourceOutlet.reuters,
      tier: SourceTier.criticalBreaking,
      keywords: ['saudi', 'iran', 'houthi', 'aramco', 'missile', 'drone', 'gulf'],
    ),
    IntelFeed(
      id: 'bbc-mideast',
      name: 'BBC Middle East',
      endpoint: '/feeds/bbc/middle-east',
      outlet: SourceOutlet.bbc,
      tier: SourceTier.criticalBreaking,
      keywords: ['saudi', 'iran', 'attack', 'oil', 'missile'],
    ),

    // ── GOVERNMENT / MILITARY ─────────────────────────────────────
    IntelFeed(
      id: 'centcom-releases',
      name: 'CENTCOM Press Releases',
      endpoint: '/feeds/centcom/press-releases',
      outlet: SourceOutlet.centcom,
      tier: SourceTier.officialStatements,
      keywords: ['saudi', 'gulf', 'iran', 'houthi', 'intercept', 'threat'],
    ),
    IntelFeed(
      id: 'spa-security',
      name: 'Saudi Press Agency — Security',
      endpoint: '/feeds/spa/security',
      outlet: SourceOutlet.spa,
      tier: SourceTier.officialStatements,
      keywords: ['defense', 'intercept', 'attack', 'ministry', 'air defense'],
    ),
    IntelFeed(
      id: 'idf-intel',
      name: 'IDF Intelligence Bulletins',
      endpoint: '/feeds/idf/bulletins',
      outlet: SourceOutlet.idf,
      tier: SourceTier.officialStatements,
      keywords: ['iran', 'missile', 'drone', 'launch', 'irgc'],
    ),

    // ── ADVERSARY MEDIA (RHETORIC MONITORING) ─────────────────────
    IntelFeed(
      id: 'irna-english',
      name: 'IRNA English Service',
      endpoint: '/feeds/irna/english',
      outlet: SourceOutlet.irna,
      tier: SourceTier.adversaryRhetoric,
      keywords: ['saudi', 'resistance', 'retaliation', 'gulf', 'oil', 'zionist'],
    ),

    // ── OSINT / ANALYSIS ──────────────────────────────────────────
    IntelFeed(
      id: 'ft-energy',
      name: 'Financial Times — Energy & Geopolitics',
      endpoint: '/feeds/ft/energy-security',
      outlet: SourceOutlet.ft,
      tier: SourceTier.osintAnalysis,
      keywords: ['saudi', 'brent', 'opec', 'oil', 'energy security'],
    ),
    IntelFeed(
      id: 'janes-gulf',
      name: 'Jane\'s Defence — Gulf Region',
      endpoint: '/feeds/janes/gulf',
      outlet: SourceOutlet.janes,
      tier: SourceTier.osintAnalysis,
      keywords: ['saudi', 'iran', 'missile', 'air defense', 'naval'],
    ),

    // ── MARKET SIGNALS ────────────────────────────────────────────
    IntelFeed(
      id: 'lloyds-war-risk',
      name: 'Lloyd\'s War Risk Premiums',
      endpoint: '/feeds/lloyds/war-risk',
      outlet: SourceOutlet.lloyds,
      tier: SourceTier.marketSignals,
      keywords: ['gulf', 'saudi', 'war risk', 'premium', 'shipping'],
    ),

    // ── CYBER THREAT INTEL ────────────────────────────────────────
    IntelFeed(
      id: 'crowdstrike-gulf',
      name: 'CrowdStrike Gulf Threat Advisories',
      endpoint: '/feeds/crowdstrike/gulf-threats',
      outlet: SourceOutlet.crowdstrike,
      tier: SourceTier.cyberIntel,
      keywords: ['apt33', 'muddywater', 'shamoon', 'saudi', 'aramco', 'scada'],
    ),
  ];

  NewsScraperService({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'SCRAPER_API_URL',
              defaultValue: 'https://api.sentryksa.local/scraper/v1',
            ),
        _client = client ?? http.Client();

  /// Start all scraper feeds.
  void startScraping() {
    _log.i('NewsScraperService: Starting ${feeds.length} intel feeds');

    for (final feed in feeds) {
      final interval = _pollIntervals[feed.tier] ?? 60;
      _scraperTimers.add(
        Timer.periodic(Duration(seconds: interval), (_) => _scrapeFeed(feed)),
      );
      // Initial scrape immediately
      _scrapeFeed(feed);
    }
  }

  /// Scrape a single feed endpoint.
  Future<void> _scrapeFeed(IntelFeed feed) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl${feed.endpoint}'),
            headers: {
              'Accept': 'application/json',
              'X-Feed-Id': feed.id,
              'X-Keywords': feed.keywords.join(','),
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> items = json.decode(response.body)['items'] ?? [];
        for (final item in items) {
          _processItem(item, feed);
        }
      }
    } on TimeoutException {
      _log.w('NewsScraperService: Timeout on ${feed.name}');
    } catch (e) {
      _log.e('NewsScraperService: Error scraping ${feed.name}: $e');
    }
  }

  /// Process a single scraped item: hash, dedup, classify, emit.
  void _processItem(Map<String, dynamic> raw, IntelFeed feed) {
    final url = raw['url'] as String? ?? '';
    final headline = raw['headline'] as String? ?? raw['title'] as String? ?? '';
    final publishedDate =
        raw['published'] as String? ?? raw['date'] as String? ?? '';
    final body = raw['body'] as String? ?? raw['summary'] as String? ?? '';

    if (headline.isEmpty) return;

    // Compute provenance hash
    final hash = _computeHash(url, publishedDate, headline);

    // Dedup: skip if already processed
    if (_ingestedHashes.contains(hash)) return;
    _ingestedHashes.add(hash);

    // Keyword relevance scoring
    final relevanceScore = _scoreRelevance(headline, body, feed.keywords);
    if (relevanceScore < 0.3) return; // Below relevance threshold

    // Classify threat type from content
    final threatType = _classifyThreatType(headline, body);

    // Extract severity from content signals
    final severity = _extractSeverity(headline, body, feed.tier);

    // Extract target corridor
    final corridor = _extractCorridor(headline, body);

    // Build the intel item
    final item = ScrapedIntelItem(
      hash: hash,
      url: url,
      headline: headline,
      publishedDate: publishedDate,
      body: body,
      feedId: feed.id,
      outlet: feed.outlet,
      tier: feed.tier,
      relevanceScore: relevanceScore,
      threatType: threatType,
      severity: severity,
      targetCorridor: corridor,
      ingestedAt: DateTime.now(),
    );

    _eventController.add(item);
  }

  /// SHA-256 provenance hash matching SourceRegistry format.
  String _computeHash(String url, String date, String headline) {
    final input = '$url|$date|$headline';
    return sha256.convert(utf8.encode(input)).toString().substring(0, 16);
  }

  /// Score how relevant a scraped item is to KSA threat monitoring.
  double _scoreRelevance(String headline, String body, List<String> keywords) {
    final text = '${headline.toLowerCase()} ${body.toLowerCase()}';
    int matches = 0;
    for (final kw in keywords) {
      if (text.contains(kw.toLowerCase())) matches++;
    }
    // High-priority terms get bonus
    if (text.contains('attack') || text.contains('strike') || text.contains('missile')) {
      matches += 2;
    }
    if (text.contains('saudi') || text.contains('ksa') || text.contains('aramco')) {
      matches += 2;
    }
    return (matches / (keywords.length + 4)).clamp(0.0, 1.0);
  }

  /// Classify the primary threat type from text analysis.
  ThreatType? _classifyThreatType(String headline, String body) {
    final text = '${headline.toLowerCase()} ${body.toLowerCase()}';
    if (text.contains('ballistic') || text.contains('mrbm') || text.contains('emad')) {
      return ThreatType.ballistic;
    }
    if (text.contains('cruise missile') || text.contains('soumar') || text.contains('hoveyzeh')) {
      return ThreatType.cruise;
    }
    if (text.contains('drone') || text.contains('uav') || text.contains('samad')) {
      return ThreatType.drone;
    }
    if (text.contains('cyber') || text.contains('shamoon') || text.contains('apt33') ||
        text.contains('scada')) {
      return ThreatType.cyber;
    }
    if (text.contains('naval') || text.contains('mine') || text.contains('shipping') ||
        text.contains('maritime')) {
      return ThreatType.naval;
    }
    if (text.contains('hybrid') || text.contains('multi-domain') ||
        text.contains('coordinated')) {
      return ThreatType.hybrid;
    }
    return null;
  }

  /// Extract severity (1-10) from content signals and source tier.
  int _extractSeverity(String headline, String body, SourceTier tier) {
    final text = '${headline.toLowerCase()} ${body.toLowerCase()}';
    int severity = 3; // Base

    // Tier-based baseline
    if (tier == SourceTier.criticalBreaking) severity += 2;
    if (tier == SourceTier.officialStatements) severity += 1;

    // Content signals
    if (text.contains('attack') || text.contains('strike')) severity += 2;
    if (text.contains('damage') || text.contains('fire') || text.contains('explosion')) {
      severity += 1;
    }
    if (text.contains('intercept') || text.contains('defense')) severity -= 1;
    if (text.contains('imminent') || text.contains('inbound') || text.contains('launched')) {
      severity += 2;
    }
    if (text.contains('war') || text.contains('hostilities')) severity += 1;
    if (text.contains('rhetoric') || text.contains('warns') || text.contains('threatens')) {
      severity -= 1; // Rhetoric is lower severity than kinetic
    }

    return severity.clamp(1, 10);
  }

  /// Extract target corridor / province from text.
  String? _extractCorridor(String headline, String body) {
    final text = '${headline.toLowerCase()} ${body.toLowerCase()}';

    // Province matching
    const corridors = {
      'eastern province': 'Eastern Province Oil Corridor',
      'abqaiq': 'Eastern Province Oil Corridor',
      'ras tanura': 'Eastern Province Oil Corridor',
      'ghawar': 'Eastern Province Oil Corridor',
      'khurais': 'Eastern Province Oil Corridor',
      'jubail': 'Eastern Province Industrial Corridor',
      'dhahran': 'Eastern Province Industrial Corridor',
      'riyadh': 'Riyadh Capital Region',
      'jeddah': 'Western Province Red Sea Corridor',
      'yanbu': 'Western Province Red Sea Corridor',
      'makkah': 'Western Province Red Sea Corridor',
      'neom': 'Northern Tabuk Province',
      'shaybah': 'Empty Quarter Southern Corridor',
      'najran': 'Southern Border Zone',
      'jazan': 'Southern Border Zone',
    };

    for (final entry in corridors.entries) {
      if (text.contains(entry.key)) return entry.value;
    }

    return null;
  }

  /// Fetch all recent items across all feeds (one-shot).
  Future<List<ScrapedIntelItem>> fetchAllRecent() async {
    final items = <ScrapedIntelItem>[];
    for (final feed in feeds) {
      try {
        final response = await _client
            .get(
              Uri.parse('$_baseUrl${feed.endpoint}?recent=true'),
              headers: {
                'Accept': 'application/json',
                'X-Feed-Id': feed.id,
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> rawItems =
              json.decode(response.body)['items'] ?? [];
          for (final raw in rawItems) {
            final url = raw['url'] as String? ?? '';
            final headline =
                raw['headline'] as String? ?? raw['title'] as String? ?? '';
            final publishedDate =
                raw['published'] as String? ?? raw['date'] as String? ?? '';
            final body =
                raw['body'] as String? ?? raw['summary'] as String? ?? '';

            if (headline.isEmpty) continue;

            final hash = _computeHash(url, publishedDate, headline);
            final relevance = _scoreRelevance(headline, body, feed.keywords);
            if (relevance < 0.3) continue;

            items.add(ScrapedIntelItem(
              hash: hash,
              url: url,
              headline: headline,
              publishedDate: publishedDate,
              body: body,
              feedId: feed.id,
              outlet: feed.outlet,
              tier: feed.tier,
              relevanceScore: relevance,
              threatType: _classifyThreatType(headline, body),
              severity: _extractSeverity(headline, body, feed.tier),
              targetCorridor: _extractCorridor(headline, body),
              ingestedAt: DateTime.now(),
            ));
          }
        }
      } catch (e) {
        _log.w('NewsScraperService: Failed to fetch ${feed.name}: $e');
      }
    }

    // Sort by date descending
    items.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
    return items;
  }

  /// Cross-reference a scraped item against the SourceRegistry.
  /// Returns the matching SourceReference if it exists (ground truth verification).
  SourceReference? crossReference(ScrapedIntelItem item) {
    return SourceRegistry.byHash(item.hash);
  }

  void dispose() {
    for (final timer in _scraperTimers) {
      timer.cancel();
    }
    _eventController.close();
    _client.close();
  }
}

/// A single scraped and processed intelligence item.
class ScrapedIntelItem {
  final String hash;
  final String url;
  final String headline;
  final String publishedDate;
  final String body;
  final String feedId;
  final SourceOutlet outlet;
  final SourceTier tier;
  final double relevanceScore;
  final ThreatType? threatType;
  final int severity;
  final String? targetCorridor;
  final DateTime ingestedAt;

  const ScrapedIntelItem({
    required this.hash,
    required this.url,
    required this.headline,
    required this.publishedDate,
    required this.body,
    required this.feedId,
    required this.outlet,
    required this.tier,
    required this.relevanceScore,
    this.threatType,
    required this.severity,
    this.targetCorridor,
    required this.ingestedAt,
  });

  /// Whether this item has a matching ground-truth reference in SourceRegistry.
  bool get isVerified => SourceRegistry.byHash(hash) != null;

  /// Convert to a ThreatEvent for ingestion into the provider pipeline.
  ThreatEvent toThreatEvent() {
    return ThreatEvent(
      id: hash,
      source: _outletToSource(),
      headline: headline,
      timestamp: DateTime.tryParse(publishedDate) ?? ingestedAt,
      type: threatType ?? ThreatType.hybrid,
      severityScore: severity,
      targetCorridor: targetCorridor,
      confidence: relevanceScore * (outlet.reliability),
    );
  }

  String _outletToSource() {
    switch (outlet) {
      case SourceOutlet.centcom:
        return 'CENTCOM';
      case SourceOutlet.idf:
        return 'IDF';
      case SourceOutlet.irna:
        return 'IRNA';
      default:
        return 'OSINT';
    }
  }
}

/// A configured intelligence feed endpoint.
class IntelFeed {
  final String id;
  final String name;
  final String endpoint;
  final SourceOutlet outlet;
  final SourceTier tier;
  final List<String> keywords;

  const IntelFeed({
    required this.id,
    required this.name,
    required this.endpoint,
    required this.outlet,
    required this.tier,
    required this.keywords,
  });
}

/// Feed priority tiers determine polling frequency.
enum SourceTier {
  criticalBreaking,     // 15s — wire services during active events
  officialStatements,   // 30s — government/military
  adversaryRhetoric,    // 45s — Iranian/Houthi media (precursor signals)
  osintAnalysis,        // 120s — analysis and OSINT aggregators
  marketSignals,        // 60s — Brent, shipping, insurance
  cyberIntel;           // 90s — cyber threat feeds

  String get label {
    switch (this) {
      case SourceTier.criticalBreaking: return 'BREAKING';
      case SourceTier.officialStatements: return 'OFFICIAL';
      case SourceTier.adversaryRhetoric: return 'RHETORIC';
      case SourceTier.osintAnalysis: return 'OSINT';
      case SourceTier.marketSignals: return 'MARKET';
      case SourceTier.cyberIntel: return 'CYBER';
    }
  }
}
