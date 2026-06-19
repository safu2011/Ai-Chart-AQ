import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences keys (mirrored from AdsProvider for read access)
const String _kChabbi        = 'rc_chabbi';
const String _kWeeklyCredits = 'rc_weekly_credits';
const String _kMonthlyCredits= 'rc_monthly_credits';
const String _kYearlyCredits = 'rc_yearly_credits';

/// Provides access to Remote Config values that were fetched and cached by
/// AdsProvider.initRemoteConfig(). Falls back to AppConstants hardcoded
/// defaults when no internet has been available yet.
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  /// Returns the OpenAI API key (chabbi).
  /// Priority: SharedPreferences cache → AppConstants.chabbi (compile-time fallback).
  Future<String> getChabbi(String fallback) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kChabbi);
    if (cached != null && cached.isNotEmpty) return cached;
    return fallback;
  }

  /// Returns weeklyCreditsPerCycle from Remote Config cache.
  Future<int> getWeeklyCredits(int fallback) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kWeeklyCredits) ?? fallback;
  }

  /// Returns monthlyCreditsPerCycle from Remote Config cache.
  Future<int> getMonthlyCredits(int fallback) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kMonthlyCredits) ?? fallback;
  }

  /// Returns yearlyCreditsPerCycle from Remote Config cache.
  Future<int> getYearlyCredits(int fallback) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kYearlyCredits) ?? fallback;
  }
}
