import 'dart:io';

import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/chart_analysis.dart';
import '../../../widgets/shared_widgets.dart';
import '../../analysis/screens/analysis_result_screen.dart';
import '../../providers.dart';

class LiveChartScreen extends ConsumerStatefulWidget {
  const LiveChartScreen({super.key});

  @override
  ConsumerState<LiveChartScreen> createState() => _LiveChartScreenState();
}

class _LiveChartScreenState extends ConsumerState<LiveChartScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;
  List<String> _searchResults = [];

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final q = query.toUpperCase();
    setState(() {
      _searchResults = AppConstants.cryptoPairs
          .where((p) => p.contains(q))
          .toList();
    });
  }

  void _selectPair(String pair) {
    ref.read(selectedPairProvider.notifier).state = pair;
    ref.read(recentPairsProvider.notifier).add(pair);
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

    ref.read(analysisProvider.notifier).reset();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisResultScreen(imageFile: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pair = ref.watch(selectedPairProvider);
    final interval = ref.watch(selectedIntervalProvider);
    final favorites = ref.watch(favoritePairsProvider);
    final recents = ref.watch(recentPairsProvider);
    final candlesAsync = ref.watch(candleDataProvider);
    final tickerAsync = ref.watch(tickerProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppTopBar(
        title: _showSearch ? '' : pair,
        actions: [
          // Favorite toggle
          if (!_showSearch)
            IconButton(
              icon: Icon(
                favorites.contains(pair)
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: favorites.contains(pair)
                    ? AppColors.gold
                    : AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () =>
                  ref.read(favoritePairsProvider.notifier).toggle(pair),
            ),
          // Search toggle
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
              // Search bar
              if (_showSearch) _buildSearchBar(),

              // Ticker info
              if (!_showSearch)
                tickerAsync.when(
                  data: (t) => _buildTickerBar(t),
                  loading: () => const SizedBox(
                      height: 48,
                      child: Center(
                          child: LinearProgressIndicator(
                              color: AppColors.gold,
                              backgroundColor: AppColors.card))),
                  error: (_, __) => const SizedBox.shrink(),
                ),

              // Search results or pair lists
              if (_showSearch && _searchResults.isNotEmpty)
                _buildSearchResults()
              else if (_showSearch && _searchCtrl.text.isEmpty)
                _buildPairLists(favorites, recents)
              else ...[
                // Timeframe selector
                _buildTimeframeBar(interval),

                // Chart
                Expanded(
                  child: candlesAsync.when(
                    data: (candles) => _buildChart(candles),
                    loading: () => const Center(
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
                    ),
                    error: (e, _) => EmptyStateWidget(
                      icon: Icons.wifi_off_rounded,
                      title: 'Failed to load',
                      subtitle: 'Check your internet connection',
                      action: GradientButton(
                        label: 'Retry',
                        onTap: () => ref.invalidate(candleDataProvider),
                        width: 120,
                        height: 44,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // FAB — Analyze Current Chart
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
                    borderRadius:
                        BorderRadius.circular(Radii.full),
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
    final price = double.tryParse(
            ticker['lastPrice'] as String? ?? '0') ??
        0;
    final change = double.tryParse(
            ticker['priceChangePercent'] as String? ?? '0') ??
        0;
    final isUp = change >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Insets.md, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5)),
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
            padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 3),
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
              _TickerStat(label: 'H',
                  value: ticker['highPrice'] as String? ?? '—'),
              _TickerStat(label: 'L',
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
        border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: AppConstants.timeframes.map((tf) {
          final isSelected = tf == selected;
          return GestureDetector(
            onTap: () {
              ref.read(selectedIntervalProvider.notifier).state = tf;
              ref.invalidate(candleDataProvider);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 6, top: 7, bottom: 7),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(Radii.full),
                border: isSelected
                    ? Border.all(
                        color: AppColors.gold.withOpacity(0.4))
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
    // Convert our CandleData to the candlesticks package Candle format
    final chartCandles = candles.reversed.map((c) => Candle(
          date: c.time,
          open: c.open,
          high: c.high,
          low: c.low,
          close: c.close,
          volume: c.volume,
        )).toList();

    return Screenshot(
      controller: _screenshotController,
      child: Container(
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 14),
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
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(Insets.md),
        children: [
          if (favorites.isNotEmpty) ...[
            const SectionHeader(title: 'Favorites'),
            const SizedBox(height: 8),
            ...favorites.map((p) => _PairTile(
                pair: p, onTap: () => _selectPair(p))),
            const SizedBox(height: Insets.md),
          ],
          const SectionHeader(title: 'All Pairs'),
          const SizedBox(height: 8),
          ...AppConstants.cryptoPairs.map((p) =>
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
    );
  }
}

class _PairTile extends StatelessWidget {
  final String pair;
  final VoidCallback onTap;

  const _PairTile({required this.pair, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = pair.replaceAll('USDT', '');
    return ListTile(
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
      subtitle: Text('/ USDT',
          style: const TextStyle(
              fontSize: 11, color: AppColors.textMuted)),
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
      style: const TextStyle(
          fontSize: 10, color: AppColors.textSecondary),
    );
  }
}
