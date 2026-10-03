import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const appName = 'AI Chart Analyzer';
  static const appVersion = '1.0.0';

  // ── OpenAI ─────────────────────────────────────────────────────────────────
  // chabbi is the compile-time / offline fallback for the OpenAI API key.
  // At runtime it is overridden by the value fetched from Firebase Remote Config
  // (key: 'chabbi') and cached in SharedPreferences. See RemoteConfigService.
  static const String chabbi = "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";
  static const openAiBaseUrl = 'https://api.openai.com/v1';
  static const openAiModel = 'gpt-4o-mini';
  // gpt-4o-mini pricing in USD per 1M tokens (update if OpenAI changes pricing
  // or if you switch openAiModel).
  static const double openAiInputPricePer1M       = 0.15;
  static const double openAiCachedInputPricePer1M = 0.075;
  static const double openAiOutputPricePer1M      = 0.60;

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
  static const rcWeeklySubId  = 'weekly:weekly';
  static const rcMonthlySubId = 'monthly:monthly';
  static const rcYearlySubId  = 'yearly:yearly';

  /// Number of API hits (credits) consumed per analysis call.
  static const double costPerApiHitUsd  = 0.006;
  static const double pricePerCreditUsd = 0.02;
  static const int    creditsPerAnalysis = 1;

  // ── Credits per subscription cycle ─────────────────────────────────────────
  // These are compile-time / offline FALLBACK defaults.
  // At runtime they are overridden by Firebase Remote Config keys:
  //   'weekly_credits_per_cycle', 'monthly_credits_per_cycle', 'yearly_credits_per_cycle'
  // Cached in SharedPreferences by AdsProvider. Read via RemoteConfigService.
  static const int weeklyCreditsPerCycle  = 250;   // $5  / 0.02
  static const int monthlyCreditsPerCycle = 850;   // $17 / 0.02
  static const int yearlyCreditsPerCycle  = 10200; // offline fallback; Remote Config (yearly_credits_per_cycle) overrides

  // ── One-time credit packs (lifetime, never expire) ─────────────────────────
  // Price per credit for packs = pricePerCreditUsd + iapPriceMarkupUsd
  // = 0.02 + 0.03 = $0.05  ->  $1 = 20, $3 = 60, $7 = 140, $10 = 200 credits.
  // Create each productId below in Google Play Console as a CONSUMABLE
  // in-app product (Monetize -> Products -> In-app products) priced at the
  // matching USD amount, and add it in RevenueCat as a non-subscription product.
  static const double iapPriceMarkupUsd    = 0.03;
  static const double iapPricePerCreditUsd = pricePerCreditUsd + iapPriceMarkupUsd;
  static const List<IapPack> iapPacks = [
    IapPack('credits_1usd', 1),
    IapPack('credits_3usd', 3),
    IapPack('credits_7usd', 7),
    IapPack('credits_10usd', 10),
  ];

  // Free tier — ONE-TIME lifetime free analyses
  static const freeAnalysesTotal = 3;
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

/// A one-time, lifetime credit pack sold as an in-app purchase.
class IapPack {
  final String productId;
  final double usd;
  const IapPack(this.productId, this.usd);

  /// Credits granted = USD price / (pricePerCreditUsd + markup).
  int get credits => (usd / AppConstants.iapPricePerCreditUsd).round();
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
  ThemeData get theme    => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text     => Theme.of(this).textTheme;
  bool get isDark        => Theme.of(this).brightness == Brightness.dark;
}
