import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/chart_analysis.dart';

/// A self-contained, fully annotated candlestick chart used both for
/// on-screen display and for the screenshot that gets sent to GPT-4o Vision
/// for analysis.
///
/// The `candlesticks` package (v2.1.0) that renders the rest of the app's
/// interactive chart does NOT support moving-average overlays, a volume
/// moving-average, or a legend — which is exactly the set of visual cues a
/// vision model uses to recognise a screenshot as "a real trading chart"
/// (see e.g. Binance's own chart: MA(7)/MA(25)/MA(99) lines + legend on the
/// price pane, and MA(5)/MA(10) lines + labelled scale on the volume pane).
///
/// This widget draws all of that itself with a [CustomPainter], so the chart
/// that gets captured for analysis always contains:
///   • Candlesticks (OHLC) with a labelled, gridded right-hand price axis
///   • MA(7) / MA(25) / MA(99) overlay lines with a coloured legend
///   • Volume bars with a labelled scale
///   • Volume MA(5) / MA(10) overlay lines with a coloured legend
///   • A bottom date/time axis
class AnnotatedCandleChart extends StatelessWidget {
  /// Candles in ascending chronological order (oldest first, newest last).
  final List<CandleData> candles;

  final String symbol;
  final String interval;

  /// Header info baked directly onto the canvas (not just shown elsewhere
  /// in the UI) so the identity of the instrument survives into the
  /// screenshot that gets sent for AI analysis. All optional/nullable so
  /// the chart still renders while the ticker is loading.
  final double? currentPrice;
  final double? changePercent;
  final double? highPrice;
  final double? lowPrice;
  final String? quoteVolumeLabel;

  /// Maximum number of candles shown on screen at once. Older candles are
  /// still used to seed the moving averages so the first visible MA values
  /// are accurate (not just computed from the visible window).
  final int maxVisibleCandles;

  const AnnotatedCandleChart({
    super.key,
    required this.candles,
    required this.symbol,
    required this.interval,
    this.currentPrice,
    this.changePercent,
    this.highPrice,
    this.lowPrice,
    this.quoteVolumeLabel,
    this.maxVisibleCandles = 90,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 360,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 420,
        );
        return RepaintBoundary(
          child: CustomPaint(
            size: size,
            painter: _CandleChartPainter(
              candles: candles,
              symbol: symbol,
              interval: interval,
              currentPrice: currentPrice,
              changePercent: changePercent,
              highPrice: highPrice,
              lowPrice: lowPrice,
              quoteVolumeLabel: quoteVolumeLabel,
              maxVisibleCandles: maxVisibleCandles,
            ),
          ),
        );
      },
    );
  }
}

class _CandleChartPainter extends CustomPainter {
  final List<CandleData> candles;
  final String symbol;
  final String interval;
  final double? currentPrice;
  final double? changePercent;
  final double? highPrice;
  final double? lowPrice;
  final String? quoteVolumeLabel;
  final int maxVisibleCandles;

  static const Color _ma7Color = Color(0xFFF2B705); // gold
  static const Color _ma25Color = Color(0xFFE83E9C); // magenta
  static const Color _ma99Color = Color(0xFF9C6ADE); // purple
  static const Color _volMa5Color = Color(0xFFF2B705);
  static const Color _volMa10Color = Color(0xFF9C6ADE);

  static const double _headerHeight = 34;
  static const double _legendHeight = 20;
  static const double _dateAxisHeight = 18;
  static const double _priceAxisWidth = 54;
  static const double _volumeLegendHeight = 14;

