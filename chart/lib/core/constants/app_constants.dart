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
  // Replace with your actual RevenueCat API keys from dashboard.revenuecat.com
  static const revenueCatApiKeyAndroid = 'YOUR_REVENUECAT_ANDROID_KEY';
  static const revenueCatApiKeyIos = 'YOUR_REVENUECAT_IOS_KEY';

  // Entitlement identifier — set in RevenueCat dashboard
  static const rcProEntitlement = 'pro';

  // Product identifiers — must match Google Play / App Store exactly
  static const rcMonthlySubId   = 'ai_chart_pro_monthly';   // $4.99/month
  static const rcPack10Id       = 'ai_chart_credits_10';    // $0.99
  static const rcPack50Id       = 'ai_chart_credits_50';    // $3.99
  static const rcPack200Id      = 'ai_chart_credits_200';   // $9.99

  // Credit amounts per product
  static const creditsInPack10  = 10;
  static const creditsInPack50  = 50;
  static const creditsInPack200 = 200;

  // Free tier
  static const freeAnalysesPerDay = 3;

  // ── AdMob ──────────────────────────────────────────────────────────────────
  // Replace with real Ad Unit IDs from https://admob.google.com
  // These are test IDs — use test IDs during development ONLY.
  static const admobBannerAndroid = 'ca-app-pub-3940256099942544/6300978111'; // test
  static const admobBannerIos     = 'ca-app-pub-3940256099942544/2934735716'; // test
  static const admobInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712'; // test
  static const admobInterstitialIos     = 'ca-app-pub-3940256099942544/4411468910'; // test

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
