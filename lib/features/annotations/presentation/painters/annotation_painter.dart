import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/annotation.dart';

/// CustomPainter que renderiza todos los elementos de una anotación.
///
/// Optimizaciones:
/// - shouldRepaint compara por referencia de lista (no deep equality)
/// - coordenadas normalizadas convertidas a píxeles solo en paint()
/// - RepaintBoundary externo debe usarse en el árbol de widgets
class AnnotationPainter extends CustomPainter {
  const AnnotationPainter({
    required this.elements,
    this.activeStroke,
  });

  final List<AnnotationElement> elements;
  final AnnotationElement? activeStroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final element in elements) {
      _paintElement(canvas, size, element);
    }
    if (activeStroke != null) {
      _paintElement(canvas, size, activeStroke!);
    }
  }

  void _paintElement(Canvas canvas, Size size, AnnotationElement el) {
    if (el.points.isEmpty) return;

    final paint = Paint()
      ..color = el.color.withOpacity(el.opacity)
      ..strokeWidth = el.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final offsets = el.points.map((p) => p.toOffset(size)).toList();

    switch (el.type) {
      case AnnotationElementType.freeStroke:
        _drawFreeStroke(canvas, offsets, paint);
      case AnnotationElementType.line:
        if (offsets.length >= 2) {
          canvas.drawLine(offsets.first, offsets.last, paint);
        }
      case AnnotationElementType.arrow:
        if (offsets.length >= 2) {
          _drawArrow(canvas, offsets.first, offsets.last, paint);
        }
      case AnnotationElementType.rectangle:
        if (offsets.length >= 2) {
          canvas.drawRect(
            Rect.fromPoints(offsets.first, offsets.last),
            paint,
          );
        }
      case AnnotationElementType.circle:
        if (offsets.length >= 2) {
          final radius = (offsets.last - offsets.first).distance / 2;
          canvas.drawCircle(offsets.first, radius, paint);
        }
      case AnnotationElementType.marker:
        if (offsets.isNotEmpty) {
          _drawMarker(canvas, offsets.first, paint);
        }
      case AnnotationElementType.text:
        if (offsets.isNotEmpty && el.text != null) {
          _drawText(canvas, offsets.first, el);
        }
      case AnnotationElementType.eraser:
        break;
    }
  }

  void _drawFreeStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length == 1) {
      canvas.drawCircle(points.first, paint.strokeWidth / 2,
          paint..style = PaintingStyle.fill);
      return;
    }
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length - 1; i++) {
      final midX = (points[i].dx + points[i + 1].dx) / 2;
      final midY = (points[i].dy + points[i + 1].dy) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, midX, midY);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    const arrowSize = 14.0;
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle - 0.4),
        end.dy - arrowSize * math.sin(angle - 0.4),
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle + 0.4),
        end.dy - arrowSize * math.sin(angle + 0.4),
      );
    canvas.drawPath(arrowPath, paint);
  }

  void _drawMarker(Canvas canvas, Offset center, Paint paint) {
    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    final r = paint.strokeWidth * 2.5;
    canvas.drawCircle(center, r, fillPaint);
    canvas.drawCircle(center, r, paint..style = PaintingStyle.stroke);
  }

  void _drawText(Canvas canvas, Offset position, AnnotationElement el) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: el.text,
        style: TextStyle(
          color: el.color,
          fontSize: el.fontSize ?? 14.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) {
    return !identical(oldDelegate.elements, elements) ||
        oldDelegate.activeStroke != activeStroke;
  }
}
