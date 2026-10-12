import 'package:stripes_ui/Models/pain_intensity.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/pain_intensity_selector.dart';

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

import 'package:stripes_ui/Util/Helpers/repo_result_handler.dart';

import 'package:stripes_ui/Providers/Questions/question_ui_registry.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/CommonWidgets/detail_field.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/blue_dye.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/pain_area.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/Util/Helpers/date_helper.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Design/reading_size.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

bool _useCompactEntries(BuildContext context, double width) {
  final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16;
  final scaledFontSize = MediaQuery.textScalerOf(context).scale(fontSize);
  // Small phones still get cards at ordinary text sizes. Switch only when
  // enlarged text leaves fewer than 18 body-font units across the entry.
  return scaledFontSize >= fontSize * 1.3 && width / scaledFontSize < 18;
}

class RenderEntryGroup extends ConsumerWidget {
  final bool grouped;
  final List<Response> responses;
  const RenderEntryGroup({
    required this.responses,
    required this.grouped,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    if (!grouped) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: responses
            .map((res) => EntryDisplay(event: res))
            .separated(by: const SizedBox(height: AppPadding.small)),
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
            header: Text.rich(
              TextSpan(
                text: localizations?.value(type) ?? type,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text:
                        " · ${context.translate.historyEntryCount(forType.length)}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.left,
            ),
            responses: forType,
          ),
        );
      }).toList(),
    );
  }
}

class RenderEntryGroupSliver extends ConsumerWidget {
  final bool grouped;
  final List<Response> responses;
  const RenderEntryGroupSliver({
    required this.responses,
    required this.grouped,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!grouped) {
      return SliverList.separated(
        itemBuilder: (context, index) => EntryDisplay(event: responses[index]),
        itemCount: responses.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppPadding.tiny),
      );
    }
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
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
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppPadding.tiny),
      itemBuilder: (context, index) {
        final List<Response> forType = byType[typeKeys[index]]!;

        return ExpandibleSymptomArea(
          header: Text.rich(
            TextSpan(
              text: localizations?.value(typeKeys[index]) ?? typeKeys[index],
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text:
                      " · ${context.translate.historyEntryCount(forType.length)}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.left,
          ),
          responses: forType,
        );
      },
      itemCount: typeKeys.length,
    );
  }
}

class ExpandibleSymptomArea extends ConsumerStatefulWidget {
  final List<Response> responses;

  final Widget header;
  final double horizontalInset;

  const ExpandibleSymptomArea({
    required this.header,
    required this.responses,
    this.horizontalInset = 0,
    super.key,
  });

  @override
  ConsumerState<ExpandibleSymptomArea> createState() {
    return _ExpandibleSymptomAreaState();
  }
}

