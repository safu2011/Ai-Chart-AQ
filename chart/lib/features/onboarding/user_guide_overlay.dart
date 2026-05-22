import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../features/providers.dart';
import '../home/screens/home_screen.dart';

// ─── GlobalKeys — attached to target widgets in HomeScreen ───────────────────

final GlobalKey guideKeyGallery     = GlobalKey(debugLabel: 'guide_gallery');
final GlobalKey guidekeyCameraBtn   = GlobalKey(debugLabel: 'guide_camera');
final GlobalKey guideKeyQuickAccess = GlobalKey(debugLabel: 'guide_quick');

// ─── Wrapper: HomeScreen + overlay ───────────────────────────────────────────


class HomeScreenWithGuide extends StatefulWidget {
  const HomeScreenWithGuide({super.key});

  @override
  State<HomeScreenWithGuide> createState() => _HomeScreenWithGuideState();
}

class _HomeScreenWithGuideState extends State<HomeScreenWithGuide> {
  bool _showGuide = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showGuide = true);
    });
  }

  void _dismiss() async {
    if (mounted) setState(() => _showGuide = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guide_shown', true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeScreen(),
        if (_showGuide)
          UserGuideOverlay(
            targetKeys: [
              guideKeyGallery,
              guidekeyCameraBtn,
              guideKeyQuickAccess,
            ],
            onDismiss: _dismiss,
          ),
      ],
    );
  }
}

// ─── Overlay widget ───────────────────────────────────────────────────────────

class UserGuideOverlay extends StatefulWidget {
  final List<GlobalKey> targetKeys;
  final VoidCallback onDismiss;

  const UserGuideOverlay({
    super.key,
    required this.targetKeys,
    required this.onDismiss,
  });

  @override
  State<UserGuideOverlay> createState() => _UserGuideOverlayState();
}

