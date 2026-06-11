import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/history_repository.dart';
import '../../../widgets/shared_widgets.dart';
import '../../home/screens/home_screen.dart';
import '../../onboarding/user_guide_overlay.dart';
import '../../paywall/paywall_screen.dart';
import '../../providers.dart';
import '../../rating/rating_dialog.dart';

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
            icon: Icons.star_outline_rounded,
            title: 'Rate Us',
            subtitle: 'Enjoying the app? Leave us a review',
            iconColor: gold,
            cardColor: cardColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textMuted: textMuted,
            onTap: () => RatingDialogHelper.show(context),
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
    // Pop settings, then push the real HomeScreenWithGuide overlay
    // (same experience as first-launch, but without the paywall on dismiss)
    Navigator.pop(context);
    if (!mounted) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: const HomeScreenWithGuide(showPaywallOnDismiss: false),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
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

