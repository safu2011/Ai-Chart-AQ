import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/providers.dart';
import 'features/splash/splash_screen.dart';
import 'providers/ads_provider.dart';
import 'services/subscription_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // ── Firebase ─────────────────────────────────────────────────────────────
  await Firebase.initializeApp();

  // ── AdMob SDK ─────────────────────────────────────────────────────────────
  // Consent + MobileAds.init happen AFTER the widget tree is ready so that
  // AdsProvider.initialize() has access to navigatorKey.currentContext.
  // We only init the SDK here; AdsProvider.initialize() handles consent +
  // Remote Config fetch when the splash screen mounts.
  await MobileAds.instance.initialize();

  // ── Service Initialisation ───────────────────────────────────────────────
  await Future.wait([
    SubscriptionService.instance.init(),
    // AlertsService.instance.init(),
  ]);

  // ── Providers ─────────────────────────────────────────────────────────────
  final themeProvider        = ThemeProvider();
  final historyProvider      = HistoryProvider();
  final analysisProvider     = AnalysisProvider();
  final liveChartProvider    = LiveChartProvider();
  final subscriptionProvider = SubscriptionProvider();
  final alertsProvider       = AlertsProvider();
  final adsProvider          = AdsProvider();

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
        ChangeNotifierProvider.value(value: adsProvider),
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

    // Initialize AdsProvider: gathers consent, fetches Remote Config,
    // and loads the first interstitial / app-open ad.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdsProvider.getProvider()
          .initialize(navigatorKey.currentContext!, showTestAds: false)
          .then((_) {
        print("MyLog Got Response from AdsProvider");
        if (AdsProvider.loadAdsOnStart) {
          final p = AdsProvider.getProvider();
          if (p.splash_screen_continue_ad_type == 2) {
            p.appOpenAdManager?.loadApOpenAd(null);
          } else if (p.splash_screen_continue_ad_type == 1) {
            p.loadInterstitialAd(null);
          }
        }
      });
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
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    return AppLifecycleReactor(
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        navigatorKey: navigatorKey,
        home: const SplashScreen(),
      ),
    );
  }
}
