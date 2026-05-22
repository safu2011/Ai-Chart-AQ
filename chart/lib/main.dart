import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/providers.dart';
import 'features/splash/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/alerts_service.dart';
import 'services/subscription_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // ── Service Initialisation ───────────────────────────────────────────────
  await Future.wait([
    SubscriptionService.instance.init(),
    AdService.instance.init(),
    AlertsService.instance.init(),
  ]);

  // ── Providers ─────────────────────────────────────────────────────────────
  final themeProvider        = ThemeProvider();
  final historyProvider      = HistoryProvider();
  final analysisProvider     = AnalysisProvider();
  final liveChartProvider    = LiveChartProvider();
  final subscriptionProvider = SubscriptionProvider();
  final alertsProvider       = AlertsProvider();

  // Wire callbacks
  analysisProvider.onAnalysisComplete = () => historyProvider.load();

  // Prefetch subscription status & alerts
  await Future.wait([
    subscriptionProvider.refresh(),
    alertsProvider.load(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: historyProvider),
        ChangeNotifierProvider.value(value: analysisProvider),
        ChangeNotifierProvider.value(value: liveChartProvider),
        ChangeNotifierProvider.value(value: subscriptionProvider),
        ChangeNotifierProvider.value(value: alertsProvider),
      ],
      child: const AiChartAnalyzerApp(),
    ),
  );
}

class AiChartAnalyzerApp extends StatefulWidget {
  const AiChartAnalyzerApp({super.key});

  @override
  State<AiChartAnalyzerApp> createState() => _AiChartAnalyzerAppState();
}

class _AiChartAnalyzerAppState extends State<AiChartAnalyzerApp> {
  bool _disclaimerShown = false;
  Timer? _alertTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disclaimerShown) {
        _disclaimerShown = true;
        _showStartupDisclaimer();
      }
    });
    // Poll alerts every 60 seconds while app is in foreground
    _alertTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      context.read<AlertsProvider>().checkAlerts();
    });
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  void _showStartupDisclaimer() {
    final isDark      = context.read<ThemeProvider>().isDark;
    final cardColor   = isDark ? AppColorsDark.card : AppColorsLight.card;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
    final gold        = isDark ? AppColorsDark.gold : AppColorsLight.gold;
    final bgColor     = isDark ? AppColorsDark.bg : AppColorsLight.bg;
    final borderColor = isDark ? AppColorsDark.border : AppColorsLight.border;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  gold,
                  isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft,
                ]),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(Icons.candlestick_chart_rounded, color: bgColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Important Notice',
                  style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(Insets.sm + 4),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.07),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: borderColor),
              ),
              child: Text(AppConstants.startupDisclaimer,
                  style: TextStyle(fontSize: 13, color: textPrimary, height: 1.5, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 12),
            Text(
              'This app uses OpenAI Vision to analyse chart images. '
              'All analyses are for educational purposes only and should '
              'never be treated as financial advice.',
              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.5),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.full)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('I Understand',
                    style: TextStyle(color: bgColor, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? AppColorsDark.bg : AppColorsLight.bg,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
