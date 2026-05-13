import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chart_analysis.dart';
import '../services/binance_service.dart';
import '../services/history_repository.dart';
import '../services/openai_service.dart';

// ─── Theme Provider ──────────────────────────────────────────────────────────
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('dark_mode') ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', state);
  }
}

// ─── Analysis State ──────────────────────────────────────────────────────────
sealed class AnalysisState {
  const AnalysisState();
}

class AnalysisIdle extends AnalysisState {
  const AnalysisIdle();
}

class AnalysisLoading extends AnalysisState {
  const AnalysisLoading();
}

class AnalysisSuccess extends AnalysisState {
  final ChartAnalysis result;
  const AnalysisSuccess(this.result);
}

class AnalysisError extends AnalysisState {
  final String message;
  const AnalysisError(this.message);
}

final analysisProvider =
    StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  return AnalysisNotifier(ref);
});

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final Ref _ref;
  AnalysisNotifier(this._ref) : super(const AnalysisIdle());

  Future<void> analyze(File imageFile) async {
    state = const AnalysisLoading();
    try {
      final result = await OpenAiService.instance.analyzeChart(imageFile);
      result.chartImagePath = imageFile.path;
      // Save to history
      await HistoryRepository.instance.add(result);
      _ref.invalidate(historyProvider);
      state = AnalysisSuccess(result);
    } catch (e) {
      state = AnalysisError(OpenAiService.friendlyError(e));
    }
  }

  void reset() => state = const AnalysisIdle();
}

// ─── History Provider ────────────────────────────────────────────────────────
final historyProvider =
    FutureProvider<List<ChartAnalysis>>((ref) async {
  return HistoryRepository.instance.loadAll();
});

// ─── Live Chart Providers ────────────────────────────────────────────────────
final selectedPairProvider = StateProvider<String>((ref) => 'BTCUSDT');
final selectedIntervalProvider = StateProvider<String>((ref) => '1h');

final favoritePairsProvider =
    StateNotifierProvider<FavoritePairsNotifier, List<String>>((ref) {
  return FavoritePairsNotifier();
});

class FavoritePairsNotifier extends StateNotifier<List<String>> {
  FavoritePairsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList('favorite_pairs') ?? [];
  }

  Future<void> toggle(String pair) async {
    if (state.contains(pair)) {
      state = state.where((p) => p != pair).toList();
    } else {
      state = [...state, pair];
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_pairs', state);
  }

  bool isFavorite(String pair) => state.contains(pair);
}

final recentPairsProvider =
    StateNotifierProvider<RecentPairsNotifier, List<String>>((ref) {
  return RecentPairsNotifier();
});

class RecentPairsNotifier extends StateNotifier<List<String>> {
  RecentPairsNotifier() : super([]);

  void add(String pair) {
    final updated = [pair, ...state.where((p) => p != pair)].take(10).toList();
    state = updated;
  }
}

/// Fetches candles for current pair+interval
final candleDataProvider = FutureProvider.autoDispose<List<CandleData>>((ref) async {
  final pair = ref.watch(selectedPairProvider);
  final interval = ref.watch(selectedIntervalProvider);
  return BinanceService.instance.getKlines(
    symbol: pair,
    interval: interval,
    limit: 200,
  );
});

/// 24h ticker for the current pair
final tickerProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final pair = ref.watch(selectedPairProvider);
  return BinanceService.instance.getTicker(pair);
});

// ─── API Key Provider ─────────────────────────────────────────────────────────
final apiKeyProvider =
    StateNotifierProvider<ApiKeyNotifier, String>((ref) {
  return ApiKeyNotifier();
});

class ApiKeyNotifier extends StateNotifier<String> {
  ApiKeyNotifier() : super('') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('openai_api_key') ?? '';
  }

  Future<void> save(String key) async {
    state = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_api_key', key);
  }
}
