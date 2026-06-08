import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/history_repository.dart';
import '../../../widgets/shared_widgets.dart';
import '../../onboarding/user_guide_overlay.dart';
import '../../paywall/paywall_screen.dart';
import '../../providers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().refresh();
    });
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final isDark        = context.watch<ThemeProvider>().isDark;
    final subProv       = context.watch<SubscriptionProvider>();
    final bgColor       = AppTheme.bgColor(context);
    final cardColor     = AppTheme.cardColor(context);
    final borderColor   = AppTheme.borderColor(context);
    final textPrimary   = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    final textMuted     = AppTheme.textMuted(context);
    final gold          = AppTheme.gold(context);
    final goldSoft      = isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft;
    final red           = AppTheme.red(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppTopBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(Insets.md),
        children: [

          // ── Subscription ─────────────────────────────────────────────────
          _SectionHeader(title: 'Subscription', textMuted: textMuted),
          const SizedBox(height: Insets.sm),
          _buildSubscriptionCard(context, subProv, gold, goldSoft, isDark,
              cardColor, borderColor, textPrimary, textSecondary, textMuted),

          const SizedBox(height: Insets.lg),

          // ── Appearance ───────────────────────────────────────────────────
          _SectionHeader(title: 'Appearance', textMuted: textMuted),
          const SizedBox(height: Insets.sm),
          _SettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'Dark Mode',
            subtitle: isDark ? 'Currently dark' : 'Currently light',
            iconColor: gold,
            cardColor: cardColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textMuted: textMuted,
            trailing: Switch(
              value: isDark,
              onChanged: (_) => context.read<ThemeProvider>().toggle(),
              activeColor: gold,
              thumbColor: WidgetStateProperty.all(Colors.white),
            ),
          ),

          const SizedBox(height: Insets.lg),

          // ── Data ─────────────────────────────────────────────────────────
          _SectionHeader(title: 'Data', textMuted: textMuted),
          const SizedBox(height: Insets.sm),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'View App Guide',
            subtitle: 'See how to analyse charts with AI',
            iconColor: gold,
            cardColor: cardColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textMuted: textMuted,
            onTap: () => _showGuide(context),
          ),
          const SizedBox(height: Insets.sm),
          _SettingsTile(
            icon: Icons.delete_outline_rounded,
            title: 'Clear Analysis History',
            subtitle: 'Remove all saved analyses',
            iconColor: red,
            cardColor: cardColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textMuted: textMuted,
            onTap: () => _clearHistory(context),
          ),

          const SizedBox(height: Insets.lg),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(title: 'About', textMuted: textMuted),
          const SizedBox(height: Insets.sm),
          Container(
            padding: const EdgeInsets.all(Insets.md),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [gold, goldSoft]),
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Icon(Icons.candlestick_chart_rounded,
                          color: isDark ? AppColorsDark.bg : AppColorsLight.bg, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppConstants.appName,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                        Text('Version $_version',
                            style: TextStyle(fontSize: 11, color: textMuted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: Insets.md),
                Divider(color: borderColor),
                const SizedBox(height: Insets.sm),
                Text('DISCLAIMER',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textMuted, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(AppConstants.disclaimer,
                    style: TextStyle(fontSize: 12, color: textSecondary, height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
        ],
      ),
    );
  }

  // ── Subscription Card ─────────────────────────────────────────────────────

  Widget _buildSubscriptionCard(
    BuildContext context,
    SubscriptionProvider subProv,
    Color gold, Color goldSoft, bool isDark,
    Color cardColor, Color borderColor,
    Color textPrimary, Color textSecondary, Color textMuted,
  ) {
    if (subProv.isPro) {
      return Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gold.withOpacity(0.15), gold.withOpacity(0.04)],
          ),
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: gold.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [gold, goldSoft]),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Icon(Icons.workspace_premium_rounded,
                  color: isDark ? AppColorsDark.bg : Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pro Subscriber',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                  Text('Unlimited analyses • Ad-free',
                      style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(Radii.full),
              ),
              child: Text('ACTIVE',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: gold, letterSpacing: 1)),
            ),
          ],
        ),
      );
    }

    // Free user — show credit balance + upgrade CTA
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(Insets.md),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Icon(Icons.bolt_rounded, color: gold, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Free Plan',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                        Text('${subProv.freeRemaining} free credits • ${subProv.paidCredits} paid credits',
                            style: TextStyle(fontSize: 11, color: textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Usage bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Free daily analyses used',
                          style: TextStyle(fontSize: 10, color: textMuted)),
                      Text('${AppConstants.freeAnalysesPerDay - subProv.freeRemaining}/${AppConstants.freeAnalysesPerDay}',
                          style: TextStyle(fontSize: 10, color: textMuted)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (AppConstants.freeAnalysesPerDay - subProv.freeRemaining) /
                          AppConstants.freeAnalysesPerDay,
                      minHeight: 6,
                      backgroundColor: AppTheme.neutral(context),
                      valueColor: AlwaysStoppedAnimation(gold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GradientButton(
                label: 'Upgrade to Pro',
                icon: Icon(Icons.workspace_premium_rounded,
                    color: isDark ? AppColorsDark.bg : AppColorsLight.bg, size: 16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                ),
                height: 44,
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.sm),
        _SettingsTile(
          icon: Icons.restore_rounded,
          title: 'Restore Purchases',
          subtitle: 'Recover your Pro subscription',
          iconColor: AppTheme.blue(context),
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textMuted: textMuted,
          onTap: () => _restorePurchases(context, subProv),
        ),
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _showGuide(BuildContext context) async {
    // Reset guide shown flag so it re-shows on next navigation
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guide_shown', false);
    if (!mounted) return;
    Navigator.of(context).pop(); // Close settings
    // The splash → home flow will show guide since guide_shown is reset.
    // For a direct in-place show, push a modal overlay instead:
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => _InlineGuideDialog(onDone: () {
        SharedPreferences.getInstance()
            .then((p) => p.setBool('guide_shown', true));
      }),
    );
  }

  Future<void> _clearHistory(BuildContext context) async {
    final isDark    = context.read<ThemeProvider>().isDark;
    final cardColor = AppTheme.cardColor(context);
    final tp        = AppTheme.textPrimary(context);
    final ts        = AppTheme.textSecondary(context);
    final red       = AppTheme.red(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
        title: Text('Clear All History?', style: TextStyle(color: tp, fontSize: 16)),
        content: Text('All saved analyses will be permanently deleted.',
            style: TextStyle(color: ts, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: ts)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await HistoryRepository.instance.clearAll();
      await context.read<HistoryProvider>().load();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('History cleared',
                style: TextStyle(
                    color: isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary)),
            backgroundColor: isDark ? AppColorsDark.cardElevated : AppColorsLight.cardElevated,
          ),
        );
      }
    }
  }

  Future<void> _restorePurchases(BuildContext context, SubscriptionProvider subProv) async {
    try {
      await subProv.restorePurchases();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(subProv.isPro
                ? 'Pro subscription restored! ✓'
                : 'No previous purchases found.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: ${e.toString()}')),
        );
      }
    }
  }
}

