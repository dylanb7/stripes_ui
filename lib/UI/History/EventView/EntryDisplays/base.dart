import 'package:collection/collection.dart';
import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

import 'package:stripes_ui/Util/Helpers/repo_result_handler.dart';

import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/blue_dye.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/pain_area.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Helpers/date_helper.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class RenderEntryGroup extends ConsumerWidget {
  final bool grouped;
  final List<Response> responses;
  const RenderEntryGroup(
      {required this.responses, required this.grouped, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    if (!grouped) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: responses
            .map(
              (res) => EntryDisplay(
                event: res,
              ),
            )
            .separated(
                by: const SizedBox(
              height: AppPadding.small,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: byType.keys.map((type) {
        final List<Response> forType = byType[type]!;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
          child: ExpandibleSymptomArea(
              header: RichText(
                text: TextSpan(
                    text: localizations?.value(type) ?? type,
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
              responses: forType),
        );
      }).toList(),
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
      return SliverList.separated(
        itemBuilder: (context, index) => EntryDisplay(
          event: responses[index],
        ),
        itemCount: responses.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(
          height: AppPadding.tiny,
        ),
      );
    }
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
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
        height: AppPadding.tiny,
      ),
      itemBuilder: (context, index) {
        final List<Response> forType = byType[typeKeys[index]]!;

        return ExpandibleSymptomArea(
            header: RichText(
              text: TextSpan(
                  text:
                      localizations?.value(typeKeys[index]) ?? typeKeys[index],
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
        borderRadius: BorderRadius.circular(AppRounding.tiny),
        color: ElevationOverlay.applySurfaceTint(Theme.of(context).cardColor,
            Theme.of(context).colorScheme.surfaceTint, 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.small),
        child: AnimatedSize(
          duration: Durations.medium1,
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!expanded) widget.header,
              if (expanded)
                ...widget.responses
                    .map(
                      (res) => EntryDisplay(
                        event: res,
                      ),
                    )
                    .separated(
                        by: const SizedBox(
                      height: AppPadding.small,
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

  final bool hasControls, hasConstraints, includeFullDate, isNested;

  const EntryDisplay(
      {super.key,
      required this.event,
      this.hasControls = true,
      this.hasConstraints = true,
      this.includeFullDate = false,
      this.isNested = false});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => EntryDisplayState();
}

class EntryDisplayState extends ConsumerState<EntryDisplay> {
  bool isLoading = false;

  bool? isBlue;

  ExpansibleController controller = ExpansibleController();

  @override
  Widget build(BuildContext context) {
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final Map<String, DisplayBuilder> overrides =
        ref.watch(questionsProvider).valueOrNull?.displayOverrides ?? {};
    final DateTime date = dateFromStamp(widget.event.stamp);
    Widget? button;
    Widget? content;
    final DisplayBuilder? mainOverride = overrides[widget.event.question.id];
    if (mainOverride != null) return mainOverride(context, widget.event);
    if (widget.event case BlueDyeResp resp) {
      content = BlueDyeVisualDisplay(resp: resp);
    } else if (widget.event case DetailResponse detail) {
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
          ? BoxConstraints(maxWidth: Breakpoint.tiny.value)
          : const BoxConstraints(),
      child: DecoratedBox(
        decoration: widget.isNested
            ? const BoxDecoration()
            : BoxDecoration(
                border: Border.all(),
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRounding.small),
                ),
                color: Theme.of(context).colorScheme.surface),
        child: Padding(
          padding: const EdgeInsetsGeometry.all(AppPadding.small),
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
                            text: localizations?.value(widget.event.type) ??
                                widget.event.type,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            children: [
                              if (isBlue != null)
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                        left: AppPadding.tiny),
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
                  height: AppPadding.tiny,
                ),
                content ?? const SizedBox(),
                if (widget.hasControls) ...[
                  const SizedBox(
                    height: AppPadding.tiny,
                  ),
                  Row(
                    children: [
                      const Spacer(),
                      if (button != null) button,
                      const SizedBox(
                        width: AppPadding.tiny,
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
        .where((val) => val.question.id == "BlueDyeQuestion")
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
            description: event.description));
  }

  _delete(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => DeleteErrorPrevention(
        delete: () async {
          if (mounted) {
            setState(() {
              isLoading = true;
            });
          }

          RepoResult<void>? result = await ref
                  .read(stampProvider)
                  .valueOrNull
                  ?.removeStamp(widget.event) ??
              const Failure(message: 'Stamp repo not found');

          if (result is Success) {
            await ref
                .read(testProvider)
                .valueOrNull
                ?.onResponseDelete(widget.event, widget.event.type);
          }

          if (context.mounted) {
            result.handle(context);
          }

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
    final bool hasResponses = detail.responses.isNotEmpty;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Map<String, Question> resolvedQuestions = _resolveQuestions();
    final List<(Response, Question?)> displayableResponses =
        _getDisplayableResponses(resolvedQuestions);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (detail.description != null && detail.description!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppPadding.small),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRounding.small),
              border: Border(
                left: BorderSide(
                  color: colors.primary,
                  width: 3,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.translate.descriptionLabel.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppPadding.tiny),
                Text(detail.description!, style: textTheme.bodyMedium),
              ],
            ),
          ),
          if (hasResponses) const SizedBox(height: AppPadding.medium),
        ],

        // Responses section
        if (displayableResponses.isNotEmpty) ...[
          Text(
            context.translate.behaviorsLabel.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppPadding.small),
          // Display responses directly without a heavy container background
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: displayableResponses.mapIndexed<Widget>((index, pair) {
              final (response, resolvedQ) = pair;
              final isLast = index == displayableResponses.length - 1;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding
                          .tiny, // Reduced horizontal padding since no container
                      vertical: AppPadding.small,
                    ),
                    child: ResponseDisplay(
                      res: response,
                      resolvedQuestion: resolvedQ,
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: colors.outlineVariant
                          .withValues(alpha: 0.25), // More subtle divider
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Map<String, Question> _resolveQuestions() {
    final Map<String, Question> resolved = {};

    for (final response in detail.responses) {
      final question = response.question;

      if (question.transform != null) {
        final resolvedQuestions = question.resolve(current: detail);
        for (final resolvedQ in resolvedQuestions) {
          if (resolvedQ.prompt.isNotEmpty) {
            resolved[resolvedQ.id] = resolvedQ;
          }
        }
      }
    }
    return resolved;
  }

  List<(Response, Question?)> _getDisplayableResponses(
      Map<String, Question> resolvedQuestions) {
    final List<(Response, Question?)> result = [];

    final Set<String> usedResolvedIds = {};

    for (final response in detail.responses) {
      final question = response.question;
      final prompt = question.prompt;

      if (prompt.isNotEmpty &&
          !prompt.startsWith('{{') &&
          !prompt.contains('{value}')) {
        result.add((response, null));
        continue;
      }

      if (question.id.contains(generatedIdDelimiter)) {
        final resolvedQ = resolvedQuestions[question.id];
        if (resolvedQ != null && resolvedQ.prompt.isNotEmpty) {
          result.add((response, resolvedQ));
          usedResolvedIds.add(question.id);
          continue;
        }
      }

      if (question.id == 'empty' && prompt.isEmpty) {
        for (final entry in resolvedQuestions.entries) {
          if (!usedResolvedIds.contains(entry.key)) {
            result.add((response, entry.value));
            usedResolvedIds.add(entry.key);
            break;
          }
        }
        continue;
      }
    }

    return result;
  }
}

class ResponseDisplay extends ConsumerWidget {
  final Response<Question> res;
  final Question? resolvedQuestion;

  const ResponseDisplay({required this.res, this.resolvedQuestion, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, DisplayBuilder> overrides =
        ref.watch(questionsProvider).valueOrNull?.displayOverrides ?? {};
    final DisplayBuilder? childOverride = overrides[res.question.id];
    if (childOverride != null) return childOverride(context, res);
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Question translatedQuestion =
        localizations?.translateQuestion(res.question) ?? res.question;

    // Use resolved question if provided for prompt and choices
    final Question effectiveQuestion = resolvedQuestion ?? translatedQuestion;
    final String displayPrompt = effectiveQuestion.prompt.isNotEmpty
        ? effectiveQuestion.prompt
        : translatedQuestion.prompt;

    // Compact row-based layout for better scannability
    Widget buildResponseRow(String prompt, String response,
        {bool forceStack = false}) {
      // If response is very long or explicit stack requested, use column
      if (forceStack || response.length > 30) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              prompt,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppPadding.tiny),
            Text(
              response,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              prompt,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(width: AppPadding.small),
          Expanded(
            flex: 2,
            child: Text(
              response,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      );
    }

    // Helper for choice chips/cards
    Widget buildChoiceCard(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.small,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRounding.small),
          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    switch (res) {
      case OpenResponse(response: String response):
        // Always stack free response for better readability
        return buildResponseRow(displayPrompt, response, forceStack: true);
      case NumericResponse(response: num response):
        return buildResponseRow(displayPrompt, response.toString());
      case Selected():
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                displayPrompt,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface
                      .withValues(alpha: 0.8), // Matches other prompts
                ),
              ),
            ),
            const SizedBox(width: AppPadding.small),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.check_circle, size: 20, color: colors.primary),
            ),
          ],
        );
      case MultiResponse(index: int index):
        final choices = effectiveQuestion is MultipleChoice
            ? effectiveQuestion.choices
            : (translatedQuestion as MultipleChoice).choices;
        final choiceText = index < choices.length
            ? (localizations?.value(choices[index]) ?? choices[index])
            : 'Unknown';

        if (choiceText.length < 20) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayPrompt,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: AppPadding.small),
              buildChoiceCard(choiceText),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayPrompt,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppPadding.small),
            buildChoiceCard(choiceText),
          ],
        );
      case AllResponse(responses: List<int> responses):
        final choices = effectiveQuestion is AllThatApply
            ? effectiveQuestion.choices
            : (translatedQuestion as AllThatApply).choices;
        final choiceTexts = responses
            .map((val) => localizations?.value(choices[val]) ?? choices[val])
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayPrompt,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.8),
              ),
            ),
            if (choiceTexts.isNotEmpty) ...[
              const SizedBox(height: AppPadding.small),
              Wrap(
                spacing: AppPadding.small,
                runSpacing: AppPadding.small,
                children: choiceTexts.map((e) => buildChoiceCard(e)).toList(),
              ),
            ],
          ],
        );
      case ResponseWrap(responses: List<Response> responses):
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: responses
              .map((res) => ResponseDisplay(res: res))
              .separated(
                  by: const SizedBox(
                height: AppPadding.tiny,
              ))
              .toList(),
        );
      case SingleResponseWrap(response: Response response):
        return ResponseDisplay(res: response);
    }
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
          height: AppPadding.tiny,
        ),
        Text(
          '${dateToMDY(resp.startEating, context)} - ${timeString(resp.startEating, context)}',
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(
          height: AppPadding.tiny,
        ),
        Text(
          context.translate.mealDurationEntry,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(
          height: AppPadding.tiny,
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
          height: AppPadding.tiny,
        ),
        if (resp.firstBlue != resp.lastBlue) ...[
          Text(
            context.translate.firstBlueEntry,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(
            height: AppPadding.tiny,
          ),
          Text(
            '${dateToMDY(resp.firstBlue, context)} - ${timeString(resp.firstBlue, context)}',
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(
            height: AppPadding.tiny,
          ),
        ],
        Text(
          context.translate.lastBlueEntry,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(
          height: AppPadding.tiny,
        ),
        Text(
          '${dateToMDY(resp.lastBlue, context)} - ${timeString(resp.lastBlue, context)}',
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(
          height: AppPadding.tiny,
        ),
        Text(
          context.translate.transitDurationEntry,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(
          height: AppPadding.tiny,
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
            height: AppPadding.small,
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
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final Question translatedQuestion =
        localizations?.translateQuestion(response.question) ??
            response.question;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            translatedQuestion.prompt,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                ),
            maxLines: null,
          ),
        ),
        const SizedBox(width: AppPadding.small),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${response.response.toInt()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(width: AppPadding.tiny),
            Image.asset(
              paths[response.response.toInt() - 1],
              height: 25,
              fit: BoxFit.fitHeight,
            ),
          ],
        ),
      ],
    );
  }
}

