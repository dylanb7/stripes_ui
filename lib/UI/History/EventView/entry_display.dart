import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
import 'package:stripes_ui/UI/Record/symptom_record_data.dart';
import 'package:stripes_ui/Util/date_helper.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class EntryDisplay extends ConsumerWidget {
  final Response event;

  const EntryDisplay({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, Widget Function(Response<Question>)> overrides =
        ref.watch(questionDisplayOverides);
    final DateTime date = dateFromStamp(event.stamp);
    List<Widget> vals = [];
    Widget? button;
    final Widget Function(Response<Question>)? mainOverride =
        overrides[event.question.id];
    if (mainOverride != null) return mainOverride(event);
    if (event is BlueDyeResp) {
      final BlueDyeResp resp = event as BlueDyeResp;
      vals = [
        Text(
          AppLocalizations.of(context)!.startTestEntry, //
          style: lightBackgroundHeaderStyle,
        ),
        Text(
          '${dateToMDY(resp.startEating, context)} - ${timeString(resp.startEating, context)}',
          style: lightBackgroundStyle,
        ),
        Text(
          AppLocalizations.of(context)!.mealDurationEntry,
          style: lightBackgroundHeaderStyle,
        ),
        Text(
          from(resp.eatingDuration),
          style: lightBackgroundStyle,
        ),
        if (resp.firstBlue != resp.lastBlue) ...[
          Text(
            AppLocalizations.of(context)!.firstBlueEntry,
            style: lightBackgroundHeaderStyle,
          ),
          Text(
            '${dateToMDY(resp.firstBlue, context)} - ${timeString(resp.firstBlue, context)}',
            style: lightBackgroundStyle,
          ),
        ],
        Text(
          AppLocalizations.of(context)!.lastBlueEntry,
          style: lightBackgroundHeaderStyle,
        ),
        Text(
          '${dateToMDY(resp.lastBlue, context)} - ${timeString(resp.lastBlue, context)}',
          style: lightBackgroundStyle,
        ),
        Text(
          AppLocalizations.of(context)!.transitDurationEntry,
          style: lightBackgroundHeaderStyle,
        ),
        Text(
          from(resp.lastBlue
              .difference(resp.startEating.add(resp.eatingDuration))),
          style: lightBackgroundStyle,
        ),
      ];
    } else if (event is DetailResponse) {
      final DetailResponse detail = event as DetailResponse;
      button = IconButton(
        onPressed: () {
          _edit(detail, context, date);
        },
        icon: const Icon(
          Icons.edit,
          size: 30,
        ),
      );
      vals = [
        if (detail.description.isNotEmpty) ...[
          Text(
            AppLocalizations.of(context)!.descriptionLabel,
            style: lightBackgroundHeaderStyle,
          ),
          Text(
            detail.description,
            style: lightBackgroundStyle,
            maxLines: null,
          )
        ],
        if (detail.responses.isNotEmpty)
          Text(
            AppLocalizations.of(context)!.behaviorsLabel,
            style: lightBackgroundHeaderStyle,
          ),
        ...detail.responses.map<Widget>(
          (res) {
            final Widget Function(Response<Question>)? childOverride =
                overrides[res.question.id];
            if (childOverride != null) return childOverride(res);
            if (res is NumericResponse) {
              return Text('${res.question.prompt} - ${res.response}',
                  style: lightBackgroundStyle, maxLines: null);
            }
            if (res is MultiResponse) {
              return Text(
                '${res.question.prompt} - ${res.question.choices[res.index]}',
                style: lightBackgroundStyle,
              );
            }
            if (res is OpenResponse) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(res.question.prompt,
                      style: lightBackgroundStyle, maxLines: null),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(res.response,
                      style: lightBackgroundStyle, maxLines: null)
                ],
              );
            }
            return Text(
              res.question.prompt,
              style: lightBackgroundStyle,
              maxLines: null,
            );
          },
        ),
      ];
    } else if (event is NumericResponse) {
      final NumericResponse numeric = event as NumericResponse;
      vals = [
        Text('${event.question.prompt} - ${numeric.response}',
            style: lightBackgroundStyle, maxLines: null)
      ];
    } else if (event is Selected) {
      vals = [
        Text(event.question.prompt, style: lightBackgroundStyle, maxLines: null)
      ];
    } else if (event is OpenResponse) {
      vals = [
        Text(event.question.prompt,
            style: lightBackgroundStyle, maxLines: null),
        const SizedBox(
          height: 2,
        ),
        Text((event as OpenResponse).response,
            style: lightBackgroundStyle, maxLines: null)
      ];
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Expandible(
        header: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.type,
                style: lightBackgroundHeaderStyle.copyWith(
                    fontWeight: FontWeight.bold),
              ),
              Text(
                '${dateToMDY(date, context)} - ${timeString(date, context)}',
                style: lightBackgroundStyle,
              ),
            ]),
        iconSize: 35,
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
                TextButton(
                    onPressed: () {
                      _delete(ref);
                    },
                    child: Text(
                      AppLocalizations.of(context)!.deleteAction,
                    )),
                if (button != null) button,
              ],
            ),
          ],
        ),
      ),
    );
  }

  _edit(DetailResponse event, BuildContext context, DateTime date) {
    String? routeName = event.type;

    final QuestionsListener questionsListener = QuestionsListener();
    for (Response res in event.responses) {
      questionsListener.addResponse(res);
    }

    context.pushNamed('recordType',
        pathParameters: {'type': routeName},
        extra: SymptomRecordData(
            isEditing: true,
            listener: questionsListener,
            submitTime: date,
            initialDesc: event.description));
  }

  _delete(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state = OverlayQuery(
      widget: DeleteErrorPrevention(
        delete: () {
          final BlueDyeTest? obj = ref.read(testHolderProvider).obj;
          List<BMTestLog> blueLog = (obj?.logs ?? [])
              .where((element) => element.response.stamp == event.stamp)
              .toList();
          ref.read(stampProvider)?.removeStamp(event);
          if (blueLog.isNotEmpty) {
            ref.read(testHolderProvider).obj!.removeLog(blueLog.first);
          }
        },
        type: event.type,
      ),
    );
  }
}

