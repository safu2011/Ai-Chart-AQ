import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../analysis/screens/image_preview_screen.dart';
import '../../charts/screens/live_chart_screen.dart';

import '../../history/screens/history_screen.dart';
import '../../settings/screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              _buildSliverHeader(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Insets.md, vertical: Insets.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildWelcomeCard(),
                    const SizedBox(height: Insets.lg),
                    _buildUploadSection(),
                    const SizedBox(height: Insets.lg),
                    _buildQuickActionsSection(),
                    const SizedBox(height: Insets.lg),
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
    );
  }

  SliverAppBar _buildSliverHeader() {
    return SliverAppBar(
      backgroundColor: AppColors.bg,
      pinned: true,
      expandedHeight: 0,
      toolbarHeight: 60,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.goldSoft],
              ),
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: const Icon(Icons.candlestick_chart_rounded,
                color: AppColors.bg, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'AI Chart Analyzer',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F2E), Color(0xFF0F1520)],
        ),
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: AppColors.borderGlow),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Insets.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(Radii.full),
                  border:
                      Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: AppColors.gold, size: 11),
                    SizedBox(width: 4),
                    Text(
                      'GPT-4o Vision',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          const Text(
            'Trade Smarter\nwith AI Analysis',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: Insets.sm),
          const Text(
            'Upload any chart — Crypto, Forex, or Stocks — and get\ninstant AI-powered technical analysis.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: Insets.lg),
          Row(
            children: [
              _StatChip(label: 'Patterns', icon: Icons.pattern),
              const SizedBox(width: 8),
              _StatChip(label: 'Levels', icon: Icons.horizontal_rule_rounded),
              const SizedBox(width: 8),
              _StatChip(label: 'Signals', icon: Icons.bolt_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Analyze a Chart'),
        const SizedBox(height: Insets.md),
        // Gallery upload — large dashed tap area
        GestureDetector(
          onTap: () => _pickImage(ImageSource.gallery),
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(Radii.xl),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.3),
                width: 1.5,
                // dashed effect approximated via style
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.gold, size: 24),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload Chart from Gallery',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PNG, JPG supported',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Insets.sm),
        // Camera button
        GradientButton(
          label: 'Capture from Camera',
          icon: const Icon(Icons.camera_alt_outlined,
              color: AppColors.bg, size: 18),
          onTap: () => _pickImage(ImageSource.camera),
          height: 50,
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Access'),
        const SizedBox(height: Insets.md),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.candlestick_chart_rounded,
                label: 'Live Crypto\nCharts',
                color: AppColors.emerald,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const LiveChartScreen()),
                ),
              ),
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: _ActionCard(
                icon: Icons.history_rounded,
                label: 'Analysis\nHistory',
                color: AppColors.blue,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const HistoryScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.circular(Radii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
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
          color: AppColors.card,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: AppColors.border),
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
