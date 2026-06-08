import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/chart_analysis.dart';
import '../../../widgets/shared_widgets.dart';
import '../../providers.dart';
import '../../../services/ad_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyProv = context.watch<HistoryProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppTopBar(
        title: 'Analysis History',
        actions: [
          if (historyProv.loadState == LoadState.loaded &&
              historyProv.items.isNotEmpty)
            TextButton(
              onPressed: () => _clearAll(context),
              child: const Text('Clear All',
                  style: TextStyle(color: AppColors.red, fontSize: 13)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Banner ad for free users
          if (!context.watch<SubscriptionProvider>().isPro)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: AppTheme.bgColor(context),
              child: const AdBannerWidget(),
            ),
          Expanded(child: _buildBody(context, historyProv)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, HistoryProvider historyProv) {
    switch (historyProv.loadState) {
      case LoadState.idle:
      case LoadState.loading:
        return ListView.separated(
          padding: const EdgeInsets.all(Insets.md),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(height: Insets.sm),
          itemBuilder: (_, __) =>
              const ShimmerBlock(height: 80, borderRadius: Radii.lg),
        );
      case LoadState.error:
        return EmptyStateWidget(
          icon: Icons.error_outline_rounded,
          title: 'Error loading history',
          subtitle: historyProv.error,
        );
      case LoadState.loaded:
        if (historyProv.items.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.history_rounded,
            title: 'No Analysis Yet',
            subtitle:
                'Upload or capture a chart to get your first AI analysis.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Insets.md),
          itemCount: historyProv.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: Insets.sm),
          itemBuilder: (context, i) =>
              _HistoryItem(analysis: historyProv.items[i]),
        );
    }
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg)),
        title: const Text('Clear All History?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: const Text(
            'All analysis records will be permanently deleted.',
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<HistoryProvider>().clearAll();
    }
  }
}

class _HistoryItem extends StatelessWidget {
  final ChartAnalysis analysis;
  const _HistoryItem({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final sentimentColor = analysis.isBullish
        ? AppColors.emerald
        : analysis.isBearish
            ? AppColors.red
            : AppColors.gold;

    return Dismissible(
      key: ValueKey(analysis.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Insets.md),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => context.read<HistoryProvider>().delete(analysis.id),
      child: GestureDetector(
        onTap: () => _openDetail(context),
        child: Container(
          padding: const EdgeInsets.all(Insets.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _openFullImage(context),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: analysis.chartImagePath != null
                          ? Image.file(
                              File(analysis.chartImagePath!),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholderThumb(),
                            )
                          : _placeholderThumb(),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.fullscreen_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(analysis.pair,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.neutral,
                            borderRadius:
                                BorderRadius.circular(Radii.full),
                          ),
                          child: Text(analysis.assetType,
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      analysis.summary.length > 70
                          ? '${analysis.summary.substring(0, 70)}...'
                          : analysis.summary,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SentimentBadge(sentiment: analysis.sentiment),
                        const Spacer(),
                        Text(
                          _formatDate(analysis.timestamp),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullImage(BuildContext context) {
    if (analysis.chartImagePath == null) return;
    final file = File(analysis.chartImagePath!);
    if (!file.existsSync()) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: _FullScreenImageView(file: file),
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: const Icon(Icons.candlestick_chart_rounded,
          color: AppColors.textMuted, size: 24),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg)),
        title: const Text('Delete this record?',
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    if (analysis.chartImagePath == null) return;
    final file = File(analysis.chartImagePath!);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chart image no longer available'),
          backgroundColor: AppColors.card,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (_) => _AnalysisDetailSheet(analysis: analysis, file: file),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _AnalysisDetailSheet extends StatelessWidget {
  final ChartAnalysis analysis;
  final File file;

  const _AnalysisDetailSheet({required this.analysis, required this.file});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Insets.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.md),
              child: Image.file(file,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover),
            ),
            const SizedBox(height: Insets.md),
            Row(
              children: [
                Text(analysis.pair,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(width: 10),
                SentimentBadge(sentiment: analysis.sentiment, large: true),
              ],
            ),
            const SizedBox(height: Insets.md),
            Text(analysis.rawMarkdown,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6)),
            const SizedBox(height: Insets.xl),
          ],
        ),
      ),
    );
  }
}


class _FullScreenImageView extends StatefulWidget {
  final File file;
  const _FullScreenImageView({required this.file});

  @override
  State<_FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<_FullScreenImageView> {
  final TransformationController _transformCtrl = TransformationController();

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {}, // prevent tap-through to close when interacting
                child: InteractiveViewer(
                  transformationController: _transformCtrl,
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Center(
                    child: Hero(
                      tag: widget.file.path,
                      child: Image.file(widget.file, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _transformCtrl.value = Matrix4.identity(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tap outside or reset zoom',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
