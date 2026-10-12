import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Models/app_display_settings.dart';
import 'package:stripes_ui/Providers/Accessibility/display_settings_provider.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

/// Chooses a detail view from the saved preference and measured text space.
/// [answerText] also supplies the measurement text for custom answer widgets.
class DetailField extends ConsumerWidget {
  final String question;
  final String answerText;
  final String? inlineAnswerText;
  final Widget? answer;
  final Widget Function(bool stacked)? answerBuilder;
  final Widget? questionLeading;
  final TextStyle? answerStyle;
  final double inlineExtraWidth;
  final bool alwaysStacked;
  final DetailLayoutPreference? preference;

  const DetailField({
    required this.question,
    required this.answerText,
    this.inlineAnswerText,
    this.answer,
    this.answerBuilder,
    this.questionLeading,
    this.answerStyle,
    this.inlineExtraWidth = 0,
    this.alwaysStacked = false,
    this.preference,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        preference ??
        ref.watch(displaySettingsProvider).value?.detailLayout ??
        DetailLayoutPreference.automatic;
    final theme = Theme.of(context);
    final questionStyle = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
    );
    final effectiveAnswerStyle =
        answerStyle ??
        theme.textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        );
    final label = questionLeading == null
        ? Text(question, style: questionStyle)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              questionLeading!,
              const SizedBox(width: AppPadding.tiny),
              Expanded(child: Text(question, style: questionStyle)),
            ],
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        final locale = Localizations.maybeLocaleOf(context);
        TextPainter measure(
          String text,
          TextStyle style,
          double width, {
          int? maxLines,
        }) => TextPainter(
          text: TextSpan(text: text, style: style),
          textScaler: scaler,
          textDirection: direction,
          locale: locale,
          maxLines: maxLines,
        )..layout(maxWidth: width);

        final measuredAnswer = inlineAnswerText ?? answerText;
        final naturalAnswer = measure(
          measuredAnswer,
          effectiveAnswerStyle,
          double.infinity,
        );
        final answerWidth = math.min(
          (naturalAnswer.width + inlineExtraWidth).ceilToDouble() + 1,
          constraints.maxWidth * 0.60,
        );
        naturalAnswer.dispose();
        final questionWidth =
            constraints.maxWidth -
            answerWidth -
            AppPadding.small -
            (questionLeading == null ? 0 : 24);
        // A short landscape viewport has less room for tall, wrapped rows.
        final maxLines = MediaQuery.sizeOf(context).height < 480 ? 1 : 2;
        final labelMeasure = measure(
          question,
          questionStyle,
          math.max(0, questionWidth),
          maxLines: maxLines,
        );
        final valueMeasure = measure(
          measuredAnswer,
          effectiveAnswerStyle,
          math.max(0, answerWidth - inlineExtraWidth),
          maxLines: maxLines,
        );
        final stacked =
            alwaysStacked ||
            selected == DetailLayoutPreference.stacked ||
            !constraints.hasBoundedWidth ||
            constraints.maxWidth / scaler.scale(questionStyle.fontSize!) < 18 ||
            labelMeasure.didExceedMaxLines ||
            valueMeasure.didExceedMaxLines;
        labelMeasure.dispose();
        valueMeasure.dispose();

        final value = DefaultTextStyle(
          style: effectiveAnswerStyle,
          child:
              answerBuilder?.call(stacked) ??
              answer ??
              Text(
                answerText,
                textAlign: stacked ? TextAlign.start : TextAlign.end,
              ),
        );
        return Semantics(
          container: true,
          child: stacked
              ? StackedDetailField(question: label, answer: value)
              : InlineDetailField(
                  question: label,
                  answer: value,
                  answerWidth: answerWidth,
                ),
        );
      },
    );
  }
}

/// Standalone full-width question-over-answer presentation.
class StackedDetailField extends StatelessWidget {
  final Widget question;
  final Widget answer;
  const StackedDetailField({
    required this.question,
    required this.answer,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      question,
      const SizedBox(height: AppPadding.small),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRounding.small),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.medium,
          vertical: AppPadding.small,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: answer,
        ),
      ),
    ],
  );
}

class InlineDetailField extends StatelessWidget {
  final Widget question;
  final Widget answer;
  final double answerWidth;
  const InlineDetailField({
    required this.question,
    required this.answer,
    required this.answerWidth,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: question),
      const SizedBox(width: AppPadding.small),
      SizedBox(
        width: answerWidth,
        child: Align(alignment: AlignmentDirectional.centerEnd, child: answer),
      ),
    ],
  );
}
