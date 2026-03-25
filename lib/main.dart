import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/threat_provider.dart';
import 'providers/map_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/civilian_provider.dart';
import 'services/threat_feed_service.dart';
import 'services/websocket_service.dart';
import 'services/civilian_report_service.dart';
import 'screens/war_room_screen.dart';
import 'screens/civilian/warning_screen.dart';
import 'screens/civilian/report_screen.dart';
import 'screens/civilian/civilian_map_screen.dart';

/// SentryKSA dual-platform architecture:
///
///   WEB  → Classified War Room dashboard (gated, eyes-only)
///          Full threat intelligence, probabilities, source provenance
///          Consumes classified feeds + civilian crowd reports
///
///   MOBILE → Civilian early warning + reporting app
///            Complements government SMS warning system
///            Citizens submit photos, damage reports, impact locations
///            Distributed sensor mesh that validates trajectory projections
///
/// The app automatically selects the correct platform at launch:
///   kIsWeb → War Room (classified dashboard)
///   !kIsWeb → Civilian App (warning + reporting)
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiUrl = const String.fromEnvironment(
    'SENTRY_API_URL',
    defaultValue: 'https://api.sentryksa.local',
  );

  if (kIsWeb) {
    _launchWarRoom(apiUrl);
  } else {
    _launchCivilianApp(apiUrl);
  }
}

/// Launch the classified War Room dashboard (web only).
void _launchWarRoom(String apiUrl) {
  final feedService = ThreatFeedService(baseUrl: apiUrl);
  final wsService = WebSocketService(
    wsUrl: const String.fromEnvironment(
      'SENTRY_WS_URL',
      defaultValue: 'wss://ws.sentryksa.local/v1/threats',
    ),
  );
  final civilianReportService = CivilianReportService(baseUrl: apiUrl);

  // War room also ingests civilian reports as an intelligence overlay
  civilianReportService.startIngesting();

  runApp(SentryKSAWarRoom(
    feedService: feedService,
    wsService: wsService,
    civilianReportService: civilianReportService,
  ));
}

/// Launch the civilian warning & reporting app (mobile).
void _launchCivilianApp(String apiUrl) {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUIOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final civilianReportService = CivilianReportService(baseUrl: apiUrl);

  runApp(SentryKSACivilianApp(
    reportService: civilianReportService,
  ));
}

// ═══════════════════════════════════════════════════════════════════
//  WAR ROOM APP (WEB — CLASSIFIED)
// ═══════════════════════════════════════════════════════════════════

class SentryKSAWarRoom extends StatelessWidget {
  final ThreatFeedService feedService;
  final WebSocketService wsService;
  final CivilianReportService civilianReportService;

  const SentryKSAWarRoom({
    super.key,
    required this.feedService,
    required this.wsService,
    required this.civilianReportService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThreatProvider(
            feedService: feedService,
            wsService: wsService,
          ),
        ),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'SentryKSA — War Room',
            debugShowCheckedModeBanner: false,
            locale: Locale(localeProvider.locale),
            theme: _warRoomTheme,
            home: const WarRoomScreen(),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CIVILIAN APP (MOBILE — PUBLIC)
// ═══════════════════════════════════════════════════════════════════

class SentryKSACivilianApp extends StatelessWidget {
  final CivilianReportService reportService;

  const SentryKSACivilianApp({
    super.key,
    required this.reportService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = CivilianProvider(reportService: reportService);
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'SentryKSA Alert',
            debugShowCheckedModeBanner: false,
            locale: Locale(localeProvider.locale),
            theme: _civilianTheme,
            initialRoute: '/',
            routes: {
              '/': (_) => const CivilianWarningScreen(),
              '/report': (_) => const ReportScreen(),
              '/civilian-map': (_) => const CivilianMapScreen(),
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  THEMES
// ═══════════════════════════════════════════════════════════════════

final _warRoomTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFF3D00),
    secondary: Color(0xFFFFAB00),
    surface: Color(0xFF1A1A2E),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Colors.white70,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Colors.white54,
      letterSpacing: 1.2,
    ),
  ),
);

final _civilianTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0a0e1a),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFF3D00),
    secondary: Color(0xFF00BCD4),
    surface: Color(0xFF1a1a2e),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 2,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Colors.white70,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Colors.white54,
      letterSpacing: 1.5,
    ),
  ),
);
