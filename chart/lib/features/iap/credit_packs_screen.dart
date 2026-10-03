import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../providers.dart';

/// One-time credit packs ($1 / $3 / $7 / $10). Credits are lifetime — they
/// never expire, are spent before subscription credits, and are unaffected
/// by subscription renewal or lapse.
class CreditPacksScreen extends StatefulWidget {
  const CreditPacksScreen({super.key});

  @override
  State<CreditPacksScreen> createState() => _CreditPacksScreenState();
}

class _CreditPacksScreenState extends State<CreditPacksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SubscriptionProvider>().loadIapProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final gold = AppTheme.gold(context);

    return PopScope(
      canPop: !sub.isIapPurchasing,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor(context),
        appBar: AppTopBar(
          title: 'Buy Credits',
          showBack: !sub.isIapPurchasing,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  Insets.md, Insets.md, Insets.md, Insets.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BalanceCard(sub: sub, gold: gold),
                  const SizedBox(height: Insets.md),
                  _Perks(gold: gold),
                  const SizedBox(height: Insets.lg),
                  if (sub.isIapLoading && sub.iapProducts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: Insets.xl),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ),
                    )
                  else ...[
                    if (sub.iapLoaded &&
                        sub.iapProducts.length < AppConstants.iapPacks.length)
                      _LoadError(
                        onRetry: () => sub.loadIapProducts(force: true),
                      ),
                    for (final pack in AppConstants.iapPacks) ...[
                      _PackCard(
                        pack: pack,
                        product: sub.iapProductFor(pack.productId),
                        busy: sub.isIapPurchasing,
                        gold: gold,
                        onBuy: () => _buy(pack),
                      ),
                      const SizedBox(height: Insets.sm),
                    ],
                  ],
                  const SizedBox(height: Insets.sm),
                  Text(
                    '1 analysis = ${AppConstants.creditsPerAnalysis} credit. '
                    'One-time purchase, not a subscription. Credits are stored '
                    'on this device and are used before any subscription credits. '
                    'Secure payment via Google Play / App Store.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.5,
                      color: AppTheme.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            if (sub.isIapPurchasing)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _buy(IapPack pack) async {
    final sub = context.read<SubscriptionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final added = await sub.purchaseIapPack(pack);
      messenger.showSnackBar(SnackBar(
        content: Text(added > 0
            ? '$added credits added to your balance! 🎉'
            : 'This purchase was already applied.'),
      ));
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      String msg;
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        msg = 'Purchase cancelled.';
      } else if (code == PurchasesErrorCode.paymentPendingError) {
        msg = 'Your payment is pending. Credits are added once it completes.';
      } else if (code == PurchasesErrorCode.networkError) {
        msg = 'Network error. Please try again.';
      } else {
        msg = 'Purchase failed. Please try again.';
      }
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Purchase failed. Please try again.')),
      );
    }
  }
}

// ─── Balance card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final SubscriptionProvider sub;
  final Color gold;
  const _BalanceCard({required this.sub, required this.gold});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final secondary = sub.isPro ? sub.subscriptionCredits : sub.freeRemaining;
    final secondaryLabel = sub.isPro ? 'Subscription' : 'Free';

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR BALANCE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppTheme.textSecondary(context))),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.bolt_rounded, color: gold, size: 30),
              const SizedBox(width: 4),
              Text('${sub.totalCredits}',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: AppTheme.textPrimary(context))),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                    'credits  •  ~${sub.totalAnalysesAvailable} analyses',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context))),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Text(
            'Lifetime: ${sub.iapCredits}   •   $secondaryLabel: $secondary',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: gold),
          ),
        ],
      ),
    );
  }
}

// ─── Perks ────────────────────────────────────────────────────────────────────

class _Perks extends StatelessWidget {
  final Color gold;
  const _Perks({required this.gold});

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(icon, size: 14, color: gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context))),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: gold.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lifetime credits',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context))),
          row(Icons.all_inclusive_rounded, 'Never expire — no time limit'),
          row(Icons.swap_vert_rounded,
              'Used first, then your subscription credits'),
          row(Icons.verified_user_outlined,
              'Kept even when a subscription ends'),
        ],
      ),
    );
  }
}

// ─── Pack card ────────────────────────────────────────────────────────────────

class _PackCard extends StatelessWidget {
  final IapPack pack;
  final StoreProduct? product;
  final bool busy;
  final Color gold;
  final VoidCallback onBuy;

  const _PackCard({
    required this.pack,
    required this.product,
    required this.busy,
    required this.gold,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final available = product != null;
    final analyses =
        (pack.credits / AppConstants.creditsPerAnalysis).floor();

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Icon(Icons.bolt_rounded, color: gold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pack.credits} credits',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary(context))),
                    Text('~$analyses analyses  •  Lifetime, no expiry',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary(context))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          GradientButton(
            label: available ? 'Buy for ${product!.priceString}' : 'Unavailable',
            height: 46,
            onTap: (available && !busy) ? onBuy : null,
          ),
        ],
      ),
    );
  }
}

// ─── Load error ───────────────────────────────────────────────────────────────

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.md),
      child: Column(
        children: [
          Text(
            'Some credit packs could not be loaded yet. Please check your connection and retry.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppTheme.textMuted(context), fontSize: 13),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
