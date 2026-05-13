import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../providers.dart';
import 'analysis_result_screen.dart';

enum _DrawTool { none, pen, line, rect }

class _DrawPoint {
  final Offset offset;
  final Color color;
  final double strokeWidth;
  final bool isLineStart;
  const _DrawPoint(this.offset, this.color, this.strokeWidth,
      {this.isLineStart = false});
}

class ImagePreviewScreen extends ConsumerStatefulWidget {
  final File imageFile;
  const ImagePreviewScreen({super.key, required this.imageFile});

  @override
  ConsumerState<ImagePreviewScreen> createState() =>
      _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends ConsumerState<ImagePreviewScreen> {
  final GlobalKey _repaintKey = GlobalKey();

  _DrawTool _selectedTool = _DrawTool.none;
  Color _drawColor = AppColors.emerald;
  double _strokeWidth = 2.5;

  final List<List<_DrawPoint>> _strokes = [];
  List<_DrawPoint> _currentStroke = [];

  bool _showDisclaimer = true;

  final List<Color> _colorPalette = [
    AppColors.emerald,
    AppColors.red,
    AppColors.gold,
    AppColors.blue,
    Colors.white,
    Colors.orange,
  ];

  Future<File> _captureAnnotated() async {
    final boundary = _repaintKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final dir = Directory.systemTemp;
    final file = File(
        '${dir.path}/annotated_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  void _onAnalyze() async {
    if (!mounted) return;
    File fileToAnalyze;
    if (_strokes.isNotEmpty) {
      fileToAnalyze = await _captureAnnotated();
    } else {
      fileToAnalyze = widget.imageFile;
    }

    ref.read(analysisProvider.notifier).reset();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AnalysisResultScreen(imageFile: fileToAnalyze),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(
        title: 'Preview & Markup',
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _strokes.clear();
                _currentStroke = [];
              });
            },
            child: const Text('Clear',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chart preview with drawing overlay
          Expanded(
            child: Stack(
              children: [
                RepaintBoundary(
                  key: _repaintKey,
                  child: Stack(
                    children: [
                      // Image
                      Positioned.fill(
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Drawing canvas
                      Positioned.fill(
                        child: GestureDetector(
                          onPanStart: _selectedTool == _DrawTool.none
                              ? null
                              : (d) {
                                  setState(() {
                                    _currentStroke = [
                                      _DrawPoint(d.localPosition,
                                          _drawColor, _strokeWidth,
                                          isLineStart: true)
                                    ];
                                  });
                                },
                          onPanUpdate: _selectedTool == _DrawTool.none
                              ? null
                              : (d) {
                                  setState(() {
                                    _currentStroke.add(_DrawPoint(
                                        d.localPosition,
                                        _drawColor,
                                        _strokeWidth));
                                  });
                                },
                          onPanEnd: _selectedTool == _DrawTool.none
                              ? null
                              : (d) {
                                  setState(() {
                                    if (_currentStroke.isNotEmpty) {
                                      _strokes.add(
                                          List.from(_currentStroke));
                                    }
                                    _currentStroke = [];
                                  });
                                },
                          child: CustomPaint(
                            painter: _DrawingPainter(
                              strokes: _strokes,
                              currentStroke: _currentStroke,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Insets.md, vertical: Insets.sm),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border:
                  Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tool row
                Row(
                  children: [
                    const Text('Markup:',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    _ToolBtn(
                      icon: Icons.touch_app_outlined,
                      label: 'None',
                      selected: _selectedTool == _DrawTool.none,
                      onTap: () =>
                          setState(() => _selectedTool = _DrawTool.none),
                    ),
                    const SizedBox(width: 6),
                    _ToolBtn(
                      icon: Icons.edit_rounded,
                      label: 'Draw',
                      selected: _selectedTool == _DrawTool.pen,
                      onTap: () =>
                          setState(() => _selectedTool = _DrawTool.pen),
                    ),
                    const SizedBox(width: 6),
                    _ToolBtn(
                      icon: Icons.horizontal_rule_rounded,
                      label: 'Line',
                      selected: _selectedTool == _DrawTool.line,
                      onTap: () =>
                          setState(() => _selectedTool = _DrawTool.line),
                    ),
                    const Spacer(),
                    // Stroke width
                    GestureDetector(
                      onTap: () => setState(() =>
                          _strokeWidth = _strokeWidth == 2.5 ? 4.5 : 2.5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius:
                              BorderRadius.circular(Radii.sm),
                          border:
                              Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.line_weight_rounded,
                                size: 14,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                                _strokeWidth == 2.5
                                    ? 'Thin'
                                    : 'Thick',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Color row
                Row(
                  children: [
                    const Text('Color:',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    ..._colorPalette.map((c) => GestureDetector(
                          onTap: () => setState(() => _drawColor = c),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _drawColor == c
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),

          // Disclaimer + CTA
          Container(
            padding: const EdgeInsets.all(Insets.md),
            color: AppColors.bg,
            child: Column(
              children: [
                if (_showDisclaimer)
                  DisclaimerBanner(
                    text: AppConstants.analysisDisclaimer,
                  ),
                if (_showDisclaimer) const SizedBox(height: Insets.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlineButton(
                        label: 'Retake',
                        icon: const Icon(Icons.refresh_rounded,
                            size: 16, color: AppColors.textSecondary),
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      flex: 2,
                      child: GradientButton(
                        label: 'Analyze Chart',
                        icon: const Icon(Icons.auto_awesome_rounded,
                            color: AppColors.bg, size: 16),
                        onTap: _onAnalyze,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withOpacity(0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: selected ? AppColors.gold.withOpacity(0.5) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 13,
                color:
                    selected ? AppColors.gold : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? AppColors.gold
                        : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<List<_DrawPoint>> strokes;
  final List<_DrawPoint> currentStroke;

  const _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in [...strokes, currentStroke]) {
      if (stroke.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.first.color
        ..strokeWidth = stroke.first.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.first.offset.dx, stroke.first.offset.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].offset.dx, stroke[i].offset.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter old) => true;
}
