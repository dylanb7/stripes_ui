import 'package:collection/collection.dart';
import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/blue_dye.dart';
import 'package:stripes_ui/Util/date_helper.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_ui/repos/blue_dye_test_repo.dart';

class RenderEntryGroup extends ConsumerWidget {
  final bool grouped;
  final List<Response> responses;
  const RenderEntryGroup(
      {required this.responses, required this.grouped, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!grouped) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: responses.map((res) => EntryDisplay(event: res)).toList(),
      );
    }
    Map<String, List<Response>> byType = {};
    for (final Response response in responses) {
      if (byType.containsKey(response.type)) {
        byType[response.type]!.add(response);
      } else {
        byType[response.type] = [response];
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: byType.keys.map((type) {
          final List<Response> forType = byType[type]!;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: ExpandibleSymptomArea(
                header: Text(
                  "$type (${AppLocalizations.of(context)!.eventFilterResults(forType.length)})",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.left,
                ),
                responses: forType),
          );
        }).toList(),
      ),
    );
  }
}

class ExpandibleSymptomArea extends StatefulWidget {
  final List<Response> responses;

  final Widget header;

  const ExpandibleSymptomArea(
      {required this.header, required this.responses, super.key});

  @override
  State<StatefulWidget> createState() {
    return _ExpandibleSymptomAreaState();
  }
}

class _ExpandibleSymptomAreaState extends State<ExpandibleSymptomArea> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: ElevationOverlay.applySurfaceTint(Theme.of(context).cardColor,
            Theme.of(context).colorScheme.surfaceTint, 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.header,
              if (expanded)
                ...widget.responses.map((res) => EntryDisplay(event: res)),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                label: Text(
                  expanded
                      ? AppLocalizations.of(context)!.viewLessButtonText
                      : AppLocalizations.of(context)!.viewMoreButtonText,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.blue),
                ),
                iconAlignment: IconAlignment.end,
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EntryDisplay extends ConsumerStatefulWidget {
  final Response event;

  final bool hasControls, hasConstraints, elevated;

  const EntryDisplay(
      {super.key,
      required this.event,
      this.hasControls = true,
      this.hasConstraints = true,
      this.elevated = true});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => EntryDisplayState();
}

class EntryDisplayState extends ConsumerState<EntryDisplay> {
  bool isLoading = false;

  bool? isBlue;

  @override
  Widget build(BuildContext context) {
    final Map<String, DisplayBuilder> overrides =
        ref.watch(questionsProvider).valueOrNull?.displayOverrides ?? {};
    final DateTime date = dateFromStamp(widget.event.stamp);
    Widget? button;
    Widget? content;
    final DisplayBuilder? mainOverride = overrides[widget.event.question.id];
    if (mainOverride != null) return mainOverride(context, widget.event);
    if (widget.event is BlueDyeResp) {
      final BlueDyeResp resp = widget.event as BlueDyeResp;
      content = BlueDyeVisualDisplay(resp: resp);
    } else if (widget.event is DetailResponse) {
      final DetailResponse detail = widget.event as DetailResponse;
      isBlue = _isBlueFromDetail(detail);
      button = IconButton(
        onPressed: isLoading
            ? null
            : () {
                _edit(detail, context, date);
              },
        icon: const Icon(
          Icons.edit,
          size: 30,
        ),
      );
      content = DetailDisplay(detail: detail);
    } else {
      content = ResponseDisplay(res: widget.event);
    }

    return ConstrainedBox(
      constraints: widget.hasConstraints
          ? const BoxConstraints(maxWidth: 380)
          : const BoxConstraints(),
      child: Expandible(
        elevated: widget.elevated,
        header: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isBlue != null) ...[
              SizedBox(
                width: 30.0,
                height: 30.0,
                child: isBlue!
                    ? Image.asset(
                        'packages/stripes_ui/assets/images/Blue_Poop.png')
                    : Image.asset(
                        'packages/stripes_ui/assets/images/Brown_Poop.png'),
              ),
              const SizedBox(
                width: 8.0,
              ),
            ],
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.type,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  timeString(date, context),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
        iconSize: 35,
        view: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            content,
            if (widget.hasControls) ...[
              const SizedBox(
                height: 3,
              ),
              Row(
                children: [
                  TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary),
                      onPressed: isLoading
                          ? null
                          : () {
                              _delete(ref);
                            },
                      child: Text(
                        AppLocalizations.of(context)!.deleteAction,
                      )),
                  const Spacer(),
                  if (button != null) button,
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  bool? _isBlueFromDetail(DetailResponse res) {
    List<Response> blueRes = res.responses
        .where((val) => val.question.id == blueQuestionId)
        .toList();
    if (blueRes.isEmpty) return null;
    final MultiResponse multi = blueRes.first as MultiResponse;
    return multi.index == 0;
  }

  _edit(DetailResponse event, BuildContext context, DateTime date) {
    String? routeName = event.type;

    context.pushNamed('recordType',
        pathParameters: {'type': routeName},
        extra: QuestionsListener(
            responses: event.responses,
            editId: event.id,
            submitTime: date,
            desc: event.description));
  }

  _delete(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state = CurrentOverlay(
      widget: DeleteErrorPrevention(
        delete: () async {
          if (mounted) {
            setState(() {
              isLoading = true;
            });
          }
          await ref.read(stampProvider).valueOrNull?.removeStamp(widget.event);
          await ref
              .read(testProvider)
              .valueOrNull
              ?.onResponseDelete(widget.event, widget.event.type);
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        },
        type: widget.event.type,
      ),
    );
  }
}

class DetailDisplay extends StatelessWidget {
  final DetailResponse detail;

  const DetailDisplay({required this.detail, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (detail.description != null && detail.description!.isNotEmpty) ...[
          Text(
            AppLocalizations.of(context)!.descriptionLabel,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.left,
          ),
          const SizedBox(
            height: 3.0,
          ),
          Text(
            detail.description!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.left,
            maxLines: null,
          ),
          const SizedBox(
            height: 3.0,
          ),
        ],
        if (detail.responses.isNotEmpty) ...[
          Text(
            AppLocalizations.of(context)!.behaviorsLabel,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.left,
          ),
          const SizedBox(
            height: 3.0,
          ),
        ],
        ...detail.responses.mapIndexed<Widget>((index, res) {
          if (index == detail.responses.length - 1) {
            return ResponseDisplay(res: res);
          }
          return Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: ResponseDisplay(res: res));
        }),
      ],
    );
  }
}

class ResponseDisplay extends ConsumerWidget {
  final Response<Question> res;

