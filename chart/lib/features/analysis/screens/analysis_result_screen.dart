import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/chart_analysis.dart';
import '../../../widgets/shared_widgets.dart';
import '../../providers.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  final File imageFile;
  const AnalysisResultScreen({super.key, required this.imageFile});

  @override
  ConsumerState<AnalysisResultScreen> createState() =>
      _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(analysisProvider);
      if (state is AnalysisIdle) {
        ref.read(analysisProvider.notifier).analyze(widget.imageFile);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(
        title: 'AI Analysis',
        actions: state is AnalysisSuccess
            ? [
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => _share(state.result),
                ),
              ]
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: switch (state) {
          AnalysisLoading() => _buildLoading(),
          AnalysisSuccess(:final result) => _buildResult(result),
          AnalysisError(:final message) => _buildError(message),
          AnalysisIdle() => _buildLoading(),
        },
      ),
    );
  }

  // ─── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return SingleChildScrollView(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart thumb
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.lg),
            child: Image.file(widget.imageFile,
                height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: Insets.md),
          GlassCard(
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Analyzing your chart...',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('GPT-4o Vision is reading patterns & levels',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.md),
          const AnalysisLoadingSkeleton(),
        ],
      ),
    );
  }

  // ─── Error ─────────────────────────────────────────────────────────────────
  Widget _buildError(String message) {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.red.withOpacity(0.3)),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.red, size: 34),
            ),
            const SizedBox(height: Insets.md),
            const Text('Analysis Failed',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5)),
            const SizedBox(height: Insets.lg),
            GradientButton(
              label: 'Try Again',
              onTap: () =>
                  ref.read(analysisProvider.notifier).analyze(widget.imageFile),
              width: 160,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Result ────────────────────────────────────────────────────────────────
  Widget _buildResult(ChartAnalysis result) {
    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(result),
          const SizedBox(height: Insets.md),
          _buildSentimentMetrics(result),
          const SizedBox(height: Insets.md),
          _buildMarkdownCard(
            icon: Icons.summarize_outlined,
            title: 'Overall Summary',
            color: AppColors.blue,
            content: result.summary,
          ),
          const SizedBox(height: Insets.sm),
          _buildMarkdownCard(
            icon: Icons.layers_outlined,
            title: 'Key Levels',
            color: AppColors.gold,
            content: result.keyLevels,
          ),
          const SizedBox(height: Insets.sm),
          _buildMarkdownCard(
            icon: Icons.swap_horiz_rounded,
            title: 'Trade Scenario',
            color: AppColors.emerald,
            content: result.tradeScenario,
          ),
          const SizedBox(height: Insets.sm),
          _buildMarkdownCard(
            icon: Icons.warning_amber_rounded,
            title: 'Risk Analysis',
            color: AppColors.red,
            content: result.riskAnalysis,
          ),
          const SizedBox(height: Insets.sm),
          _buildMarkdownCard(
            icon: Icons.notes_rounded,
            title: 'Final Notes',
            color: AppColors.textSecondary,
            content: result.finalNotes,
          ),
          const SizedBox(height: Insets.md),
          _buildActions(result),
          const SizedBox(height: Insets.md),
          _buildFooterDisclaimer(),
          const SizedBox(height: Insets.xl),
        ],
      ),
    );
  }

  Widget _buildHeader(ChartAnalysis result) {
    return GlassCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Row(
        children: [
          // Chart thumb
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md),
            child: Image.file(
              widget.imageFile,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.neutral,
                        borderRadius:
                            BorderRadius.circular(Radii.full),
                      ),
                      child: Text(result.assetType,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    SentimentBadge(sentiment: result.sentiment),
                  ],
                ),
                const SizedBox(height: 6),
                Text(result.pair,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  _formatDate(result.timestamp),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentMetrics(ChartAnalysis result) {
    final sentimentPct =
        '${(result.sentimentScore * 100).toStringAsFixed(0)}%';
    final volPct = '${(result.volumeScore * 100).toStringAsFixed(0)}%';
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Sentiment',
            value: sentimentPct,
            progress: result.sentimentScore,
            color: result.isBullish
                ? AppColors.emerald
                : result.isBearish
                    ? AppColors.red
                    : AppColors.gold,
          ),
        ),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: _MetricCard(
            label: 'Volume Signal',
            value: result.volumeLabel,
            progress: result.volumeScore,
            color: AppColors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMarkdownCard({
    required IconData icon,
    required String title,
    required Color color,
    required String content,
  }) {
    if (content.trim().isEmpty) return const SizedBox.shrink();
    return GlassCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: Insets.sm),
          MarkdownBody(
            data: content,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.6),
              strong: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              listBullet: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
              h3: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ChartAnalysis result) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onTap: () {
              Clipboard.setData(
                  ClipboardData(text: result.rawMarkdown));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analysis copied to clipboard'),
                  backgroundColor: AppColors.card,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: _ActionBtn(
            icon: Icons.share_rounded,
            label: 'Share',
            onTap: () => _share(result),
          ),
        ),
      ],
    );
  }

  void _share(ChartAnalysis result) {
    final text = '''
${AppConstants.appName} — AI Chart Analysis
${result.pair} | ${result.assetType} | ${result.sentiment}
Generated: ${_formatDate(result.timestamp)}

${result.rawMarkdown}

---
${AppConstants.disclaimer}
''';
    Share.share(text, subject: '${result.pair} Chart Analysis');
  }

  Widget _buildFooterDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.red.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: AppColors.red),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              AppConstants.disclaimer,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Metric card with progress bar ──────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.neutral,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
