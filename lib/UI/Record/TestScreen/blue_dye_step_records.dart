import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Test/blue_dye_study_records_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/detail_field.dart';
import 'package:stripes_ui/UI/Record/TestScreen/amount_consumed.dart';
import 'package:stripes_ui/UI/Record/TestScreen/recordings_state.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/extensions.dart';

/// The wait period has no user-entered records. Other steps belong to one run.
BlueDyeStudyRunRecords? recordsForStudyStep(
  Map<int, BlueDyeStudyRunRecords> records,
  int stepIndex,
) => stepIndex == 2 ? null : records[stepIndex < 2 ? 0 : 1];

String? studyStepRecordLabel(
  BuildContext context,
  BlueDyeStudyRunRecords? records,
  int stepIndex,
) {
  if (records == null) return null;
  if (stepIndex == 0 || stepIndex == 3) {
    return records.hasMeal ? context.translate.blueMealRecordedMeal : null;
  }
  return records.bowelMovements.isEmpty
      ? null
      : context.translate.blueMealRecordedBms(records.bowelMovements.length);
}

class BlueDyeStepRecords extends StatelessWidget {
  final BlueDyeStudyRunRecords records;
  final int stepIndex;
  const BlueDyeStepRecords({
    required this.records,
    required this.stepIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.translate;
    final title = studyStepRecordLabel(context, records, stepIndex);
    if (title == null) return const SizedBox.shrink();
    final mealStep = stepIndex == 0 || stepIndex == 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (mealStep)
          _RecordedMeal(records: records)
        else
          BMDisplay(logs: records.bowelMovements),
        const Divider(height: 32),
        Text(
          s.blueMealStepInstructions,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

class _RecordedMeal extends StatelessWidget {
  final BlueDyeStudyRunRecords records;
  const _RecordedMeal({required this.records});

  @override
  Widget build(BuildContext context) {
    final s = context.translate;
    final meal = records.meal;
    final tubeFed = meal.finishedEating == Duration.zero;
    final duration = meal.finishedEating;
    final amount = meal.amountConsumed;
    final durationText = duration == null
        ? null
        : switch (MealTime.fromDuration(duration)) {
            MealTime.fifteenOrLess => s.blueMealDurationAnswerOne,
            MealTime.fifteenToThrity => s.blueMealDurationAnswerTwo,
            MealTime.thirtyToHour => s.blueMealDurationAnswerThree,
            MealTime.hourOrMore => s.blueMealDurationAnswerFour,
            null => from(duration, context),
          };
    final amountText = switch (amount) {
      AmountConsumed.all => s.amountConsumedAll,
      AmountConsumed.half => s.amountConsumedHalf,
      AmountConsumed.halfOrLess => s.amountConsumedHalfOrLess,
      AmountConsumed.moreThanHalf => s.amountConsumedHalfOrMore,
      AmountConsumed.undetermined => s.amountConsumedUnable,
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tubeFed) Text(FeedingMethod.tubeFed.toDisplayString(context)),
        if (meal.startTime != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              s.mealCompleteStartTime(
                meal.startTime!.toLocal(),
                meal.startTime!.toLocal(),
              ),
            ),
          ),
        if (!tubeFed && meal.finishedEatingTime != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DetailField(
              question: s.blueMealRecordedFinish,
              answerText: DateFormat.yMMMd(
                Localizations.localeOf(context).toString(),
              ).add_jm().format(meal.finishedEatingTime!.toLocal()),
            ),
          ),
        if (!tubeFed && durationText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DetailField(
              question: s.blueMealTimeTitle,
              answerText: durationText,
            ),
          ),
        if (!tubeFed && amountText != null)
          DetailField(question: s.blueMealAmountTitle, answerText: amountText),
      ],
    );
  }
}
