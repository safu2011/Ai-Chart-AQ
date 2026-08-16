import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Manages rating prompt logic and Play Store navigation.
class RatingService {
  RatingService._();
  static final instance = RatingService._();

  // ── SharedPreferences keys ─────────────────────────────────────────────────
  static const _kHasRated       = 'rating_has_rated';
  static const _kTaskCount      = 'rating_task_count';
  static const _kLastPromptDate = 'rating_last_prompt_date';

  /// Number of completed tasks before the first prompt appears.
  static const int _promptThreshold = 3;

  /// Minimum days between two successive prompts.
  static const int _minDaysBetweenPrompts = 7;

  // ── Play Store URL ─────────────────────────────────────────────────────────
  /// Replace YOUR_PACKAGE_ID with your actual Android package name.
  static const String _playStorePackageId = 'com.aq.aichartanalyzer.cryptosignals';

  static Uri get _playStoreUri =>
      Uri.parse('market://details?id=$_playStorePackageId');

  static Uri get _playStoreFallbackUri =>
      Uri.parse('https://play.google.com/store/apps/details?id=$_playStorePackageId');

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Call this every time the user completes a main task (e.g. after a
  /// successful analysis). Returns `true` when a rating prompt should be shown.
  Future<bool> recordTaskAndCheckPrompt() async {
    final prefs = await SharedPreferences.getInstance();

    // Never prompt again if the user already rated.
    if (prefs.getBool(_kHasRated) == true) return false;

    // Increment task counter.
    final count = (prefs.getInt(_kTaskCount) ?? 0) + 1;
    await prefs.setInt(_kTaskCount, count);

    // Not enough tasks yet.
    if (count < _promptThreshold) return false;

    // Enforce minimum gap between prompts.
    final lastMs = prefs.getInt(_kLastPromptDate);
    if (lastMs != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      if (DateTime.now().difference(last).inDays < _minDaysBetweenPrompts) {
        return false;
      }
    }

    return true;
  }

  /// Record that the dialog was shown (resets the cooldown timer).
  Future<void> markPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _kLastPromptDate, DateTime.now().millisecondsSinceEpoch);
    // Reset counter so next prompt fires after another _promptThreshold tasks.
    await prefs.setInt(_kTaskCount, 0);
  }

  /// Mark that the user submitted a rating — never prompt again.
  Future<void> markRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasRated, true);
  }

  /// Open the Play Store (or browser fallback) to the app's rating page.
  Future<void> openPlayStore() async {
    if (await canLaunchUrl(_playStoreUri)) {
      await launchUrl(_playStoreUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(_playStoreFallbackUri,
          mode: LaunchMode.externalApplication);
    }
    await markRated();
  }
}
