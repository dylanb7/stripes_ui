import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class AnimatedPainter extends CustomPainter {
  final double progress;

  final Paint _paint;

  final Path Function(Size) path;

  AnimatedPainter(
      {required this.progress,
      required this.path,
      required Color paintColor,
      double strokeWidth = 3.0})
      : _paint = Paint()
          ..color = paintColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    Path path = this.path(size);
    PathMetrics pathMetric = path.computeMetrics();
    if (pathMetric.isEmpty) {
      return;
    }
    Path extractPath =
        pathMetric.first.extractPath(0.0, pathMetric.length * progress);
    canvas.drawPath(extractPath, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
