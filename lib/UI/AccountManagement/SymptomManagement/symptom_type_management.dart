import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/CommonWidgets/type_tag.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';

class SymptomTypeManagement extends ConsumerStatefulWidget {
  final String? category;

  const SymptomTypeManagement({required this.category, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _SymptomTypeManagementState();
  }
}

class _SymptomTypeManagementState extends ConsumerState<SymptomTypeManagement> {
  bool editing = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(questionHomeProvider);
    final AsyncValue<PagesData> pagesData =
        ref.watch(pagesByPath(PagesByPathProps(pathName: widget.category)));

    Widget topRow(PagesData data) {
      return Row(
        children: [
          IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed(RouteName.SYMPTOMS);
                }
              },
              icon: const Icon(Icons.keyboard_arrow_left)),
          widget.category != null
              ? Text(
                  widget.category!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.left,
                )
              : Text(
                  "No Category Provided",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.left,
                ),
          const Spacer(),
          if (!editing) ...[
            IconButton(
              onPressed: data.loadedLayouts?.isEmpty ?? true
                  ? null
                  : () {
                      setState(() {
                        editing = !editing;
                      });
                    },
              icon: const Icon(Icons.edit),
            ),
            IconButton(
                onPressed: widget.category == null
                    ? null
                    : () {
                        showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) {
                              return AddSymptomWidget(type: widget.category!);
                            });
                      },
                icon: const Icon(Icons.add)),
            const SizedBox(
              width: AppPadding.tiny,
            ),
          ]
        ],
      );
    }

    Widget createNewCategory() {
      return Center(
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const Text("Category not created"),
          const SizedBox(
            height: AppPadding.small,
          ),
          FilledButton.icon(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final QuestionRepo? repo =
                    await ref.read(questionsProvider.future);
                if (repo == null) {
                  if (context.mounted) {
                    showSnack(context, "Failed to add ${widget.category}");
                  }
                  return;
                }
                final bool added = await repo.addRecordPath(
                  RecordPath(
                      pages: const [],
                      period: null,
                      userCreated: true,
                      name: widget.category!),
                );
                if (!added && context.mounted) {
                  showSnack(context, "Failed to add ${widget.category}");
                }
              },
              label: const Text("Create"))
        ]),
      );
    }

    return AsyncValueDefaults(
      value: pagesData,
      onData: (loadedPagesData) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: AppPadding.large,
            ),
            topRow(loadedPagesData),
            const SizedBox(
              height: AppPadding.medium,
            ),
            Divider(
              thickness: 1,
              height: 1,
              endIndent: AppPadding.small,
              indent: AppPadding.small,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            if (loadedPagesData.loadedLayouts == null &&
                widget.category != null)
              createNewCategory(),
            if (loadedPagesData.loadedLayouts != null &&
                widget.category != null)
              Expanded(
                child: editing
                    ? EditingMode(
                        pagesData: loadedPagesData,
                        setNotEditing: () {
                          if (mounted) {
                            setState(() {
                              editing = false;
                            });
                          }
                        },
                      )
                    : RefreshWidget(
                        depth: RefreshDepth.subuser,
                        scrollable: ViewingMode(
                          type: widget.category!,
                          pages: loadedPagesData.loadedLayouts!,
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }
}

class EditingMode extends ConsumerStatefulWidget {
  final PagesData pagesData;

  final Function setNotEditing;

  const EditingMode(
      {required this.pagesData, required this.setNotEditing, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _EditingModeState();
  }
}

class _EditingModeState extends ConsumerState<EditingMode>
    with SingleTickerProviderStateMixin {
  late List<LoadedPageLayout> layouts;

  late List<LoadedPageLayout> dependentLayouts;

  late final ScrollController scrollController;

  bool isDragging = false;

  double? listHeight;

  @override
  void initState() {
    scrollController = ScrollController();
    layouts = widget.pagesData.loadedLayouts!;
    dependentLayouts = layouts
        .where((layout) => layout.dependsOn != const DependsOn.nothing())
        .toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildList(),
        !isDragging
            ? const SizedBox()
            : Align(
                alignment: Alignment.topCenter,
                child: DragTarget<Question>(
                  builder:
                      (context, List<Question?> candidateData, rejectedData) =>
                          Container(
                    height: 40.0,
                    width: double.infinity,
                    color: Colors.transparent,
                  ),
                  onWillAcceptWithDetails: (_) {
                    _moveUp();
                    return false;
                  },
                ),
              ),
        !isDragging
            ? const SizedBox()
            : Align(
                alignment: Alignment.bottomCenter,
                child: DragTarget<Question>(
                  builder:
                      (context, List<Question?> candidateData, rejectedData) =>
                          Container(
                    height: 20.0,
                    width: double.infinity,
                    color: Colors.transparent,
                  ),
                  onWillAcceptWithDetails: (_) {
                    _moveDown();
                    return false;
                  },
                ),
              ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppPadding.xxl,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface,
                    spreadRadius: 2,
                    blurRadius: 2,
                    blurStyle: BlurStyle.outer,
                    offset: const Offset(0, 0),
                  ),
                ],
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.all(
                  Radius.circular(100.0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 100,
                    child: TextButton(
                      onPressed: () {
                        widget.setNotEditing();
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ),
                  Container(
                    width: 1.0,
                    height:
                        Theme.of(context).buttonTheme.height - AppPadding.small,
                    color: Theme.of(context).dividerColor,
                  ),
                  SizedBox(
                    width: 100,
                    child: TextButton(
                      onPressed: () async {
                        if (await _save()) {
                          widget.setNotEditing();
                        } else if (context.mounted) {
                          showSnack(context, "Failed to edit layouts");
                        }
                      },
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  _moveUp() {
    final double height = (listHeight ?? 400);
    final double endpoint = max(scrollController.offset - height,
        scrollController.position.minScrollExtent);
    final int travelInMillis =
        (((endpoint - scrollController.offset).abs() / height) *
                Durations.long1.inMilliseconds)
            .round();
    if (travelInMillis == 0) return;
    scrollController.animateTo(endpoint,
        curve: Curves.linear, duration: Duration(milliseconds: travelInMillis));
  }

  _moveDown() {
    final double height = (listHeight ?? 400);
    final double endpoint = min(scrollController.offset + height,
        scrollController.position.maxScrollExtent);
    final int travelInMillis =
        (((endpoint - scrollController.offset).abs() / height) *
                Durations.long1.inMilliseconds)
            .round();
    if (travelInMillis == 0) return;
    scrollController.animateTo(endpoint,
        curve: Curves.linear, duration: Duration(milliseconds: travelInMillis));
  }

  Widget _buildDropPreview(BuildContext context, Question? value) {
    return SizedBox(
        height: 60,
        child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
        ));
  }

  Widget _buildList() {
    List<Widget> widgets = [];

    for (int i = 0; i < layouts.length; i++) {
      final LoadedPageLayout page = layouts[i];

      final bool isDependentPage = page.dependsOn != const DependsOn.nothing();

      String dependentTooltipText() {
        String? promptProvider(String qid) {
          final Iterable<Question> questionMatch = layouts
              .map((layout) => layout.questions)
              .flattenedToList
              .where((question) => question.id == qid);
          if (questionMatch.isEmpty) return null;
          return questionMatch.first.prompt;
        }

        return page.dependsOn.toReadableString(promptProvider: promptProvider);
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.large, vertical: AppPadding.tiny),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Page ${i + 1}",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (isDependentPage)
                TypeTag(
                  text: "conditional",
                  onHover: dependentTooltipText(),
                  onHoverTitle: "Depends on:",
                ),
            ],
          ),
        ),
      );

      const double sepHeight = AppPadding.xl;

      const Widget sep = Divider(
        height: sepHeight,
        endIndent: AppPadding.large,
        indent: AppPadding.large,
      );

      final List<Question> pageQuestions = page.questions;

      void onAccept(DragTargetDetails<Question> details, int insertIndex) {
        bool found = false;
        bool wasInSameLayout = false;
        for (int i = 0; i < layouts.length; i++) {
          final LoadedPageLayout pageLayout = layouts[i];
          for (int j = 0; j < pageLayout.questions.length; j++) {
            if (pageLayout.questions[j] == details.data) {
              if (page == pageLayout && insertIndex > j) {
                wasInSameLayout = true;
              }
              final List<Question> newQuestions = pageLayout.questions
                ..removeAt(j);
              if (newQuestions.isEmpty) {
                layouts.removeAt(i);
              } else {
                layouts[i] = pageLayout.copyWith(questions: newQuestions);
              }
              found = true;
              break;
            }
          }
          if (found) break;
        }

        pageQuestions.insert(
            wasInSameLayout ? insertIndex - 1 : insertIndex, details.data);
        setState(() {});
      }

      for (int j = 0; j < pageQuestions.length; j++) {
        final Question question = pageQuestions[j];

        bool isNeighbor(Question candidate) {
          if (candidate == question) return true;
          if ((j + 1 < pageQuestions.length &&
                  pageQuestions[j + 1] == question) ||
              (j - 1 >= 0 && pageQuestions[j - 1] == question)) {
            return true;
          }
          return false;
        }

        Widget separator = j == 0
            ? const SizedBox(
                height: sepHeight,
              )
            : sep;

        widgets.add(
          isDependentPage
              ? separator
              : DragTarget<Question>(
                  builder: (context, List<Question?> candidates, rejects) {
                    if (candidates.isEmpty || candidates[0] == null) return sep;
                    final Question candidate = candidates[0]!;
                    return !isNeighbor(candidate)
                        ? _buildDropPreview(context, candidates[0])
                        : separator;
                  },
                  onWillAcceptWithDetails: (details) {
                    return !isNeighbor(details.data) ||
                        !existsInPreviousDependency(i, question);
                  },
                  onAcceptWithDetails: (details) {
                    onAccept(details, j);
                  },
                ),
        );
        widgets.add(isDependentPage
            ? _symptomDisplay(question: question, enabled: false)
            : _buildSymptom(question));
      }
      widgets.add(
        isDependentPage
            ? const SizedBox(
                height: sepHeight,
              )
            : DragTarget<Question>(
                onWillAcceptWithDetails: (details) {
                  if (existsInPreviousDependency(i, details.data)) return false;
                  return details.data !=
                      pageQuestions[pageQuestions.length - 1];
                },
                onAcceptWithDetails: (details) {
                  onAccept(details, pageQuestions.length);
                },
                builder: (context, List<Question?> candidates, rejects) {
                  if (candidates.isEmpty || candidates[0] == null) return sep;
                  final Question candidate = candidates[0]!;
                  return pageQuestions.isEmpty ||
                          candidate != pageQuestions.last
                      ? _buildDropPreview(context, candidates[0])
                      : const SizedBox(
                          height: sepHeight,
                        );
                },
              ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      listHeight = constraints.maxHeight;
      return ListView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        children: [
          const SizedBox(
            height: AppPadding.xxxl,
          ),
          DragTarget<Question>(
            builder:
                (context, List<Question?> candidates, List<dynamic> rejects) {
              if (candidates.isEmpty || candidates[0] == null) {
                return const SizedBox(
                  height: AppPadding.xl,
                );
              }
              final Question candidate = candidates[0]!;
              return _buildDropPreview(context, candidate);
            },
            onWillAcceptWithDetails: (details) {
              return existsInDependency(details.data) == null;
            },
            onAcceptWithDetails: (details) {
              bool found = false;
              for (int i = 0; i < layouts.length; i++) {
                final LoadedPageLayout pageLayout = layouts[i];
                for (int j = 0; j < pageLayout.questions.length; j++) {
                  if (pageLayout.questions[j] == details.data) {
                    final List<Question> newQuestions = pageLayout.questions
                      ..removeAt(j);
                    if (newQuestions.isEmpty) {
                      layouts.removeAt(i);
                    } else {
                      layouts[i] = pageLayout.copyWith(questions: newQuestions);
                    }
                    found = true;
                    break;
                  }
                }
                if (found) break;
              }
              layouts.insert(
                  0,
                  LoadedPageLayout(
                      questions: [details.data],
                      dependsOn: const DependsOn.nothing()));
              setState(() {});
            },
          ),
          ...widgets,
          if (isDragging) ...[
            Padding(
              padding: const EdgeInsets.only(
                  left: AppPadding.large, bottom: AppPadding.tiny),
              child: Text(
                "Page ${layouts.length + 1}",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ),
            DragTarget<Question>(
              builder:
                  (context, List<Question?> candidates, List<dynamic> rejects) {
                if (candidates.isEmpty || candidates[0] == null) {
                  return const SizedBox(
                    height: AppPadding.xl,
                  );
                }
                final Question candidate = candidates[0]!;
                return _buildDropPreview(context, candidate);
              },
              onWillAcceptWithDetails: (details) {
                return existsInDependency(details.data) == null;
              },
              onAcceptWithDetails: (details) {
                bool found = false;
                for (int i = 0; i < layouts.length; i++) {
                  final LoadedPageLayout pageLayout = layouts[i];
                  for (int j = 0; j < pageLayout.questions.length; j++) {
                    if (pageLayout.questions[j] == details.data) {
                      final List<Question> newQuestions = pageLayout.questions
                        ..removeAt(j);
                      if (newQuestions.isEmpty) {
                        layouts.removeAt(i);
                      } else {
                        layouts[i] =
                            pageLayout.copyWith(questions: newQuestions);
                      }
                      found = true;
                      break;
                    }
                  }
                  if (found) break;
                }
                layouts.add(LoadedPageLayout(
                    questions: [details.data],
                    dependsOn: const DependsOn.nothing()));
                setState(() {});
              },
            ),
          ],
          const SizedBox(
            height: 150,
          ),
        ],
      );
    });
  }

  Widget _symptomDisplay({required Question question, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppPadding.tiny, horizontal: AppPadding.large),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: SymptomInfoDisplay(question: question),
          ),
          const SizedBox(width: AppPadding.tiny),
          if (enabled)
            const Icon(
              Icons.drag_handle,
            )
        ],
      ),
    );
  }

  Widget _buildSymptom(Question question) {
    return Draggable<Question>(
      affinity: Axis.vertical,
      maxSimultaneousDrags: 1,
      data: question,
      axis: Axis.vertical,
      hitTestBehavior: HitTestBehavior.deferToChild,
      feedback: Padding(
        padding: const EdgeInsetsGeometry.symmetric(vertical: AppPadding.large),
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).primaryColor,
                  blurStyle: BlurStyle.outer,
                  blurRadius: 2.0,
                  spreadRadius: 2.0)
            ],
          ),
          child: _symptomDisplay(question: question),
        ),
      ),
      onDragStarted: () {
        setState(() {
          isDragging = true;
        });
      },
      onDragEnd: (_) {
        setState(() {
          isDragging = false;
        });
      },
      childWhenDragging: const SizedBox(),
      child: _symptomDisplay(question: question),
    );
  }

  LoadedPageLayout? existsInDependency(Question question) {
    for (final LoadedPageLayout dependentLayout in dependentLayouts) {
      for (final RelationOp op in dependentLayout.dependsOn.operations) {
        for (final Relation rel in op.relations) {
          if (question.id == rel.qid) return dependentLayout;
        }
      }
    }
    return null;
  }

  bool existsInPreviousDependency(int pageIndex, Question question) {
    final LoadedPageLayout? dependency = existsInDependency(question);
    if (dependency == null) return false;
    final int index = layouts.indexOf(dependency);
    return pageIndex < index;
  }

  Future<bool> _save() async {
    final RecordPath path = widget.pagesData.path!;
    final List<PageLayout> newPages =
        layouts.map((layout) => layout.toPageLayout()).toList();
    final QuestionRepo? repo = await ref.read(questionsProvider.future);
    return await repo?.updateRecordPath(path.copyWith(pages: newPages)) ??
        false;
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

class ViewingMode extends ConsumerWidget {
  final String type;

  final List<LoadedPageLayout> pages;

  const ViewingMode({required this.type, required this.pages, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(questionsProvider);

    Iterable<Widget> questionDisplays() {
      List<Widget> displays = [];
      for (final (int index, LoadedPageLayout page) in pages.indexed) {
        displays.addAll([
          Padding(
            padding: const EdgeInsetsGeometry.only(left: AppPadding.small),
            child: Text("Page ${index + 1}",
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Divider(
            endIndent: AppPadding.small,
            indent: AppPadding.small,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          ...page.questions
              .map((question) => SymptomDisplay(question: question))
              .separated(
                by: Divider(
                  endIndent: AppPadding.medium,
                  indent: AppPadding.medium,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
        ]);
      }
      return displays;
    }

    return SingleChildScrollView(
      key: const PageStorageKey("SymptomScreen"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: AppPadding.small,
          ),
          ...questionDisplays(),
          const SizedBox(
            height: 100,
          ),
        ],
      ),
    );
  }
}

class SymptomDisplay extends ConsumerWidget {
  final Question question;

  const SymptomDisplay({required this.question, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Iterable<Widget>? added;

    if (question
        case AllThatApply(choices: List<String> choices) ||
            MultipleChoice(choices: List<String> choices)) {
      added = [
        SizedBox(
          height: 60.0,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            const SizedBox(
              width: AppPadding.large,
            ),
            ...choices.map((choice) => Chip(label: Text(choice))).separated(
                  by: const SizedBox(
                    width: AppPadding.tiny,
                  ),
                ),
            const SizedBox(
              width: AppPadding.large,
            ),
          ]),
        ),
      ];
    } else if (question case Numeric(min: num? min, max: num? max)) {
      added = [
        Padding(
          padding: const EdgeInsetsGeometry.only(left: AppPadding.large),
          child: Text("${min ?? 1} - ${max ?? 5}"),
        )
      ];
    }

    Widget editsRow() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Switch(
            value: question.enabled,
            onChanged: question.locked
                ? null
                : (_) async {
                    if (!await (await ref.read(questionsProvider.future))!
                            .setQuestionEnabled(question, !question.enabled) &&
                        context.mounted) {
                      showSnack(context,
                          "Failed to ${!question.enabled ? "enable" : "disable"} ${question.prompt}");
                    }
                  },
            thumbIcon: question.locked
                ? WidgetStateProperty.all(const Icon(Icons.lock))
                : null,
          ),
          IconButton(
              onPressed: question.userCreated
                  ? () async {
                      if (!await (await ref.read(questionsProvider.future))!
                              .removeQuestion(question) &&
                          context.mounted) {
                        showSnack(
                            context, "Failed to delete ${question.prompt}");
                      }
                    }
                  : null,
              icon: const Icon(Icons.delete))
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppPadding.tiny, horizontal: AppPadding.large),
          child: Row(
            children: [
              Expanded(
                child: SymptomInfoDisplay(question: question),
              ),
              const SizedBox(
                width: AppPadding.tiny,
              ),
              IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return SizedBox();
                        });
                  },
                  icon: const Icon(Icons.more_horiz))
            ],
          ),
        ),
        if (added != null) ...added,
      ],
    );
  }
}

