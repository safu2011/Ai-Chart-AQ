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
    // AlertsService.instance.init(),
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
  Timer? _alertTimer;

  @override
  void initState() {
    super.initState();
    // Poll alerts every 60 seconds while app is in foreground
    _alertTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) context.read<AlertsProvider>().checkAlerts();
    });
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
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