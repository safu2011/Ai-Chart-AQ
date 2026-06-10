import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/rating_service.dart';

/// Shows a lightweight in-app rating prompt.
///
/// Call [RatingDialogHelper.maybeShow] after any significant task completion
/// (e.g. successful AI analysis, alert created).  The service handles
/// whether to actually show it based on task count and cooldown.
class RatingDialogHelper {
  RatingDialogHelper._();

  /// Check conditions and optionally show the dialog.
  /// Safe to call on every task completion — the service throttles it.
  static Future<void> maybeShow(BuildContext context) async {
    final shouldShow =
        await RatingService.instance.recordTaskAndCheckPrompt();
    if (!shouldShow) return;

    await RatingService.instance.markPromptShown();

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _RatingDialog(),
    );
  }

  /// Show immediately (e.g. from Settings → Rate Us).
  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _RatingDialog(),
    );
  }
}

// ── Dialog widget ─────────────────────────────────────────────────────────────

class _RatingDialog extends StatefulWidget {
  const _RatingDialog();

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _selectedStars = 0;
  bool _submitting = false;

  Future<void> _submit() async {
    if (_selectedStars == 0 || _submitting) return;
    setState(() => _submitting = true);

    if (_selectedStars >= 4) {
      await RatingService.instance.openPlayStore();
    } else {
      await RatingService.instance.markRated();
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final cardColor   = AppTheme.cardColor(context);
    final borderColor = AppTheme.borderColor(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textMuted   = AppTheme.textMuted(context);
    final gold        = AppTheme.gold(context);
    final goldSoft    = isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: Insets.lg),
      child: Container(
        padding: const EdgeInsets.all(Insets.lg),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ─────────────────────────────────────────────────────
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [gold, goldSoft]),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Icon(
                Icons.candlestick_chart_rounded,
                color: isDark ? AppColorsDark.bg : AppColorsLight.bg,
                size: 26,
              ),
            ),
            const SizedBox(height: Insets.md),

            // ── Title ─────────────────────────────────────────────────────
            Text(
              'Enjoying the app?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'A quick rating helps us keep improving.',
              style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: Insets.lg),

            // ── Stars ─────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star   = i + 1;
                final filled = star <= _selectedStars;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStars = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        key: ValueKey(filled),
                        color: filled ? gold : textMuted,
                        size: 36,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: Insets.md),

            // ── Rate button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 46,
              child: AnimatedOpacity(
                opacity: _selectedStars > 0 ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [gold, goldSoft]),
                    borderRadius: BorderRadius.circular(Radii.lg),
                  ),
                  child: TextButton(
                    onPressed: _selectedStars > 0 && !_submitting
                        ? _submit
                        : null,
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.lg),
                      ),
                    ),
                    child: _submitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark
                                  ? AppColorsDark.bg
                                  : AppColorsLight.bg,
                            ),
                          )
                        : Text(
                            _selectedStars >= 4
                                ? 'Rate on Play Store'
                                : 'Submit',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColorsDark.bg
                                  : AppColorsLight.bg,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // ── Not now ───────────────────────────────────────────────────
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: textMuted),
              child: Text(
                'Not now',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