class SymptomEditSheet extends ConsumerStatefulWidget {
  final Question question;
  const SymptomEditSheet({required this.question, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return SymptomEditSheetState();
  }
}

class SymptomEditSheetState extends ConsumerState<SymptomEditSheet> {
  @override
  Widget build(BuildContext context) {
    final Question? question = ref.watch(
      questionHomeProvider.select(
        (value) => value.valueOrNull?.forDisplay(widget.question.id),
      ),
    );
    return SizedBox(
      width: double.infinity,
      child: Padding(
          padding:
              const EdgeInsetsGeometry.symmetric(horizontal: AppPadding.large),
          child:
              SizedBox() /* AsyncValueDefaults(
          value: path,
          onData: (path) {
            if (path == null) return Text("Failed to load ${widget.path.name}");
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  height: AppPadding.large,
                ),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          text: path.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: path.enabled
                                      ? null
                                      : Theme.of(context).disabledColor),
                          children: [
                            if (widget.path.userCreated) ...[
                              TextSpan(
                                text: " · custom category",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.75),
                                    ),
                              )
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: AppPadding.tiny,
                    ),
                    IconButton(
                        onPressed: () {
                          context.pop();
                        },
                        icon: const Icon(Icons.keyboard_arrow_down))
                  ],
                ),
                Text(
                  "$symptoms symptom${symptoms == 1 ? "" : "s"}${path.period != null ? " / ${path.period!.name}" : ""}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.75)),
                ),
                const SizedBox(
                  height: AppPadding.small,
                ),
                const Divider(),
                if (path.locked && lockTried)
                  Center(
                    child: Text(
                      "This category is currently locked on ${widget.path.enabled ? "enabled" : "disabled"}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Row(
                  children: [
                    Text(
                      "Enabled",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          lockTried = true;
                        });
                      },
                      child: Switch(
                        value: path.enabled,
                        onChanged: path.locked
                            ? null
                            : (_) async {
                                if (!await (await ref
                                            .read(questionsProvider.future))!
                                        .setQuestionEnabled(
                                            question, !question.enabled) &&
                                    context.mounted) {
                                  showSnack(context,
                                      "Failed to ${!question.enabled ? "enable" : "disable"} ${question.prompt}");
                                }
                              },
                        thumbIcon: path.locked
                            ? WidgetStateProperty.all(const Icon(Icons.lock))
                            : null,
                      ),
                    ),
                  ],
                ),
                if (!path.userCreated && deleteTried)
                  Center(
                    child: Text(
                      "Cannot delete a predefined category. Disable it to remove it from the record page",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        deleteTried = true;
                      });
                    },
                    child: FilledButton.icon(
                      onPressed: path.userCreated
                          ? () async {
                              if (!await (await ref
                                          .read(questionsProvider.future))!
                                      .removeRecordPath(widget.path) &&
                                  context.mounted) {
                                showSnack(context,
                                    "Failed to deleted ${widget.path.name}");
                              }
                            }
                          : null,
                      label: const Text("Delete"),
                      icon: const Icon(Icons.delete),
                    ),
                  ),
                ),
              ],
            );
          },
        ),*/
          ),
    );
  }
}

class SymptomInfoDisplay extends StatelessWidget {
  final Question question;
  const SymptomInfoDisplay({required this.question, super.key});