class PainSliderDisplay extends StatelessWidget {
  final NumericResponse response;

  const PainSliderDisplay({required this.response, super.key});

  @override
  Widget build(BuildContext context) {
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final Question translatedQuestion =
        localizations?.translateQuestion(response.question) ??
            response.question;
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            translatedQuestion.prompt,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                ),
            maxLines: null,
          ),
        ),
        const SizedBox(width: AppPadding.small),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (response.response != -1) ...[
              Text(
                '${response.response}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(width: AppPadding.tiny),
            ],
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
                        width: AppPadding.tiny,
                      ),
                      Text(
                        hurtLevels[selectedIndex],
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                      ),
                    ],
                  )
          ],
        ),
      ],
    );
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
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final Question translatedQuestion =
        localizations?.translateQuestion(response.question) ??
            response.question;
    final int res = response.response.toInt();
    final int selectedIndex = (res.toDouble() / 2).floor();
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            translatedQuestion.prompt,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                ),
            maxLines: null,
          ),
        ),
        const SizedBox(width: AppPadding.small),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${response.response}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(width: AppPadding.tiny),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                from(5 - selectedIndex),
                const SizedBox(
                  width: AppPadding.tiny,
                ),
              ],
            )
          ],
        ),
      ],
    );
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
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final AllThatApply translatedQuestion = localizations
            ?.translateQuestion(painLocation.question) as AllThatApply? ??
        painLocation.question;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filledBorder = BorderSide(color: colors.onSurface);
    const blankBorder = BorderSide(color: Colors.transparent);

    final List<String> selectedLocations = painLocation.responses
        .map((res) => res < translatedQuestion.choices.length
            ? translatedQuestion.choices[res]
            : 'Unknown')
        .toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                translatedQuestion.prompt,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(width: AppPadding.small),
          ],
        ),
        if (selectedLocations.isNotEmpty) ...[
          const SizedBox(height: AppPadding.tiny),
          SizedBox(
            height: 26.0,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedLocations.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppPadding.tiny),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.small,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRounding.small),
                    border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    selectedLocations[index],
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (painLocation.responses.isNotEmpty &&
            Area.fromValue(painLocation.responses[0]) != Area.none) ...[
          const SizedBox(height: AppPadding.small),
          ConstrainedBox(
            constraints:
                BoxConstraints(maxHeight: 100, maxWidth: Breakpoint.tiny.value),
            child: Stack(children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: colors.onSurface),
                  borderRadius: BorderRadius.circular(AppRounding.medium),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRounding.medium),
                  clipBehavior: Clip.hardEdge,
                  child: Image.asset(
                    'packages/stripes_ui/assets/images/abdomin.png',
                    fit: BoxFit.fill,
                  ),
                ),
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
                                final bool isSelected =
                                    painLocation.responses.contains(index + 1);
                                return Expanded(
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(AppPadding.tiny),
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
                                            : filledBorder,
                                      ),
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
                                                      center: Alignment.center,
                                                      radius: 0.7,
                                                      colors: [
                                                        colors.error,
                                                        Colors.transparent
                                                      ],
                                                      stops: const [0.1, 1.0],
                                                    )
                                                  : null,
                                            ),
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                      ),
                                    ]),
                                  ),
                                );
                              })
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}
