import 'package:flutter/material.dart';
import 'package:stripes_ui/Models/pain_intensity.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

/// The range choices are controlled by the question's response, with no
/// implicit zero answer when the question has not been answered.
class PainIntensitySelector extends StatelessWidget {
  final PainIntensityBand? selectedBand;
  final bool notSure;
  final ValueChanged<PainIntensityBand> onBandSelected;
  final VoidCallback onNotSure;

  const PainIntensitySelector({
    required this.selectedBand,
    required this.notSure,
    required this.onBandSelected,
    required this.onNotSure,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyMedium!
        .copyWith(fontWeight: FontWeight.w600);
    final painter = TextPainter(
      text: TextSpan(text: '9 – 10', style: style),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    )..layout();
    final rangeWidth = painter.width;
    painter.dispose();

    return RadioGroup<PainIntensityBand>(
      groupValue: notSure ? null : selectedBand,
      onChanged: (band) {
        if (band != null) onBandSelected(band);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final band in PainIntensityBand.values) ...[
            Material(
              color: !notSure && selectedBand == band
                  ? colors.primaryContainer.withValues(alpha: 0.45)
                  : colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRounding.small),
                side: BorderSide(
                  color: !notSure && selectedBand == band
                      ? colors.primary
                      : colors.outlineVariant,
                ),
              ),
              child: RadioListTile<PainIntensityBand>(
                key: ValueKey('pain-band-${band.name}'),
                value: band,
                selected: !notSure && selectedBand == band,
                controlAffinity: ListTileControlAffinity.trailing,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.medium,
                  vertical: AppPadding.tiny,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRounding.small),
                ),
                title: Wrap(
                  spacing: AppPadding.large,
                  runSpacing: AppPadding.tiny,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: rangeWidth,
                      child: Text(band.rangeLabel, style: style),
                    ),
                    Text(painIntensityLabel(context, band), style: style),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.small),
          ],
          const SizedBox(height: AppPadding.small),
          Semantics(
            selected: notSure,
            child: OutlinedButton(
              key: const ValueKey('pain-intensity-not-sure'),
              onPressed: onNotSure,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.all(AppPadding.small),
                backgroundColor: notSure
                    ? colors.primaryContainer.withValues(alpha: 0.45)
                    : colors.surface,
                side: BorderSide(
                  color: notSure ? colors.primary : colors.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRounding.small),
                ),
              ),
              child: Text(context.translate.painIntensityNotSure),
            ),
          ),
        ],
      ),
    );
  }
}

String painIntensityLabel(BuildContext context, PainIntensityBand band) =>
    switch (band) {
      PainIntensityBand.none => context.translate.painIntensityNone,
      PainIntensityBand.mild => context.translate.mildTag,
      PainIntensityBand.moderate => context.translate.painIntensityModerate,
      PainIntensityBand.severe => context.translate.severeTag,
      PainIntensityBand.worst => context.translate.painIntensityWorst,
    };
