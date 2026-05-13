import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const appName = 'AI Chart Analyzer';
  static const appVersion = '1.0.0';

  // Binance
  static const binanceBaseUrl = 'https://api.binance.com/api/v3';
  static const binanceWsUrl = 'wss://stream.binance.com:9443/ws';
  static const binanceKlinesEndpoint = '/klines';

  // OpenAI
  static const openAiBaseUrl = 'https://api.openai.com/v1';
  static const openAiModel = 'gpt-4o-mini';

  static const cryptoPairs = [
    'BTCUSDT',
    'ETHUSDT',
    'BNBUSDT',
    'SOLUSDT',
    'XRPUSDT',
    'DOGEUSDT',
  ];

  static const timeframes = ['1m', '5m', '15m', '1h', '4h', '1d'];

  static const binanceIntervalMap = {
    '1m': '1m',
    '5m': '5m',
    '15m': '15m',
    '1h': '1h',
    '4h': '4h',
    '1d': '1d',
  };

  // Disclaimer text
  static const disclaimer =
      'This analysis is AI-generated and is for educational purposes only. '
      'This is NOT financial or investment advice. Always do your own research. '
      'Trade at your own risk. Markets are highly volatile.';

  static const startupDisclaimer =
      'AI-generated analysis is for educational purposes only and not financial advice.';

  static const analysisDisclaimer =
      'By continuing, you acknowledge this app does not provide financial or investment advice.';
}

/// Padding / spacing helpers
class Insets {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Radius helpers
class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 100;
}

extension ContextExt on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
