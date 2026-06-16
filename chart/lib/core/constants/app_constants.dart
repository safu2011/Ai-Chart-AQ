import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const appName = 'AI Chart Analyzer';
  static const appVersion = '1.0.0';

  // ── OpenAI ─────────────────────────────────────────────────────────────────
  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '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',
  );
  static const openAiBaseUrl = 'https://api.openai.com/v1';
  static const openAiModel = 'gpt-4o-mini';

  // ── Binance ────────────────────────────────────────────────────────────────
  static const binanceBaseUrl = 'https://api.binance.com/api/v3';
  static const binanceWsUrl = 'wss://stream.binance.com:9443/ws';
  static const binanceKlinesEndpoint = '/klines';

  // ── RevenueCat ─────────────────────────────────────────────────────────────
  static const revenueCatApiKeyAndroid = 'goog_IKxQVdvoKfNxhqifVJQqKmkpSsz';
  static const revenueCatApiKeyIos = 'YOUR_REVENUECAT_IOS_KEY';

  // Entitlement identifier — must match RevenueCat dashboard
  static const rcProEntitlement = 'pro';

  // Offering identifier — matches the "pro" offering in RevenueCat dashboard
  static const rcOfferingId = 'pro';

  // ── Subscription Product IDs (match Google Play / App Store exactly) ───────
  // These are the base plan IDs as shown in RevenueCat: "productId:basePlanId"
  static const rcWeeklySubId  = 'weekly:weekly';   // $5.00/week
  static const rcMonthlySubId = 'monthly:monthly'; // $17.00/month
  static const rcYearlySubId  = 'yearly:yearly';   // $190.00/year


  /// Number of API hits (credits) consumed per analysis call.
  static const double costPerApiHitUsd   = 0.006; // your OpenAI cost
  static const double pricePerCreditUsd  = 0.02;  // what user pays per credit
  static const int    creditsPerAnalysis = 1;      // 1 credit = 1 API hit

  // Monthly credit grants per subscription tier
  static const int weeklyCreditsPerCycle  = 250;  // $5  / 0.02
  static const int monthlyCreditsPerCycle = 850;  // $17 / 0.02
  static const int yearlyCreditsPerCycle  = 9500; // $190 / 0.02

  // Free tier — ONE-TIME lifetime free analyses (not per day)
  static const freeAnalysesTotal = 3;
  // Keep alias for any legacy references
  static const freeAnalysesPerDay = freeAnalysesTotal;

  static void showErrorToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  // ── AdMob ──────────────────────────────────────────────────────────────────
  static const admobBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const admobBannerIos     = 'ca-app-pub-3940256099942544/2934735716';
  static const admobInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const admobInterstitialIos     = 'ca-app-pub-3940256099942544/4411468910';

  // ── Crypto Pairs ───────────────────────────────────────────────────────────
  static const cryptoPairs = [
    'BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT', 'XRPUSDT',
    'DOGEUSDT', 'ADAUSDT', 'MATICUSDT', 'DOTUSDT', 'LTCUSDT',
    'AVAXUSDT', 'LINKUSDT', 'UNIUSDT', 'ATOMUSDT', 'NEARUSDT',
  ];

  static const timeframes = ['1m', '5m', '15m', '1h', '4h', '1d'];

  static const binanceIntervalMap = {
    '1m': '1m', '5m': '5m', '15m': '15m',
    '1h': '1h', '4h': '4h', '1d': '1d',
  };

  // ── Strings ────────────────────────────────────────────────────────────────
  static const disclaimer =
      'This analysis is AI-generated and is for educational purposes only. '
      'This is NOT financial or investment advice. Always do your own research. '
      'Trade at your own risk. Markets are highly volatile.';

  static const startupDisclaimer =
      'AI-generated analysis is for educational purposes only and not financial advice.';

  static const analysisDisclaimer =
      'By continuing, you acknowledge this app does not provide financial or investment advice.';
}

class Insets {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

class Radii {
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 24;
  static const double full = 100;
}

extension ContextExt on BuildContext {
  double get width  => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;
  ThemeData get theme   => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text    => Theme.of(this).textTheme;
  bool get isDark       => Theme.of(this).brightness == Brightness.dark;
}
