import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

// ─── Premium Gradient Button ──────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final double? width;
  final double height;
  final List<Color>? colors;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.width,
    this.height = 52,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = AppTheme.gold(context);
    final goldSoft =
        isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft;

    final grad = colors ?? [goldColor, goldSoft, const Color(0xFFB8860B)];
    final labelColor =
        onTap != null ? AppTheme.bgColor(context) : AppTheme.textMuted(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: grad),
          borderRadius: BorderRadius.circular(Radii.full),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: grad.first.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Outlined Button ──────────────────────────────────────────────────────────
class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final Color? borderColor;
  final Color? textColor;

  const OutlineButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bc = borderColor ?? AppTheme.borderColor(context);
    final tc = textColor ?? AppTheme.textPrimary(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: bc),
          borderRadius: BorderRadius.circular(Radii.full),
          color: AppTheme.cardColor(context),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(
              label,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: tc),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Glass Card ───────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = Radii.lg,
    this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardElevated = isDark
        ? AppColorsDark.cardElevated
        : AppColorsLight.cardElevated;
    final cardBase =
        isDark ? AppColorsDark.card : AppColorsLight.card;
    final bColor = borderColor ?? AppTheme.borderColor(context);

    return Container(
      padding: padding ?? const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardElevated, cardBase],
            ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: bColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.gold(context);
    final goldSoft =
        isDark ? AppColorsDark.goldSoft : AppColorsLight.goldSoft;

    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gold, goldSoft],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

// ─── Sentiment Badge ──────────────────────────────────────────────────────────
class SentimentBadge extends StatelessWidget {
  final String sentiment;
  final bool large;

  const SentimentBadge({super.key, required this.sentiment, this.large = false});

  @override
  Widget build(BuildContext context) {
    final lower = sentiment.toLowerCase();
    late Color color;
    late IconData icon;

    if (lower == 'bullish') {
      color = AppTheme.emerald(context);
      icon = Icons.trending_up_rounded;
    } else if (lower == 'bearish') {
      color = AppTheme.red(context);
      icon = Icons.trending_down_rounded;
    } else {
      color = AppTheme.gold(context);
      icon = Icons.trending_flat_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(Radii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: large ? 20 : 14),
          const SizedBox(width: 5),
          Text(
            sentiment,
            style: TextStyle(
              color: color,
              fontSize: large ? 15 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer Loader ───────────────────────────────────────────────────────────
class ShimmerBlock extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerBlock({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = Radii.md,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        isDark ? AppColorsDark.card : AppColorsLight.neutral;
    final highlight =
        isDark ? AppColorsDark.cardElevated : AppColorsLight.cardElevated;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ─── Analysis Loading Skeleton ────────────────────────────────────────────────
class AnalysisLoadingSkeleton extends StatelessWidget {
  const AnalysisLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBlock(height: 60, borderRadius: Radii.lg),
        SizedBox(height: 12),
        ShimmerBlock(height: 120, borderRadius: Radii.lg),
        SizedBox(height: 12),
        ShimmerBlock(height: 100, borderRadius: Radii.lg),
        SizedBox(height: 12),
        ShimmerBlock(height: 80, borderRadius: Radii.lg),
      ],
    );
  }
}

// ─── Custom AppBar ────────────────────────────────────────────────────────────
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;

  const AppTopBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.bgColor(context);
    final cardColor = AppTheme.cardColor(context);
    final borderColor = AppTheme.borderColor(context);
    final textPrimary = AppTheme.textPrimary(context);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border:
            Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Insets.md,vertical: Insets.md),
          child: Row(
            children: [
              if (showBack)
                GestureDetector(
                  onTap: onBack ?? () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius:
                          BorderRadius.circular(Radii.md),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: textPrimary,
                    ),
                  ),
                ),
              if (showBack) const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State Widget ───────────────────────────────────────────────────────
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppTheme.textMuted(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

// ─── Disclaimer Banner ────────────────────────────────────────────────────────
class DisclaimerBanner extends StatelessWidget {
  final String text;
  const DisclaimerBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final gold = AppTheme.gold(context);
    return Container(
      padding: const EdgeInsets.all(Insets.sm + 4),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.07),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: gold.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: gold),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Metric Tile ──────────────────────────────────────────────────────────────
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: Insets.md, vertical: Insets.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: AppTheme.textMuted(context)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}