  _CandleChartPainter({
    required this.candles,
    required this.symbol,
    required this.interval,
    required this.currentPrice,
    required this.changePercent,
    required this.highPrice,
    required this.lowPrice,
    required this.quoteVolumeLabel,
    required this.maxVisibleCandles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final n = math.min(candles.length, maxVisibleCandles);
    final visible = candles.sublist(candles.length - n);
    final startIdx = candles.length - n;

    final closes = candles.map((c) => c.close).toList(growable: false);
    final volumes = candles.map((c) => c.volume).toList(growable: false);

    final ma7 = _sma(closes, 7);
    final ma25 = _sma(closes, 25);
    final ma99 = _sma(closes, 99);
    final volMa5 = _sma(volumes, 5);
    final volMa10 = _sma(volumes, 10);

    // ── Layout ──────────────────────────────────────────────────────────
    final chartWidth = size.width - _priceAxisWidth;
    final bodyHeight = size.height -
        _headerHeight -
        _legendHeight -
        _dateAxisHeight -
        _volumeLegendHeight;
    final priceAreaHeight = bodyHeight * 0.70;
    final volumeAreaHeight = bodyHeight - priceAreaHeight;
    final priceTop = _headerHeight + _legendHeight;
    final volumeLegendTop = priceTop + priceAreaHeight + 4;
    final volumeTop = volumeLegendTop + _volumeLegendHeight;

    final candleWidth = chartWidth / n;
    final bodyWidth = math.max(1.0, candleWidth * 0.62);

    double xForIndex(int i) => i * candleWidth + candleWidth / 2;

    // ── Price range (candles + any visible MA values) ──────────────────
    double maxPrice = -double.infinity;
    double minPrice = double.infinity;
    for (final c in visible) {
      maxPrice = math.max(maxPrice, c.high);
      minPrice = math.min(minPrice, c.low);
    }
    void considerMa(List<double?> ma) {
      for (int i = startIdx; i < candles.length; i++) {
        final v = ma[i];
        if (v != null) {
          maxPrice = math.max(maxPrice, v);
          minPrice = math.min(minPrice, v);
        }
      }
    }

    considerMa(ma7);
    considerMa(ma25);
    considerMa(ma99);

    final rawRange = maxPrice - minPrice;
    final pad = rawRange == 0 ? (maxPrice.abs() * 0.01 + 1) : rawRange * 0.08;
    maxPrice += pad;
    minPrice -= pad;
    final priceRange = (maxPrice - minPrice) == 0 ? 1 : (maxPrice - minPrice);

    double yForPrice(double p) =>
        priceTop + (maxPrice - p) / priceRange * priceAreaHeight;

    // ── Volume range ─────────────────────────────────────────────────────
    double maxVol = 0;
    for (final c in visible) {
      maxVol = math.max(maxVol, c.volume);
    }
    if (maxVol == 0) maxVol = 1;
    double yForVol(double v) =>
        volumeTop + volumeAreaHeight - (v / maxVol * volumeAreaHeight);

    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.5)
      ..strokeWidth = 0.5;

    // ── Header row baked directly onto the canvas ───────────────────────
    // This is what makes the screenshot self-describing: the pair name,
    // price and change% are pixels inside the captured image itself, not
    // just text elsewhere in the app UI that the screenshot might not
    // include. Without this a vision model can see candles but has no way
    // to tell what instrument or price they belong to.
    canvas.drawLine(Offset(0, _headerHeight), Offset(size.width, _headerHeight),
        gridPaint);

    _drawText(canvas, symbol, const Offset(6, 4),
        color: AppColors.textPrimary, fontSize: 13, bold: true);

    if (currentPrice != null) {
      final isUp = (changePercent ?? 0) >= 0;
      final priceColor = isUp ? AppColors.emerald : AppColors.red;
      double px = _drawText(
          canvas, _fmtPrice(currentPrice!), const Offset(6, 19),
          color: priceColor, fontSize: 14, bold: true);
      if (changePercent != null) {
        px += 6;
        _drawText(
          canvas,
          '${isUp ? '+' : ''}${changePercent!.toStringAsFixed(2)}%',
          Offset(px, 21),
          color: priceColor,
          fontSize: 10,
          bold: true,
        );
      }
    }

    if (highPrice != null && lowPrice != null) {
      final hlText = 'H: ${_fmtPrice(highPrice!)}  L: ${_fmtPrice(lowPrice!)}';
      final hlWidth = _textWidth(hlText, 9);
      _drawText(canvas, hlText, Offset(size.width - hlWidth - 6, 20),
          color: AppColors.textSecondary, fontSize: 9);
    }
    final intervalWidth = _textWidth(interval, 9);
    _drawText(canvas, interval, Offset(size.width - intervalWidth - 6, 5),
        color: AppColors.gold, fontSize: 9, bold: true);

    // ── Price grid + right-hand axis labels ─────────────────────────────
    const priceGridLines = 5;
    for (int i = 0; i <= priceGridLines; i++) {
      final y = priceTop + priceAreaHeight * i / priceGridLines;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
      final price = maxPrice - priceRange * i / priceGridLines;
      _drawText(
        canvas,
        _fmtPrice(price),
        Offset(chartWidth + 4, y - 6),
        color: AppColors.textMuted,
        fontSize: 9,
      );
    }

    // ── Candles ──────────────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final c = visible[i];
      final x = xForIndex(i);
      final isBull = c.close >= c.open;
      final color = isBull ? AppColors.emerald : AppColors.red;

      canvas.drawLine(
        Offset(x, yForPrice(c.high)),
        Offset(x, yForPrice(c.low)),
        Paint()
          ..color = color
          ..strokeWidth = 1,
      );

      final bodyTop = yForPrice(math.max(c.open, c.close));
      final bodyBottomRaw = yForPrice(math.min(c.open, c.close));
      final bodyBottom = math.max(bodyBottomRaw, bodyTop + 1);
      canvas.drawRect(
        Rect.fromLTRB(
            x - bodyWidth / 2, bodyTop, x + bodyWidth / 2, bodyBottom),
        Paint()..color = color,
      );
    }

