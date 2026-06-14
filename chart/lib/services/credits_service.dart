import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import 'subscription_service.dart';

/// Manages the analysis credit system.
///
/// Credit model:
///   • 1 credit  = 1 API hit
///   • 1 analysis = 3 API hits = 3 credits consumed
///   • API cost: $0.02 per 3 hits; user charged: $0.06 per 3 hits
///
/// Subscription grants (credits per billing cycle):
///   Weekly  ($5/wk)    → [AppConstants.weeklyCreditsPerCycle]  credits/week
///   Monthly ($17/mo)   → [AppConstants.monthlyCreditsPerCycle] credits/month
///   Yearly  ($190/yr)  → [AppConstants.yearlyCreditsPerCycle]  credits/year
///
/// Free tier: [AppConstants.freeAnalysesTotal] lifetime analyses (one-time).
class CreditsService {
  static final CreditsService instance = CreditsService._();
  CreditsService._();

  // SharedPreferences keys
  static const _kSubCredits     = 'sub_credits';       // subscription credits
  static const _kSubTier        = 'sub_tier';           // last known tier name
  static const _kSubGrantedAt   = 'sub_granted_at';    // epoch ms of last grant
  static const _kFreeUsed       = 'free_used_total';   // lifetime free counter

  // ── Subscription Credit Management ────────────────────────────────────────

  /// Called after a purchase or restore. Grants the correct number of credits
  /// for the active [tier] if a new billing cycle has started.
  Future<void> handleSubscriptionChange(SubscriptionTier tier) async {
    if (tier == SubscriptionTier.none) return;

    final p = await SharedPreferences.getInstance();
    final lastTier      = p.getString(_kSubTier) ?? '';
    final lastGrantedAt = p.getInt(_kSubGrantedAt) ?? 0;
    final now           = DateTime.now().millisecondsSinceEpoch;
    final tierName      = tier.name;

    // Grant credits when:
    //   (a) tier changed (upgrade / downgrade / new subscription), OR
    //   (b) billing cycle elapsed since last grant
    final tierChanged = lastTier != tierName;
    final cycleMs     = _cycleDurationMs(tier);
    final cycleElapsed = (now - lastGrantedAt) >= cycleMs;

    if (tierChanged || cycleElapsed || lastGrantedAt == 0) {
      final grant = _creditsForTier(tier);
      // On tier change, replace credits; on renewal, add credits
      if (tierChanged) {
        await p.setInt(_kSubCredits, grant);
      } else {
        final existing = p.getInt(_kSubCredits) ?? 0;
        await p.setInt(_kSubCredits, existing + grant);
      }
      await p.setString(_kSubTier, tierName);
      await p.setInt(_kSubGrantedAt, now);
    }
  }

  /// Clears subscription credits when subscription lapses.
  Future<void> clearSubscriptionCredits() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kSubCredits, 0);
    await p.setString(_kSubTier, '');
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Returns current subscription credits.
  Future<int> getSubscriptionCredits() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kSubCredits) ?? 0;
  }

  /// Returns how many free lifetime analyses have been used.
  Future<int> getFreeUsed() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kFreeUsed) ?? 0;
  }

  /// Returns remaining free analyses (lifetime total, never resets).
  Future<int> getFreeRemaining() async {
    final used = await getFreeUsed();
    return (AppConstants.freeAnalysesTotal - used)
        .clamp(0, AppConstants.freeAnalysesTotal);
  }

  /// Returns true when the user can run an analysis.
  /// Pro subscribers with active credits can analyze.
  Future<bool> canAnalyze({required bool isPro}) async {
    if (!isPro) {
      // Check free tier
      final freeLeft = await getFreeRemaining();
      return freeLeft > 0;
    }
    // Pro: check subscription credits
    final subCredits = await getSubscriptionCredits();
    return subCredits >= AppConstants.creditsPerAnalysis;
  }

  // ── Consumption ───────────────────────────────────────────────────────────

  /// Consumes [AppConstants.creditsPerAnalysis] credits for one analysis.
  ///
  /// For free users: decrements free-use counter.
  /// For pro users: decrements subscription credits.
  /// Returns [CreditConsumeResult] describing the outcome.
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

    // Pro subscriber — consume from subscription credits
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

  static int _cycleDurationMs(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.weekly:
        return const Duration(days: 7).inMilliseconds;
      case SubscriptionTier.monthly:
        return const Duration(days: 30).inMilliseconds;
      case SubscriptionTier.yearly:
        return const Duration(days: 365).inMilliseconds;
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