import 'dart:io';

import 'package:chart/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/chart_analysis.dart';
import '../../../widgets/shared_widgets.dart';
import '../../paywall/paywall_screen.dart';
import '../../providers.dart';
import '../../../providers/ads_provider.dart';
import '../../rating/rating_dialog.dart';

class AnalysisResultScreen extends StatefulWidget {
  final File imageFile;
  const AnalysisResultScreen({super.key, required this.imageFile});

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  Widget? _adWidget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final subProv = context.read<SubscriptionProvider>();

      // Load native ad for free users
      if (!subProv.isPro) {
        setState(() {
          _adWidget = AdsProvider.getProvider().getAdWidget(
            AdsProvider.getProvider().analysis_result_screen_middle,
          );
        });
      }

      final analysisProv = context.read<AnalysisProvider>();
      if (analysisProv.state is! AnalysisIdle) return;

      // Hook rating prompt after successful analysis
      final prevCallback = analysisProv.onAnalysisComplete;
      analysisProv.onAnalysisComplete = () {
        prevCallback?.call();
        // Delay slightly so the result screen has rendered before the dialog
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) RatingDialogHelper.maybeShow(context);
        });
      };

      // Credit is only deducted by AnalysisProvider once the API call
      // actually succeeds — see analyze() for the gate + consume logic.
      await analysisProv.analyze(
        widget.imageFile,
        canAnalyzeFn: subProv.canAnalyze,
        consumeFn: subProv.consumeCredit,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AnalysisProvider>().state;

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppTopBar(
        title: 'AI Analysis',
        actions: (state is AnalysisSuccess &&
                !(state as AnalysisSuccess).result.isInvalidImage)
            ? [
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => _share((state as AnalysisSuccess).result),
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
          AnalysisNoCredits() => _buildNoCredits(),
          AnalysisIdle() => _buildLoading(),
        },
      ),
    );
  }

  Widget _buildLoading() {
    return SingleChildScrollView(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Analyzing your chart...',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('GPT-4o Vision is reading patterns & levels',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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

  Widget _buildNoCredits() {
    return Center(
      key: const ValueKey('no_credits'),
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1), shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: const Icon(Icons.bolt_outlined, color: AppColors.gold, size: 34),
            ),
            const SizedBox(height: Insets.md),
            const Text('No Credits Remaining',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'You don\'t have any credits left for this analysis. Nothing was charged.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: Insets.lg),
            GradientButton(
              label: 'View Plans',
              onTap: () async {
                final purchased = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
                if (!mounted) return;
                if (purchased == true) {
                  // Credits are available now — retry automatically.
                  final subProv = context.read<SubscriptionProvider>();
                  context.read<AnalysisProvider>().analyze(
                        widget.imageFile,
                        canAnalyzeFn: subProv.canAnalyze,
                        consumeFn: subProv.consumeCredit,
                      );
                } else {
                  Navigator.of(context).pop();
                }
              },
              width: 160,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1), shape: BoxShape.circle,
                border: Border.all(color: AppColors.red.withOpacity(0.3)),
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 34),
            ),
            const SizedBox(height: Insets.md),
            const Text('Analysis Failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: Insets.lg),
            GradientButton(
              label: 'Try Again',
              onTap: () async {
                final subProv = context.read<SubscriptionProvider>();

                // Just a balance check — does NOT touch the user's credits.
                // The retry's credit (if any) is deducted inside analyze()
                // only after the API call actually succeeds, same as the
                // first attempt.
                final canAnalyze = await subProv.canAnalyze();
                if (canAnalyze && mounted) {
                  await context.read<AnalysisProvider>().analyze(
                        widget.imageFile,
                        canAnalyzeFn: subProv.canAnalyze,
                        consumeFn: subProv.consumeCredit,
                      );
                } else if (mounted) {
                  final purchased = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                  if (purchased != true && mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  }
                }
              },
              width: 160,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvalidImageUI(ChartAnalysis result) {
    return _InvalidImageView(
      imageFile: widget.imageFile,
      message: result.summary.isNotEmpty ? result.summary : 'Please upload a valid financial chart image.',
      onBack: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildResult(ChartAnalysis result) {
    // Show dedicated invalid-image UI
    if (result.isInvalidImage) return _buildInvalidImageUI(result);

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
          _buildMarkdownCard(icon: Icons.summarize_outlined, title: 'Overall Summary',
              color: AppColors.blue, content: result.summary),
          const SizedBox(height: Insets.sm),
          _buildMarkdownCard(icon: Icons.layers_outlined, title: 'Key Levels',
              color: AppColors.gold, content: result.keyLevels),
          const SizedBox(height: Insets.sm),
          _buildMarkdownCard(icon: Icons.swap_horiz_rounded, title: 'Trade Scenario',
              color: AppColors.emerald, content: result.tradeScenario),
          const SizedBox(height: Insets.sm),
          _buildMarkdownCard(icon: Icons.warning_amber_rounded, title: 'Risk Analysis',
              color: AppColors.red, content: result.riskAnalysis),
          const SizedBox(height: Insets.sm),
          _buildMarkdownCard(icon: Icons.notes_rounded, title: 'Final Notes',
              color: AppColors.textSecondary, content: result.finalNotes),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md),
            child: Image.file(widget.imageFile, width: 70, height: 70, fit: BoxFit.cover),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.neutral,
                        borderRadius: BorderRadius.circular(Radii.full),
                      ),
                      child: Text(result.assetType,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    SentimentBadge(sentiment: result.sentiment),
                  ],
                ),
                const SizedBox(height: 6),
                Text(result.pair,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(_formatDate(result.timestamp),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentMetrics(ChartAnalysis result) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Sentiment',
            value: '${(result.sentimentScore * 100).toStringAsFixed(0)}%',
            progress: result.sentimentScore,
            color: result.isBullish ? AppColors.emerald : result.isBearish ? AppColors.red : AppColors.gold,
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

  Widget _buildMarkdownCard({required IconData icon, required String title, required Color color, required String content}) {
    if (content.trim().isEmpty) return const SizedBox.shrink();
    return GlassCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Builder(builder: (context) {
            final tp = AppTheme.textPrimary(context);
            final ts = AppTheme.textSecondary(context);
            return MarkdownBody(
              data: content,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(fontSize: 13, color: ts, height: 1.6),
                strong: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tp),
                listBullet: TextStyle(fontSize: 13, color: ts),
                h3: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tp),
              ),
            );
          }),
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
              Clipboard.setData(ClipboardData(text: result.rawMarkdown));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analysis copied to clipboard'), backgroundColor: AppColors.card),
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
    // Strip any disclaimer already embedded in rawMarkdown to avoid duplication
    final cleanRaw = result.rawMarkdown
        .replaceAll(AppConstants.disclaimer, '')
        .trimRight();
    final text = '${AppConstants.appName} — AI Chart Analysis\n'
        '${result.pair} | ${result.assetType} | ${result.sentiment}\n'
        'Generated: ${_formatDate(result.timestamp)}\n\n'
        '$cleanRaw\n\n---\n${AppConstants.disclaimer}';
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
          const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.red),
          const SizedBox(width: 6),
          Expanded(
            child: Text(AppConstants.disclaimer,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _MetricCard({required this.label, required this.value, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0), minHeight: 4,
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

  const _ActionBtn({required this.icon, required this.label, required this.onTap});

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
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ── Invalid Image View ────────────────────────────────────────────────────────

class _InvalidImageView extends StatefulWidget {
  final File imageFile;
  final String message;
  final VoidCallback onBack;

  const _InvalidImageView({
    required this.imageFile,
    required this.message,
    required this.onBack,
  });

  @override
  State<_InvalidImageView> createState() => _InvalidImageViewState();
}

class _InvalidImageViewState extends State<_InvalidImageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('invalid'),
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated warning icon
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold.withOpacity(0.35), width: 2),
                    ),
                    child: const Icon(Icons.image_not_supported_rounded,
                        color: AppColors.gold, size: 40),
                  ),
                ),
                const SizedBox(height: Insets.lg),
                const Text(
                  'Invalid Chart Image',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: Insets.sm),
                Container(
                  padding: const EdgeInsets.all(Insets.md),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(Radii.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // Thumbnail of uploaded image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Radii.md),
                        child: Image.file(widget.imageFile,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      const SizedBox(height: Insets.md),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.lg),
                Container(
                  padding: const EdgeInsets.all(Insets.md),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded,
                              size: 14, color: AppColors.gold),
                          SizedBox(width: 6),
                          Text('Tips for a valid chart:',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...[
                        'Upload a candlestick, line, or bar chart',
                        'Ensure the chart shows price/time data',
                        'Crypto, Forex, or Stock charts work best',
                        'Screenshot from TradingView, Binance, etc.',
                      ].map((tip) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                                Expanded(
                                  child: Text(tip,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          height: 1.4)),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.lg),
                GradientButton(
                  label: 'Try Another Image',
                  icon: const Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.bg, size: 16),
                  onTap: widget.onBack,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
