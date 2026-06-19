import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import 'remote_config_service.dart';
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

  /// Called ONLY immediately after `Purchases.purchasePackage()` returns
  /// successfully — i.e. the user just completed a real payment in this
  /// session. This is the one moment we can trust unconditionally, so it
  /// always grants the tier's full allotment, regardless of whatever local
  /// state (or lack of it) is currently on disk.
  ///
  /// Do NOT call this from `refresh()` or `restorePurchases()` — those run
  /// on ordinary app launch / restore-purchases tap, which is exactly the
  /// path a reinstall or cleared-cache would also take, and granting there
  /// would reopen the exploit this is meant to close. Use
  /// [handleSubscriptionChange] for those instead.
  Future<void> handleFreshPurchase(
    SubscriptionTier tier, {
    DateTime? expiration,
  }) async {
    if (tier == SubscriptionTier.none) return;

    final p = await SharedPreferences.getInstance();
    final grant = await _creditsForTier(tier);
    await p.setInt(_kSubCredits, grant);
    await p.setString(_kSubTier, tier.name);
    if (expiration != null) {
      await p.setInt(_kSubExpirationMs, expiration.millisecondsSinceEpoch);
    }
  }

  /// Called after restore-purchases or an ordinary app refresh/launch.
  ///
  /// Behavior is split deliberately:
  ///   - First time we ever see this subscription locally (no local record —
  ///     this covers a genuine first purchase AND a reinstall/cleared-cache
  ///     on an already-active subscription, since both look identical from
  ///     on-device storage alone): credits start at **0**, not a full
  ///     allotment. We only remember the current entitlement expiration as
  ///     an anchor.
  ///   - Tier change (upgrade/downgrade) while we already have a local
  ///     anchor: grant the new tier's allotment immediately, discarding
  ///     whatever was left. A tier change is an intentional, visible action
  ///     (the user just bought a different plan), so it's not the same risk
  ///     as a silent reinstall.
  ///   - Real renewal (RevenueCat reports a later entitlement expiration
  ///     than our stored anchor, with an anchor already on record): grant
  ///     a fresh allotment, discarding any leftover balance from the prior
  ///     cycle.
  ///   - Same tier, same cycle: no-op, leave the existing balance untouched.
  ///
  /// This intentionally means: clearing app storage (or uninstalling and
  /// reinstalling) while a subscription is active and mid-cycle resets
  /// credits to 0 for the remainder of that cycle, even though the
  /// subscription itself is still valid. That's a deliberate trade-off to
  /// close the "burn credits, clear cache, repeat" exploit, since credits
  /// only live in local SharedPreferences with no server-side ledger. The
  /// user's subscription is not cancelled and will resume granting credits
  /// normally on the next real renewal.
  ///
  /// [expiration] should come from
  /// SubscriptionService.instance.getEntitlementExpirationDate(customerInfo).
  /// Pass null only if unavailable; in that case a tier change is still
  /// honored but renewal-without-tier-change won't be detected, and a fresh
  /// first-sight anchor can't be recorded either (handled defensively below).
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

    final hasLocalAnchor = lastExpirationMs != null;
    final tierChanged    = hasLocalAnchor && lastTier != tierName;
    final renewed        = hasLocalAnchor &&
        newExpirationMs != null &&
        newExpirationMs > lastExpirationMs;

    if (!hasLocalAnchor) {
      // No local record at all. Could be a genuine first purchase, or it
      // could be a reinstall/cleared-cache on a subscription that's been
      // active and mid-cycle for a while — on-device storage alone can't
      // tell these apart, so we deliberately do NOT grant the full
      // allotment here. Credits start at 0 and only repopulate on the next
      // detected renewal. We still record the tier and expiration so a
      // future real renewal can be detected against this anchor.
      await p.setInt(_kSubCredits, 0);
      await p.setString(_kSubTier, tierName);
      if (newExpirationMs != null) {
        await p.setInt(_kSubExpirationMs, newExpirationMs);
      }
      return;
    }

    if (tierChanged || renewed) {
      // Discard old balance entirely and replace with the fresh allotment —
      // never add to what's left over from the prior cycle/tier.
      final grant = await _creditsForTier(tier);
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

  /// Returns credit allotment for [tier], checking Remote Config cache first
  /// and falling back to compile-time [AppConstants] defaults when offline.
  static Future<int> _creditsForTier(SubscriptionTier tier) async {
    final rc = RemoteConfigService.instance;
    switch (tier) {
      case SubscriptionTier.weekly:
        return rc.getWeeklyCredits(AppConstants.weeklyCreditsPerCycle);
      case SubscriptionTier.monthly:
        return rc.getMonthlyCredits(AppConstants.monthlyCreditsPerCycle);
      case SubscriptionTier.yearly:
        return rc.getYearlyCredits(AppConstants.yearlyCreditsPerCycle);
      case SubscriptionTier.none:
        return 0;
    }
  }
}

enum CreditConsumeResult {
  subscriptionCredit, // Used a subscription credit
  freeSlot,           // Used a free lifetime slot
  noCredits,          // No credits available — show paywall
}