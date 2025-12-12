import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ChartAnnotation<D> extends Equatable {
  final D value;
  final String label;
  final Color color;
  final TextStyle? textStyle;
  final VoidCallback? onTap;

  const ChartAnnotation({
    required this.value,
    required this.label,
    required this.color,
    this.textStyle,
    this.onTap,
  });

  @override
  List<Object?> get props => [value, label, color, textStyle, onTap];
}
