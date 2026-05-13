import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/chart_analysis.dart';

/// Fetches candlestick data from the Binance REST API
class BinanceService {
  static final BinanceService instance = BinanceService._();
  BinanceService._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.binance.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  /// Fetch OHLCV candles for [symbol] at [interval]
  /// [limit] max 1000
  Future<List<CandleData>> getKlines({
    required String symbol,
    required String interval,
    int limit = 200,
  }) async {
    final response = await _dio.get(
      '/api/v3/klines',
      queryParameters: {
        'symbol': symbol.toUpperCase(),
        'interval': interval,
        'limit': limit,
      },
    );

    if (response.statusCode == 200) {
      final raw = response.data as List<dynamic>;
      return raw
          .map((e) => CandleData.fromBinance(e as List<dynamic>))
          .toList();
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Binance error: ${response.statusCode}',
      );
    }
  }

  /// Fetch 24h price ticker info
  Future<Map<String, dynamic>> getTicker(String symbol) async {
    final response = await _dio.get(
      '/api/v3/ticker/24hr',
      queryParameters: {'symbol': symbol.toUpperCase()},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Search all USDT pairs (for the search box)
  Future<List<String>> getAllUsdtPairs() async {
    final response = await _dio.get('/api/v3/exchangeInfo');
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final symbols = (data['symbols'] as List<dynamic>)
          .where((s) =>
              (s['quoteAsset'] as String) == 'USDT' &&
              (s['status'] as String) == 'TRADING')
          .map((s) => s['symbol'] as String)
          .toList()
        ..sort();
      return symbols;
    }
    return [];
  }
}
