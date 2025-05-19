import 'package:flutter/material.dart';
import 'package:image_annotation_plus/image_annotation_plus.dart';

// AnnotationPainter class
class AnnotationPainter extends CustomPainter {
  final List<List<Offset>> annotations;
  final List<TextAnnotation> textAnnotations;
  final AnnotationType annotationType;
  final Color color;
  final double thickness;

  AnnotationPainter({
    required this.annotations,
    required this.textAnnotations,
    required this.annotationType,
    this.thickness = 2.0,
    this.color = Colors.pinkAccent,
  });

  // Paint annotations and text on the canvas
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..filterQuality = FilterQuality.high;

    for (var annotation in annotations) {
      if (annotation.isNotEmpty) {
        if (annotationType == AnnotationType.line) {
          for (var i = 0; i < annotation.length - 1; i++) {
            canvas.drawLine(annotation[i], annotation[i + 1], paint);
          }
        } else if (annotationType == AnnotationType.rectangle) {
          final rect = Rect.fromPoints(annotation.first, annotation.last);
          canvas.drawRect(rect, paint);
        } else if (annotationType == AnnotationType.oval) {
          final oval = Rect.fromPoints(annotation.first, annotation.last);
          canvas.drawOval(oval, paint);
        }
      }
    }

    drawTextAnnotations(canvas); // Draw text annotations
  }

  // Draw text annotations on the canvas
  void drawTextAnnotations(Canvas canvas) {
    for (var annotation in textAnnotations) {
      final textSpan = TextSpan(
        text: annotation.text,
        style: TextStyle(color: annotation.textColor, fontSize: annotation.fontSize),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textPosition = Offset(
        annotation.position.dx - textPainter.width / 2,
        annotation.position.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, textPosition);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
