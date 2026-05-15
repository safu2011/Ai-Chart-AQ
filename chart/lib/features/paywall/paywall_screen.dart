import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../providers.dart';

/// Full-screen paywall shown when the user has no credits left.
/// Displays the monthly Pro subscription and all three credit packs.
class PaywallScreen extends StatefulWidget {
  /// If true, the paywall is presented as a modal bottom sheet flow
  /// rather than a full pushed route.
  final bool isModal;

  const PaywallScreen({super.key, this.isModal = false});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().loadOfferings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subProv   = context.watch<SubscriptionProvider>();
    final isDark    = context.watch<ThemeProvider>().isDark;
    final gold      = AppTheme.gold(context);
    final bgColor   = AppTheme.bgColor(context);
    final textPrimary    = AppTheme.textPrimary(context);
    final textSecondary  = AppTheme.textSecondary(context);
    final textMuted      = AppTheme.textMuted(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppTopBar(
        title: 'Get More Analyses',
        showBack: !subProv.isLoading,
      ),
      body: subProv.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(Insets.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(context, isDark, gold, bgColor, textPrimary, textSecondary),
                  const SizedBox(height: Insets.lg),
                  _buildProSubscriptionCard(context, subProv, gold, isDark),
                  const SizedBox(height: Insets.lg),
                  SectionHeader(title: 'Credit Packs'),
                  const SizedBox(height: Insets.md),
                  _buildCreditPacks(context, subProv, gold, isDark),
                  const SizedBox(height: Insets.lg),
                  _buildRestoreButton(context, subProv, textMuted),
                  const SizedBox(height: Insets.sm),
                  Center(
                    child: Text(
                      'Credits never expire • Secure payment via ${_storeName()}',
                      style: TextStyle(fontSize: 11, color: textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: Insets.xl),
                ],
              ),
            ),
    );
  }

  // ── Hero Card ─────────────────────────────────────────────────────────────

  Widget _buildHeroCard(BuildContext ctx, bool isDark, Color gold,
      Color bgColor, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
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
        border: Border.all(
          color: gold.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.08),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gold, isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft],
                  ),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: bgColor, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You\'ve used all free analyses',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                  Text('${AppConstants.freeAnalysesPerDay} free per day',
                      style: TextStyle(fontSize: 12, color: textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeatureChip(icon: Icons.all_inclusive_rounded, label: 'Unlimited with Pro'),
              _FeatureChip(icon: Icons.bolt_rounded, label: 'Instant Analysis'),
              _FeatureChip(icon: Icons.history_rounded, label: 'Full History'),
              _FeatureChip(icon: Icons.notifications_none_rounded, label: 'Price Alerts'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pro Subscription Card ─────────────────────────────────────────────────

  Widget _buildProSubscriptionCard(BuildContext ctx, SubscriptionProvider subProv,
      Color gold, bool isDark) {
    final offerings = subProv.offerings;
    Package? monthly;

    if (offerings != null) {
      final current = offerings.current;
      if (current != null) {
        monthly = current.monthly;
      }
    }

    return GlassCard(
      borderColor: gold.withOpacity(0.4),
      padding: const EdgeInsets.all(Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gold, isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft],
                  ),
                  borderRadius: BorderRadius.circular(Radii.full),
                ),
                child: Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800,
                    color: isDark ? AppColorsDark.bg : Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                monthly?.storeProduct.priceString ?? '\$4.99',
                style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w900, color: gold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/month',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary(ctx))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pro Subscription — Unlimited Analyses',
            style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(ctx),
            ),
          ),
          const SizedBox(height: 8),
          ...[
            '✓  Unlimited AI chart analyses',
            '✓  No daily limits — ever',
            '✓  Price alert notifications',
            '✓  Ad-free experience',
            '✓  Cancel anytime',
          ].map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(f, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(ctx), height: 1.5)),
          )),
          const SizedBox(height: Insets.md),
          GradientButton(
            label: subProv.isLoading ? 'Processing...' : 'Start Pro — ${monthly?.storeProduct.priceString ?? '\$4.99'}/mo',
            onTap: monthly != null && !subProv.isLoading
                ? () => _purchase(ctx, subProv, monthly!)
                : null,
            height: 50,
          ),
        ],
      ),
    );
  }

  // ── Credit Packs ──────────────────────────────────────────────────────────

  Widget _buildCreditPacks(BuildContext ctx, SubscriptionProvider subProv,
      Color gold, bool isDark) {
    final offerings = subProv.offerings;
    final current = offerings?.current;

    final packs = [
      _PackInfo(
        id: AppConstants.rcPack10Id,
        credits: AppConstants.creditsInPack10,
        label: '10 Credits',
        price: '\$0.99',
        perCredit: '10¢ each',
        icon: Icons.bolt_rounded,
        color: AppTheme.blue(ctx),
      ),
      _PackInfo(
        id: AppConstants.rcPack50Id,
        credits: AppConstants.creditsInPack50,
        label: '50 Credits',
        price: '\$3.99',
        perCredit: '8¢ each',
        icon: Icons.stars_rounded,
        color: gold,
        badge: 'SAVE 20%',
      ),
      _PackInfo(
        id: AppConstants.rcPack200Id,
        credits: AppConstants.creditsInPack200,
        label: '200 Credits',
        price: '\$9.99',
        perCredit: '5¢ each',
        icon: Icons.workspace_premium_rounded,
        color: AppTheme.emerald(ctx),
        badge: 'BEST VALUE',
      ),
    ];

    return Column(
      children: packs.map((pack) {
        Package? pkg;
        if (current != null) {
          try {
            pkg = current.availablePackages
                .firstWhere((p) => p.storeProduct.identifier == pack.id);
          } catch (_) {
            pkg = null;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: Insets.sm),
          child: _CreditPackTile(
            pack: pack,
            pkg: pkg,
            isLoading: subProv.isLoading,
            onBuy: (p) => _purchase(ctx, subProv, p),
          ),
        );
      }).toList(),
    );
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  Widget _buildRestoreButton(BuildContext ctx, SubscriptionProvider subProv,
      Color textMuted) {
    return Center(
      child: TextButton(
        onPressed: subProv.isLoading ? null : () => _restore(ctx, subProv),
        child: Text(
          'Restore Purchases',
          style: TextStyle(
            fontSize: 13,
            color: textMuted,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _purchase(BuildContext ctx, SubscriptionProvider subProv, Package pkg) async {
    try {
      await subProv.purchasePackage(pkg);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Purchase successful! 🎉')),
        );
        Navigator.of(ctx).pop(true);
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(_purchaseError(e))),
        );
      }
    }
  }

  Future<void> _restore(BuildContext ctx, SubscriptionProvider subProv) async {
    try {
      await subProv.restorePurchases();
      if (ctx.mounted) {
        final isPro = subProv.isPro;
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(isPro
                ? 'Pro subscription restored! ✓'
                : 'No previous purchases found.'),
          ),
        );
        if (isPro) Navigator.of(ctx).pop(true);
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Restore failed: ${e.toString()}')),
        );
      }
    }
  }

  String _purchaseError(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains('cancelled') || str.contains('cancel')) {
      return 'Purchase cancelled.';
    }
    if (str.contains('network')) return 'Network error. Please try again.';
    return 'Purchase failed. Please try again.';
  }

  String _storeName() {
    try {
      // Checking platform without dart:io to keep widget layer clean
      return 'App Store / Google Play';
    } catch (_) {
      return 'App Store / Google Play';
    }
  }
}

