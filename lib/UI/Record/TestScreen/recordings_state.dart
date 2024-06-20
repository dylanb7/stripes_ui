import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/test_progress_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class RecordingsState extends ConsumerWidget {
  const RecordingsState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BlueDyeState? blueDyeState = ref.watch(testsHolderProvider
        .select((holder) => holder.valueOrNull?.getTestState<BlueDyeState>()));
    final BlueDyeTestProgress progress = ref.watch(blueDyeTestProgressProvider);
    final BlueDyeProgression stage =
        progress.getProgression() ?? BlueDyeProgression.stepOne;
    if (blueDyeState == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        stage == BlueDyeProgression.stepTwo
            ? BlueStudyInstructionsPartTwo(
                initiallyExpanded: blueDyeState.logs.isEmpty)
            : BlueStudyInstructionsPartTwo(
                initiallyExpanded: blueDyeState.logs.isEmpty),
        const SizedBox(
          height: 12.0,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: ElevationOverlay.applySurfaceTint(
                Theme.of(context).cardColor,
                Theme.of(context).colorScheme.surfaceTint,
                3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.recordingStateTitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                ...blueDyeState.logs.map((log) {
                  final DateTime logTime = dateFromStamp(log.stamp);
                  return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                            width: 35.0,
                            height: 35.0,
                            child: log.isBlue
                                ? Image.asset(
                                    'packages/stripes_ui/assets/images/Blue_Poop.png')
                                : Image.asset(
                                    'packages/stripes_ui/assets/images/Brown_Poop.png')),
                        const SizedBox(
                          width: 6.0,
                        ),
                        Text(
                          '${DateFormat.yMMMd().format(logTime)} - ${DateFormat.jm().format(logTime)}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ]);
                }),
                const SizedBox(
                  height: 8.0,
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      context.pushNamed(
                        'recordType',
                        pathParameters: {'type': Symptoms.BM},
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.nextButton),
                  ),
                ),
                const SizedBox(
                  height: 25.0,
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
