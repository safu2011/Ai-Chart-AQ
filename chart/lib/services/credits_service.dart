import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

/// Manages the analysis credit system.
///
/// Logic:
///   - Free users get [AppConstants.freeAnalysesPerDay] analyses per calendar day.
///   - Paid credit packs add to [_paidCredits] stored in SharedPreferences.
///   - Pro subscribers bypass all credit checks.
///
/// The daily counter resets at midnight local time.
class CreditsService {
  static final CreditsService instance = CreditsService._();
  CreditsService._();

  static const _kPaidCredits   = 'paid_credits';
  static const _kDailyCount    = 'daily_count';
  static const _kLastResetDate = 'last_reset_date';

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Returns how many paid credits the user has.
  Future<int> getPaidCredits() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kPaidCredits) ?? 0;
  }

  /// Returns how many free analyses have been used today.
  Future<int> getDailyUsed() async {
    final p = await SharedPreferences.getInstance();
    await _resetDailyIfNeeded(p);
    return p.getInt(_kDailyCount) ?? 0;
  }

  /// Returns remaining free analyses for today.
  Future<int> getFreeRemaining() async {
    final used = await getDailyUsed();
    return (AppConstants.freeAnalysesPerDay - used).clamp(0, AppConstants.freeAnalysesPerDay);
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
    await _resetDailyIfNeeded(p);

    final dailyUsed  = p.getInt(_kDailyCount) ?? 0;
    final paidCredits = p.getInt(_kPaidCredits) ?? 0;

    if (dailyUsed < AppConstants.freeAnalysesPerDay) {
      await p.setInt(_kDailyCount, dailyUsed + 1);
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

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _resetDailyIfNeeded(SharedPreferences p) async {
    final todayStr = _todayString();
    final lastReset = p.getString(_kLastResetDate) ?? '';
    if (lastReset != todayStr) {
      await p.setInt(_kDailyCount, 0);
      await p.setString(_kLastResetDate, todayStr);
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

enum CreditConsumeResult {
  pro,        // Pro subscriber — unlimited
  freeSlot,   // Used a free daily slot
  paidCredit, // Used a paid credit
  noCredits,  // No credits available — show paywall
}
