import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/threat_event.dart';

/// Service for fetching threat intelligence from monitored sources.
/// Polls CENTCOM, IDF, and IRNA feeds for trigger events.
class ThreatFeedService {
  final String baseUrl;
  final http.Client _client;
  final Logger _log = Logger();

  // Polling intervals per source
  static const Duration centcomInterval = Duration(seconds: 30);
  static const Duration idfInterval = Duration(seconds: 45);
  static const Duration irnaInterval = Duration(seconds: 60);

  final _eventController = StreamController<ThreatEvent>.broadcast();
  Stream<ThreatEvent> get eventStream => _eventController.stream;

  Timer? _centcomTimer;
  Timer? _idfTimer;
  Timer? _irnaTimer;

  ThreatFeedService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Start polling all intelligence sources.
  void startMonitoring() {
    _log.i('Starting threat feed monitoring...');
    _pollSource('CENTCOM', centcomInterval);
    _pollSource('IDF', idfInterval);
    _pollSource('IRNA', irnaInterval);
  }

  void _pollSource(String source, Duration interval) {
    // Initial fetch
    _fetchEvents(source);

    // Recurring poll
    final timer = Timer.periodic(interval, (_) => _fetchEvents(source));
    switch (source) {
      case 'CENTCOM':
        _centcomTimer = timer;
        break;
      case 'IDF':
        _idfTimer = timer;
        break;
      case 'IRNA':
        _irnaTimer = timer;
        break;
    }
  }

  Future<void> _fetchEvents(String source) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/v1/threats/$source'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        for (final item in data) {
          final event =
              ThreatEvent.fromJson(item as Map<String, dynamic>);
          _eventController.add(event);
        }
      } else {
        _log.w('$source feed returned ${response.statusCode}');
      }
    } on TimeoutException {
      _log.w('$source feed timed out');
    } catch (e) {
      _log.e('Error fetching $source feed: $e');
    }
  }

  /// Fetch all recent events as a one-shot list.
  Future<List<ThreatEvent>> fetchAllRecent() async {
    final events = <ThreatEvent>[];
    for (final source in ['CENTCOM', 'IDF', 'IRNA']) {
      try {
        final response = await _client
            .get(Uri.parse('$baseUrl/api/v1/threats/$source'))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> data =
              jsonDecode(response.body) as List<dynamic>;
          events.addAll(data.map(
              (item) => ThreatEvent.fromJson(item as Map<String, dynamic>)));
        }
      } catch (e) {
        _log.e('Error fetching $source: $e');
      }
    }
    return events;
  }

  /// Stop all polling timers.
  void stopMonitoring() {
    _centcomTimer?.cancel();
    _idfTimer?.cancel();
    _irnaTimer?.cancel();
    _log.i('Threat feed monitoring stopped.');
  }

  void dispose() {
    stopMonitoring();
    _eventController.close();
    _client.close();
  }
}
