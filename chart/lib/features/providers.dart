import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/chart_analysis.dart';
import '../models/price_alert.dart';
import '../services/alerts_service.dart';
import '../services/binance_service.dart';
import '../services/credits_service.dart';
import '../services/history_repository.dart';
import '../services/openai_service.dart';
import '../services/subscription_service.dart';

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
      print("Error = ${e}");
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

  List<String> _allPairs = AppConstants.cryptoPairs;
  bool _pairsLoading = false;
  bool _pairsLoaded = false;

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
  List<String> get allPairs => _allPairs;
  bool get pairsLoading => _pairsLoading;

  LoadState get candleState => _candleState;
  List<CandleData> get candles => _candles;
  String get candleError => _candleError;

  LoadState get tickerState => _tickerState;
  Map<String, dynamic> get ticker => _ticker;
  String get tickerError => _tickerError;

  LiveChartProvider() {
    _loadFavorites();
    _fetchAllPairs();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoritePairs = prefs.getStringList(_kFavoritesKey) ?? [];
    notifyListeners();
  }

  Future<void> _fetchAllPairs() async {
    if (_pairsLoading || _pairsLoaded) return;
    _pairsLoading = true;
    notifyListeners();
    try {
      final pairs = await BinanceService.instance.getAllUsdtPairs();
      if (pairs.isNotEmpty) {
        _allPairs = pairs;
        _pairsLoaded = true;
      }
    } catch (_) {
    } finally {
      _pairsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAllPairs() async {
    _pairsLoaded = false;
    await _fetchAllPairs();
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

// ─── Subscription / Credits Provider ─────────────────────────────────────────

class SubscriptionProvider extends ChangeNotifier {
  bool _isPro = false;
  int _subscriptionCredits = 0;
  int _freeRemaining = AppConstants.freeAnalysesPerDay;
  bool _isLoading = false;
  Offerings? _offerings;
  SubscriptionTier _activeTier = SubscriptionTier.none;

  bool get isPro => _isPro;
  int get subscriptionCredits => _subscriptionCredits;
  int get freeRemaining => _freeRemaining;
  bool get isLoading => _isLoading;
  Offerings? get offerings => _offerings;
  SubscriptionTier get activeTier => _activeTier;

  /// Total analyses remaining (credit-based for Pro, free count for non-Pro).
  int get analysesAvailable {
    if (_isPro) {
      return (_subscriptionCredits / AppConstants.creditsPerAnalysis).floor();
    }
    return _freeRemaining;
  }

  /// Credit count to display in UI (subscription credits for Pro users).
  int get displayCredits => _isPro ? _subscriptionCredits : _freeRemaining;

  void setIsPro(bool value) {
    _isPro = value;
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    _isPro             = await SubscriptionService.instance.isPro();
    _activeTier        = await SubscriptionService.instance.getActiveSubscriptionTier();
    _subscriptionCredits = await CreditsService.instance.getSubscriptionCredits();
    _freeRemaining     = await CreditsService.instance.getFreeRemaining();

    // If active subscription, ensure credits have been granted for this cycle
    if (_activeTier != SubscriptionTier.none) {
      await CreditsService.instance.handleSubscriptionChange(_activeTier);
      _subscriptionCredits = await CreditsService.instance.getSubscriptionCredits();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadOfferings() async {
    if (_isLoading && _offerings != null) return;
    _isLoading = true;
    notifyListeners();
    _offerings = await SubscriptionService.instance.fetchOfferings();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> canAnalyze() async {
    return CreditsService.instance.canAnalyze(isPro: _isPro);
  }

  Future<CreditConsumeResult> consumeCredit() async {
    final result = await CreditsService.instance.consume(isPro: _isPro);
    _subscriptionCredits = await CreditsService.instance.getSubscriptionCredits();
    _freeRemaining       = await CreditsService.instance.getFreeRemaining();
    notifyListeners();
    return result;
  }

  /// Purchases a subscription package. Grants subscription credits on success.
  Future<void> purchasePackage(Package package) async {
    _isLoading = true;
    notifyListeners();
    try {
      final info = await SubscriptionService.instance.purchase(package);
      _isPro = info.entitlements.active
          .containsKey(AppConstants.rcProEntitlement);

      if (_isPro) {
        // Determine the tier from the purchased product identifier
        final productId = package.storeProduct.identifier;
        final tier = _tierFromProductId(productId);
        _activeTier = tier;
        await CreditsService.instance.handleSubscriptionChange(tier);
      }
      await refresh();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    _isLoading = true;
    notifyListeners();
    try {
      final info = await SubscriptionService.instance.restore();
      _isPro = info.entitlements.active
          .containsKey(AppConstants.rcProEntitlement);

      if (_isPro) {
        final tier = await SubscriptionService.instance.getActiveSubscriptionTier();
        _activeTier = tier;
        await CreditsService.instance.handleSubscriptionChange(tier);
      }
      await refresh();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static SubscriptionTier _tierFromProductId(String productId) {
    if (productId == AppConstants.rcYearlySubId ||
        productId.contains('yearly')) {
      return SubscriptionTier.yearly;
    }
    if (productId == AppConstants.rcMonthlySubId ||
        productId.contains('monthly')) {
      return SubscriptionTier.monthly;
    }
    if (productId == AppConstants.rcWeeklySubId ||
        productId.contains('weekly')) {
      return SubscriptionTier.weekly;
    }
    return SubscriptionTier.monthly;
  }

  /// Human-readable tier label.
  String get tierLabel {
    switch (_activeTier) {
      case SubscriptionTier.weekly:  return 'Weekly Pro';
      case SubscriptionTier.monthly: return 'Monthly Pro';
      case SubscriptionTier.yearly:  return 'Yearly Pro';
      case SubscriptionTier.none:    return 'Free';
    }
  }
}

// ─── Alerts Provider ──────────────────────────────────────────────────────────

class AlertsProvider extends ChangeNotifier {
  List<PriceAlert> _alerts = [];
  bool _isLoading = false;
  String _error = '';
  DateTime? _lastChecked;

  List<PriceAlert> get alerts => _alerts;
  List<PriceAlert> get activeAlerts =>
      _alerts.where((a) => a.isActive).toList();
  List<PriceAlert> get triggeredAlerts =>
      _alerts.where((a) => !a.isActive && a.triggeredAt != null).toList();
  bool get isLoading => _isLoading;
  String get error => _error;
  DateTime? get lastChecked => _lastChecked;
  int get activeCount => activeAlerts.length;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _alerts = await AlertsService.instance.loadAll();
      _error = '';
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAlert({
    required String pair,
    required double targetPrice,
    required AlertCondition condition,
  }) async {
    final alert = PriceAlert.create(
      pair: pair,
      targetPrice: targetPrice,
      condition: condition,
    );
    await AlertsService.instance.add(alert);
    await load();
  }

  Future<void> deleteAlert(String id) async {
    await AlertsService.instance.delete(id);
    _alerts = _alerts.where((a) => a.id != id).toList();
    notifyListeners();
  }

  Future<void> toggleAlert(String id) async {
    await AlertsService.instance.toggle(id);
    await load();
  }

  Future<void> checkAlerts() async {
    await AlertsService.instance.checkAlerts();
    _lastChecked = DateTime.now();
    await load();
  }
}