class _UserGuideOverlayState extends State<UserGuideOverlay>
    with TickerProviderStateMixin {
  int _step = 0;
  Rect? _targetRect;

  // Estimated guide card height — used for clearance calculation
  static const double _cardEstHeight = 230.0;
  static const double _cardMargin    = 28.0;
  static const double _arrowHeight   = 52.0;
  static const double _topSafeArea   = 80.0; // approx status bar + app bar

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  late AnimationController _arrowCtrl;
  late Animation<double> _arrowBounce;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _slideFade;

  static const _steps = [
    _GuideStep(
      title: 'Upload a Chart Image',
      description:
          'Tap "Upload Chart from Gallery" to pick any crypto, forex or stock chart image from your gallery. PNG and JPG are supported.',
      icon: Icons.add_photo_alternate_outlined,
      keyIndex: 0,
    ),
    _GuideStep(
      title: 'Or Capture from Camera',
      description:
          'Tap "Capture from Camera" to photograph a chart from your screen or a printed chart — then get instant AI analysis.',
      icon: Icons.camera_alt_outlined,
      keyIndex: 1,
    ),
    _GuideStep(
      title: 'Live Crypto Charts',
      description:
          'Open Live Crypto Charts to browse all Binance USDT pairs in real-time, then tap "Analyze Chart" to run AI analysis on any live chart.',
      icon: Icons.candlestick_chart_rounded,
      keyIndex: 2,
    ),
    _GuideStep(
      title: 'Get AI Analysis',
      description:
          'GPT-4o Vision identifies chart patterns, support/resistance levels and trading signals. Every analysis is saved to Analysis History.',
      icon: Icons.auto_awesome_rounded,
      keyIndex: -1,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _arrowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650))
      ..repeat(reverse: true);
    _arrowBounce = Tween<double>(begin: 0.0, end: 10.0).animate(
        CurvedAnimation(parent: _arrowCtrl, curve: Curves.easeInOut));

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideFade = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slideCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollAndMeasure());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _arrowCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Scroll target into view then measure ─────────────────────────────────

  Future<void> _scrollAndMeasure() async {
    final step = _steps[_step];

    if (step.keyIndex < 0 || step.keyIndex >= widget.targetKeys.length) {
      // No target — scroll back to top so screen looks clean
      await _scrollToTop();
      if (mounted) setState(() => _targetRect = null);
      return;
    }

    final key = widget.targetKeys[step.keyIndex];
    final ctx  = key.currentContext;
    if (ctx == null) {
      if (mounted) setState(() => _targetRect = null);
      return;
    }

    final screenH = MediaQuery.of(context).size.height;

    // Work out how much space the guide card + arrow needs below the target.
    // Required clearance below target = arrow + card + margin
    final neededBelow = _arrowHeight + _cardEstHeight + _cardMargin;

    // Scroll so the target sits near the top, leaving room for the guide card.
    // alignment = fraction of viewport the widget should be placed at.
    // 0.0 = very top, 1.0 = very bottom.
    // We want target top at roughly: topSafeArea + small padding
    // as a fraction of screenH that is: topSafeArea / screenH ≈ 0.10–0.12
    final alignFraction = (_topSafeArea / screenH).clamp(0.0, 0.25);

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      alignment: alignFraction,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );

    // Wait for scroll to settle
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    // Measure actual position post-scroll
    final rect = _rectForKey(key);
    if (rect == null) {
      if (mounted) setState(() => _targetRect = null);
      return;
    }

    // If the target bottom + needed clearance still exceeds screen height,
    // do a second scroll to push it higher
    if (rect.bottom + neededBelow > screenH) {
      final extra = (rect.bottom + neededBelow) - screenH + 16.0;
      final scrollable = Scrollable.of(ctx);
      final pos = scrollable.position;
      await pos.animateTo(
        (pos.pixels + extra).clamp(pos.minScrollExtent, pos.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
    }

    // Final measurement after all scrolling is done
    final finalRect = _rectForKey(key);
    if (mounted) setState(() => _targetRect = finalRect);
  }

  Future<void> _scrollToTop() async {
    // Find any scrollable in the tree and scroll to top
    final ctx = context;
    try {
      final scrollable = Scrollable.of(ctx);
      await scrollable.position.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 60));
  }

  Rect? _rectForKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _nextStep() async {
    if (_step < _steps.length - 1) {
      _slideCtrl.reset();
      setState(() {
        _step++;
        _targetRect = null;
      });
      _slideCtrl.forward();
      await _scrollAndMeasure();
    } else {
      _fadeCtrl.reverse().then((_) => widget.onDismiss());
    }
  }

  void _skip() {
    _fadeCtrl.reverse().then((_) => widget.onDismiss());
  }

  // ── Card position: above target when target is in lower half ─────────────

  /// Returns [top, null] when card should be positioned from top,
  /// or [null, bottom] when pinned from bottom.
  /// Also returns whether arrow should point DOWN (true) or UP (false).
  ({double? top, double? bottom, bool arrowDown}) _cardPosition(
      Rect? targetRect, double screenH) {
    if (targetRect == null) {
      // No target — pin card at bottom
      return (top: null, bottom: _cardMargin, arrowDown: true);
    }

    // Space above target (minus safe area)
    final spaceAbove = targetRect.top - _topSafeArea;
    // Space below target
    final spaceBelow = screenH - targetRect.bottom;

    // Preferred: card BELOW target (normal), arrow pointing DOWN from above
    // Fallback: card ABOVE target if not enough space below
    final neededBelow = _arrowHeight + _cardEstHeight + _cardMargin;

    if (spaceBelow >= neededBelow) {
      // Enough room below → card below, arrow above pointing down
      final cardTop = targetRect.bottom + _arrowHeight + 4;
      return (top: cardTop, bottom: null, arrowDown: true);
    } else {
      // Not enough room below → card above, arrow below pointing up
      final cardBottom = screenH - (targetRect.top - _arrowHeight - 4);
      return (top: null, bottom: cardBottom, arrowDown: false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final gold       = isDark ? AppColorsDark.gold       : AppColorsLight.gold;
    final goldSoft   = isDark ? AppColorsDark.goldSoft   : AppColorsLight.goldSoft;
    final bg         = isDark ? AppColorsDark.bg         : AppColorsLight.bg;
    final card       = isDark ? AppColorsDark.card       : AppColorsLight.card;
    final textPrimary    = isDark ? AppColorsDark.textPrimary    : AppColorsLight.textPrimary;
    final textSecondary  = isDark ? AppColorsDark.textSecondary  : AppColorsLight.textSecondary;

    final screenH    = MediaQuery.of(context).size.height;
    final step       = _steps[_step];
    final targetRect = _targetRect;

    final pos = _cardPosition(targetRect, screenH);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Stack(
        children: [
          // ── Backdrop ────────────────────────────────────────────────────
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.70)),
          ),

          // ── Spotlight border ────────────────────────────────────────────
          if (targetRect != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => CustomPaint(
                  painter: _SpotlightPainter(
                    rect: targetRect,
                    borderColor: gold,
                    pulse: _pulseAnim.value,
                  ),
                ),
              ),
            ),

          // ── Bouncing arrow ───────────────────────────────────────────────
          if (targetRect != null)
            AnimatedBuilder(
              animation: _arrowBounce,
              builder: (_, __) {
                final centreX = targetRect.center.dx - 16.0;
                double arrowTop;
                IconData arrowIcon;

                if (pos.arrowDown) {
                  // Arrow above target, pointing down
                  arrowTop = (targetRect.top - 44.0 - _arrowBounce.value)
                      .clamp(_topSafeArea, screenH - 60.0);
                  arrowIcon = Icons.arrow_downward_rounded;
                } else {
                  // Arrow below target, pointing up
                  arrowTop = (targetRect.bottom + 6.0 + _arrowBounce.value)
                      .clamp(_topSafeArea, screenH - 60.0);
                  arrowIcon = Icons.arrow_upward_rounded;
                }

                return Positioned(
                  left: centreX,
                  top: arrowTop,
                  child: Icon(
                    arrowIcon,
                    color: gold,
                    size: 32,
                    shadows: [
                      Shadow(color: gold.withOpacity(0.6), blurRadius: 12),
                    ],
                  ),
                );
              },
            ),

          // ── Guide card ───────────────────────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            top:    pos.top,
            bottom: pos.bottom,
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _slideFade,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: gold.withOpacity(0.28)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [gold, goldSoft]),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(step.icon, color: bg, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _skip,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          step.description,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: textSecondary,
                            height: 1.55,
                            decoration: TextDecoration.none,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Bottom row
                        Row(
                          children: [
                            Row(
                              children: List.generate(
                                _steps.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 280),
                                  width: i == _step ? 22 : 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: i == _step
                                        ? gold
                                        : gold.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _nextStep,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 13),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [gold, goldSoft]),
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gold.withOpacity(0.4),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _step == _steps.length - 1
                                      ? 'Start Trading'
                                      : 'Next',
                                  style: TextStyle(
                                    color: bg,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Spotlight painter ────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Rect rect;
  final Color borderColor;
  final double pulse;

  const _SpotlightPainter({
    required this.rect,
    required this.borderColor,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inflated = rect.inflate(6);
    final rRect = RRect.fromRectAndRadius(inflated, const Radius.circular(16));

    final glowPaint = Paint()
      ..color = borderColor.withOpacity(0.12 + 0.18 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(rRect, glowPaint);

    final borderPaint = Paint()
      ..color = borderColor.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rRect, borderPaint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.pulse != pulse || old.rect != rect;
}

// ─── Step data ────────────────────────────────────────────────────────────────

class _GuideStep {
  final String title;
  final String description;
  final IconData icon;
  final int keyIndex;

  const _GuideStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.keyIndex,
  });
}
