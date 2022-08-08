import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/bm_test_log.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_time_entry.dart';
import 'package:stripes_ui/UI/CommonWidgets/delete_error_prevention.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
import 'package:stripes_ui/UI/Record/record_screen.dart';
import 'package:stripes_ui/UI/Record/symptom_record_data.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

final logChangeProvider =
    Provider.autoDispose.family<List<BMTestLog>, DateTime>((ref, finished) {
  final StampNotifier stampNotif = ref.watch(stampHolderProvider);
  final TestNotifier testNotif = ref.watch(testHolderProvider);
  List<DetailResponse> bmResps(List<Stamp> stamps) {
    List<DetailResponse> bms = [];
    for (int i = 0; i < stamps.length; i++) {
      final Stamp stamp = stamps[i];
      if (stamp.stamp < dateToStamp(finished)) {
        return bms;
      }
      if (stamp.type == Symptoms.BM) {
        bms.add(stamp as DetailResponse);
      }
    }
    return bms;
  }

  List<DetailResponse> bmResponses = bmResps(stampNotif.stamps);
  List<BMTestLog> logs = testNotif.obj!.logs;
  List<BMTestLog> logsCopy = logs.toList();

  for (DetailResponse element in bmResponses) {
    final int index =
        logs.indexWhere((log) => log.response.stamp == element.stamp);
    final bool contains = index != -1;
    if (!contains) {
      logsCopy.add(BMTestLog(response: element, isBlue: false));
      continue;
    }
    final BMTestLog bmLog = logs[index];
    if (bmLog.response != element) {
      final int index =
          logsCopy.indexWhere((val) => val.response == bmLog.response);
      if (index == -1) continue;
      logsCopy[index] = BMTestLog(response: element, isBlue: bmLog.isBlue);
    }
  }
  for (BMTestLog log in logs) {
    if (!bmResponses.contains(log.response)) {
      logsCopy.remove(log);
    }
  }
  if (logs.toString() != logsCopy.toString()) {
    ref.read(testProvider)?.setValue(testNotif.obj!..setLogs(logsCopy));
  }
  return logsCopy;
});

class Logs extends ConsumerWidget {
  final TimeListener startTime = TimeListener();
  final DateListener dateListener = DateListener();

  Logs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TestNotifier testNotif = ref.watch(testHolderProvider);
    final DateTime started = testNotif.obj!.start!;
    final Duration duration = testNotif.obj!.finishedEating!;
    final DateTime finished = started.add(duration);
    final TimeOfDay initStart = TimeOfDay.fromDateTime(started);
    final TimeOfDay initEnd = TimeOfDay.fromDateTime(finished);
    List<BMTestLog> logs = ref.watch(logChangeProvider(finished));
    startTime.quietSet(initStart);
    startTime.addListener(() {
      ref
          .read(testHolderProvider.notifier)
          .setStart(_combine(started, startTime.time));
    });
    dateListener.quietSet(started);
    startTime.addListener(() {
      ref
          .read(testHolderProvider.notifier)
          .setStart(_combine(started, startTime.time));
    });
    dateListener.addListener(() {
      ref
          .read(testHolderProvider.notifier)
          .setStart(_combine(dateListener.date, initStart));
    });

    OverlayQuery overlay = ref.watch(overlayProvider);

    final bool submitDisabled = testNotif.state != TestState.logsSubmit;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Logs',
                  style: darkBackgroundScreenHeaderStyle.copyWith(
                      color: lightBackgroundText),
                ),
                StripesRoundedButton(
                  text: 'Submit Test',
                  onClick: () {
                    ref
                        .read(testHolderProvider.notifier)
                        .submit(DateTime.now());
                  },
                  disabled: submitDisabled,
                  disabledClick: () {
                    showSnack(
                        'Must record a blue bowel movement before submitting test',
                        context);
                  },
                  tall: true,
                  shadow: false,
                  light: true,
                ),
              ],
            ),
            const SizedBox(
              height: 12.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Start Date:',
                  style: lightBackgroundHeaderStyle.copyWith(
                      color: lightIconButton),
                ),
                const SizedBox(
                  width: 30,
                ),
                DateWidget(
                  dateListener: dateListener,
                  hasHeader: false,
                  hasIcon: false,
                ),
              ],
            ),
            const SizedBox(
              height: 12.0,
            ),
            Row(
              children: [
                Text(
                  'Start Time:',
                  style: lightBackgroundHeaderStyle.copyWith(
                      color: lightIconButton),
                ),
                const SizedBox(
                  width: 30,
                ),
                TimeWidget(
                  timeListener: startTime,
                  latest: initEnd,
                  hasHeader: false,
                  hasIcon: false,
                ),
              ],
            ),
            const SizedBox(
              height: 4.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 15.0,
                  height: 120.0,
                  decoration: const BoxDecoration(
                      color: lightIconButton,
                      borderRadius: BorderRadius.all(Radius.circular(25.0))),
                ),
                const SizedBox(
                  width: 30.0,
                ),
                GestureDetector(
                  child: Text(
                    'Meal Duration - ${from(duration)}',
                    style: lightBackgroundStyle.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () {
                    _showDurationPicker(context, duration, ref);
                  },
                ).showCursorOnHover,
              ],
            ),
            const SizedBox(
              height: 4.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'End Time:',
                  style: lightBackgroundHeaderStyle.copyWith(
                      color: lightIconButton),
                ),
                const SizedBox(
                  width: 30,
                ),
                Text(
                  timeString(initEnd),
                  style: lightBackgroundStyle,
                ),
              ],
            ),
            const SizedBox(
              height: 4.0,
            ),
            Center(
              child: StripesRoundedButton(
                text: 'Log BM',
                onClick: () {
                  context.pushNamed(Routes.BM);
                },
              ),
            ),
            if (logs.isNotEmpty) ...[
              const SizedBox(
                height: 12.0,
              ),
              Text(
                'Tracked Bowel Movements',
                style:
                    lightBackgroundHeaderStyle.copyWith(color: lightIconButton),
              ),
            ],
            const SizedBox(
              height: 4.0,
            ),
            ...logs.map((item) => LogRow(
                  log: item,
                  ref: ref,
                )),
          ],
        ),
        if (overlay.widget != null) overlay.widget!
      ],
    );
  }

  _showDurationPicker(
      BuildContext context, Duration initial, WidgetRef ref) async {
    /*Duration? durr = await showDurationPicker(
      context: context,
      initialTime: initial,
      baseUnit: BaseUnit.second,
    );
    if (durr == null) return;
    ref.read(testHolderProvider.notifier).setDuration(durr);
    */
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute,
        date.second, date.millisecond);
  }
}