class _ExpandibleSymptomAreaState extends ConsumerState<ExpandibleSymptomArea> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!ref.watch(configProvider).betaUi.compactHistory ||
          !_useCompactEntries(
            context,
            constraints.maxWidth - 2 * widget.horizontalInset,
          )) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalInset),
          child: _buildCard(context),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalInset),
            child: Semantics(
              button: true,
              expanded: expanded,
              child: InkWell(
                onTap: () => setState(() => expanded = !expanded),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Expanded(child: widget.header),
                      const SizedBox(width: AppPadding.small),
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        size: readingIconSize(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (expanded)
            ...widget.responses.map(
              (res) => Padding(
                padding: const EdgeInsets.only(top: AppPadding.small),
                child: EntryDisplay(
                  event: res,
                  horizontalInset: widget.horizontalInset,
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _buildCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRounding.tiny),
        color: ElevationOverlay.applySurfaceTint(
          Theme.of(context).cardColor,
          Theme.of(context).colorScheme.surfaceTint,
          3,
        ),
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
                    .map((res) => EntryDisplay(event: res))
                    .separated(by: const SizedBox(height: AppPadding.small)),
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
                  style: Theme.of(context).textTheme.bodyMedium
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

  final bool hasControls, hasConstraints, includeFullDate, isNested, isReview;
  final String? dateLabel;

  /// Outer margin for cards, or inner padding for full-width compact entries.
  final double horizontalInset;

  const EntryDisplay({
    super.key,
    required this.event,
    this.hasControls = true,
    this.hasConstraints = true,
    this.includeFullDate = false,
    this.isNested = false,
    this.isReview = false,
    this.dateLabel,
    this.horizontalInset = 0,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => EntryDisplayState();
}

class EntryDisplayState extends ConsumerState<EntryDisplay> {
  bool isLoading = false;

  bool? isBlue;

  final ExpansibleController controller = ExpansibleController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final StripesConfig config = ref.watch(configProvider);
    final Map<String, DisplayBuilder> overrides = ref
        .watch(questionUIRegistryProvider)
        .allDisplayOverrides;
    final DateTime date = occurrenceTimeForResponse(widget.event);

    final bool themed = config.betaUi.useCategoryTheme;
    final bool colored = config.betaUi.categoryColorsEnabled;
    final CategoryAppearance appearance = CategoryTheme.resolve(
      widget.event.type,
    );
    final Color accentColor = colored
        ? appearance.color
        : Theme.of(context).dividerColor;

    Widget? content;
    final DisplayBuilder? mainOverride = overrides[widget.event.question.id];
    if (mainOverride != null) return mainOverride(context, widget.event);
    if (widget.event case BlueDyeResp resp) {
      content = BlueDyeVisualDisplay(resp: resp);
    } else if (widget.event case DetailResponse detail) {
      isBlue = _isBlueFromDetail(detail);
      content = DetailDisplay(
        detail: detail,
        accentColor: colored ? appearance.color : null,
      );
    } else {
      content = ResponseDisplay(
        res: widget.event,
        accentColor: colored ? appearance.color : null,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = math.max(
          0.0,
          constraints.maxWidth - 2 * widget.horizontalInset,
        );
        final cardWidth = widget.hasConstraints
            ? math.min(availableWidth, Breakpoint.tiny.value)
            : availableWidth;
        final compact =
            config.betaUi.compactHistory &&
            _useCompactEntries(context, cardWidth);
        final colors = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 0 : widget.horizontalInset,
          ),
          child: ConstrainedBox(
            constraints:
                widget.hasConstraints &&
                    !(compact && widget.horizontalInset > 0)
                ? BoxConstraints(maxWidth: Breakpoint.tiny.value)
                : const BoxConstraints(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                widget.isNested || compact ? 0 : AppRounding.small,
              ),
              child: DecoratedBox(
                decoration: widget.isNested || compact
                    ? const BoxDecoration()
                    : colored
                    ? BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: widget.isReview
                                ? Theme.of(context).colorScheme.primary
                                : accentColor,
                            width: widget.isReview ? 2 : 3,
                          ),
                        ),
                        color: widget.isReview
                            ? Theme.of(context).colorScheme.primaryContainer
                                  .withValues(alpha: 0.1)
                            : accentColor.withValues(alpha: 0.04),
                      )
                    // Non-themed: uniform border, borderRadius is safe.
                    : BoxDecoration(
                        border: Border.all(
                          color: widget.isReview
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
                          width: widget.isReview ? 2 : 1,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppRounding.small),
                        ),
                        color: widget.isReview
                            ? Theme.of(context).colorScheme.primaryContainer
                                  .withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.surface,
                      ),
                child: Padding(
                  padding: compact
                      ? EdgeInsets.zero
                      : const EdgeInsets.all(AppPadding.small),
                  child: Expansible(
                    key: PageStorageKey(
                      'entry-${widget.event.id ?? "${widget.event.type}-${widget.event.stamp}"}',
                    ),
                    animationStyle: MediaQuery.disableAnimationsOf(context)
                        ? AnimationStyle.noAnimation
                        : const AnimationStyle(
                            duration: Durations.short4,
                            curve: Curves.easeInOut,
                          ),
                    expansibleBuilder: (context, header, body, animation) {
                      final contents = Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [header, body],
                      );
                      if (!compact) return contents;
                      return DecoratedBox(
                        key: const ValueKey('compact-entry-surface'),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.horizontalInset,
                            vertical: AppPadding.medium,
                          ),
                          child: contents,
                        ),
                      );
                    },
                    headerBuilder: (context, animation) {
                      final title = Text.rich(
                        TextSpan(
                          text:
                              localizations?.value(widget.event.type) ??
                              widget.event.type,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          children: [
                            if (isBlue != null)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: AppPadding.tiny,
                                  ),
                                  child: Image.asset(
                                    isBlue!
                                        ? 'packages/stripes_ui/assets/images/Blue_Poop.png'
                                        : 'packages/stripes_ui/assets/images/Brown_Poop.png',
                                    width: readingIconSize(context, 18),
                                    height: readingIconSize(context, 18),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                      final timestamp = Text(
                        widget.dateLabel ??
                            (widget.includeFullDate
                                ? "${(date.year == DateTime.now().year ? DateFormat.MMMd() : DateFormat.yMMMd()).format(date)} ${approximateRecordTimeLabel(widget.event, context) ?? timeString(date, context)}"
                                : approximateRecordTimeLabel(
                                        widget.event,
                                        context,
                                      ) ??
                                      timeString(date, context)),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                      final arrow = RotationTransition(
                        turns: animation.drive(
                          Tween<double>(begin: 0, end: 0.5),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: readingIconSize(context),
                        ),
                      );
                      return Semantics(
                        button: true,
                        expanded: controller.isExpanded,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            AppRounding.small,
                          ),
                          onTap: controller.toggle,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (themed && !compact) ...[
                                  CategoryIcon(
                                    appearance: appearance,
                                    size: readingIconSize(context, 14),
                                  ),
                                  const SizedBox(width: AppPadding.tiny),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [title, timestamp],
                                  ),
                                ),
                                const SizedBox(width: AppPadding.small),
                                arrow,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    bodyBuilder: (context, animation) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppPadding.medium),
                        content ?? const SizedBox(),
                        if (widget.hasControls) ...[
                          const SizedBox(height: AppPadding.medium),
                          Row(
                            key: const ValueKey('entry-controls'),
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (widget.event case DetailResponse detail)
                                IconButton(
                                  tooltip: context.translate.historyEditEntry,
                                  onPressed: isLoading
                                      ? null
                                      : () => _edit(detail, context, date),
                                  icon: Icon(
                                    Icons.edit,
                                    size: readingIconSize(context),
                                  ),
                                ),
                              const SizedBox(width: AppPadding.tiny),
                              IconButton(
                                tooltip: context.translate.deleteAction,
                                onPressed: isLoading
                                    ? null
                                    : () => _delete(ref),
                                icon: Icon(
                                  Icons.delete,
                                  size: readingIconSize(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    controller: controller,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool? _isBlueFromDetail(DetailResponse res) {
    final blueRes = res.responses
        .whereType<MultiResponse>()
        .where((val) => val.question.id == "BlueDyeQuestion")
        .toList();
    if (blueRes.isEmpty) return null;
    final MultiResponse multi = blueRes.first;
    return multi.index == 0;
  }

  void _edit(DetailResponse event, BuildContext context, DateTime date) {
    String? routeName = event.type;

    context.pushNamed(
      'recordType',
      pathParameters: {'type': routeName},
      extra: SessionData(
        responses: {for (final r in event.responses) r.question.id: r},
        editId: event.id,
        submitTime: date,
        description: event.description,
      ),
    );
  }

  void _delete(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => DeleteErrorPrevention(
        delete: () async {
          if (mounted) {
            setState(() {
              isLoading = true;
            });
          }

          final stampRepo = await ref.read(stampProvider.future);
          final RepoResult<void> result;
          if (widget.event case TimedDetailResponse(:final entry)) {
            final writer = await ref.read(recordSessionWriterProvider.future);
            result = writer == null
                ? const Failure(message: 'Entry repo not found')
                : await removeRecordedEntry(
                    writer: writer,
                    entry: entry,
                    stampRepo: stampRepo,
                  );
          } else {
            result = stampRepo == null
                ? const Failure(message: 'Stamp repo not found')
                : await stampRepo.removeStamp(widget.event);
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

class DetailDisplay extends ConsumerWidget {
  final DetailResponse detail;
  final Color? accentColor;

  const DetailDisplay({required this.detail, this.accentColor, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasResponses = detail.responses.isNotEmpty;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final AsyncValue<List<Stamp>> baselines = ref.watch(
      baselinesStreamProvider,
    );

    final Map<String, Question> resolvedQuestions = _resolveQuestions(
      QuestionsLocalizations.of(context),
      baselines.value ?? [],
    );
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.translate.descriptionLabel.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: accentColor ?? colors.primary,
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
          // Leave space between question/answer pairs, with a visible rule
          // distinct from the stronger boundary around the complete entry.
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
                      horizontal: AppPadding.tiny,
                      vertical: AppPadding.medium,
                    ),
                    child: ResponseDisplay(
                      res: response,
                      resolvedQuestion: resolvedQ,
                      accentColor: accentColor,
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colors.outlineVariant,
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Map<String, Question> _resolveQuestions(
    QuestionsLocalizations? localizations,
    List<Stamp> baselines,
  ) {
    final Map<String, Question> resolved = {};

    for (final response in detail.responses) {
      final question = response.question;

      if (question.fromBaseline != null) {
        final Response? baseline = baselines.firstWhereOrNull(
          (element) => element.type == question.fromBaseline,
        ) as Response?;

        if (baseline != null) {
          final resolvedQuestions = question.resolveFromBaseline(
            baseline: baseline,
          );
          for (final resolvedQ in resolvedQuestions) {
            if (resolvedQ.prompt.isNotEmpty) {
              final effectiveQ = localizations != null
                  ? localizations.translateQuestion(resolvedQ)
                  : resolvedQ;
              resolved[effectiveQ.id] = effectiveQ;
            }
          }
        }
      } else if (question.transform != null) {
        final resolvedQuestions = question.resolve(current: detail);
        for (final resolvedQ in resolvedQuestions) {
          if (resolvedQ.prompt.isNotEmpty) {
            final effectiveQ = localizations != null
                ? localizations.translateQuestion(resolvedQ)
                : resolvedQ;
            resolved[effectiveQ.id] = effectiveQ;
          }
        }
      }
    }
    return resolved;
  }

  List<(Response, Question?)> _getDisplayableResponses(
    Map<String, Question> resolvedQuestions,
  ) {
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

      if (question.interpolations != null &&
          question.interpolations!.isNotEmpty) {
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
  final Color? accentColor;

  const ResponseDisplay({
    required this.res,
    this.resolvedQuestion,
    this.accentColor,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (accentColor == null) return _buildResponse(context, ref);
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        primaryColor: accentColor,
        colorScheme: theme.colorScheme.copyWith(primary: accentColor),
      ),
      child: Builder(builder: (context) => _buildResponse(context, ref)),
    );
  }

  Widget _buildResponse(BuildContext context, WidgetRef ref) {
    final response = res;
    if (response is UnresolvedResponse) {
      final unresolved = response;
      return ListTile(
        leading: const Icon(Icons.warning_amber_rounded),
        title: const Text('Answer unavailable'),
        subtitle: Text(
          '${unresolved.question.id}\n${unresolved.reason}\nSaved answer retained.',
        ),
      );
    }
    final Map<String, DisplayBuilder> overrides = ref
        .watch(questionUIRegistryProvider)
        .allDisplayOverrides;
    final DisplayBuilder? childOverride = overrides[res.question.id];
    if (childOverride != null) return childOverride(context, res);
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final Color accent = accentColor ?? colors.primary;

    final Question translatedQuestion =
        localizations?.translateQuestion(res.question) ?? res.question;

    // Use resolved question if provided for prompt and choices
    final Question effectiveQuestion = resolvedQuestion ?? translatedQuestion;
    final String displayPrompt = effectiveQuestion.prompt.isNotEmpty
        ? effectiveQuestion.prompt
        : translatedQuestion.prompt;

    Widget buildResponseRow(
      String prompt,
      String value, {
      bool forceStack = false,
    }) => DetailField(
      question: prompt,
      answerText: value,
      alwaysStacked: forceStack,
      answerStyle: textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: accent,
      ),
    );

    // Helper for choice chips/cards
    Widget buildChoiceCard(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.small,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRounding.small),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
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

    switch (response) {
      case UnresolvedResponse(:final reason):
        return Text('Answer unavailable: $reason');
      case OpenResponse(response: String response):
        // Always stack free response for better readability
        return buildResponseRow(displayPrompt, response, forceStack: true);
      case NumericResponse(response: num response):
        return buildResponseRow(displayPrompt, response.toString());
      case Selected():
        final selectedText = context.translate.detailAnswerSelected;
        return DetailField(
          question: displayPrompt,
          answerText: selectedText,
          inlineAnswerText: '',
          inlineExtraWidth: readingIconSize(context, 20) + 4,
          answerBuilder: (stacked) => stacked
              ? Wrap(
                  spacing: AppPadding.tiny,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: readingIconSize(context, 20),
                      color: accent,
                    ),
                    Text(selectedText),
                  ],
                )
              : Semantics(
                  label: selectedText,
                  child: ExcludeSemantics(
                    child: Icon(
                      Icons.check_circle,
                      size: readingIconSize(context, 20),
                      color: accent,
                    ),
                  ),
                ),
        );
      case MultiResponse(index: int index):
        final choices = effectiveQuestion is MultipleChoice
            ? effectiveQuestion.choices
            : (translatedQuestion as MultipleChoice).choices;
        final choiceText = index < choices.length
            ? (localizations?.value(choices[index]) ?? choices[index])
            : 'Unknown';

        return DetailField(
          question: displayPrompt,
          answerText: choiceText,
          answerStyle: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          inlineExtraWidth: AppPadding.small * 2 + 2, // Padding and border.
          answer: buildChoiceCard(choiceText),
        );
      case AllResponse(responses: List<int> responses):
        final choices = effectiveQuestion is AllThatApply
            ? effectiveQuestion.choices
            : (translatedQuestion as AllThatApply).choices;
        final choiceTexts = responses
            .map<String>(
              (val) => localizations?.value(choices[val]) ?? choices[val],
            )
            .toList();

        return DetailField(
          question: displayPrompt,
          answerText: choiceTexts.join(', '),
          alwaysStacked: true,
          answer: Wrap(
            spacing: AppPadding.small,
            runSpacing: AppPadding.small,
            children: choiceTexts.map(buildChoiceCard).toList(),
          ),
        );
      case ResponseWrap(responses: List<Response> responses):
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: responses
              .map((res) => ResponseDisplay(res: res, accentColor: accentColor))
              .separated(by: const SizedBox(height: AppPadding.tiny))
              .toList(),
        );
      case SingleResponseWrap(response: Response response):
        return ResponseDisplay(res: response, accentColor: accentColor);
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
        const SizedBox(height: AppPadding.tiny),
        Text(
          '${dateToMDY(resp.startEating, context)} - ${timeString(resp.startEating, context)}',
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppPadding.tiny),
        Text(
          context.translate.mealDurationEntry,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppPadding.tiny),
        Text(
          prettyDuration(
            resp.eatingDuration,
            abbreviated: true,
            locale:
                DurationLocale.fromLanguageCode(current.languageCode) ??
                const EnglishDurationLocale(),
          ),
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppPadding.tiny),
        if (resp.firstBlue != resp.lastBlue) ...[
          Text(
            context.translate.firstBlueEntry,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppPadding.tiny),
          Text(
            '${dateToMDY(resp.firstBlue, context)} - ${timeString(resp.firstBlue, context)}',
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppPadding.tiny),
        ],
        Text(
          context.translate.lastBlueEntry,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppPadding.tiny),
        Text(
          '${dateToMDY(resp.lastBlue, context)} - ${timeString(resp.lastBlue, context)}',
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppPadding.tiny),
        Text(
          context.translate.transitDurationEntry,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppPadding.tiny),
        Text(
          prettyDuration(
            resp.lastBlue.difference(resp.startEating.add(resp.eatingDuration)),
            delimiter: ' ',
            locale:
                DurationLocale.fromLanguageCode(current.languageCode) ??
                const EnglishDurationLocale(),
            abbreviated: true,
          ),
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

  const DeleteErrorPrevention({
    required this.delete,
    required this.type,
    super.key,
  });

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
          const SizedBox(height: AppPadding.small),
          Text(
            context.translate.stampDeleteWarningTwo,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _confirm(WidgetRef ref) {
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
      'packages/stripes_ui/assets/images/poop7.png',
    ];
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final Question translatedQuestion =
        localizations?.translateQuestion(response.question) ??
        response.question;
    final type = response.response.toInt();
    return DetailField(
      question: translatedQuestion.prompt,
      answerText: '$type',
      inlineExtraWidth: 64,
      answer: Wrap(
        spacing: AppPadding.tiny,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$type'),
          if (type >= 1 && type <= paths.length)
            SizedBox(
              width: 60,
              height: 25,
              child: Image.asset(paths[type - 1], fit: BoxFit.contain),
            ),
        ],
      ),
    );
  }
}

class PainSliderDisplay extends StatelessWidget {
  final NumericResponse response;

  const PainSliderDisplay({required this.response, super.key});

  @override
  Widget build(BuildContext context) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final Question translatedQuestion =
        localizations?.translateQuestion(response.question) ??
        response.question;
    final score = response.response;
    final band = PainIntensityBand.fromScore(score);
    final scoreLabel = score % 1 == 0 ? '${score.toInt()}' : '$score';
    final description = band == null ? null : painIntensityLabel(context, band);
    return DetailField(
      question: translatedQuestion.prompt,
      answerText: score == -1
          ? context.translate.painIntensityNotSure
          : description == null
          ? scoreLabel
          : '$scoreLabel · $description',
    );
  }
}

class MoodSliderDisplay extends StatelessWidget {
  final NumericResponse response;

  const MoodSliderDisplay({required this.response, super.key});

  @override
  Widget build(BuildContext context) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final Question translatedQuestion =
        localizations?.translateQuestion(response.question) ??
        response.question;
    final int res = response.response.toInt();
    final int selectedIndex = (res.toDouble() / 2).floor();
    return DetailField(
      question: translatedQuestion.prompt,
      answerText: '$res',
      inlineExtraWidth: 29,
      answer: Wrap(
        spacing: AppPadding.tiny,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [Text('$res'), from((5 - selectedIndex).clamp(0, 5))],
      ),
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
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final AllThatApply translatedQuestion =
        localizations?.translateQuestion(painLocation.question)
            as AllThatApply? ??
        painLocation.question;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filledBorder = BorderSide(color: colors.onSurface);
    const blankBorder = BorderSide(color: Colors.transparent);

    final List<String> selectedLocations = painLocation.responses
        .map(
          (res) => res < translatedQuestion.choices.length
              ? translatedQuestion.choices[res]
              : 'Unknown',
        )
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
          Wrap(
            spacing: AppPadding.tiny,
            runSpacing: AppPadding.tiny,
            children: [
              for (final location in selectedLocations)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.small,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRounding.small),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    location,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (painLocation.responses.isNotEmpty &&
            Area.fromValue(painLocation.responses[0]) != Area.none) ...[
          const SizedBox(height: AppPadding.small),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 100,
              maxWidth: Breakpoint.tiny.value,
            ),
            child: Stack(
              children: [
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
                                  final bool isSelected = painLocation.responses
                                      .contains(index + 1);
                                  return Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        AppPadding.tiny,
                                      ),
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
                                      child: Stack(
                                        children: [
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
                                                            colors.error,
                                                            Colors.transparent,
                                                          ],
                                                          stops: const [
                                                            0.1,
                                                            1.0,
                                                          ],
                                                        )
                                                      : null,
                                                ),
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
