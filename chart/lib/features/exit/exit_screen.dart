import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/rating_service.dart';

class ExitScreen extends StatefulWidget {
  const ExitScreen({super.key});

  @override
  State<ExitScreen> createState() => _ExitScreenState();
}

class _ExitScreenState extends State<ExitScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  int _selectedStars = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _submitRating() async {
    if (_selectedStars == 0) return;

    await RatingService.instance.openPlayStore();
    await RatingService.instance.markRated();

    if (mounted) Navigator.of(context).pop(); // back to home
  }

  void _exitApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final bgColor     = AppTheme.bgColor(context);
    final cardColor   = AppTheme.cardColor(context);
    final borderColor = AppTheme.borderColor(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textMuted   = AppTheme.textMuted(context);
    final gold        = AppTheme.gold(context);
    final goldSoft    = isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft;

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Insets.md, vertical: Insets.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── App icon header ─────────────────────────────────────
                  const SizedBox(height: Insets.xl),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient:
                          LinearGradient(colors: [gold, goldSoft]),
                      borderRadius: BorderRadius.circular(Radii.lg),
                      boxShadow: [
                        BoxShadow(
                            color: gold.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Icon(
                      Icons.candlestick_chart_rounded,
                      color: isDark ? AppColorsDark.bg : AppColorsLight.bg,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: Insets.lg),

                  // ── Headline ────────────────────────────────────────────
                  Text(
                    'Enjoying AI Chart Analyzer?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Insets.sm),
                  Text(
                    'Your feedback helps us improve and keeps\nthe app free for everyone.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textMuted,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: Insets.xl),

                  // ── Star rating ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(Insets.lg),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(Radii.xl),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Rate your experience',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: Insets.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final starIndex = i + 1;
                            final filled = starIndex <= _selectedStars;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedStars = starIndex),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                          scale: anim, child: child),
                                  child: Icon(
                                    filled
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    key: ValueKey(filled),
                                    color: filled ? gold : textMuted,
                                    size: 40,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        if (_selectedStars > 0) ...[
                          const SizedBox(height: Insets.sm),
                          Text(
                            _ratingLabel(_selectedStars),
                            style: TextStyle(
                                fontSize: 13,
                                color: gold,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: Insets.lg),

                  // ── Submit rating button ────────────────────────────────
                  AnimatedOpacity(
                    opacity: _selectedStars > 0 ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [gold, goldSoft]),
                          borderRadius:
                              BorderRadius.circular(Radii.lg),
                        ),
                        child: TextButton(
                          onPressed:
                              _selectedStars > 0 ? _submitRating : null,
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(Radii.lg),
                            ),
                          ),
                          child: Text(
                            _selectedStars >= 4
                                ? 'Rate on Play Store  ★'
                                : 'Submit Rating',
                            style: TextStyle(
                              fontSize: 15,
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

                  const SizedBox(height: Insets.sm),

                  // ── Maybe later ─────────────────────────────────────────
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: textMuted,
                    ),
                    child: Text(
                      'Maybe later',
                      style: TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ),

                  const Spacer(),

                  // ── Exit button — intentionally low-prominence ──────────
                  TextButton(
                    onPressed: _exitApp,
                    style: TextButton.styleFrom(
                      foregroundColor: textMuted.withOpacity(0.6),
                    ),
                    child: Text(
                      'Exit app',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted.withOpacity(0.55),
                      ),
                    ),
                  ),
                  const SizedBox(height: Insets.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int stars) {
    switch (stars) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Great!';
      case 5:
        return 'Excellent! 🎉';
      default:
        return '';
    }
  }
}
