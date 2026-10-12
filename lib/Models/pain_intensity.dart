/// Display bands for the existing 0–10 pain scale.
enum PainIntensityBand {
  none(0, 0),
  mild(1, 3),
  moderate(4, 6),
  severe(7, 8),
  worst(9, 10);

  final int minimum;
  final int maximum;

  const PainIntensityBand(this.minimum, this.maximum);

  String get rangeLabel =>
      minimum == maximum ? '$minimum' : '$minimum – $maximum';

  /// Rounded midpoint keeps stored scores on the existing integer scale.
  int get representativeScore => ((minimum + maximum) / 2).round();

  static PainIntensityBand? fromScore(num? score) {
    if (score == null) return null;
    for (final band in values) {
      if (score >= band.minimum && score <= band.maximum) return band;
    }
    return null;
  }
}