    // ── MA overlay lines ─────────────────────────────────────────────────
    void drawMaLine(List<double?> ma, Color color) {
      final path = Path();
      bool started = false;
      for (int i = 0; i < n; i++) {
        final v = ma[startIdx + i];
        if (v == null) continue;
        final x = xForIndex(i);
        final y = yForPrice(v);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
      if (started) {
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }

    drawMaLine(ma7, _ma7Color);
    drawMaLine(ma25, _ma25Color);
    drawMaLine(ma99, _ma99Color);

    // ── Price-pane legend (top-left, like Binance's MA(7)/MA(25)/MA(99)) ──
    final lastIdx = candles.length - 1;
    String fmt(double? v) => v == null ? '--' : _fmtPrice(v);
    double lx = 6;
    lx = _drawText(canvas, 'MA(7): ${fmt(ma7[lastIdx])}', Offset(lx, _headerHeight + 3),
        color: _ma7Color, fontSize: 10, bold: true);
    lx += 10;
    lx = _drawText(canvas, 'MA(25): ${fmt(ma25[lastIdx])}', Offset(lx, _headerHeight + 3),
        color: _ma25Color, fontSize: 10, bold: true);
    lx += 10;
    _drawText(canvas, 'MA(99): ${fmt(ma99[lastIdx])}', Offset(lx, _headerHeight + 3),
        color: _ma99Color, fontSize: 10, bold: true);

    // ── Volume-pane legend (Vol + MA(5)/MA(10), like Binance's volume panel) ─
    double vlx = 6;
    vlx = _drawText(
        canvas,
        quoteVolumeLabel != null
            ? '24h Vol: $quoteVolumeLabel'
            : 'Vol: ${_fmtVol(visible.last.volume)}',
        Offset(vlx, volumeLegendTop - 1),
        color: AppColors.textSecondary, fontSize: 9, bold: true);
    vlx += 8;
    vlx = _drawText(canvas, 'MA(5): ${_fmtVol(volMa5[lastIdx] ?? 0)}',
        Offset(vlx, volumeLegendTop - 1),
        color: _volMa5Color, fontSize: 9, bold: true);
    vlx += 8;
    _drawText(canvas, 'MA(10): ${_fmtVol(volMa10[lastIdx] ?? 0)}',
        Offset(vlx, volumeLegendTop - 1),
        color: _volMa10Color, fontSize: 9, bold: true);

    // ── Volume grid + right-hand axis labels ────────────────────────────
    canvas.drawLine(Offset(0, volumeTop), Offset(chartWidth, volumeTop),
        gridPaint);
    canvas.drawLine(Offset(0, volumeTop + volumeAreaHeight),
        Offset(chartWidth, volumeTop + volumeAreaHeight), gridPaint);
    _drawText(canvas, _fmtVol(maxVol), Offset(chartWidth + 4, volumeTop - 5),
        color: AppColors.textMuted, fontSize: 9);
    _drawText(canvas, '0',
        Offset(chartWidth + 4, volumeTop + volumeAreaHeight - 5),
        color: AppColors.textMuted, fontSize: 9);

    // ── Volume bars ──────────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final c = visible[i];
      final x = xForIndex(i);
      final isBull = c.close >= c.open;
      final color =
      (isBull ? AppColors.emerald : AppColors.red).withOpacity(0.55);
      canvas.drawLine(
        Offset(x, volumeTop + volumeAreaHeight),
        Offset(x, yForVol(c.volume)),
        Paint()
          ..color = color
          ..strokeWidth = bodyWidth,
      );
    }

    // ── Volume MA overlay lines ──────────────────────────────────────────
    void drawVolMaLine(List<double?> ma, Color color) {
      final path = Path();
      bool started = false;
      for (int i = 0; i < n; i++) {
        final v = ma[startIdx + i];
        if (v == null) continue;
        final x = xForIndex(i);
        final y = yForVol(v);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
      if (started) {
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }

    drawVolMaLine(volMa5, _volMa5Color);
    drawVolMaLine(volMa10, _volMa10Color);

    // ── Bottom date/time axis ────────────────────────────────────────────
    final dateY = size.height - _dateAxisHeight + 3;
    const dateLabelCount = 4;
    for (int i = 0; i <= dateLabelCount; i++) {
      final pos = (n - 1) * i / dateLabelCount;
      final idx = pos.round().clamp(0, n - 1);
      final x = xForIndex(idx);
      final label = _fmtDate(visible[idx].time, interval);
      _drawText(canvas, label, Offset(x - 16, dateY),
          color: AppColors.textMuted, fontSize: 9);
    }
  }

  double _textWidth(String text, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }

  double _drawText(Canvas canvas, String text, Offset offset,
      {required Color color, double fontSize = 10, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
    return offset.dx + tp.width;
  }

  List<double?> _sma(List<double> values, int period) {
    final result = List<double?>.filled(values.length, null);
    if (values.isEmpty) return result;
    double sum = 0;
    for (int i = 0; i < values.length; i++) {
      sum += values[i];
      if (i >= period) sum -= values[i - period];
      if (i >= period - 1) result[i] = sum / period;
    }
    return result;
  }

  String _fmtPrice(double v) => v.toStringAsFixed(v > 100 ? 2 : 4);

  String _fmtVol(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)}K';
    return v.toStringAsFixed(2);
  }

  static const _intradayIntervals = {
    '1m', '3m', '5m', '15m', '30m', '1h', '2h', '4h', '6h', '8h', '12h',
  };

  String _fmtDate(DateTime d, String interval) {
    if (_intradayIntervals.contains(interval)) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant _CandleChartPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.symbol != symbol ||
        oldDelegate.interval != interval ||
        oldDelegate.currentPrice != currentPrice ||
        oldDelegate.changePercent != changePercent ||
        oldDelegate.highPrice != highPrice ||
        oldDelegate.lowPrice != lowPrice ||
        oldDelegate.quoteVolumeLabel != quoteVolumeLabel ||
        oldDelegate.maxVisibleCandles != maxVisibleCandles;
  }
}