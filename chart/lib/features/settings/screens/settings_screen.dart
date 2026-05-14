import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/history_repository.dart';
import '../../../widgets/shared_widgets.dart';
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
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bgColor = AppTheme.bgColor(context);
    final cardColor = AppTheme.cardColor(context);
    final borderColor = AppTheme.borderColor(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    final textMuted = AppTheme.textMuted(context);
    final gold = AppTheme.gold(context);
    final neutral = AppTheme.neutral(context);
    final goldSoft = isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft;
    final red = AppTheme.red(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppTopBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(Insets.md),
        children: [
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
          _SectionHeader(title: 'Data', textMuted: textMuted),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [gold, goldSoft]),
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Icon(
                        Icons.candlestick_chart_rounded,
                        color: isDark ? AppColorsDark.bg : AppColorsLight.bg,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Version $_version',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: Insets.md),
                Divider(color: borderColor),
                const SizedBox(height: Insets.sm),
                Text(
                  'DISCLAIMER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppConstants.disclaimer,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
        ],
      ),
    );
  }

  Future<void> _clearHistory(BuildContext context) async {
    final isDark = context.read<ThemeProvider>().isDark;
    final cardColor = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    final red = AppTheme.red(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg)),
        title: Text('Clear All History?',
            style: TextStyle(color: textPrimary, fontSize: 16)),
        content: Text(
          'All saved analyses will be permanently deleted.',
          style: TextStyle(color: textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
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
            content: Text(
              'History cleared',
              style: TextStyle(
                  color: isDark
                      ? AppColorsDark.textPrimary
                      : AppColorsLight.textPrimary),
            ),
            backgroundColor: isDark
                ? AppColorsDark.cardElevated
                : AppColorsLight.cardElevated,
          ),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textMuted;
  const _SectionHeader({required this.title, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: textMuted,
        letterSpacing: 1,
      ),
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
              width: 36,
              height: 36,
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
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                  Text(subtitle,
                      style: TextStyle(fontSize: 11, color: textMuted)),
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
