import 'package:collection/collection.dart';
import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/blue_dye.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/pain_area.dart';
import 'package:stripes_ui/Util/date_helper.dart';
import 'package:stripes_ui/Util/extensions.dart';
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
        children: responses
            .map(
              (res) => EntryDisplay(
                event: res,
              ),
            )
            .separated(
                by: const SizedBox(
              height: 8.0,
            )),
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
                header: RichText(
                  text: TextSpan(
                      text: type,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text:
                              " · ${context.translate.eventFilterResults(forType.length)}",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.75)),
                        )
                      ]),
                  textAlign: TextAlign.left,
                ),
                responses: forType),
          );
        }).toList(),
      ),
    );
  }
}

class RenderEntryGroupSliver extends ConsumerWidget {
  final bool grouped;
  final List<Response> responses;
  const RenderEntryGroupSliver(
      {required this.responses, required this.grouped, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!grouped) {
      return SliverList.builder(
        itemBuilder: (context, index) => EntryDisplay(
          event: responses[index],
        ),
        itemCount: responses.length,
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

    final List<String> typeKeys = byType.keys.toList();

    return SliverList.separated(
      separatorBuilder: (context, index) => const SizedBox(
        height: 6.0,
      ),
      itemBuilder: (context, index) {
        final List<Response> forType = byType[typeKeys[index]]!;

        return ExpandibleSymptomArea(
            header: RichText(
              text: TextSpan(
                  text: typeKeys[index],
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text:
                          " · ${context.translate.eventFilterResults(forType.length)}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.75)),
                    )
                  ]),
              textAlign: TextAlign.left,
            ),
            responses: forType);
      },
      itemCount: typeKeys.length,
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
        padding: const EdgeInsets.all(6.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.header,
              if (expanded)
                ...widget.responses
                    .map(
                      (res) => EntryDisplay(
                        event: res,
                      ),
                    )
                    .separated(
                        by: const SizedBox(
                      height: 8.0,
                    )),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                label: Text(
                  expanded
                      ? context.translate.viewLessButtonText
                      : context.translate.viewMoreButtonText,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).primaryColor),
                ),
                iconAlignment: IconAlignment.end,
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Theme.of(context).primaryColor,
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

  final bool hasControls, hasConstraints, includeFullDate;

  const EntryDisplay(
      {super.key,
      required this.event,
      this.hasControls = true,
      this.hasConstraints = true,
      this.includeFullDate = false});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => EntryDisplayState();
}

class EntryDisplayState extends ConsumerState<EntryDisplay> {
  bool isLoading = false;

  bool? isBlue;

