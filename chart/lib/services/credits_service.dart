import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import 'subscription_service.dart';


class CreditsService {
  static final CreditsService instance = CreditsService._();
  CreditsService._();

  // SharedPreferences keys
  static const _kSubCredits      = 'sub_credits';       // subscription credits
  static const _kSubTier         = 'sub_tier';           // last known tier name
  static const _kSubExpirationMs = 'sub_expiration_ms';  // epoch ms of RC entitlement expiration
  static const _kFreeUsed        = 'free_used_total';    // lifetime free counter

  // ── Subscription Credit Management ────────────────────────────────────────

  /// Called after purchase, restore, or refresh. Grants a fresh credit
  /// allotment for [tier] — discarding any previous balance — whenever
  /// the tier changed OR RevenueCat reports a new entitlement expiration
  /// date (i.e. the subscription actually renewed).
  ///
  /// [expiration] should come from
  /// SubscriptionService.instance.getEntitlementExpirationDate(customerInfo).
  /// Pass null only if unavailable; in that case a tier change is still
  /// honored but renewal-without-tier-change won't be detected.
  Future<void> handleSubscriptionChange(
      SubscriptionTier tier, {
        DateTime? expiration,
      }) async {
    if (tier == SubscriptionTier.none) {
      await clearSubscriptionCredits();
      return;
    }

    final p = await SharedPreferences.getInstance();
    final lastTier         = p.getString(_kSubTier) ?? '';
    final lastExpirationMs = p.getInt(_kSubExpirationMs);
    final tierName         = tier.name;
    final newExpirationMs  = expiration?.millisecondsSinceEpoch;

    final tierChanged = lastTier != tierName;
    final isFirstGrant = lastExpirationMs == null;
    final renewed = !isFirstGrant &&
        newExpirationMs != null &&
        newExpirationMs > lastExpirationMs;

    if (tierChanged || renewed || isFirstGrant) {
      // Discard old balance entirely and replace with the fresh allotment —
      // never add to what's left over from the prior cycle/tier.
      final grant = _creditsForTier(tier);
      await p.setInt(_kSubCredits, grant);
      await p.setString(_kSubTier, tierName);
      if (newExpirationMs != null) {
        await p.setInt(_kSubExpirationMs, newExpirationMs);
      }
    }
    // else: same tier, same cycle — leave existing balance untouched.
  }

  /// Clears subscription credits when subscription lapses/expires/cancels.
  Future<void> clearSubscriptionCredits() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kSubCredits, 0);
    await p.setString(_kSubTier, '');
    await p.remove(_kSubExpirationMs);
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<int> getSubscriptionCredits() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kSubCredits) ?? 0;
  }

  Future<int> getFreeUsed() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kFreeUsed) ?? 0;
  }

  Future<int> getFreeRemaining() async {
    final used = await getFreeUsed();
    return (AppConstants.freeAnalysesTotal - used)
        .clamp(0, AppConstants.freeAnalysesTotal);
  }

  Future<bool> canAnalyze({required bool isPro}) async {
    if (!isPro) {
      final freeLeft = await getFreeRemaining();
      return freeLeft > 0;
    }
    final subCredits = await getSubscriptionCredits();
    return subCredits >= AppConstants.creditsPerAnalysis;
  }

  // ── Consumption ───────────────────────────────────────────────────────────

  Future<CreditConsumeResult> consume({required bool isPro}) async {
    final p = await SharedPreferences.getInstance();

    if (!isPro) {
      final freeUsed = p.getInt(_kFreeUsed) ?? 0;
      if (freeUsed < AppConstants.freeAnalysesTotal) {
        await p.setInt(_kFreeUsed, freeUsed + 1);
        return CreditConsumeResult.freeSlot;
      }
      return CreditConsumeResult.noCredits;
    }

    final subCredits = p.getInt(_kSubCredits) ?? 0;
    if (subCredits >= AppConstants.creditsPerAnalysis) {
      await p.setInt(_kSubCredits, subCredits - AppConstants.creditsPerAnalysis);
      return CreditConsumeResult.subscriptionCredit;
    }

    return CreditConsumeResult.noCredits;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static int _creditsForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.weekly:  return AppConstants.weeklyCreditsPerCycle;
      case SubscriptionTier.monthly: return AppConstants.monthlyCreditsPerCycle;
      case SubscriptionTier.yearly:  return AppConstants.yearlyCreditsPerCycle;
      case SubscriptionTier.none:    return 0;
    }
  }
}

enum CreditConsumeResult {
  subscriptionCredit, // Used a subscription credit
  freeSlot,           // Used a free lifetime slot
  noCredits,          // No credits available — show paywall
}