// ── Sub Widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textMuted;
  const _SectionHeader({required this.title, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textMuted, letterSpacing: 1),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textMuted;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textMuted,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppTheme.gold(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: textMuted)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              Icon(Icons.chevron_right_rounded, color: textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Simple full-screen dialog that shows the user guide
class _InlineGuideDialog extends StatelessWidget {
  final VoidCallback onDone;
  const _InlineGuideDialog({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: _UserGuideOverlayStandalone(onDismiss: () {
        onDone();
        Navigator.of(context).pop();
      }),
    );
  }
}

/// Standalone version of the user guide overlay (without needing HomeScreen behind it)
class _UserGuideOverlayStandalone extends StatefulWidget {
  final VoidCallback onDismiss;
  const _UserGuideOverlayStandalone({required this.onDismiss});

  @override
  State<_UserGuideOverlayStandalone> createState() =>
      _UserGuideOverlayStandaloneState();
}

class _UserGuideOverlayStandaloneState
    extends State<_UserGuideOverlayStandalone>
    with TickerProviderStateMixin {
  int _step = 0;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _slideFade;

  late AnimationController _arrowCtrl;
  late Animation<Offset> _arrowAnim;

  static const _steps = [
    _GuideInfo(
      title: 'Upload a Chart Image',
      description:
          'Tap "Upload Chart from Gallery" to pick any crypto, forex, or stock chart image from your gallery. PNG and JPG files are supported.',
      icon: Icons.add_photo_alternate_outlined,
    ),
    _GuideInfo(
      title: 'Or Capture Live',
      description:
          'Tap "Capture from Camera" to photograph a chart from your screen, then analyze it instantly with AI.',
      icon: Icons.camera_alt_outlined,
    ),
    _GuideInfo(
      title: 'Browse All Crypto Pairs',
      description:
          'In Live Crypto Charts, all USDT pairs from Binance are available. Search any coin by symbol — BTC, SOL, PEPE, and many more.',
      icon: Icons.candlestick_chart_rounded,
    ),
    _GuideInfo(
      title: 'Analyze Any Chart',
      description:
          'On any live chart, tap "Analyze Chart" to run GPT-4o Vision analysis. Results are saved to Analysis History automatically.',
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideFade = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slideCtrl.forward();

    _arrowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _arrowAnim =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.3)).animate(
            CurvedAnimation(parent: _arrowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _arrowCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _steps.length - 1) {
      _slideCtrl.reset();
      setState(() => _step++);
      _slideCtrl.forward();
    } else {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final gold = isDark ? AppColorsDark.gold : AppColorsLight.gold;
    final goldSoft = isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft;
    final bg = isDark ? AppColorsDark.bg : AppColorsLight.bg;
    final card = isDark ? AppColorsDark.card : AppColorsLight.card;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
    final step = _steps[_step];

    return Stack(
      children: [
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.8))),
        Center(
          child: SlideTransition(
            position: _arrowAnim,
            child: Icon(Icons.touch_app_rounded, color: gold, size: 64),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 60,
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _slideFade,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: gold.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient:
                                LinearGradient(colors: [gold, goldSoft]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(step.icon, color: bg, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textPrimary),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onDismiss,
                          child: Text('Close',
                              style: TextStyle(
                                  fontSize: 13, color: textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(step.description,
                        style: TextStyle(
                            fontSize: 14, color: textSecondary, height: 1.55)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            _steps.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: i == _step ? 20 : 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: i == _step
                                    ? gold
                                    : gold.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _next,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient:
                                  LinearGradient(colors: [gold, goldSoft]),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                    color: gold.withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Text(
                              _step == _steps.length - 1 ? 'Done' : 'Next',
                              style: TextStyle(
                                  color: bg,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideInfo {
  final String title;
  final String description;
  final IconData icon;
  const _GuideInfo(
      {required this.title, required this.description, required this.icon});
}
