import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chart_analysis.dart';
import '../services/binance_service.dart';
import '../services/history_repository.dart';
import '../services/openai_service.dart';

// ─── Theme Provider ───────────────────────────────────────────────────────────

class ThemeProvider extends ChangeNotifier {
  static const _kDarkModeKey = 'dark_mode';

  bool _isDark = true;
  bool get isDark => _isDark;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_kDarkModeKey);
    if (saved != null && saved != _isDark) {
      _isDark = saved;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, _isDark);
  }

  Future<void> setDark(bool isDark) async {
    if (_isDark == isDark) return;
    _isDark = isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, _isDark);
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

class AnalysisProvider extends ChangeNotifier {
  AnalysisState _state = const AnalysisIdle();
  AnalysisState get state => _state;

  VoidCallback? onAnalysisComplete;

  Future<void> analyze(File imageFile) async {
    _state = const AnalysisLoading();
    notifyListeners();
    try {
      final result = await OpenAiService.instance.analyzeChart(imageFile);
      result.chartImagePath = imageFile.path;
      await HistoryRepository.instance.add(result);
      onAnalysisComplete?.call();
      _state = AnalysisSuccess(result);
    } catch (e) {
      _state = AnalysisError(OpenAiService.friendlyError(e));
    }
    notifyListeners();
  }

  void reset() {
    _state = const AnalysisIdle();
    notifyListeners();
  }
}

// ─── History Provider ─────────────────────────────────────────────────────────

enum LoadState { idle, loading, loaded, error }

class HistoryProvider extends ChangeNotifier {
  LoadState _loadState = LoadState.idle;
  List<ChartAnalysis> _items = [];
  String _error = '';

  LoadState get loadState => _loadState;
  List<ChartAnalysis> get items => _items;
  String get error => _error;

  Future<void> load() async {
    _loadState = LoadState.loading;
    notifyListeners();
    try {
      _items = await HistoryRepository.instance.loadAll();
      _loadState = LoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _loadState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    await HistoryRepository.instance.clearAll();
    await load();
  }

  Future<void> delete(String id) async {
    await HistoryRepository.instance.delete(id);
    _items = _items.where((a) => a.id != id).toList();
    notifyListeners();
  }
}

// ─── Live Chart Provider ──────────────────────────────────────────────────────

class LiveChartProvider extends ChangeNotifier {
  static const _kFavoritesKey = 'favorite_pairs';

  String _selectedPair = 'BTCUSDT';
  String _selectedInterval = '1h';
  List<String> _favoritePairs = [];
  List<String> _recentPairs = [];

  LoadState _candleState = LoadState.idle;
  List<CandleData> _candles = [];
  String _candleError = '';

  LoadState _tickerState = LoadState.idle;
  Map<String, dynamic> _ticker = {};
  String _tickerError = '';

  String get selectedPair => _selectedPair;
  String get selectedInterval => _selectedInterval;
  List<String> get favoritePairs => _favoritePairs;
  List<String> get recentPairs => _recentPairs;

  LoadState get candleState => _candleState;
  List<CandleData> get candles => _candles;
  String get candleError => _candleError;

  LoadState get tickerState => _tickerState;
  Map<String, dynamic> get ticker => _ticker;
  String get tickerError => _tickerError;

  LiveChartProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoritePairs = prefs.getStringList(_kFavoritesKey) ?? [];
    notifyListeners();
  }

  void selectPair(String pair) {
    _selectedPair = pair;
    _addRecent(pair);
    notifyListeners();
    fetchData();
  }

  void selectInterval(String interval) {
    _selectedInterval = interval;
    notifyListeners();
    fetchData();
  }

  void _addRecent(String pair) {
    _recentPairs =
        [pair, ..._recentPairs.where((p) => p != pair)].take(10).toList();
  }

  Future<void> toggleFavorite(String pair) async {
    if (_favoritePairs.contains(pair)) {
      _favoritePairs = _favoritePairs.where((p) => p != pair).toList();
    } else {
      _favoritePairs = [..._favoritePairs, pair];
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFavoritesKey, _favoritePairs);
  }

  bool isFavorite(String pair) => _favoritePairs.contains(pair);

  Future<void> fetchData() async {
    await Future.wait([_fetchCandles(), _fetchTicker()]);
  }

  Future<void> _fetchCandles() async {
    _candleState = LoadState.loading;
    notifyListeners();
    try {
      _candles = await BinanceService.instance.getKlines(
        symbol: _selectedPair,
        interval: _selectedInterval,
        limit: 200,
      );
      _candleState = LoadState.loaded;
    } catch (e) {
      _candleError = e.toString();
      _candleState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> _fetchTicker() async {
    _tickerState = LoadState.loading;
    notifyListeners();
    try {
      _ticker = await BinanceService.instance.getTicker(_selectedPair);
      _tickerState = LoadState.loaded;
    } catch (e) {
      _tickerError = e.toString();
      _tickerState = LoadState.error;
    }
    notifyListeners();
  }
}
