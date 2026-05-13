import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/history_repository.dart';
import '../../../widgets/shared_widgets.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  bool _apiKeyObscured = true;
  final TextEditingController _apiKeyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInfo();
    final key = ref.read(apiKeyProvider);
    _apiKeyCtrl.text = key;
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const AppTopBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(Insets.md),
        children: [
          // ── API Configuration ──────────────────────────────────────
          const SectionHeader(title: 'API Configuration'),
          const SizedBox(height: Insets.sm),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OpenAI API Key',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiKeyCtrl,
                  obscureText: _apiKeyObscured,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'sk-...',
                    hintStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.neutral,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(Radii.md),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(Radii.md),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(Radii.md),
                      borderSide:
                          const BorderSide(color: AppColors.gold),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _apiKeyObscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      onPressed: () => setState(
                          () => _apiKeyObscured = !_apiKeyObscured),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GradientButton(
                  label: 'Save API Key',
                  height: 42,
                  onTap: () {
                    ref
                        .read(apiKeyProvider.notifier)
                        .save(_apiKeyCtrl.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('API key saved'),
                        backgroundColor: AppColors.card,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your key is stored locally on-device only and never sent anywhere except directly to OpenAI.',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: Insets.lg),

          // ── Appearance ──────────────────────────────────────────────
          const SectionHeader(title: 'Appearance'),
          const SizedBox(height: Insets.sm),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: isDark ? 'Currently dark' : 'Currently light',
            trailing: Switch(
              value: isDark,
              onChanged: (_) =>
                  ref.read(themeModeProvider.notifier).toggle(),
              activeColor: AppColors.gold,
              inactiveTrackColor: AppColors.card,
            ),
          ),

          const SizedBox(height: Insets.lg),

          // ── Data ────────────────────────────────────────────────────
          const SectionHeader(title: 'Data'),
          const SizedBox(height: Insets.sm),
          _SettingsTile(
            icon: Icons.delete_outline_rounded,
            title: 'Clear Analysis History',
            subtitle: 'Remove all saved analyses',
            iconColor: AppColors.red,
            onTap: () => _clearHistory(context),
          ),

          const SizedBox(height: Insets.lg),

          // ── Disclaimer / About ──────────────────────────────────────
          const SectionHeader(title: 'About'),
          const SizedBox(height: Insets.sm),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.gold, AppColors.goldSoft]),
                        borderRadius:
                            BorderRadius.circular(Radii.sm),
                      ),
                      child: const Icon(
                          Icons.candlestick_chart_rounded,
                          color: AppColors.bg,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(AppConstants.appName,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        Text('Version $_version',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: Insets.md),
                const Divider(color: AppColors.border),
                const SizedBox(height: Insets.sm),
                const Text(
                  'DISCLAIMER',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppConstants.disclaimer,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.6),
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
            'All saved analyses will be permanently deleted.',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History cleared'),
            backgroundColor: AppColors.card,
          ),
        );
      }
    }
  }
}

// ─── Settings Tile ────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.gold).withOpacity(0.1),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(icon,
                  color: iconColor ?? AppColors.gold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
