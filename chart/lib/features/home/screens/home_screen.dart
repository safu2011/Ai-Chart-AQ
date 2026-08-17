import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../alerts/screens/alerts_screen.dart';
import '../../analysis/screens/image_preview_screen.dart';
import '../../charts/screens/live_chart_screen.dart';
import '../../exit/exit_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../onboarding/user_guide_overlay.dart';
import '../../paywall/paywall_screen.dart';
import '../../providers.dart';
import '../../../providers/ads_provider.dart';
import '../../settings/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey? guideKeyGallery;
  final GlobalKey? guidekeyCameraBtn;
  final GlobalKey? guideKeyQuickAccess;

  const HomeScreen({
    super.key,
    this.guideKeyGallery,
    this.guidekeyCameraBtn,
    this.guideKeyQuickAccess,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  StreamSubscription? _intentSub;

  late final GlobalKey _guideKeyGallery;
  late final GlobalKey _guidekeyCameraBtn;
  late final GlobalKey _guideKeyQuickAccess;

  Widget? _adWidget;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.read<SubscriptionProvider>().isPro) {
        setState(() {
          _adWidget = AdsProvider.getProvider().getAdWidget(
            AdsProvider.getProvider().home_screen_middle,
          );
        });
      }
    });

    _guideKeyGallery =
        widget.guideKeyGallery ?? GlobalKey(debugLabel: 'guide_gallery');
    _guidekeyCameraBtn =
        widget.guidekeyCameraBtn ?? GlobalKey(debugLabel: 'guide_camera');
    _guideKeyQuickAccess =
        widget.guideKeyQuickAccess ?? GlobalKey(debugLabel: 'guide_quick');

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _initSharingIntent();
  }

  void _initSharingIntent() {
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> files) {
        if (files.isNotEmpty) _handleSharedImagePath(files.first.path);
      },
      onError: (_) {},
    );

    ReceiveSharingIntent.instance.getInitialMedia().then(
      (List<SharedMediaFile> files) {
        if (files.isNotEmpty) {
          final path = files.first.path;
          ReceiveSharingIntent.instance.reset();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleSharedImagePath(path);
          });
        }
      },
    );
  }

  Future<void> _handleSharedImagePath(String path) async {
    final file = File(path);
    if (!await file.exists()) return;
    final subProv = context.read<SubscriptionProvider>();
    final canAnalyze = await subProv.canAnalyze();
    if (!canAnalyze && mounted) {
      final purchased = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      if (purchased != true) return;
      final canNow = await subProv.canAnalyze();
      if (!canNow || !mounted) return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ImagePreviewScreen(imageFile: file)),
    );
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Credit-gated image pick ───────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final subProv = context.read<SubscriptionProvider>();
    final canAnalyze = await subProv.canAnalyze();

    if (!canAnalyze && mounted) {
      final purchased = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      if (purchased != true) return;
      final canNow = await subProv.canAnalyze();
      if (!canNow || !mounted) return;
    }

    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, imageQuality: 90);
    if (xFile == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImagePreviewScreen(imageFile: File(xFile.path)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.bgColor(context);
    final borderColor = AppTheme.borderColor(context);
    final textSecondary = AppTheme.textSecondary(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExitScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              slivers: [
                _buildSliverHeader(bgColor, borderColor, textSecondary),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Insets.md, vertical: Insets.md),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildCreditsCard(context),
                      const SizedBox(height: Insets.md),
                      _buildWelcomeCard(context),
                      const SizedBox(height: Insets.lg),
                      _buildUploadSection(context),
                      const SizedBox(height: Insets.lg),
                      _buildQuickActionsSection(context),
                      const SizedBox(height: Insets.lg),
                      if (!context.watch<SubscriptionProvider>().isPro &&
                          _adWidget != null)
                        _adWidget!,
                      if (!context.watch<SubscriptionProvider>().isPro &&
                          _adWidget != null)
                        const SizedBox(height: Insets.md),
                      const DisclaimerBanner(
                          text: AppConstants.startupDisclaimer),
                      const SizedBox(height: Insets.xl),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Credits Status Card ───────────────────────────────────────────────────

  Widget _buildCreditsCard(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final gold = AppTheme.gold(context);
    final cardColor = AppTheme.cardColor(context);
    final borderColor = AppTheme.borderColor(context);

    // ── Pro subscriber ───────────────────────────────────────────────────────
    if (sub.isPro) {
      final creditsLeft = sub.subscriptionCredits;
      final analysesLeft = sub.analysesAvailable;
      final isLow = analysesLeft <= 5;

      return GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PaywallScreen()),
        ),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gold.withOpacity(0.12), gold.withOpacity(0.04)],
            ),
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(
              color: isLow
                  ? AppTheme.red(context).withOpacity(0.5)
                  : gold.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isLow
                    ? Icons.warning_amber_rounded
                    : Icons.workspace_premium_rounded,
                color: isLow ? AppTheme.red(context) : gold,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sub.tierLabel} — $creditsLeft credits',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isLow ? AppTheme.red(context) : gold,
                      ),
                    ),
                    Text(
                      isLow
                          ? '$analysesLeft ${analysesLeft == 1 ? 'analysis' : 'analyses'} left — tap to manage plan'
                          : '~$analysesLeft analyses remaining this cycle',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_circle_rounded, color: gold, size: 16),
            ],
          ),
        ),
      );
    }

    // ── Free user ────────────────────────────────────────────────────────────
    final freeLeft = sub.freeRemaining;
    final isLow = freeLeft <= 1;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 12),
        decoration: BoxDecoration(
          color: isLow ? AppTheme.red(context).withOpacity(0.06) : cardColor,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(
            color: isLow ? AppTheme.red(context).withOpacity(0.3) : borderColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isLow ? AppTheme.red(context) : gold).withOpacity(0.12),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(
                isLow ? Icons.warning_amber_rounded : Icons.bolt_rounded,
                color: isLow ? AppTheme.red(context) : gold,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLow
                        ? 'Almost out of analyses!'
                        : 'Free Analyses Available',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  Text(
                    freeLeft > 0
                        ? '$freeLeft free ${freeLeft == 1 ? 'analysis' : 'analyses'} remaining'
                        : 'No analyses left — tap to subscribe',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary(context)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(Radii.full),
                border: Border.all(color: gold.withOpacity(0.3)),
              ),
              child: Text(
                'Subscribe',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: gold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver Header ─────────────────────────────────────────────────────────

  SliverAppBar _buildSliverHeader(
      Color bgColor, Color borderColor, Color textSecondary) {
    return SliverAppBar(
      backgroundColor: bgColor,
      pinned: true,
      expandedHeight: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
        ),
      ),
      title: Row(
        children: [
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final gold = AppTheme.gold(context);
            final goldSoft =
                isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft;
            final iconBg = isDark ? AppColorsDark.bg : AppColorsLight.bg;
            return Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [gold, goldSoft]),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(Icons.candlestick_chart_rounded,
                  color: iconBg, size: 18),
            );
          }),
          const SizedBox(width: 10),
          Builder(
            builder: (context) => Text(
              'AI Chart Analyzer',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined, color: textSecondary),
          onPressed: () => AdsProvider.getProvider().loadAndShowInterstitialAd((){
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }),
        ),
      ],
    );
  }

  // ── Welcome Card ──────────────────────────────────────────────────────────

  Widget _buildWelcomeCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.gold(context);
    final borderGlow =
        isDark ? AppColorsDark.borderGlow : AppColorsLight.borderGlow;

    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1A1F2E), Color(0xFF0F1520)]
              : const [Color(0xFFFFFFFF), Color(0xFFF0F4FF)],
        ),
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: borderGlow),
        boxShadow: [
          BoxShadow(
              color: gold.withOpacity(0.06),
              blurRadius: 30,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: 4),
            decoration: BoxDecoration(
              color: gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(Radii.full),
              border: Border.all(color: gold.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, color: gold, size: 11),
                const SizedBox(width: 4),
                Text('GPT-4o Vision',
                    style: TextStyle(
                        color: gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: Insets.md),
          Text(
            'Trade Smarter\nwith AI Analysis',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary(context),
                height: 1.2),
          ),
          const SizedBox(height: Insets.sm),
          Text(
            'Upload any chart — Crypto, Forex, or Stocks — and get\ninstant AI-powered technical analysis.',
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary(context),
                height: 1.5),
          ),
          const SizedBox(height: Insets.lg),
          Row(children: [
            _StatChip(label: 'Patterns', icon: Icons.pattern),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('·',
                  style: TextStyle(
                      color: AppTheme.textSecondary(context), fontSize: 14)),
            ),
            _StatChip(label: 'Levels', icon: Icons.horizontal_rule_rounded),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('·',
                  style: TextStyle(
                      color: AppTheme.textSecondary(context), fontSize: 14)),
            ),
            _StatChip(label: 'Signals', icon: Icons.bolt_rounded),
          ]),
        ],
      ),
    );
  }

  // ── Upload Section ────────────────────────────────────────────────────────

  Widget _buildUploadSection(BuildContext context) {
    final gold = AppTheme.gold(context);
    final cardColor = AppTheme.cardColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Analyze a Chart'),
        const SizedBox(height: Insets.md),
        GestureDetector(
          onTap: () => _pickImage(ImageSource.gallery),
          child: Container(
            key: _guideKeyGallery,
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(Radii.xl),
              border: Border.all(color: gold.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_photo_alternate_outlined,
                      color: gold, size: 24),
                ),
                const SizedBox(height: 8),
                Text('Upload Chart from Gallery',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context))),
                const SizedBox(height: 4),
                Text('PNG, JPG supported',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textMuted(context))),
              ],
            ),
          ),
        ),
        const SizedBox(height: Insets.sm),
        SizedBox(
          key: _guidekeyCameraBtn,
          width: double.infinity,
          height: 50,
          child: GradientButton(
            label: 'Capture from Camera',
            icon: Icon(Icons.camera_alt_outlined,
                color: AppTheme.bgColor(context), size: 18),
            onTap: () => _pickImage(ImageSource.camera),
            height: 50,
          ),
        ),
      ],
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Access'),
        const SizedBox(height: Insets.md),
        Row(key: _guideKeyQuickAccess, children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.candlestick_chart_rounded,
              label: 'Live Crypto\nCharts',
              color: AppTheme.emerald(context),
              onTap: () =>
                  AdsProvider.getProvider().loadAndShowInterstitialAd(() {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LiveChartScreen()),
                );
              }),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: _ActionCard(
              icon: Icons.notifications_active_outlined,
              label: 'Price\nAlerts',
              color: AppTheme.gold(context),
              onTap: () =>
                  AdsProvider.getProvider().loadAndShowInterstitialAd(() {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                );
              }),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: _ActionCard(
              icon: Icons.history_rounded,
              label: 'Analysis\nHistory',
              color: AppTheme.blue(context),
              onTap: () =>
                  AdsProvider.getProvider().loadAndShowInterstitialAd(() {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              }),
            ),
          ),
        ]),
      ],
    );
  }
}

// ── Sub Widgets ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textSecondary(context)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}