  ExpansibleController controller = ExpansibleController();

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
      child: DecoratedBox(
        decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: const BorderRadius.all(
              Radius.circular(8.0),
            ),
            color: Theme.of(context).colorScheme.surface),
        child: Padding(
          padding: const EdgeInsetsGeometry.all(8.0),
          child: Expansible(
            key: ValueKey(widget.event.id ?? "${widget.event.stamp}"),
            headerBuilder: (context, animation) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (controller.isExpanded) {
                  controller.collapse();
                } else {
                  controller.expand();
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                            text: widget.event.type,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            children: [
                              if (isBlue != null)
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Container(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    width: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.fontSize ??
                                        20,
                                    height: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.fontSize ??
                                        20,
                                    child: isBlue!
                                        ? Image.asset(
                                            'packages/stripes_ui/assets/images/Blue_Poop.png')
                                        : Image.asset(
                                            'packages/stripes_ui/assets/images/Brown_Poop.png'),
                                  ),
                                ),
                            ]),
                      ),
                      Text(
                        widget.includeFullDate
                            ? "${(date.year == DateTime.now().year ? DateFormat.MMMd() : DateFormat.yMMMd()).format(date)} ${timeString(date, context)}"
                            : timeString(date, context),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(controller.isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down),
                ],
              ),
            ),
            bodyBuilder: (context, animation) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 4.0,
                ),
                content ?? const SizedBox(),
                if (widget.hasControls) ...[
                  const SizedBox(
                    height: 3,
                  ),
                  Row(
                    children: [
                      const Spacer(),
                      if (button != null) button,
                      const SizedBox(
                        width: 4.0,
                      ),
                      IconButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                _delete(ref);
                              },
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ]
              ],
            ),
            controller: controller,
          ),
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
            context.translate.descriptionLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.75)),
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
          const Divider(
            height: 8.0,
          ),
        ],
        if (detail.responses.isNotEmpty) ...[
          Text(
            context.translate.behaviorsLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.85),
                ),
            textAlign: TextAlign.left,
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
          context.translate.startTestEntry,
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
          context.translate.mealDurationEntry,
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
            context.translate.firstBlueEntry,
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
          context.translate.lastBlueEntry,
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
          context.translate.transitDurationEntry,
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
        context.translate.errorPreventionTitle,
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
      cancel: context.translate.stampDeleteCancel,
      confirm: context.translate.stampDeleteConfirm,
      onConfirm: () => _confirm(ref),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            context.translate.stampDeleteWarningOne,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 8.0,
          ),
          Text(
            context.translate.stampDeleteWarningTwo,
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
    ref.read(overlayProvider.notifier).state = closedOverlay;
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
      context.translate.painLevelZero,
      context.translate.painLevelOne,
      context.translate.painLevelTwo,
      context.translate.painLevelThree,
      context.translate.painLevelFour,
      context.translate.painLevelFive,
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

class PainLocationDisplay extends StatelessWidget {
  final AllResponse painLocation;

  const PainLocationDisplay({required this.painLocation, super.key});

  @override
  Widget build(BuildContext context) {
    final filledBorder =
        BorderSide(color: Theme.of(context).colorScheme.onSurface);
    const blankBorder = BorderSide(color: Colors.transparent);

    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              '${painLocation.question.prompt} - ${painLocation.choices.join(", ")}',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: null),
          const SizedBox(
            width: 4,
          ),
          if (painLocation.responses.isNotEmpty &&
              Area.fromValue(painLocation.responses[0]) != Area.none)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 100, maxWidth: 400),
              child: Stack(children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    clipBehavior: Clip.hardEdge,
                    child: Image.asset(
                      'packages/stripes_ui/assets/images/abdomin.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 4.0,
                ),
                Positioned.fill(
                  child: FractionallySizedBox(
                      widthFactor: 0.55,
                      heightFactor: 0.7,
                      child: Column(
                        children: [
                          ...List.generate(
                            3,
                            (colIndex) => Expanded(
                              child: Row(
                                children: [
                                  ...List.generate(3, (rowIndex) {
                                    final int index = (colIndex * 3) + rowIndex;
                                    final bool isSelected = painLocation
                                        .responses
                                        .contains(index + 1);
                                    return Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(2.0),
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border(
                                              top: colIndex == 0
                                                  ? blankBorder
                                                  : filledBorder,
                                              left: rowIndex == 0
                                                  ? blankBorder
                                                  : filledBorder,
                                              right: rowIndex == 2
                                                  ? blankBorder
                                                  : filledBorder,
                                              bottom: colIndex == 2
                                                  ? blankBorder
                                                  : filledBorder),
                                        ),
                                        child: Stack(children: [
                                          Positioned.fill(
                                            child: FractionallySizedBox(
                                              widthFactor: 0.9,
                                              heightFactor: 0.9,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: isSelected
                                                      ? RadialGradient(
                                                          center:
                                                              Alignment.center,
                                                          radius: 0.7,
                                                          colors: [
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .error,
                                                            Colors.transparent
                                                          ],
                                                          stops: const [
                                                            0.1,
                                                            1.0
                                                          ],
                                                        )
                                                      : null,
                                                ),
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                            ),
                                          ),
                                        ]),
                                      ), /*SelectableTile(
                                  row: rowIndex,
                                  col: colIndex,
                                  index: index,
                                  selected: (selected?.contains(area) ?? false)
                                      ? area
                                      : null,
                                  onSelect: (newValue) {
                                    setResponse(newValue);
                                  }),*/
                                    );
                                  })
                                ],
                              ),
                            ),
                          )
                        ],
                      )),
                ),
              ]),
            ),
        ]);
  }
}
