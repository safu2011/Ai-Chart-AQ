import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/chart_analysis.dart';
import '../../../services/history_repository.dart';
import '../../../widgets/shared_widgets.dart';
import '../../providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(
        title: 'Analysis History',
        actions: [
          historyAsync.maybeWhen(
            data: (items) => items.isNotEmpty
                ? TextButton(
                    onPressed: () => _clearAll(context, ref),
                    child: const Text('Clear All',
                        style: TextStyle(
                            color: AppColors.red, fontSize: 13)),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(Insets.md),
          itemCount: 6,
          separatorBuilder: (_, __) =>
              const SizedBox(height: Insets.sm),
          itemBuilder: (_, __) =>
              const ShimmerBlock(height: 80, borderRadius: Radii.lg),
        ),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_outline_rounded,
          title: 'Error loading history',
          subtitle: e.toString(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history_rounded,
              title: 'No Analysis Yet',
              subtitle:
                  'Upload or capture a chart to get your first AI analysis.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(Insets.md),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: Insets.sm),
            itemBuilder: (context, i) =>
                _HistoryItem(analysis: items[i], ref: ref),
          );
        },
      ),
    );
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg)),
        title: const Text('Clear All History?',
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 16)),
        content: const Text(
            'All analysis records will be permanently deleted.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
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
    if (confirmed == true) {
      await HistoryRepository.instance.clearAll();
      ref.invalidate(historyProvider);
    }
  }
}

class _HistoryItem extends StatelessWidget {
  final ChartAnalysis analysis;
  final WidgetRef ref;

  const _HistoryItem({required this.analysis, required this.ref});

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
        child:
            const Icon(Icons.delete_outline_rounded, color: AppColors.red),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        await HistoryRepository.instance.delete(analysis.id);
        ref.invalidate(historyProvider);
      },
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
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: analysis.chartImagePath != null
                    ? Image.file(
                        File(analysis.chartImagePath!),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholderThumb(),
                      )
                    : _placeholderThumb(),
              ),
              const SizedBox(width: Insets.md),
              // Info
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
                        SentimentBadge(
                            sentiment: analysis.sentiment),
                        const Spacer(),
                        Text(
                          _formatDate(analysis.timestamp),
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted),
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
    // Show a bottom sheet with the full analysis
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (_) => _AnalysisDetailSheet(analysis: analysis, file: file),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Detail Bottom Sheet ─────────────────────────────────────────────────────
class _AnalysisDetailSheet extends StatelessWidget {
  final ChartAnalysis analysis;
  final File file;

  const _AnalysisDetailSheet(
      {required this.analysis, required this.file});

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
            // Handle
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
