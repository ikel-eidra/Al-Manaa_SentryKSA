import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/threat_provider.dart';
import 'providers/map_provider.dart';
import 'providers/locale_provider.dart';
import 'services/threat_feed_service.dart';
import 'services/websocket_service.dart';
import 'screens/war_room_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Mobile-only: orientation lock and status bar styling
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUIOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  // Initialize services
  final feedService = ThreatFeedService(
    baseUrl: const String.fromEnvironment(
      'SENTRY_API_URL',
      defaultValue: 'https://api.sentryksa.local',
    ),
  );

  final wsService = WebSocketService(
    wsUrl: const String.fromEnvironment(
      'SENTRY_WS_URL',
      defaultValue: 'wss://ws.sentryksa.local/v1/threats',
    ),
  );

  runApp(SentryKSAApp(
    feedService: feedService,
    wsService: wsService,
  ));
}

class SentryKSAApp extends StatelessWidget {
  final ThreatFeedService feedService;
  final WebSocketService wsService;

  const SentryKSAApp({
    super.key,
    required this.feedService,
    required this.wsService,
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
            title: 'SentryKSA',
            debugShowCheckedModeBanner: false,
            locale: Locale(localeProvider.locale),
            theme: ThemeData(
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
            ),
            home: const WarRoomScreen(),
          );
        },
      ),
    );
  }
}
