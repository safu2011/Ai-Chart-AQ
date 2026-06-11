import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../features/providers.dart';
import '../home/screens/home_screen.dart';
import '../onboarding/user_guide_overlay.dart';
import '../paywall/paywall_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo
  late AnimationController _logoCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  // Candlestick bars
  late AnimationController _barsCtrl;
  late Animation<double> _barsAnim;

  // Tagline
  late AnimationController _taglineCtrl;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  // Progress bar
  late AnimationController _progressCtrl;

  // Proceed button
  late AnimationController _buttonCtrl;
  late Animation<double> _buttonFade;
  late Animation<double> _buttonScale;

  // Rotating ring
  late AnimationController _ringCtrl;

  // Pulse
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  bool _showProceed = false;
  bool _disclaimerShown = false;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    _barsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _barsAnim = CurvedAnimation(parent: _barsCtrl, curve: Curves.easeOutCubic);

    _taglineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _taglineFade =
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut);
    _taglineSlide = Tween<Offset>(
        begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOutCubic));

    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 6500));

    _buttonCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _buttonFade =
        CurvedAnimation(parent: _buttonCtrl, curve: Curves.easeOut);
    _buttonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _buttonCtrl, curve: Curves.elasticOut));

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _barsCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _taglineCtrl.forward();
    _progressCtrl.forward();

    // After 7 seconds total, show disclaimer then the button
    await Future.delayed(const Duration(milliseconds: 6000));
    if (!mounted) return;
    await _showDisclaimerIfNeeded();
    if (!mounted) return;
    setState(() => _showProceed = true);
    _buttonCtrl.forward();
  }

  Future<void> _showDisclaimerIfNeeded() async {
    if (_disclaimerShown) return;
    _disclaimerShown = true;

    final isDark = context.read<ThemeProvider>().isDark;
    final cardColor = isDark ? AppColorsDark.card : AppColorsLight.card;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
    final gold = isDark ? AppColorsDark.gold : AppColorsLight.gold;
    final bgColor = isDark ? AppColorsDark.bg : AppColorsLight.bg;
    final borderColor = isDark ? AppColorsDark.border : AppColorsLight.border;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.xl)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  gold,
                  isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft,
                ]),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(Icons.candlestick_chart_rounded,
                  color: bgColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Important Notice',
                style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(Insets.sm + 4),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.07),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                AppConstants.startupDisclaimer,
                style: TextStyle(
                    fontSize: 13,
                    color: textPrimary,
                    height: 1.5,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This app uses OpenAI Vision to analyse chart images. '
                  'All analyses are for educational purposes only and should '
                  'never be treated as financial advice.',
              style:
              TextStyle(fontSize: 12, color: textSecondary, height: 1.5),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: gold,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.full)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'I Understand',
                  style: TextStyle(
                      color: bgColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _proceed() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = !(prefs.getBool('guide_shown') ?? false);

    if (!mounted) return;

    final subProv = context.read<SubscriptionProvider>();
    await subProv.refresh();

    if (isFirstTime) {
      // First launch → show tutorial overlay
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const HomeScreenWithGuide(),
          ),
        ),
      ).then((v) async {
        if (!subProv.isPro) {
          print("Navigating to paywall");
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => _PaywallThenHome(),
            ),
          );
        } else {
          print("Navigating to HomeScreen");
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeScreen(),
            ),
          );
        }
      });
    } else {

      if (!mounted) return;

      if (!subProv.isPro) {
        // No credits left → push paywall, then home on back
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, animation, __) => FadeTransition(
              opacity: animation,
              child: const _PaywallThenHome(),
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, animation, __) => FadeTransition(
              opacity: animation,
              child: const HomeScreen(),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _barsCtrl.dispose();
    _taglineCtrl.dispose();
    _progressCtrl.dispose();
    _buttonCtrl.dispose();
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColorsDark.bg : AppColorsLight.bg;
    final gold = isDark ? AppColorsDark.gold : AppColorsLight.gold;
    final goldSoft = isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft;
    final textPrimary =
    isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
    isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Background grid dots
          Positioned.fill(child: _GridDots(isDark: isDark)),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: _LogoWidget(
                      gold: gold,
                      goldSoft: goldSoft,
                      bg: bg,
                      ringCtrl: _ringCtrl,
                      pulseAnim: _pulseAnim,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Candlestick bar animation
                AnimatedBuilder(
                  animation: _barsAnim,
                  builder: (_, __) =>
                      _CandleBarRow(progress: _barsAnim.value, gold: gold),
                ),

                const SizedBox(height: 28),

                // Tagline
                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _taglineFade,
                    child: Column(
                      children: [
                        Text(
                          'AI Chart Analyzer',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Trade Smarter with AI Analysis',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                color: gold, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Powered by GPT-4o Vision',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: gold,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom section: progress + button
          Positioned(
            left: 32,
            right: 32,
            bottom: 60,
            child: Column(
              children: [
                // Progress bar
                AnimatedBuilder(
                  animation: _progressCtrl,
                  builder: (_, __) => Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progressCtrl.value,
                          minHeight: 3,
                          backgroundColor: gold.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(gold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!_showProceed)
                        Text(
                          'Initialising AI systems...',
                          style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                              fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Proceed button
                if (_showProceed)
                  FadeTransition(
                    opacity: _buttonFade,
                    child: ScaleTransition(
                      scale: _buttonScale,
                      child: GestureDetector(
                        onTap: _proceed,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [gold, goldSoft],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight),
                            borderRadius: BorderRadius.circular(27),
                            boxShadow: [
                              BoxShadow(
                                color: gold.withOpacity(0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColorsDark.bg
                                        : AppColorsLight.bg,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded,
                                    color: isDark
                                        ? AppColorsDark.bg
                                        : AppColorsLight.bg,
                                    size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 54),
              ],
            ),
          ),

          // Disclaimer at very bottom
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: FadeTransition(
              opacity: _taglineFade,
              child: Text(
                'AI-generated analysis is for educational purposes only.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub Widgets ───────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  final Color gold;
  final Color goldSoft;
  final Color bg;
  final AnimationController ringCtrl;
  final Animation<double> pulseAnim;

  const _LogoWidget({
    required this.gold,
    required this.goldSoft,
    required this.bg,
    required this.ringCtrl,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating dashed ring
          AnimatedBuilder(
            animation: ringCtrl,
            builder: (_, __) => Transform.rotate(
              angle: ringCtrl.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(130, 130),
                painter: _DashedCirclePainter(color: gold.withOpacity(0.3)),
              ),
            ),
          ),

          // Pulsing glow circle
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: pulseAnim.value,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [gold.withOpacity(0.25), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // Logo container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gold, goldSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.candlestick_chart_rounded, color: bg, size: 40),
          ),
        ],
      ),
    );
  }
}

class _CandleBarRow extends StatelessWidget {
  final double progress;
  final Color gold;

  const _CandleBarRow({required this.progress, required this.gold});

  @override
  Widget build(BuildContext context) {
    const heights = [30.0, 50.0, 25.0, 60.0, 40.0, 55.0, 35.0, 45.0, 20.0];
    const isGreen = [true, false, true, true, false, true, false, true, true];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(heights.length, (i) {
        final delay = i / heights.length;
        final itemProgress =
        ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
        final color = isGreen[i]
            ? const Color(0xFF26A69A)
            : const Color(0xFFEF5350);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Wick top
              Container(
                width: 1.5,
                height: heights[i] * 0.3 * itemProgress,
                color: color,
              ),
              // Body
              Container(
                width: 12,
                height: heights[i] * itemProgress,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Wick bottom
              Container(
                width: 1.5,
                height: heights[i] * 0.2 * itemProgress,
                color: color,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _GridDots extends StatelessWidget {
  final bool isDark;
  const _GridDots({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridDotsPainter(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.04),
      ),
    );
  }
}

class _GridDotsPainter extends CustomPainter {
  final Color color;
  _GridDotsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridDotsPainter old) => false;
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 20;
    const dashAngle = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle * 0.5,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => false;
}

// ── PaywallThenHome ───────────────────────────────────────────────────────────
/// Shown on 2nd+ launch when user has no credits.
/// Displays the paywall first; pressing back reveals the HomeScreen underneath.

class _PaywallThenHome extends StatelessWidget {
  const _PaywallThenHome();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeScreen(),
        const _ImmediatePaywall(),
      ],
    );
  }
}

class _ImmediatePaywall extends StatefulWidget {
  const _ImmediatePaywall();

  @override
  State<_ImmediatePaywall> createState() => _ImmediatePaywallState();
}

class _ImmediatePaywallState extends State<_ImmediatePaywall> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _push());
  }

  Future<void> _push() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            FadeTransition(opacity: anim, child: const PaywallScreen()),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    // After paywall is dismissed (back), hide this overlay — HomeScreen shows
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) => _visible ? const SizedBox.shrink() : const SizedBox.shrink();
}