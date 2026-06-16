import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../providers.dart';
import '../../services/subscription_service.dart';
class PaywallScreen extends StatefulWidget {
  final bool isModal;
  const PaywallScreen({super.key, this.isModal = false});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  // Which plan card is tapped/selected for purchase
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SubscriptionProvider>().loadOfferings();
      _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sub     = context.watch<SubscriptionProvider>();
    final isDark  = context.watch<ThemeProvider>().isDark;
    final gold    = AppTheme.gold(context);
    final bg      = AppTheme.bgColor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppTopBar(
        title: 'Pro Subscription',
        showBack: !sub.isLoading,
      ),
      body: sub.isLoading && sub.offerings == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              Insets.md, Insets.sm, Insets.md, Insets.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroHeader(isDark: isDark, gold: gold),
              const SizedBox(height: Insets.md),
              _CreditInfoBanner(sub: sub, gold: gold, isDark: isDark),
              const SizedBox(height: Insets.lg),
              _buildPlanCards(context, sub, gold, isDark),
              const SizedBox(height: Insets.lg),
              _FeatureList(gold: gold),
              const SizedBox(height: Insets.lg),
              _buildRestoreButton(context, sub),
              const SizedBox(height: Insets.sm),
              _buildFootnote(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Plan Cards ────────────────────────────────────────────────────────────

  Widget _buildPlanCards(BuildContext ctx, SubscriptionProvider sub,
      Color gold, bool isDark) {
    final offerings = sub.offerings;
    // Use the "pro" offering by id, fallback to current
    final offering = offerings?.getOffering(AppConstants.rcOfferingId)
        ?? offerings?.current;

    if (offering == null) {
      return Center(
        child: Text(
          'Unable to load plans. Please check your connection.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted(ctx), fontSize: 14),
        ),
      );
    }

    // Extract weekly, monthly, yearly packages from the offering
    final pkgWeekly  = _findPackage(offering, AppConstants.rcWeeklySubId);
    final pkgMonthly = _findPackage(offering, AppConstants.rcMonthlySubId);
    final pkgYearly  = _findPackage(offering, AppConstants.rcYearlySubId);

    // Compute yearly savings vs monthly (annualised)
    String? yearlySavingsLabel;
    if (pkgMonthly != null && pkgYearly != null) {
      final monthlyAnnual = pkgMonthly.storeProduct.price * 12;
      final yearlyPrice   = pkgYearly.storeProduct.price;
      if (monthlyAnnual > yearlyPrice) {
        final savePct = ((monthlyAnnual - yearlyPrice) / monthlyAnnual * 100)
            .round();
        yearlySavingsLabel = 'SAVE $savePct%';
      }
    }

    return Column(
      children: [
        if (pkgWeekly != null)
          _PlanCard(
            pkg: pkgWeekly,
            planId: AppConstants.rcWeeklySubId,
            title: 'Weekly',
            subtitle: 'per week',
            creditsPerCycle: AppConstants.weeklyCreditsPerCycle,
            analysesPerCycle: (AppConstants.weeklyCreditsPerCycle /
                AppConstants.creditsPerAnalysis)
                .floor(),
            cycleLabel: 'week',
            activeTier: sub.activeTier,
            targetTier: SubscriptionTier.weekly,
            selectedPlanId: _selectedPlanId,
            isLoading: sub.isLoading,
            gold: gold,
            isDark: isDark,
            onSelect: (id) => setState(() => _selectedPlanId = id),
            onSubscribe: () => _subscribe(ctx, sub, pkgWeekly),
          ),
        const SizedBox(height: Insets.sm),
        if (pkgMonthly != null)
          _PlanCard(
            pkg: pkgMonthly,
            planId: AppConstants.rcMonthlySubId,
            title: 'Monthly',
            subtitle: 'per month',
            creditsPerCycle: AppConstants.monthlyCreditsPerCycle,
            analysesPerCycle: (AppConstants.monthlyCreditsPerCycle /
                AppConstants.creditsPerAnalysis)
                .floor(),
            cycleLabel: 'month',
            activeTier: sub.activeTier,
            targetTier: SubscriptionTier.monthly,
            selectedPlanId: _selectedPlanId,
            isLoading: sub.isLoading,
            gold: gold,
            isDark: isDark,
            badge: 'POPULAR',
            onSelect: (id) => setState(() => _selectedPlanId = id),
            onSubscribe: () => _subscribe(ctx, sub, pkgMonthly),
          ),
        const SizedBox(height: Insets.sm),
        if (pkgYearly != null)
          _PlanCard(
            pkg: pkgYearly,
            planId: AppConstants.rcYearlySubId,
            title: 'Yearly',
            subtitle: 'per year',
            creditsPerCycle: AppConstants.yearlyCreditsPerCycle,
            analysesPerCycle: (AppConstants.yearlyCreditsPerCycle /
                AppConstants.creditsPerAnalysis)
                .floor(),
            cycleLabel: 'year',
            activeTier: sub.activeTier,
            targetTier: SubscriptionTier.yearly,
            selectedPlanId: _selectedPlanId,
            isLoading: sub.isLoading,
            gold: gold,
            isDark: isDark,
            badge: yearlySavingsLabel ?? 'BEST VALUE',
            onSelect: (id) => setState(() => _selectedPlanId = id),
            onSubscribe: () => _subscribe(ctx, sub, pkgYearly),
          ),
      ],
    );
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  Widget _buildRestoreButton(BuildContext ctx, SubscriptionProvider sub) {
    return Center(
      child: TextButton(
        onPressed: sub.isLoading ? null : () => _restore(ctx, sub),
        child: Text(
          'Restore Purchases',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted(ctx),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildFootnote(BuildContext ctx) {
    return Text(
      'Subscriptions auto-renew. Cancel anytime via the Play Store / App Store. '
          '1 analysis = ${AppConstants.creditsPerAnalysis} credits '
          '(${AppConstants.creditsPerAnalysis} API hits). Secure payment via Google Play / App Store.',
      style: TextStyle(fontSize: 10, color: AppTheme.textMuted(ctx), height: 1.5),
      textAlign: TextAlign.center,
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _subscribe(
      BuildContext ctx, SubscriptionProvider sub, Package pkg) async {
    final isUpgrade   = sub.activeTier != SubscriptionTier.none;
    final actionLabel = isUpgrade ? 'Plan changed' : 'Subscribed';
    try {
      await sub.purchasePackage(pkg);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('$actionLabel successfully! 🎉')),
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

  Future<void> _restore(BuildContext ctx, SubscriptionProvider sub) async {
    try {
      await sub.restorePurchases();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(sub.isPro
                ? 'Subscription restored! ✓'
                : 'No active subscription found.'),
          ),
        );
        if (sub.isPro) Navigator.of(ctx).pop(true);
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Finds a package by matching [productId] in available packages.
  Package? _findPackage(Offering offering, String productId) {
    try {
      return offering.availablePackages.firstWhere(
            (p) => p.storeProduct.identifier == productId,
      );
    } catch (_) {
      return null;
    }
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final bool isDark;
  final Color gold;
  const _HeroHeader({required this.isDark, required this.gold});

  @override
  Widget build(BuildContext context) {
    final textPrimary   = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

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
        border: Border.all(color: gold.withOpacity(0.3), width: 1.5),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gold,
                      isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft],
                  ),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.bgColor(context), size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unlock Pro Analysis',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
                  Text('Subscribe to get analysis credits',
                      style: TextStyle(fontSize: 12, color: textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: const [
              _FeatureBenefit(icon: Icons.bolt_rounded,label: 'Instant AI Analysis'),
              _FeatureBenefit(icon: Icons.history_rounded,label: 'Full History'),
              _FeatureBenefit(icon: Icons.notifications_none_rounded,label: 'Price Alerts'),
              _FeatureBenefit(icon: Icons.block_rounded,label: 'Ad-Free'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Credit Info Banner ───────────────────────────────────────────────────────

class _CreditInfoBanner extends StatelessWidget {
  final SubscriptionProvider sub;
  final Color gold;
  final bool isDark;

  const _CreditInfoBanner({
    required this.sub,
    required this.gold,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Insets.md, vertical: Insets.sm + 2),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: gold.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How credits work',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '•  1 analysis = ${AppConstants.creditsPerAnalysis} credit\n'
                      '•  Credits reset each billing cycle\n'
                      '•  Unused credits do not carry over',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary(context),
                    height: 1.4,
                  ),
                ),
                if (sub.isPro) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${sub.subscriptionCredits} credits remaining  '
                        '(${sub.analysesAvailable} analyses)  •  ${sub.tierLabel}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: gold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Plan Card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final Package pkg;
  final String planId;
  final String title;
  final String subtitle;
  final int creditsPerCycle;
  final int analysesPerCycle;
  final String cycleLabel;
  final SubscriptionTier activeTier;
  final SubscriptionTier targetTier;
  final String? selectedPlanId;
  final bool isLoading;
  final Color gold;
  final bool isDark;
  final String? badge;
  final void Function(String) onSelect;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.pkg,
    required this.planId,
    required this.title,
    required this.subtitle,
    required this.creditsPerCycle,
    required this.analysesPerCycle,
    required this.cycleLabel,
    required this.activeTier,
    required this.targetTier,
    required this.selectedPlanId,
    required this.isLoading,
    required this.gold,
    required this.isDark,
    required this.onSelect,
    required this.onSubscribe,
    this.badge,
  });

  bool get isActive   => activeTier == targetTier;
  bool get isSelected => selectedPlanId == planId;

  /// Whether subscribing to this plan from the current plan is an upgrade.
  bool get isUpgrade {
    if (activeTier == SubscriptionTier.none) return false;
    // weekly < monthly < yearly in value
    final currentRank = _tierRank(activeTier);
    final targetRank  = _tierRank(targetTier);
    return targetRank > currentRank;
  }

  bool get isDowngrade {
    if (activeTier == SubscriptionTier.none) return false;
    return _tierRank(targetTier) < _tierRank(activeTier);
  }

  static int _tierRank(SubscriptionTier t) {
    switch (t) {
      case SubscriptionTier.none:    return 0;
      case SubscriptionTier.weekly:  return 1;
      case SubscriptionTier.monthly: return 2;
      case SubscriptionTier.yearly:  return 3;
    }
  }

  String _ctaLabel() {
    if (isActive)     return '✓  Current Plan';
    if (isUpgrade)    return 'Upgrade to $title';
    if (isDowngrade)  return 'Downgrade to $title';
    return 'Subscribe — $title';
  }

  Color _borderColor() {
    if (isActive)    return gold;
    if (isSelected)  return gold.withOpacity(0.6);
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary   = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    final textMuted     = AppTheme.textMuted(context);
    final bg            = AppTheme.bgColor(context);

    return GestureDetector(
      onTap: isActive ? null : () => onSelect(planId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark
              ? (isActive
              ? const Color(0xFF1E2435)
              : isSelected
              ? const Color(0xFF181D2C)
              : const Color(0xFF141821))
              : (isActive
              ? const Color(0xFFFFFBF0)
              : isSelected
              ? const Color(0xFFF8F9FF)
              : const Color(0xFFF5F6FA)),
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(
            color: _borderColor(),
            width: isActive ? 2 : 1.5,
          ),
          boxShadow: isActive || isSelected
              ? [
            BoxShadow(
              color: gold.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            )
          ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(Insets.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isActive ? gold : textPrimary,
                              ),
                            ),
                            if (badge != null && !isActive) ...[
                              const SizedBox(width: 8),
                              _Badge(label: badge!, gold: gold, isDark: isDark),
                            ],
                            if (isActive) ...[
                              const SizedBox(width: 8),
                              _Badge(
                                label: 'ACTIVE',
                                gold: gold,
                                isDark: isDark,
                                isActive: true,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              pkg.storeProduct.priceString,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isActive ? gold : textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                ' / $subtitle',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Selection indicator
                  if (!isActive)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? gold : textMuted.withOpacity(0.4),
                          width: 2,
                        ),
                        color: isSelected ? gold : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(Icons.check_rounded,
                          size: 13, color: bg)
                          : null,
                    ),
                ],
              ),

              const SizedBox(height: Insets.sm),
              const Divider(height: 1),
              const SizedBox(height: Insets.sm),

              // ── Credit breakdown ─────────────────────────────────────────
              _CreditRow(
                icon: Icons.toll_rounded,
                color: gold,
                text:
                '$creditsPerCycle credits per $cycleLabel',
              ),
              const SizedBox(height: 4),
              _CreditRow(
                icon: Icons.bar_chart_rounded,
                color: AppTheme.blue(context),
                text:
                '~$analysesPerCycle analyses per $cycleLabel',
              ),
              const SizedBox(height: 4),
              _CreditRow(
                icon: Icons.bolt_rounded,
                color: AppTheme.emerald(context),
                text:
                '${AppConstants.creditsPerAnalysis} credit per analysis',
              ),

              const SizedBox(height: Insets.md),

              // ── CTA Button ───────────────────────────────────────────────
              if (!isActive)
                GradientButton(
                  label: isLoading && isSelected
                      ? 'Processing...'
                      : _ctaLabel(),
                  height: 46,
                  onTap: isLoading
                      ? null
                      : () {
                    onSelect(planId);
                    onSubscribe();
                  },
                  colors: isDowngrade
                      ? [
                    AppTheme.textMuted(context),
                    AppTheme.textMuted(context).withOpacity(0.7),
                  ]
                      : null,
                )
              else
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Radii.full),
                    border: Border.all(color: gold.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      '✓  Your Current Plan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: gold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Feature List ─────────────────────────────────────────────────────────────

class _FeatureList extends StatelessWidget {
  final Color gold;
  const _FeatureList({required this.gold});

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.toll_rounded,              'Credits refresh every billing cycle'),
      (Icons.swap_vert_rounded,         'Upgrade or downgrade anytime'),
      (Icons.cancel_outlined,           'Cancel anytime — no lock-in'),
      (Icons.history_rounded,           'Full analysis history'),
      (Icons.notifications_none_rounded,'Unlimited price alerts'),
      (Icons.block_rounded,             'Ad-free experience'),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Pro plans include',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: Insets.sm),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(f.$1, size: 15, color: gold),
                const SizedBox(width: 8),
                Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─── Small reusable widgets ───────────────────────────────────────────────────

class _FeatureBenefit extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureBenefit({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.gold(context)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary(context))),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color gold;
  final bool isDark;
  final bool isActive;

  const _Badge({
    required this.label,
    required this.gold,
    required this.isDark,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(colors: [gold, gold.withOpacity(0.7)])
            : LinearGradient(
            colors: [gold.withOpacity(0.2), gold.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(Radii.full),
        border: isActive ? null : Border.all(color: gold.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: isActive
              ? (isDark ? AppColorsDark.bg : Colors.white)
              : gold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _CreditRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}