  const ResponseDisplay({required this.res, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, DisplayBuilder> overrides =
        ref.watch(questionsProvider).valueOrNull?.displayOverrides ?? {};
    final DisplayBuilder? childOverride = overrides[res.question.id];
    if (childOverride != null) return childOverride(context, res);
    if (res is NumericResponse) {
      final NumericResponse numeric = res as NumericResponse;
      return Text('${numeric.question.prompt} - ${numeric.response}',
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: null);
    }
    if (res is MultiResponse) {
      final MultiResponse multi = res as MultiResponse;
      return Text(
        '${multi.question.prompt} - ${multi.question.choices[multi.index]}',
        textAlign: TextAlign.left,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    if (res is OpenResponse) {
      final OpenResponse open = res as OpenResponse;
      return Text('${open.question.prompt} - ${open.response}',
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: null);
    }
    return Text(
      res.question.prompt,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.bodyMedium,
      maxLines: null,
    );
  }
}

class BlueDyeDisplay extends StatelessWidget {
  final BlueDyeResp resp;

  const BlueDyeDisplay({required this.resp, super.key});

  @override
  Widget build(BuildContext context) {
    final Locale current = Localizations.localeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppLocalizations.of(context)!.startTestEntry,
          textAlign: TextAlign.left, //
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(
          height: 3.0,
        ),
        Text(
          '${dateToMDY(resp.startEating, context)} - ${timeString(resp.startEating, context)}',
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(
          height: 3.0,
        ),
        Text(
          AppLocalizations.of(context)!.mealDurationEntry,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(
          height: 3.0,
        ),
        Text(
          prettyDuration(
            resp.eatingDuration,
            abbreviated: true,
            locale: DurationLocale.fromLanguageCode(current.languageCode) ??
                const EnglishDurationLocale(),
          ),
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(
          height: 3.0,
        ),
        if (resp.firstBlue != resp.lastBlue) ...[
          Text(
            AppLocalizations.of(context)!.firstBlueEntry,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(
            height: 3.0,
          ),
          Text(
            '${dateToMDY(resp.firstBlue, context)} - ${timeString(resp.firstBlue, context)}',
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(
            height: 3.0,
          ),
        ],
        Text(
          AppLocalizations.of(context)!.lastBlueEntry,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(
          height: 3.0,
        ),
        Text(
          '${dateToMDY(resp.lastBlue, context)} - ${timeString(resp.lastBlue, context)}',
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(
          height: 3.0,
        ),
        Text(
          AppLocalizations.of(context)!.transitDurationEntry,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(
          height: 3.0,
        ),
        Text(
          prettyDuration(
              resp.lastBlue.difference(
                resp.startEating.add(resp.eatingDuration),
              ),
              delimiter: ' ',
              locale: DurationLocale.fromLanguageCode(current.languageCode) ??
                  const EnglishDurationLocale(),
              abbreviated: true),
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class DeleteErrorPrevention extends ConsumerWidget {
  final String type;

  final Function delete;

  const DeleteErrorPrevention(
      {required this.delete, required this.type, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConfirmationPopup(
      title: Text(
        AppLocalizations.of(context)!.errorPreventionTitle,
        style: Theme.of(context).textTheme.bodyLarge,
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
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 8.0,
          ),
          Text(
            AppLocalizations.of(context)!.stampDeleteWarningTwo,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
          style: Theme.of(context).textTheme.bodyMedium, maxLines: null),
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
          style: Theme.of(context).textTheme.bodyMedium, maxLines: null),
      const SizedBox(
        width: 4,
      ),
      response.response == -1
          ? Text(
              "Undetermined",
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                from(selectedIndex),
                const SizedBox(
                  width: 4,
                ),
                Text(
                  hurtLevels[selectedIndex],
                  style: Theme.of(context).textTheme.bodyMedium,
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
          style: Theme.of(context).textTheme.bodyMedium, maxLines: null),
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
