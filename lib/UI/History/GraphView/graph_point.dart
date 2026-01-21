import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';

class GraphPoint extends Equatable {
  final double x;
  final double y;
  final Color color;
  final List<Stamp> data;

  const GraphPoint(this.x, this.y, this.color, this.data);

  @override
  List<Object?> get props => [x, y, color];
}

/// A graph point that represents a range (start to end) instead of a single point.
class RangeGraphPoint extends GraphPoint {
  final double xEnd;

  const RangeGraphPoint(
    super.x,
    this.xEnd,
    super.y,
    super.color,
    super.data,
  );

  @override
  List<Object?> get props => [x, xEnd, y, color];
}
