import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../services/sketch_provider.dart';

class SketchCanvas extends StatelessWidget {
  final Size size;

  const SketchCanvas({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Consumer<SketchProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onPanStart: (details) {
            provider.startStroke(details.localPosition);
          },
          onPanUpdate: (details) {
            provider.addPoint(details.localPosition);
          },
          onPanEnd: (details) {
            provider.endStroke();
          },
          child: Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              color: AppTheme.canvasBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.outlineColor.withAlpha(51),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                size: size,
                painter: SketchPainter(
                  strokes: provider.strokes,
                  currentStrokePoints: provider.currentStrokePoints,
                  currentColor: provider.currentColor,
                  currentWidth: provider.currentWidth,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SketchPainter extends CustomPainter {
  final List<StrokeData> strokes;
  final List<Offset> currentStrokePoints;
  final Color currentColor;
  final double currentWidth;

  SketchPainter({
    required this.strokes,
    required this.currentStrokePoints,
    required this.currentColor,
    required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes - 각 스트로크별 저장된 색상/굵기 사용
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      _drawStroke(canvas, stroke.points, paint);
    }

    // Draw current stroke - 현재 선택된 색상/굵기 사용
    if (currentStrokePoints.isNotEmpty) {
      final currentPaint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      _drawStroke(canvas, currentStrokePoints, currentPaint);
    }

    // Draw placeholder text if canvas is empty
    if (strokes.isEmpty && currentStrokePoints.isEmpty) {
      _drawPlaceholder(canvas, size);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      if (points.isNotEmpty) {
        canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      }
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];

      // Quadratic bezier for smoother lines
      final midPoint = Offset(
        (p0.dx + p1.dx) / 2,
        (p0.dy + p1.dy) / 2,
      );
      path.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawPlaceholder(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '여기에 기분을 그려주세요',
        style: TextStyle(
          color: AppTheme.onSurfaceVariant.withAlpha(128),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    // Draw hint icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.gesture_rounded.codePoint),
        style: TextStyle(
          fontFamily: Icons.gesture_rounded.fontFamily,
          package: Icons.gesture_rounded.fontPackage,
          fontSize: 48,
          color: AppTheme.onSurfaceVariant.withAlpha(77),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size.width - iconPainter.width) / 2,
        (size.height - iconPainter.height) / 2 - 50,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) {
    return strokes != oldDelegate.strokes ||
        currentStrokePoints != oldDelegate.currentStrokePoints ||
        currentColor != oldDelegate.currentColor ||
        currentWidth != oldDelegate.currentWidth;
  }
}