class LogRow extends StatelessWidget {
  final BMTestLog log;
  final WidgetRef ref;
  const LogRow({required this.log, required this.ref, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    DetailResponse event = log.response;
    final DateTime date = dateFromStamp(event.stamp);
    List<Text> vals = [
      Text(
        event.type,
        style: lightBackgroundHeaderStyle,
      ),
      if (event.description.isNotEmpty) ...[
        const Text(
          'Description:',
          style: lightBackgroundHeaderStyle,
        ),
        Text(
          event.description,
          style: lightBackgroundStyle,
          maxLines: null,
        )
      ],
      const Text(
        'Behaviors:',
        style: lightBackgroundHeaderStyle,
      ),
      ...event.responses.map(
        (res) {
          if (res is NumericResponse) {
            return Text('${res.question.prompt} - ${res.response}',
                style: lightBackgroundStyle, maxLines: null);
          }
          return Text(
            res.question.prompt,
            style: lightBackgroundStyle,
            maxLines: null,
          );
        },
      ),
    ];
    final Widget setBlueButton = TextButton(
      onPressed: () {
        _setBlue(context, !log.isBlue);
      },
      child: Text(
        log.isBlue ? 'Unmark BM' : 'Mark as Blue',
        style: lightBackgroundHeaderStyle.copyWith(color: lightIconButton),
      ),
    );
    return Expandible(
      highlightOnShrink: true,
      highlightColor: lightIconButton,
      header: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          '${dateToMDY(date)} at ${timeString(TimeOfDay.fromDateTime(date))}',
          style: lightBackgroundHeaderStyle,
        ),
        if (!log.isBlue) setBlueButton,
      ]),
      selected: log.isBlue,
      view: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ...vals
              .map(
                (text) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: text,
                ),
              )
              .toList(),
          Row(
            children: [
              const Spacer(),
              if (log.isBlue) setBlueButton,
              TextButton(
                  onPressed: () {
                    _delete(context, event);
                  },
                  child: Text(
                    'Delete',
                    style: lightBackgroundHeaderStyle.copyWith(
                        color: lightIconButton),
                  )),
              IconButton(
                onPressed: () {
                  _edit(event, context, date);
                },
                icon: const Icon(
                  Icons.edit,
                  size: 30,
                  color: lightIconButton,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _setBlue(BuildContext context, bool isBlue) {
    BlueDyeTest curr = ref.read(testHolderProvider).obj!;
    ref.read(testProvider)?.setValue(
        curr..updateLog(BMTestLog(response: log.response, isBlue: isBlue)));
  }

  _edit(DetailResponse event, BuildContext context, DateTime date) {
    final String type = event.type;
    if (!Symptoms.ordered().contains(type)) return;
    final QuestionsListener questionsListener = QuestionsListener();
    for (Response res in event.responses) {
      questionsListener.addResponse(res);
    }
    context.pushNamed(Options.symToRoute[type]!,
        extra: SymptomRecordData(
            isEditing: true,
            listener: questionsListener,
            submitTime: date,
            initialDesc: event.description));
  }

  _delete(BuildContext context, DetailResponse event) {
    ref.read(overlayProvider.notifier).state = OverlayQuery(
        widget: DeleteErrorPrevention(
      delete: () {
        ref.read(stampProvider)?.removeStamp(event);
      },
      type: event.type,
    ));
  }
}
