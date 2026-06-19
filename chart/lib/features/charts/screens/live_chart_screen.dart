import 'dart:io';

import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/chart_analysis.dart';
import '../../../widgets/shared_widgets.dart';
import '../../analysis/screens/analysis_result_screen.dart';
import '../../providers.dart';
import '../../../providers/ads_provider.dart';

class LiveChartScreen extends StatefulWidget {
  const LiveChartScreen({super.key});

  @override
  State<LiveChartScreen> createState() => _LiveChartScreenState();
}

class _LiveChartScreenState extends State<LiveChartScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;
  List<String> _searchResults = [];

  // ── Ad widget (loaded in initState for free users) ────────────────────────
  Widget? _adWidget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiveChartProvider>().fetchData();

      // Load native ad for free users
      if (!context.read<SubscriptionProvider>().isPro) {
        setState(() {
          _adWidget = AdsProvider.getProvider().getAdWidget(
            AdsProvider.getProvider().live_chart_screen_top,
          );
        });
      }
    });
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final q = query.toUpperCase();
    final allPairs = context.read<LiveChartProvider>().allPairs;
    setState(() {
      _searchResults = allPairs.where((p) => p.contains(q)).toList();
    });
  }

  void _selectPair(String pair) {
    context.read<LiveChartProvider>().selectPair(pair);
    setState(() {
      _showSearch = false;
      _searchCtrl.clear();
      _searchResults = [];
    });
  }

  Future<void> _analyzeChart() async {
    final bytes = await _screenshotController.capture(pixelRatio: 2.0);
    if (bytes == null || !mounted) return;

    final dir = Directory.systemTemp;
    final file = File(
        '${dir.path}/live_chart_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);

    context.read<AnalysisProvider>().reset();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisResultScreen(imageFile: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveChart = context.watch<LiveChartProvider>();
    final pair = liveChart.selectedPair;
    final interval = liveChart.selectedInterval;
    final favorites = liveChart.favoritePairs;
    final recents = liveChart.recentPairs;
    final candleState = liveChart.candleState;
    final tickerState = liveChart.tickerState;
    final isPro = context.watch<SubscriptionProvider>().isPro;

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppTopBar(
        title: _showSearch ? '' : pair,
        actions: [
          if (!_showSearch)
            IconButton(
              icon: Icon(
                liveChart.isFavorite(pair)
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: liveChart.isFavorite(pair)
                    ? AppColors.gold
                    : AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () =>
                  context.read<LiveChartProvider>().toggleFavorite(pair),
            ),
          IconButton(
            icon: Icon(
                _showSearch ? Icons.close_rounded : Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 20),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchCtrl.clear();
                _searchResults = [];
              }
            }),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_showSearch) _buildSearchBar(),

              // ── Native ad for free users (above ticker/chart) ────────────
              if (!_showSearch && !isPro && _adWidget != null)
                _adWidget!,

              if (!_showSearch)
                tickerState == LoadState.loading
                    ? const SizedBox(
                        height: 48,
                        child: Center(
                            child: LinearProgressIndicator(
                                color: AppColors.gold,
                                backgroundColor: AppColors.card)))
                    : tickerState == LoadState.loaded
                        ? _buildTickerBar(liveChart.ticker)
                        : const SizedBox.shrink(),

              if (_showSearch && _searchResults.isNotEmpty)
                _buildSearchResults()
              else if (_showSearch && _searchCtrl.text.isEmpty)
                _buildPairLists(favorites, recents)
              else ...[
                _buildTimeframeBar(interval),
                Expanded(
                  child: candleState == LoadState.loading
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: AppColors.gold, strokeWidth: 2),
                              SizedBox(height: 12),
                              Text('Loading chart...',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ],
                          ),
                        )
                      : candleState == LoadState.error
                          ? EmptyStateWidget(
                              icon: Icons.wifi_off_rounded,
                              title: 'Failed to load',
                              subtitle: 'Check your internet connection',
                              action: GradientButton(
                                label: 'Retry',
                                onTap: () => context
                                    .read<LiveChartProvider>()
                                    .fetchData(),
                                width: 120,
                                height: 44,
                              ),
                            )
                          : _buildChart(liveChart.candles),
                ),
              ],
            ],
          ),

          if (!_showSearch)
            Positioned(
              bottom: 24,
              right: 20,
              child: GestureDetector(
                onTap: _analyzeChart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gold, AppColors.goldSoft],
                    ),
                    borderRadius: BorderRadius.circular(Radii.full),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: AppColors.bg, size: 16),
                      SizedBox(width: 7),
                      Text(
                        'Analyze Chart',
                        style: TextStyle(
                          color: AppColors.bg,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTickerBar(Map<String, dynamic> ticker) {
    final price =
        double.tryParse(ticker['lastPrice'] as String? ?? '0') ?? 0;
    final change =
        double.tryParse(ticker['priceChangePercent'] as String? ?? '0') ?? 0;
    final isUp = change >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Insets.md, vertical: 10),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            '\$${price.toStringAsFixed(price > 100 ? 2 : 4)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isUp ? AppColors.emerald : AppColors.red,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isUp
                  ? AppColors.emerald.withOpacity(0.1)
                  : AppColors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Radii.full),
            ),
            child: Text(
              '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isUp ? AppColors.emerald : AppColors.red,
              ),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _TickerStat(
                  label: 'H',
                  value: ticker['highPrice'] as String? ?? '—'),
              _TickerStat(
                  label: 'L',
                  value: ticker['lowPrice'] as String? ?? '—'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeBar(String selected) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: Insets.md),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: AppConstants.timeframes.map((tf) {
          final isSelected = tf == selected;
          return GestureDetector(
            onTap: () =>
                context.read<LiveChartProvider>().selectInterval(tf),
            child: Container(
              margin: const EdgeInsets.only(right: 6, top: 7, bottom: 7),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(Radii.full),
                border: isSelected
                    ? Border.all(color: AppColors.gold.withOpacity(0.4))
                    : null,
              ),
              child: Center(
                child: Text(
                  tf,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isSelected
                        ? AppColors.gold
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(List<CandleData> candles) {
    final chartCandles = candles.reversed
        .map((c) => Candle(
              date: c.time,
              open: c.open,
              high: c.high,
              low: c.low,
              close: c.close,
              volume: c.volume,
            ))
        .toList();

    return Screenshot(
      controller: _screenshotController,
      child: Stack(
        children: [
          Container(
            color: AppColors.bg,
            child: chartCandles.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.bar_chart_rounded,
                    title: 'No chart data',
                    subtitle: 'Could not load candle data for this pair.')
                : Candlesticks(
                    candles: chartCandles,
                    actions: const [],
                  ),
          ),
          // Expand button overlay
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: () => _openFullscreen(chartCandles),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.card.withOpacity(0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.fullscreen_rounded,
                    color: AppColors.textSecondary, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreen(List<Candle> candles) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullscreenChartView(candles: candles),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 8),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style:
            const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Search pair, e.g. BTC, ETH...',
          hintStyle:
              const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 18),
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.full),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.full),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.full),
            borderSide: const BorderSide(color: AppColors.gold),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Expanded(
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (_, i) => _PairTile(
          pair: _searchResults[i],
          onTap: () => _selectPair(_searchResults[i]),
        ),
      ),
    );
  }

  Widget _buildPairLists(List<String> favorites, List<String> recents) {
    final liveChart = context.watch<LiveChartProvider>();
    final allPairs = liveChart.allPairs;
    final isPairsLoading = liveChart.pairsLoading;

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(Insets.md),
        itemCount: 1,
        itemBuilder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (favorites.isNotEmpty) ...[
              const SectionHeader(title: 'Favorites'),
              const SizedBox(height: 8),
              ...favorites.map((p) => _PairTile(pair: p, onTap: () => _selectPair(p))),
              const SizedBox(height: Insets.md),
            ],
            Row(
              children: [
                const Expanded(child: SectionHeader(title: 'All Pairs')),
                const SizedBox(width: 8),
                if (isPairsLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        color: AppColors.gold, strokeWidth: 2),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${allPairs.length}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...allPairs.map((p) =>
                _PairTile(pair: p, onTap: () => _selectPair(p))),
            if (recents.isNotEmpty) ...[
              const SizedBox(height: Insets.md),
              const SectionHeader(title: 'Recent'),
              const SizedBox(height: 8),
              ...recents.map((p) =>
                  _PairTile(pair: p, onTap: () => _selectPair(p))),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _PairTile extends StatelessWidget {
  final String pair;
  final VoidCallback onTap;

  const _PairTile({required this.pair, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = pair.replaceAll('USDT', '');
    return ListTile(
      iconColor: AppColors.gold,
      textColor: AppColors.textPrimary,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(base.length > 3 ? base.substring(0, 3) : base,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold)),
        ),
      ),
      title: Text(pair,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
      subtitle: const Text('/ USDT',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
      onTap: onTap,
    );
  }
}

class _TickerStat extends StatelessWidget {
  final String label;
  final String value;
  const _TickerStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final v = double.tryParse(value) ?? 0;
    return Text(
      '$label: \$${v.toStringAsFixed(v > 100 ? 2 : 4)}',
      style:
          const TextStyle(fontSize: 10, color: AppColors.textSecondary),
    );
  }
}

// ── Fullscreen Chart View ─────────────────────────────────────────────────────

class _FullscreenChartView extends StatelessWidget {
  final List<Candle> candles;
  const _FullscreenChartView({required this.candles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: candles.isEmpty
                ? const Center(
                    child: Text('No data',
                        style:
                            TextStyle(color: AppColors.textSecondary)))
                : Candlesticks(
                    candles: candles,
                    actions: const [],
                  ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.card.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.fullscreen_exit_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