  @override
  Widget build(BuildContext context) {
    final QuestionType type = QuestionType.from(question);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
              text: question.prompt,
              style: Theme.of(context).textTheme.titleMedium,
              children: [
                if (question.isRequired)
                  const TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                if (question.userCreated)
                  TextSpan(
                    text: " · custom symptom",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.75),
                        ),
                  ),
              ]),
        ),
        const SizedBox(
          height: AppPadding.tiny,
        ),
        Text(
          type.value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.75)),
        ),
      ],
    );
  }
}

class AddSymptomWidget extends ConsumerStatefulWidget {
  final String type;

  const AddSymptomWidget({required this.type, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _AddSymptomWidgetState();
  }
}

class _AddSymptomWidgetState extends ConsumerState<AddSymptomWidget> {
  final TextEditingController prompt = TextEditingController();

  final TextEditingController minValue = TextEditingController(text: "1");
  final TextEditingController maxValue = TextEditingController(text: "5");
  List<String> choices = [];

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isLoading = false, submitSuccess = false, isRequired = false;

  QuestionType selectedQuestionType = QuestionType.check;

  @override
  Widget build(BuildContext context) {
    ref.watch(pagesByPath(PagesByPathProps(pathName: widget.type)));
    return DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        snap: true,
        expand: false,
        snapSizes: const [
          0.55,
          0.9,
        ],
        builder: (context, controller) {
          return Padding(
            padding: const EdgeInsets.only(
                left: AppPadding.medium,
                right: AppPadding.medium,
                top: AppPadding.large),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add Symptom",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Expanded(
                  child: Form(
                    key: formKey,
                    child: Opacity(
                      opacity: isLoading ? 0.6 : 1.0,
                      child: IgnorePointer(
                        ignoring: isLoading,
                        child: ListView(
                          controller: controller,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Symptom type",
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const Spacer(),
                                const SizedBox(
                                  width: AppPadding.tiny,
                                ),
                                Expanded(
                                  child: DropdownMenuFormField<QuestionType>(
                                    dropdownMenuEntries: QuestionType.ordered
                                        .map(
                                          (option) => DropdownMenuEntry(
                                              label: option.value,
                                              value: option),
                                        )
                                        .toList(),
                                    initialSelection: QuestionType.check,
                                    enableSearch: false,
                                    enableFilter: false,
                                    onSelected: (option) {
                                      if (option == null) return;
                                      setState(() {
                                        selectedQuestionType = option;
                                      });
                                    },
                                    inputDecorationTheme:
                                        InputDecorationThemeData(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppPadding.tiny),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: AppPadding.small,
                            ),
                            LabeledField(
                              label: "prompt",
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(AppRounding.tiny),
                                    ),
                                  ),
                                ),
                                controller: prompt,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a prompt';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(
                              height: AppPadding.small,
                            ),
                            if (selectedQuestionType == QuestionType.slider)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: LabeledField(
                                      label: "min",
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(AppRounding.tiny),
                                            ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        controller: minValue,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a minimum';
                                          }
                                          int? minNum = int.tryParse(value);
                                          int? maxNum =
                                              int.tryParse(maxValue.text);
                                          if (minNum == null ||
                                              maxNum == null) {
                                            return "Must have a range";
                                          }
                                          if (minNum >= maxNum) {
                                            return "Invalid range";
                                          }
                                          return null;
                                        },
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 20.0,
                                  ),
                                  Expanded(
                                    child: LabeledField(
                                      label: "max",
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(AppRounding.tiny),
                                            ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        controller: maxValue,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a minimum';
                                          }
                                          int? maxNum = int.tryParse(value);
                                          int? minNum =
                                              int.tryParse(minValue.text);
                                          if (minNum == null ||
                                              maxNum == null) {
                                            return "Must have a range";
                                          }
                                          if (maxNum <= minNum) {
                                            return "Invalid range";
                                          }
                                          return null;
                                        },
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (selectedQuestionType ==
                                    QuestionType.multipleChoice ||
                                selectedQuestionType ==
                                    QuestionType.allThatApply)
                              ChoicesFormField(
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? "Must have at least one option"
                                        : null,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    choices = value;
                                  });
                                },
                                initialValue: choices,
                              ),
                            const SizedBox(
                              height: AppPadding.large,
                            ),
                            Row(
                              children: [
                                Text(
                                  "Is required",
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                const SizedBox(
                                  width: AppPadding.tiny,
                                ),
                                Checkbox(
                                    value: isRequired,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        isRequired = value;
                                      });
                                    }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        border: const Border(top: BorderSide()),
                        color: Theme.of(context).colorScheme.surface),
                    child: Padding(
                      padding: const EdgeInsetsGeometry.symmetric(
                          vertical: AppPadding.small),
                      child: FilledButton(
                        onPressed: () async {
                          await add();
                        },
                        child: submitSuccess
                            ? const Icon(Icons.check)
                            : isLoading
                                ? const ButtonLoadingIndicator()
                                : const Text("Add Symptom"),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Future<void> add() async {
    if (isLoading) return;

    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });
    Question question;
    switch (selectedQuestionType) {
      case QuestionType.check:
        question = Check(
            id: "",
            prompt: prompt.text,
            type: widget.type,
            isRequired: isRequired,
            userCreated: true);
      case QuestionType.freeResponse:
        question = FreeResponse(
            id: "",
            prompt: prompt.text,
            type: widget.type,
            isRequired: isRequired,
            userCreated: true);
      case QuestionType.slider:
        question = Numeric(
            id: "",
            prompt: prompt.text,
            type: widget.type,
            isRequired: isRequired,
            userCreated: true);
      case QuestionType.multipleChoice:
        question = MultipleChoice(
            id: "",
            prompt: prompt.text,
            type: widget.type,
            choices: choices,
            isRequired: isRequired,
            userCreated: true);
      case QuestionType.allThatApply:
        question = AllThatApply(
            id: "",
            prompt: prompt.text,
            type: widget.type,
            choices: choices,
            isRequired: isRequired,
            userCreated: true);
    }
    final bool added =
        await (await ref.read(questionsProvider.future))!.addQuestion(question);

    if (added) {
      if (mounted) {
        setState(() {
          submitSuccess = true;
        });
      }
      await Future.delayed(Durations.long4);
      prompt.clear();
      minValue.clear();
      maxValue.clear();
      choices.clear();
      formKey.currentState?.reset();
    } else if (mounted) {
      context.pop();
      showSnack(context, "Failed to add question");
    }

    if (mounted) {
      setState(() {
        submitSuccess = false;
        isLoading = false;
        context.pop();
      });
    }
  }
}

class ChoicesFormField extends FormField<List<String>> {
  ChoicesFormField({
    super.key,
    super.onSaved,
    super.validator,
    ValueChanged<List<String>?>? onChanged,
    List<String> super.initialValue = const [],
  }) : super(
          builder: (FormFieldState<List<String>> state) {
            final TextEditingController controller = TextEditingController();

            void onChangedHandler(List<String>? value) {
              state.didChange(value);
              if (onChanged != null) {
                onChanged(value);
              }
            }

            return UnmanagedRestorationScope(
              bucket: state.bucket,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.value != null)
                    LabeledField(
                      label: "Choice",
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(AppRounding.tiny),
                                ),
                              ),
                            ),
                            controller: controller,
                          ),
                        ),
                        const SizedBox(
                          width: AppPadding.small,
                        ),
                        IconButton.filled(
                            onPressed: () {
                              if (controller.text.isNotEmpty) {
                                if (state.value != null) {
                                  onChangedHandler([
                                    ...state.value!,
                                    controller.text,
                                  ]);
                                } else {
                                  onChangedHandler([controller.text]);
                                }
                                controller.clear();
                              }
                            },
                            icon: const Icon(Icons.add)),
                      ]),
                    ),
                  ...state.value!
                      .mapIndexed(
                        (index, choice) => ListTile(
                          title: Text(choice),
                          trailing: IconButton(
                            onPressed: () {
                              onChangedHandler(state.value!..removeAt(index));
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ),
                      )
                      .separated(by: const Divider()),
                  if (state.hasError) ...[
                    const SizedBox(
                      height: AppPadding.tiny,
                    ),
                    Text(
                      state.errorText!,
                      style: TextStyle(
                          fontSize: 12.0,
                          color: Theme.of(state.context).colorScheme.error),
                    ),
                  ],
                ],
              ),
            );
          },
        );
}

class LabeledField extends StatelessWidget {
  final Widget child;
  final String label;

  const LabeledField({required this.label, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.75),
                ),
          ),
          const SizedBox(
            height: AppPadding.tiny,
          ),
          child
        ],
      ),
    );
  }
}
