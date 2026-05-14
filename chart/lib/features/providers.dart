import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chart_analysis.dart';
import '../services/binance_service.dart';
import '../services/history_repository.dart';
import '../services/openai_service.dart';

// ─── Theme Provider ───────────────────────────────────────────────────────────

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<bool> {
  static const _kDarkModeKey = 'dark_mode';

  ThemeModeNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to dark mode when no preference is saved.
    final saved = prefs.getBool(_kDarkModeKey);
    if (saved != null && saved != state) {
      state = saved;
    }
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, state);
  }

  Future<void> setDark(bool isDark) async {
    if (state == isDark) return;
    state = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, state);
  }
}

// ─── Analysis State ───────────────────────────────────────────────────────────

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
      await HistoryRepository.instance.add(result);
      _ref.invalidate(historyProvider);
      state = AnalysisSuccess(result);
    } catch (e) {
      state = AnalysisError(OpenAiService.friendlyError(e));
    }
  }

  void reset() => state = const AnalysisIdle();
}

// ─── History Provider ─────────────────────────────────────────────────────────

final historyProvider = FutureProvider<List<ChartAnalysis>>((ref) async {
  return HistoryRepository.instance.loadAll();
});

// ─── Live Chart Providers ─────────────────────────────────────────────────────

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
    final updated =
        [pair, ...state.where((p) => p != pair)].take(10).toList();
    state = updated;
  }
}

/// Fetches candles for current pair + interval.
final candleDataProvider =
    FutureProvider.autoDispose<List<CandleData>>((ref) async {
  final pair = ref.watch(selectedPairProvider);
  final interval = ref.watch(selectedIntervalProvider);
  return BinanceService.instance.getKlines(
    symbol: pair,
    interval: interval,
    limit: 200,
  );
});

/// 24 h ticker for the current pair.
final tickerProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final pair = ref.watch(selectedPairProvider);
  return BinanceService.instance.getTicker(pair);
});
