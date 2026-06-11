import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

/// Manages the analysis credit system.
///
/// Logic:
///   - Free users get [AppConstants.freeAnalysesTotal] analyses ONE TIME ever
///     (not per day). Once exhausted they must purchase credits or subscribe.
///   - Paid credit packs add to [_paidCredits] stored in SharedPreferences.
///   - Pro subscribers bypass all credit checks.
class CreditsService {
  static final CreditsService instance = CreditsService._();
  CreditsService._();

  static const _kPaidCredits    = 'paid_credits';
  static const _kFreeUsed       = 'free_used_total';  // lifetime counter

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Returns how many paid credits the user has.
  Future<int> getPaidCredits() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kPaidCredits) ?? 0;
  }

  /// Returns how many free lifetime analyses have been used.
  Future<int> getFreeUsed() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kFreeUsed) ?? 0;
  }

  /// Returns remaining free analyses (lifetime total, never resets).
  Future<int> getFreeRemaining() async {
    final used = await getFreeUsed();
    return (AppConstants.freeAnalysesTotal - used).clamp(0, AppConstants.freeAnalysesTotal);
  }

  /// Returns true when the user can run an analysis (free slot OR paid credits),
  /// assuming [isPro] is false (pro bypasses this entirely).
  Future<bool> canAnalyze({required bool isPro}) async {
    if (isPro) return true;
    final freeLeft = await getFreeRemaining();
    if (freeLeft > 0) return true;
    final paid = await getPaidCredits();
    return paid > 0;
  }

  // ── Consumption ───────────────────────────────────────────────────────────

  /// Consumes one credit for an analysis.
  ///
  /// Priority: free slot first, then paid credit.
  /// Returns [CreditConsumeResult] describing what was used.
  Future<CreditConsumeResult> consume({required bool isPro}) async {
    if (isPro) return CreditConsumeResult.pro;

    final p = await SharedPreferences.getInstance();
    final freeUsed    = p.getInt(_kFreeUsed) ?? 0;
    final paidCredits = p.getInt(_kPaidCredits) ?? 0;

    if (freeUsed < AppConstants.freeAnalysesTotal) {
      await p.setInt(_kFreeUsed, freeUsed + 1);
      return CreditConsumeResult.freeSlot;
    }

    if (paidCredits > 0) {
      await p.setInt(_kPaidCredits, paidCredits - 1);
      return CreditConsumeResult.paidCredit;
    }

    return CreditConsumeResult.noCredits;
  }

  // ── Adding Credits ────────────────────────────────────────────────────────

  Future<void> addPaidCredits(int amount) async {
    final p = await SharedPreferences.getInstance();
    final current = p.getInt(_kPaidCredits) ?? 0;
    await p.setInt(_kPaidCredits, current + amount);
  }
}

enum CreditConsumeResult {
  pro,        // Pro subscriber — unlimited
  freeSlot,   // Used a free lifetime slot
  paidCredit, // Used a paid credit
  noCredits,  // No credits available — show paywall
}