class DeleteErrorPrevention extends ConsumerWidget {
  final String type;

  final Function delete;

  const DeleteErrorPrevention(
      {required this.delete, required this.type, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConfirmationPopup(
      title: Text(
        AppLocalizations.of(context)!.errorPreventionTitle,
        style: darkBackgroundHeaderStyle,
        textAlign: TextAlign.center,
      ),
      cancel: AppLocalizations.of(context)!.stampDeleteCancel,
      confirm: AppLocalizations.of(context)!.stampDeleteConfirm,
      onConfirm: () => _confirm(ref),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.stampDeleteWarningOne,
            style: lightBackgroundStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 8.0,
          ),
          Text(
            AppLocalizations.of(context)!.stampDeleteWarningTwo,
            style: lightBackgroundStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    /*return OverlayBackdrop(
      child: SizedBox(
        width: SMALL_LAYOUT / 1.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0))),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.errorPreventionTitle,
                      style: darkBackgroundHeaderStyle.copyWith(
                          color: buttonDarkBackground),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                    Text(
                      AppLocalizations.of(context)!.stampDeleteWarningOne,
                      style: lightBackgroundStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                    Text(
                      AppLocalizations.of(context)!.stampDeleteWarningTwo,
                      style: lightBackgroundStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                BasicButton(
                    onClick: (_) {
                      _closeOverlay(ref);
                    },
                    text: AppLocalizations.of(context)!.stampDeleteCancel),
                BasicButton(
                    onClick: (_) {
                      _confirm(ref);
                    },
                    text: AppLocalizations.of(context)!.stampDeleteConfirm),
              ],
            ),
          ],
        ),
      ),
    );*/
  }

  _confirm(WidgetRef ref) {
    delete();
    _closeOverlay(ref);
  }

  _closeOverlay(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state = closedQuery;
  }
}

class BMRow extends StatelessWidget {
  final NumericResponse response;

  const BMRow({required this.response, super.key});

  @override
  Widget build(BuildContext context) {
    const List<String> paths = [
      'packages/stripes_ui/assets/images/poop1.png',
      'packages/stripes_ui/assets/images/poop2.png',
      'packages/stripes_ui/assets/images/poop3.png',
      'packages/stripes_ui/assets/images/poop4.png',
      'packages/stripes_ui/assets/images/poop5.png',
      'packages/stripes_ui/assets/images/poop6.png',
      'packages/stripes_ui/assets/images/poop7.png'
    ];
    return Row(children: [
      Text('${response.question.prompt} - ${response.response.toInt()}',
          style: lightBackgroundStyle, maxLines: null),
      const SizedBox(
        width: 4,
      ),
      Image.asset(
        paths[response.response.toInt() - 1],
        height: 25,
        fit: BoxFit.fitHeight,
      ),
    ]);
  }
}

class PainSliderDisplay extends StatelessWidget {
  final NumericResponse response;

  const PainSliderDisplay({required this.response, super.key});

  @override
  Widget build(BuildContext context) {
    final int res = response.response.toInt();
    final List<String> hurtLevels = [
      AppLocalizations.of(context)!.painLevelZero,
      AppLocalizations.of(context)!.painLevelOne,
      AppLocalizations.of(context)!.painLevelTwo,
      AppLocalizations.of(context)!.painLevelThree,
      AppLocalizations.of(context)!.painLevelFour,
      AppLocalizations.of(context)!.painLevelFive,
    ];
    final int selectedIndex = (res.toDouble() / 2).floor();
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text('${response.question.prompt} - ${response.response}',
          style: lightBackgroundStyle, maxLines: null),
      const SizedBox(
        width: 4,
      ),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          from(selectedIndex),
          const SizedBox(
            width: 4,
          ),
          Text(
            hurtLevels[selectedIndex],
            style: lightBackgroundStyle,
            maxLines: 1,
          ),
        ],
      )
    ]);
  }

  Widget from(int index) {
    return SizedBox(
      height: 25,
      child: AspectRatio(
        aspectRatio: 1,
        child: SvgPicture.asset(
          'packages/stripes_ui/assets/svg/pain_face_$index.svg',
        ),
      ),
    );
  }
}

class MoodSliderDisplay extends StatelessWidget {
  final NumericResponse response;

  const MoodSliderDisplay({required this.response, super.key});

  @override
  Widget build(BuildContext context) {
    final int res = response.response.toInt();
    final int selectedIndex = (res.toDouble() / 2).floor();
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text('${response.question.prompt} - ${response.response}',
          style: lightBackgroundStyle, maxLines: null),
      const SizedBox(
        width: 4,
      ),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          from(5 - selectedIndex),
          const SizedBox(
            width: 4,
          ),
        ],
      )
    ]);
  }

  Widget from(int index) {
    return SizedBox(
      height: 25,
      child: AspectRatio(
        aspectRatio: 1,
        child: SvgPicture.asset(
          'packages/stripes_ui/assets/svg/pain_face_$index.svg',
        ),
      ),
    );
  }
}

typedef DisplayBuilder<T extends Response> = Widget Function(T);

final questionDisplayOverides =
    Provider<Map<String, DisplayBuilder>>((ref) => {});