// ── Internal Widgets ──────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.neutral(context),
        borderRadius: BorderRadius.circular(Radii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.gold(context)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))),
        ],
      ),
    );
  }
}

class _PackInfo {
  final String id;
  final int credits;
  final String label;
  final String price;
  final String perCredit;
  final IconData icon;
  final Color color;
  final String? badge;

  const _PackInfo({
    required this.id,
    required this.credits,
    required this.label,
    required this.price,
    required this.perCredit,
    required this.icon,
    required this.color,
    this.badge,
  });
}

class _CreditPackTile extends StatelessWidget {
  final _PackInfo pack;
  final Package? pkg;
  final bool isLoading;
  final void Function(Package) onBuy;

  const _CreditPackTile({
    required this.pack,
    required this.pkg,
    required this.isLoading,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final priceStr = pkg?.storeProduct.priceString ?? pack.price;

    return GlassCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: pack.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(pack.icon, color: pack.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(pack.label,
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context),
                        )),
                    if (pack.badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: pack.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(Radii.full),
                        ),
                        child: Text(pack.badge!,
                            style: TextStyle(
                              fontSize: 8, fontWeight: FontWeight.w800,
                              color: pack.color, letterSpacing: 0.5,
                            )),
                      ),
                    ],
                  ],
                ),
                Text(pack.perCredit,
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: pkg != null && !isLoading ? () => onBuy(pkg!) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [pack.color, pack.color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(Radii.full),
              ),
              child: Text(
                priceStr,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
