import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_header.dart';
import 'package:stripes_ui/UI/CommonWidgets/Conditions/rule_summary.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/question_graph.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/session_graph.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/CommonWidgets/segmented_draggable_list.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/dependency_editor.dart';
import 'package:stripes_ui/UI/CommonWidgets/Conditions/condition_editor.dart';
import 'package:stripes_ui/UI/Record/Screens/question_screen.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/requirement.dart';

String _questionTypeLabel(BuildContext context, QuestionType type) {
  return switch (type) {
    QuestionType.check => context.translate.questionTypeCheck,
    QuestionType.slider => context.translate.questionTypeSlider,
    QuestionType.multipleChoice => context.translate.questionTypeMultipleChoice,
    QuestionType.allThatApply => context.translate.questionTypeAllThatApply,
    QuestionType.freeResponse => context.translate.questionTypeFreeResponse,
  };
}

IconData _questionTypeIcon(QuestionType type) => switch (type) {
  QuestionType.check => Icons.check_box_outlined,
  QuestionType.slider => Icons.linear_scale,
  QuestionType.multipleChoice => Icons.radio_button_checked,
  QuestionType.allThatApply => Icons.checklist,
  QuestionType.freeResponse => Icons.short_text,
};

Future<String?> showSectionNameEditor(
  BuildContext context, {
  required String currentName,
  required String fallbackName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => _SectionNameEditorSheet(
      currentName: currentName,
      fallbackName: fallbackName,
    ),
  );
}

class _SectionNameEditorSheet extends StatefulWidget {
  final String currentName;
  final String fallbackName;

  const _SectionNameEditorSheet({
    required this.currentName,
    required this.fallbackName,
  });

  @override
  State<_SectionNameEditorSheet> createState() =>
      _SectionNameEditorSheetState();
}

class _SectionNameEditorSheetState extends State<_SectionNameEditorSheet> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.currentName);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppPadding.large,
        AppPadding.small,
        AppPadding.large,
        AppPadding.large + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppPadding.large),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppPadding.small),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRounding.small),
                  ),
                  child: Icon(
                    Icons.view_agenda_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppPadding.medium),
                Expanded(
                  child: Text(
                    context.translate.renameSection,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppPadding.small),
            Text(
              context.translate.sectionNameDescription,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppPadding.large),
            TextFormField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: context.translate.sectionName,
                hintText: widget.fallbackName,
                prefixIcon: const Icon(Icons.title),
                filled: true,
                fillColor: colors.surfaceContainerLowest,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.translate.sectionNameRequired
                  : null,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppPadding.large),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.translate.stampDeleteCancel),
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(context.translate.saveChanges),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (formKey.currentState?.validate() != true) return;
    Navigator.pop(context, controller.text.trim());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

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
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final AsyncValue<PagesData> pagesData = ref.watch(
      pagesByPath(PagesByPathProps(pathName: widget.category)),
    );

    Widget topRow(PagesData data) {
      final layouts = data.loadedLayouts ?? const <LoadedPageLayout>[];
      final canEditStructure = data.path?.userCreated == true;
      final questionCount = layouts.fold<int>(
        0,
        (total, page) => total + page.questions.length,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: context.translate.backToRecordFlows,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.goNamed(RouteName.SYMPTOMS);
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category == null
                            ? context.translate.noRecordFlowSelected
                            : localizations?.value(widget.category!) ??
                                  widget.category!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      if (data.loadedLayouts != null)
                        Text(
                          '${context.translate.questionsCount(questionCount)} · '
                          '${context.translate.sectionsCount(layouts.length)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (!editing && canEditStructure) ...[
              const SizedBox(height: AppPadding.medium),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: layouts.isEmpty
                          ? null
                          : () => setState(() => editing = true),
                      icon: const Icon(Icons.reorder),
                      label: Text(context.translate.reorderAndGroup),
                    ),
                  ),
                  const SizedBox(width: AppPadding.small),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.category == null
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => AddQuestionPage(
                                  type: widget.category!,
                                  recordPath: data.path,
                                  sections: layouts.indexed
                                      .where((entry) => entry.$2.id != null)
                                      .map(
                                        (entry) => QuestionSectionOption(
                                          id: entry.$2.id!,
                                          label:
                                              entry.$2.header?.isNotEmpty ==
                                                  true
                                              ? localizations?.value(
                                                      entry.$2.header!,
                                                    ) ??
                                                    entry.$2.header!
                                              : context.translate.sectionNumber(
                                                  entry.$1 + 1,
                                                ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                      icon: const Icon(Icons.add),
                      label: Text(context.translate.addQuestion),
                    ),
                  ),
                ],
              ),
            ],
            if (!editing && data.path != null && !canEditStructure) ...[
              const SizedBox(height: AppPadding.medium),
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.small,
                ),
                leading: Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  context.translate.builtInFlowStructure,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                childrenPadding: const EdgeInsets.all(AppPadding.medium),
                children: [
                  Text(context.translate.builtInFlowStructureDescription),
                ],
              ),
            ],
          ],
        ),
      );
    }

    Widget createNewCategory() {
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(context.translate.recordFlowNotFound),
            const SizedBox(height: AppPadding.small),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final QuestionRepo? repo = await ref.read(
                  questionsProvider.future,
                );
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
                    name: widget.category!,
                  ),
                );
                if (!added && context.mounted) {
                  showSnack(context, "Failed to add ${widget.category}");
                }
              },
              label: const Text("Create"),
            ),
          ],
        ),
      );
    }

    return AsyncValueDefaults(
      value: pagesData,
      onData: (loadedPagesData) {
        final PagesData translatedPagesData =
            localizations?.translatePage(loadedPagesData) ?? loadedPagesData;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppPadding.large),
            topRow(translatedPagesData),
            const SizedBox(height: AppPadding.medium),
            if (loadedPagesData.loadedLayouts == null &&
                widget.category != null)
              createNewCategory(),
            if (loadedPagesData.loadedLayouts != null &&
                widget.category != null)
              Expanded(
                child: editing && loadedPagesData.path?.userCreated == true
                    ? EditListOrder(
                        pagesData: loadedPagesData,
                        setNotEditing: () {
                          if (mounted) {
                            setState(() {
                              editing = false;
                            });
                          }
                        },
                      ) /*EditingMode(
                        pagesData: translatedPagesData,
                        setNotEditing: () {
                          if (mounted) {
                            setState(() {
                              editing = false;
                            });
                          }
                        },
                      )*/
                    : RefreshWidget(
                        depth: RefreshDepth.subuser,
                        scrollable: ViewingMode(
                          type: widget.category!,
                          pageData: loadedPagesData,
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }
}

class EditListOrder extends ConsumerWidget {
  final PagesData pagesData;

  final Function setNotEditing;

  const EditListOrder({
    required this.pagesData,
    required this.setNotEditing,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<LoadedPageLayout> loadedLayouts = pagesData.loadedLayouts!;
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );

    Map<String, LoadedPageLayout> layoutsById = {};

    List<SegmentedDraggablePage<Question>> draggablePages = [];

    for (final LoadedPageLayout layout in loadedLayouts) {
      draggablePages.add(
        SegmentedDraggablePage(
          items: layout.questions,
          id: layout.id,
          header: layout.header,
        ),
      );
      if (layout.id != null) {
        layoutsById[layout.id!] = layout;
      }
    }

    /*LoadedPageLayout? existsInDependency(Question question) {
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
    }*/

    Widget pageHeaderBuilder(
      BuildContext context,
      SegmentedDraggablePage<Question> page,
      int index,
      SegmentedPageActions actions,
    ) {
      Question? questionProvider(String qid) {
        final Iterable<Question> questionMatch = loadedLayouts
            .map((layout) => layout.questions)
            .flattenedToList
            .where((question) => question.id == qid);
        if (questionMatch.isEmpty) return null;
        return localizations?.translateQuestion(questionMatch.first) ??
            questionMatch.first;
      }

      final dependency = layoutsById[page.id]?.dependsOn;
      final hasRule =
          dependency != null && dependency != const DependsOn.nothing();
      final title = page.header?.isNotEmpty == true
          ? localizations?.value(page.header!) ?? page.header!
          : context.translate.sectionNumber(index + 1);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: 0.45),
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppPadding.tiny),
                      Text(
                        hasRule
                            ? localizedRuleSummary(
                                context,
                                dependency,
                                questionProvider,
                              )
                            : context.translate.alwaysShown,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.translate.renameSection,
                  onPressed: actions.updateHeader == null
                      ? null
                      : () async {
                          final updatedName = await showSectionNameEditor(
                            context,
                            currentName: page.header ?? '',
                            fallbackName: context.translate.sectionNumber(
                              index + 1,
                            ),
                          );
                          if (updatedName != null && context.mounted) {
                            actions.updateHeader!(updatedName);
                          }
                        },
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: context.translate.moveSectionUp,
                  onPressed: actions.moveUp,
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                IconButton(
                  tooltip: context.translate.moveSectionDown,
                  onPressed: actions.moveDown,
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
                if (actions.remove != null)
                  IconButton(
                    tooltip: context.translate.removeEmptySection,
                    onPressed: actions.remove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      );
    }

    List<PageLayout> toPageLayouts(
      List<SegmentedDraggablePage<Question>> layouts,
    ) {
      return layouts
          .map(
            (layout) => PageLayout(
              questionIds: layout.items.map((item) => item.id).toList(),
              uid: layout.id,
              header: layout.header,
              dependsOn:
                  layoutsById[layout.id]?.dependsOn ??
                  const DependsOn.nothing(),
              requirement:
                  layoutsById[layout.id]?.requirement ??
                  const Requirement.nothing(),
            ),
          )
          .toList();
    }

    Future<bool> save(List<SegmentedDraggablePage<Question>> layouts) async {
      if (layouts.any((layout) => layout.items.isEmpty)) {
        showSnack(context, context.translate.emptySectionSaveError);
        return false;
      }
      final QuestionRepo? repo = await ref.read(questionsProvider.future);
      if (repo == null) return false;

      final RecordPath path = pagesData.path!;
      final List<PageLayout> newPages = toPageLayouts(layouts);
      return await repo.updateRecordPath(path.copyWith(pages: newPages));
    }

    return SegmentedDraggableList<Question>(
      layouts: draggablePages,
      canAddFirstPage: false,
      canCreatePageByDragging: false,
      setNotEditing: setNotEditing,
      save: save,
      header: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.drag_indicator,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppPadding.small),
            Expanded(
              child: Text(
                context.translate.reorderHelp,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
      pageHeaderBuilder: pageHeaderBuilder,
      pageDecorator: (context, child, index) {
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(
            bottom: AppPadding.medium,
            left: AppPadding.large,
            right: AppPadding.large,
          ),
          child: child,
        );
      },
      buildDropPreview: (context, question, isNewPage) {
        if (question == null) return const SizedBox();
        if (!isNewPage) {
          return Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRounding.small),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.symmetric(
            vertical: AppPadding.medium,
            horizontal: AppPadding.large,
          ),
          width: double.infinity,
          padding: const EdgeInsets.all(AppPadding.medium),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRounding.medium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsGeometry.only(left: AppPadding.small),
                child: Text(
                  context.translate.newSection,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _symptomDisplay(
                context: context,
                question: question,
                handle: null,
                enabled: false,
              ),
            ],
          ),
        );
      },
      shouldAccept: (layouts, details) => true,
      buildItem: (context, question, handle, enabled) => _symptomDisplay(
        context: context,
        question: question,
        handle: handle,
        enabled: enabled,
      ),
    );
  }

  Widget _symptomDisplay({
    required BuildContext context,
    required Question question,
    required Widget? handle,
    bool enabled = true,
  }) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final translated = localizations?.translateQuestion(question) ?? question;
    final type = QuestionType.from(translated);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppPadding.small,
        horizontal: AppPadding.large,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(_questionTypeIcon(type), size: 20),
          ),
          const SizedBox(width: AppPadding.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translated.prompt,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppPadding.tiny),
                Text(
                  _questionTypeLabel(context, type),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppPadding.small),
          if (handle != null && enabled) handle,
        ],
      ),
    );
  }
}

class ViewingMode extends ConsumerWidget {
  final String type;

  final PagesData pageData;

  const ViewingMode({required this.type, required this.pageData, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(questionsProvider);
    final pages = pageData.loadedLayouts ?? [];
    final QuestionsLocalizations? questionLocalizations =
        QuestionsLocalizations.of(context);

    Iterable<Widget> questionDisplays() {
      List<Widget> displays = [];
      for (final (int index, LoadedPageLayout page) in pages.indexed) {
        Question? questionProvider(String qid) {
          final question = pages
              .expand((layout) => layout.questions)
              .firstWhereOrNull((question) => question.id == qid);
          return question == null
              ? null
              : questionLocalizations?.translateQuestion(question) ?? question;
        }

        final bool hasRule = page.dependsOn != const DependsOn.nothing();
        final String ruleSummary = hasRule
            ? localizedRuleSummary(context, page.dependsOn, questionProvider)
            : index == 0
            ? context.translate.alwaysShownFirst
            : context.translate.alwaysShown;
        final String sectionTitle = page.header?.isNotEmpty == true
            ? questionLocalizations?.value(page.header!) ?? page.header!
            : context.translate.sectionNumber(index + 1);
        displays.add(
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            margin: const EdgeInsets.only(
              bottom: AppPadding.medium,
              left: AppPadding.large,
              right: AppPadding.large,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Theme.of(context).colorScheme.primaryContainer
                      .withValues(alpha: 0.45),
                  padding: const EdgeInsets.fromLTRB(
                    AppPadding.large,
                    AppPadding.medium,
                    AppPadding.small,
                    AppPadding.medium,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sectionTitle,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppPadding.tiny),
                            Row(
                              children: [
                                Icon(
                                  hasRule
                                      ? Icons.alt_route
                                      : Icons.visibility_outlined,
                                  size: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(width: AppPadding.tiny),
                                Expanded(
                                  child: Text(
                                    ruleSummary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (index > 0 && pageData.path?.userCreated == true)
                        TextButton.icon(
                          icon: const Icon(Icons.rule_outlined, size: 18),
                          label: Text(
                            hasRule
                                ? context.translate.editRule
                                : context.translate.addRule,
                          ),
                          onPressed: () {
                            final previousQuestions = pages
                                .sublist(0, index)
                                .map((l) => l.questions)
                                .flattenedToList
                                .toList();

                            ref
                                .read(sheetControllerProvider)
                                .show(
                                  context: context,
                                  scrollControlled: true,
                                  child: (context) => DependencyEditor(
                                    initialDependency: page.dependsOn,
                                    availableQuestions: previousQuestions,
                                    onSave: (newDependency) async {
                                      onSaveDependency(
                                        context: context,
                                        ref: ref,
                                        pages: pages,
                                        page: page,
                                        newDependency: newDependency,
                                        index: index,
                                      );
                                    },
                                  ),
                                );
                          },
                        ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outline,
                ),
                ...page.questions
                    .map((question) => SymptomDisplay(question: question))
                    .separated(by: const Divider(height: 1, indent: 72)),
              ],
            ),
          ),
        );
      }
      return displays;
    }

    return SingleChildScrollView(
      key: const PageStorageKey("SymptomScreen"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppPadding.small),
          ...questionDisplays(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Future<void> onSaveDependency({
    required BuildContext context,
    required WidgetRef ref,
    required List<LoadedPageLayout> pages,
    required LoadedPageLayout page,
    required DependsOn newDependency,
    required int index,
  }) async {
    // Create a copy to avoid mutating the original list
    final List<LoadedPageLayout> pagesCopy = List.from(pages);
    final LoadedPageLayout newLayout = page.copyWith(dependsOn: newDependency);
    pagesCopy[index] = newLayout;
    if (pageData.path != null) {
      final pageLayouts = pagesCopy
          .map(
            (page) => PageLayout(
              questionIds: page.questions
                  .map((question) => question.id)
                  .toList(),
              uid: page.id,
              header: page.header,
              dependsOn: page.dependsOn,
            ),
          )
          .toList();

      final RecordPath toSave = pageData.path!.copyWith(pages: pageLayouts);

      await (await ref.read(questionsProvider.future))
          ?.updateRecordPath(toSave);
      if (context.mounted) {
        Navigator.pop(context);

        (context as Element).markNeedsBuild();
      }
    }
  }
}

class SymptomDisplay extends ConsumerWidget {
  final Question question;

  const SymptomDisplay({required this.question, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final Question translated =
        localizations?.translateQuestion(question) ?? question;
    final QuestionType type = QuestionType.from(translated);
    final String typeLabel = _questionTypeLabel(context, type);
    final String details = switch (translated) {
      AllThatApply(choices: final choices) =>
        '$typeLabel · ${context.translate.optionsCount(choices.length)}',
      MultipleChoice(choices: final choices) =>
        '$typeLabel · ${context.translate.optionsCount(choices.length)}',
      Numeric(min: final min, max: final max) =>
        '$typeLabel · ${min ?? 1}–${max ?? 5}',
      _ => typeLabel,
    };
    final IconData typeIcon = switch (type) {
      QuestionType.check => Icons.check_box_outlined,
      QuestionType.slider => Icons.linear_scale,
      QuestionType.multipleChoice => Icons.radio_button_checked,
      QuestionType.allThatApply => Icons.checklist,
      QuestionType.freeResponse => Icons.short_text,
    };

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(
        AppPadding.large,
        AppPadding.small,
        AppPadding.small,
        AppPadding.small,
      ),
      onTap: () {
        ref
            .read(sheetControllerProvider)
            .show(
              context: context,
              scrollControlled: true,
              child: (context) => SymptomEditSheet(question: question),
            );
      },
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(typeIcon, size: 20),
      ),
      title: Text(
        translated.prompt,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: question.enabled
              ? null
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppPadding.tiny),
        child: Text(
          [
            details,
            if (question.userCreated) context.translate.customQuestionLabel,
            if (!question.enabled) 'Hidden from check-ins',
          ].join(' · '),
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
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
  bool lockTried = false;

  @override
  Widget build(BuildContext context) {
    final Question? question = ref.watch(
      questionHomeProvider.select(
        (value) => value.value?.forDisplay(widget.question.id),
      ),
    );

    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
        child: question == null
            ? Text("Failed to load ${widget.question.prompt}")
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: AppPadding.small),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppPadding.medium),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.translate.questionSettingsTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.small),
                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRounding.medium),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppPadding.medium),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            child: Icon(
                              _questionTypeIcon(QuestionType.from(question)),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppPadding.medium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.translate.questionCardLabel,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: AppPadding.tiny),
                                SymptomInfoDisplay(
                                  question:
                                      localizations?.translateQuestion(
                                        question,
                                      ) ??
                                      question,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppPadding.medium),
                  if (question.locked && lockTried)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppPadding.small),
                      child: Text(
                        "This question is locked ${question.enabled ? "on" : "off"}.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.translate.showInCheckIns),
                    subtitle: Text(
                      question.locked
                          ? context.translate.settingManagedByApp
                          : context.translate.hideQuestionDescription,
                    ),
                    trailing: GestureDetector(
                      onTap: question.locked
                          ? () => setState(() => lockTried = true)
                          : null,
                      child: Switch(
                        value: question.enabled,
                        onChanged: question.locked
                            ? null
                            : (_) async {
                                final repo = await ref.read(
                                  questionsProvider.future,
                                );
                                if (repo == null) return;
                                if (!await repo.setQuestionEnabled(
                                      question,
                                      !question.enabled,
                                    ) &&
                                    context.mounted) {
                                  showSnack(
                                    context,
                                    "Failed to ${!question.enabled ? "show" : "hide"} ${question.prompt}",
                                  );
                                }
                              },
                        thumbIcon: question.locked
                            ? WidgetStateProperty.all(const Icon(Icons.lock))
                            : null,
                      ),
                    ),
                  ),
                  const Divider(height: AppPadding.large),
                  if (question.userCreated) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.task_alt_outlined),
                      title: Text(context.translate.responseRequirementTitle),
                      subtitle: Text(
                        question.requirement == null ||
                                question.requirement!.groups.isEmpty
                            ? context.translate.optionalResponseDescription
                            : context.translate.requiredResponseDescription,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (context) => _RequirementEditorSheet(
                            initialRequirement: question.requirement,
                            availableQuestions: [question],
                            onSave: (newRequirement) async {
                              final repo = await ref.read(
                                questionsProvider.future,
                              );
                              if (repo == null) return;
                            },
                          ),
                        );
                      },
                    ),
                    const Divider(height: AppPadding.large),
                  ],
                  if (!question.userCreated)
                    Container(
                      padding: const EdgeInsets.all(AppPadding.medium),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRounding.medium),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline),
                          const SizedBox(width: AppPadding.small),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.translate.builtInQuestionLabel,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: AppPadding.tiny),
                                Text(
                                  context.translate.builtInQuestionDescription,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Center(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete question?'),
                              content: Text(
                                'This will permanently delete "${question.prompt}".',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          final repo = await ref.read(questionsProvider.future);
                          if (repo == null) return;
                          final removed = await repo.removeQuestion(question);
                          if (!context.mounted) return;
                          if (removed) {
                            Navigator.pop(context);
                          } else {
                            showSnack(
                              context,
                              'Failed to delete ${question.prompt}',
                            );
                          }
                        },
                        label: Text(context.translate.deleteQuestionFromDraft),
                        icon: const Icon(Icons.delete_outline),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .errorContainer,
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .onErrorContainer,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppPadding.large),
                ],
              ),
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
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final Question translated =
        localizations?.translateQuestion(question) ?? question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: translated.prompt,
            style: Theme.of(context).textTheme.titleMedium,
            children: [
              if (question.userCreated)
                TextSpan(
                  text: " · ${context.translate.customQuestionLabel}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.75),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppPadding.tiny),
        RichText(
          text: TextSpan(
            text: _questionTypeLabel(context, type),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}

class _RequirementEditorSheet extends StatefulWidget {
  final Requirement? initialRequirement;
  final List<Question> availableQuestions;
  final Function(Requirement?) onSave;

  const _RequirementEditorSheet({
    required this.initialRequirement,
    required this.availableQuestions,
    required this.onSave,
  });

  @override
  State<_RequirementEditorSheet> createState() =>
      _RequirementEditorSheetState();
}

class _RequirementEditorSheetState extends State<_RequirementEditorSheet> {
  Condition? _root;

  @override
  void initState() {
    super.initState();
    if (widget.initialRequirement == null) {
      _root = null;
    } else {
      final groups = widget.initialRequirement!.groups;
      if (groups.isEmpty) {
        _root = null;
      } else if (groups.length == 1) {
        final group = groups.first;
        if (group.conditions.length == 1 &&
            group.conditions.first is! ConditionGroup &&
            group.op == GroupOp.all) {
          _root = group.conditions.first;
        } else {
          _root = group;
        }
      } else {
        _root = ConditionGroup(conditions: groups, op: GroupOp.all);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                "Response requirement",
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            'Define what counts as a completed response to this question.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppPadding.large),
          Flexible(
            child: SingleChildScrollView(
              child: ConditionEditor(
                initialCondition: _root,
                availableQuestions: widget.availableQuestions,
                localizations: QuestionsLocalizations.of(context),
                onChanged: (condition) {
                  setState(() {
                    _root = condition;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: AppPadding.large),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_root != null)
                TextButton(
                  onPressed: () {
                    setState(() => _root = null);
                  },
                  child: const Text("Make optional"),
                ),
              const SizedBox(width: AppPadding.small),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text("Save requirement"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_root == null) {
      widget.onSave(null);
      return;
    }

    Requirement requirement;
    if (_root is ConditionGroup) {
      requirement = Requirement([_root as ConditionGroup]);
    } else {
      requirement = Requirement([
        ConditionGroup(conditions: [_root!], op: GroupOp.all),
      ]);
    }

    widget.onSave(requirement);
  }
}

@immutable
class QuestionSectionOption {
  final String id;
  final String label;

  const QuestionSectionOption({required this.id, required this.label});
}

@immutable
class QuestionDraftResult {
  final Question question;
  final String sectionId;

  const QuestionDraftResult({required this.question, required this.sectionId});
}

class AddQuestionPage extends StatelessWidget {
  final String type;
  final bool saveToRepository;
  final String? draftId;
  final Question? initialQuestion;
  final List<QuestionSectionOption> sections;
  final String? initialSectionId;
  final RecordPath? recordPath;
  final Map<String, List<Question>> availableDependenciesBySection;

  const AddQuestionPage({
    required this.type,
    this.saveToRepository = true,
    this.draftId,
    this.initialQuestion,
    this.sections = const [],
    this.initialSectionId,
    this.recordPath,
    this.availableDependenciesBySection = const {},
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            RecordFlowHeader(
              title: initialQuestion == null
                  ? context.translate.addQuestion
                  : context.translate.questionSettingsTitle,
              subtitle: type,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: AddSymptomWidget(
                type: type,
                saveToRepository: saveToRepository,
                draftId: draftId,
                initialQuestion: initialQuestion,
                sections: sections,
                initialSectionId: initialSectionId,
                recordPath: recordPath,
                availableDependenciesBySection: availableDependenciesBySection,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddSymptomWidget extends ConsumerStatefulWidget {
  final String type;
  final bool saveToRepository;
  final String? draftId;
  final Question? initialQuestion;
  final List<QuestionSectionOption> sections;
  final String? initialSectionId;
  final RecordPath? recordPath;
  final Map<String, List<Question>> availableDependenciesBySection;

  const AddSymptomWidget({
    required this.type,
    this.saveToRepository = true,
    this.draftId,
    this.initialQuestion,
    this.sections = const [],
    this.initialSectionId,
    this.recordPath,
    this.availableDependenciesBySection = const {},
    super.key,
  });

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

  bool isLoading = false, submitSuccess = false;

  QuestionType selectedQuestionType = QuestionType.check;
  String? selectedSectionId;
  DependsOn dependency = const DependsOn.nothing();
  late final String questionId;

  @override
  void initState() {
    super.initState();
    questionId =
        widget.initialQuestion?.id ??
        widget.draftId ??
        (widget.sections.isEmpty
            ? ''
            : 'custom-${DateTime.now().microsecondsSinceEpoch}');
    final initial = widget.initialQuestion;
    if (initial != null) {
      prompt.text = initial.prompt;
      selectedQuestionType = QuestionType.from(initial);
      dependency = initial.dependsOn ?? const DependsOn.nothing();
      if (initial is Numeric) {
        minValue.text = (initial.min ?? 1).toString();
        maxValue.text = (initial.max ?? 5).toString();
      }
      if (initial is MultipleChoice) choices = List.of(initial.choices);
      if (initial is AllThatApply) choices = List.of(initial.choices);
    }
    selectedSectionId =
        widget.initialSectionId ??
        (widget.sections.isEmpty ? null : widget.sections.first.id);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.saveToRepository) {
      ref.watch(pagesByPath(PagesByPathProps(pathName: widget.type)));
    }
    return SafeArea(
      child: Opacity(
        opacity: isLoading ? 0.6 : 1,
        child: IgnorePointer(
          ignoring: isLoading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Form(
                  key: formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppPadding.large,
                      AppPadding.medium,
                      AppPadding.large,
                      AppPadding.xxl,
                    ),
                    children: [
                      _QuestionBuilderSection(
                        icon: Icons.edit_note,
                        title: context.translate.questionContentTitle,
                        description:
                            context.translate.questionContentDescription,
                        child: TextFormField(
                          controller: prompt,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 3,
                          minLines: 2,
                          decoration: InputDecoration(
                            labelText: context.translate.questionPromptLabel,
                            hintText: context.translate.questionPromptHint,
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLowest,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? context.translate.questionPromptRequired
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppPadding.medium),
                      _QuestionBuilderSection(
                        icon: Icons.tune,
                        title: context.translate.responseSetupTitle,
                        description: context.translate.responseSetupDescription,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: AppPadding.small,
                              runSpacing: AppPadding.tiny,
                              children: QuestionType.ordered
                                  .map(
                                    (option) => ChoiceChip(
                                      showCheckmark: false,
                                      avatar: Icon(
                                        _questionTypeIcon(option),
                                        size: 18,
                                      ),
                                      label: Text(
                                        _questionTypeLabel(context, option),
                                      ),
                                      selected: selectedQuestionType == option,
                                      onSelected: (_) => setState(
                                        () => selectedQuestionType = option,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            if (selectedQuestionType ==
                                QuestionType.slider) ...[
                              const SizedBox(height: AppPadding.large),
                              Divider(
                                height: 1,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              const SizedBox(height: AppPadding.medium),
                              Text(
                                context.translate.responseRange,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppPadding.small),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: minValue,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        labelText:
                                            context.translate.minimumLabel,
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLowest,
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: _validateRange,
                                    ),
                                  ),
                                  const SizedBox(width: AppPadding.small),
                                  Expanded(
                                    child: TextFormField(
                                      controller: maxValue,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        labelText:
                                            context.translate.maximumLabel,
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLowest,
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: _validateRange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (selectedQuestionType ==
                                    QuestionType.multipleChoice ||
                                selectedQuestionType ==
                                    QuestionType.allThatApply) ...[
                              const SizedBox(height: AppPadding.large),
                              Divider(
                                height: 1,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              const SizedBox(height: AppPadding.medium),
                              Text(
                                context.translate.optionsLabel,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppPadding.small),
                              ChoicesFormField(
                                allowMultiple:
                                    selectedQuestionType ==
                                    QuestionType.allThatApply,
                                validator: _validateChoices,
                                onChanged: (value) {
                                  choices = value ?? const [];
                                },
                                initialValue: choices,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.sections.isNotEmpty) ...[
                        _QuestionBuilderSection(
                          icon: Icons.place_outlined,
                          title: context.translate.placementTitle,
                          description: widget.sections
                              .firstWhere(
                                (s) => s.id == selectedSectionId,
                                orElse: () => widget.sections.first,
                              )
                              .label,
                          child: DropdownMenuFormField<String>(
                            initialSelection: selectedSectionId,
                            expandedInsets: EdgeInsets.zero,
                            enableFilter: false,
                            enableSearch: false,
                            leadingIcon: const Icon(Icons.view_agenda_outlined),
                            label: Text(context.translate.appearsInSection),
                            inputDecorationTheme: InputDecorationThemeData(
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLowest,
                              border: const OutlineInputBorder(),
                            ),
                            dropdownMenuEntries: widget.sections
                                .map(
                                  (section) => DropdownMenuEntry(
                                    value: section.id,
                                    label: section.label,
                                  ),
                                )
                                .toList(),
                            onSelected: (value) => setState(() {
                              selectedSectionId = value;
                              dependency = const DependsOn.nothing();
                            }),
                          ),
                        ),
                        const SizedBox(height: AppPadding.medium),
                      ],
                      if (_availableDependencyQuestions.isNotEmpty) ...[
                        const SizedBox(height: AppPadding.medium),
                        _QuestionBuilderSection(
                          icon: Icons.visibility_outlined,
                          title: context.translate.questionVisibilityRuleTitle,
                          description: dependency.groups.isEmpty
                              ? context.translate.alwaysShown
                              : _dependencySummary(),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              dependency.groups.isEmpty
                                  ? context.translate.alwaysShown
                                  : _dependencySummary(),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _editDependency,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppPadding.large),
                child: FilledButton.icon(
                  onPressed: isLoading ? null : add,
                  icon: submitSuccess
                      ? const Icon(Icons.check)
                      : const Icon(Icons.add),
                  label: isLoading
                      ? const ButtonLoadingIndicator()
                      : Text(
                          widget.initialQuestion == null
                              ? context.translate.createQuestion
                              : context.translate.saveChanges,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateRange(String? _) {
    final min = int.tryParse(minValue.text);
    final max = int.tryParse(maxValue.text);
    if (min == null || max == null) return context.translate.rangeRequired;
    if (min >= max) return context.translate.rangeInvalid;
    return null;
  }

  String? _validateChoices(List<String>? value) {
    final normalized = (value ?? const <String>[])
        .map((choice) => choice.trim())
        .toList();
    if (normalized.length < 2 || normalized.any((choice) => choice.isEmpty)) {
      return context.translate.optionsMinimumRequired;
    }
    if (normalized.toSet().length != normalized.length) {
      return context.translate.optionsMustBeUnique;
    }
    if (normalized.any((choice) => choice.contains(','))) {
      return context.translate.optionCommaUnsupported;
    }
    return null;
  }

  List<Question> get _availableDependencyQuestions =>
      widget.availableDependenciesBySection[selectedSectionId] ?? const [];

  String _dependencySummary() {
    return localizedRuleSummary(
      context,
      dependency,
      (id) => _availableDependencyQuestions.firstWhereOrNull((q) => q.id == id),
    );
  }

  Future<void> _editDependency() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => DependencyEditor(
        initialDependency: dependency,
        availableQuestions: _availableDependencyQuestions,
        title: context.translate.questionVisibilityRuleTitle,
        description: context.translate.questionVisibilityRuleDescription,
        onSave: (value) {
          setState(() => dependency = value);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  Future<void> add() async {
    if (isLoading) return;

    if (!formKey.currentState!.validate()) return;

    final question = _buildQuestion(id: questionId);
    if (!widget.saveToRepository) {
      Navigator.pop(
        context,
        QuestionDraftResult(
          question: question,
          sectionId: selectedSectionId ?? '',
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    final repo = await ref.read(questionsProvider.future);
    if (repo == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
    bool added = await repo.addQuestion(question);
    if (added && widget.recordPath != null && selectedSectionId != null) {
      final pages = widget.recordPath!.pages
          .map(
            (page) => page.copyWith(
              questionIds: page.questionIds
                  .where((questionId) => questionId != question.id)
                  .toList(),
            ),
          )
          .toList();
      final targetIndex = pages.indexWhere(
        (page) => page.id == selectedSectionId,
      );
      if (targetIndex >= 0) {
        pages[targetIndex] = pages[targetIndex].copyWith(
          questionIds: [...pages[targetIndex].questionIds, question.id],
        );
        added = await repo.updateRecordPath(
          widget.recordPath!.copyWith(pages: pages),
        );
      } else {
        added = false;
      }
      if (!added) await repo.removeQuestion(question);
    }

    if (added) {
      if (!mounted) return;
      setState(() => submitSuccess = true);
      await Future.delayed(Durations.medium2);
      if (mounted) Navigator.pop(context);
    } else if (mounted) {
      setState(() => isLoading = false);
      showSnack(context, "Failed to add question");
    }
  }

  @override
  void dispose() {
    prompt.dispose();
    minValue.dispose();
    maxValue.dispose();
    super.dispose();
  }

  Question _buildQuestion({String id = ''}) {
    return switch (selectedQuestionType) {
      QuestionType.check => Check(
        id: id,
        prompt: prompt.text.trim(),
        type: widget.type,
        userCreated: true,
        dependsOn: dependency,
      ),
      QuestionType.freeResponse => FreeResponse(
        id: id,
        prompt: prompt.text.trim(),
        type: widget.type,
        userCreated: true,
        dependsOn: dependency,
      ),
      QuestionType.slider => Numeric(
        id: id,
        prompt: prompt.text.trim(),
        type: widget.type,
        min: int.parse(minValue.text),
        max: int.parse(maxValue.text),
        userCreated: true,
        dependsOn: dependency,
      ),
      QuestionType.multipleChoice => MultipleChoice(
        id: id,
        prompt: prompt.text.trim(),
        type: widget.type,
        choices: List.unmodifiable(choices),
        userCreated: true,
        dependsOn: dependency,
      ),
      QuestionType.allThatApply => AllThatApply(
        id: id,
        prompt: prompt.text.trim(),
        type: widget.type,
        choices: List.unmodifiable(choices),
        userCreated: true,
        dependsOn: dependency,
      ),
    };
  }
}

class _QuestionBuilderSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  const _QuestionBuilderSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppPadding.small),
        child,
      ],
    );
  }
}

class PreviewQuestionHome extends QuestionHome {
  PreviewQuestionHome(Iterable<Question> questions) {
    for (final question in questions) {
      all[question.id] = question;
    }
  }

  @override
  Map<String, List<Question>> byType() {
    final result = <String, List<Question>>{};
    for (final question in all.values) {
      result.putIfAbsent(question.type, () => []).add(question);
    }
    return result;
  }
}

class RecordFlowPreviewSheet extends StatefulWidget {
  final QuestionGraph graph;
  final RecordPath path;
  final String? title;

  const RecordFlowPreviewSheet({
    required this.graph,
    required this.path,
    this.title,
    super.key,
  });

  @override
  State<RecordFlowPreviewSheet> createState() => _RecordFlowPreviewSheetState();
}

class _RecordFlowPreviewSheetState extends State<RecordFlowPreviewSheet> {
  late final SessionGraph session;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    session = widget.graph.createSession(recordPathName: widget.path.name);
  }

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final title =
        widget.title ??
        localizations?.value(widget.path.name) ??
        widget.path.name;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.92,
      child: AnimatedBuilder(
        animation: session,
        builder: (context, _) {
          final visiblePages = session.visiblePages;
          if (visiblePages.isEmpty) {
            return Center(child: Text(context.translate.conditionNoConditions));
          }
          if (pageIndex >= visiblePages.length) {
            pageIndex = visiblePages.length - 1;
          }
          final page = visiblePages[pageIndex];
          final questions = page.questionIds
              .map((id) => widget.graph.node(id)?.question)
              .whereType<Question>()
              .toList();
          final header = page.header?.isNotEmpty == true
              ? localizations?.value(page.header!) ?? page.header!
              : context.translate.sectionNumber(pageIndex + 1);
          final isLast = pageIndex == visiblePages.length - 1;

          return SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppPadding.small),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppPadding.large,
                    AppPadding.small,
                    AppPadding.small,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              context.translate.previewMode,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: context.translate.closePreview,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppPadding.large),
                  child: Container(
                    padding: const EdgeInsets.all(AppPadding.small),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRounding.small),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_outlined, size: 18),
                        const SizedBox(width: AppPadding.small),
                        Expanded(
                          child: Text(
                            context.translate.previewModeDescription,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppPadding.large),
                    child: QuestionScreen(
                      header: header,
                      questions: questions,
                      questionsListener: session,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppPadding.large),
                  child: Row(
                    children: [
                      if (pageIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => pageIndex--),
                            child: Text(context.translate.previousButton),
                          ),
                        ),
                      if (pageIndex > 0)
                        const SizedBox(width: AppPadding.small),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (isLast) {
                              Navigator.pop(context);
                            } else {
                              setState(() => pageIndex++);
                            }
                          },
                          child: Text(
                            isLast
                                ? context.translate.doneButton
                                : context.translate.nextButton,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ChoicesFormField extends StatefulWidget {
  final FormFieldValidator<List<String>>? validator;
  final ValueChanged<List<String>?>? onChanged;
  final List<String> initialValue;
  final bool allowMultiple;

  const ChoicesFormField({
    this.validator,
    this.onChanged,
    this.initialValue = const [],
    this.allowMultiple = false,
    super.key,
  });

  @override
  State<ChoicesFormField> createState() => _ChoicesFormFieldState();
}

class _ChoicesFormFieldState extends State<ChoicesFormField> {
  late final List<_ChoiceDraft> drafts;
  int nextId = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue.isEmpty
        ? const ['', '']
        : widget.initialValue;
    drafts = initial.map(_newDraft).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify(null));
  }

  _ChoiceDraft _newDraft(String value) => _ChoiceDraft(
    id: nextId++,
    controller: TextEditingController(text: value),
    focusNode: FocusNode(),
  );

  List<String> get values =>
      drafts.map((draft) => draft.controller.text).toList(growable: false);

  void _notify(FormFieldState<List<String>>? field) {
    field?.didChange(values);
    widget.onChanged?.call(values);
  }

  void _addOption(FormFieldState<List<String>> field) {
    final draft = _newDraft('');
    setState(() => drafts.add(draft));
    _notify(field);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) draft.focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: values,
      validator: widget.validator,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.translate.optionsEditorHelp,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppPadding.small),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: drafts.length,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final draft = drafts.removeAt(oldIndex);
                drafts.insert(newIndex, draft);
              });
              _notify(field);
            },
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return Container(
                key: ValueKey(draft.id),
                margin: const EdgeInsets.only(bottom: AppPadding.small),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.tiny,
                  vertical: AppPadding.tiny,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(AppRounding.small),
                ),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.all(AppPadding.small),
                        child: Icon(
                          Icons.drag_indicator,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Icon(
                      widget.allowMultiple
                          ? Icons.check_box_outline_blank
                          : Icons.radio_button_unchecked,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppPadding.small),
                    Expanded(
                      child: TextFormField(
                        controller: draft.controller,
                        focusNode: draft.focusNode,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: context.translate.optionNumber(index + 1),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        textInputAction: index == drafts.length - 1
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onChanged: (_) => _notify(field),
                        onFieldSubmitted: (_) {
                          if (index == drafts.length - 1) _addOption(field);
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: context.translate.removeOption,
                      onPressed: drafts.length <= 2
                          ? null
                          : () {
                              final removed = drafts.removeAt(index);
                              removed.dispose();
                              setState(() {});
                              _notify(field);
                            },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            },
          ),
          OutlinedButton.icon(
            onPressed: () => _addOption(field),
            icon: const Icon(Icons.add),
            label: Text(context.translate.addOption),
          ),
          if (field.hasError) ...[
            const SizedBox(height: AppPadding.tiny),
            Text(
              field.errorText!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final draft in drafts) {
      draft.dispose();
    }
    super.dispose();
  }
}

class _ChoiceDraft {
  final int id;
  final TextEditingController controller;
  final FocusNode focusNode;

  const _ChoiceDraft({
    required this.id,
    required this.controller,
    required this.focusNode,
  });

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
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
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppPadding.tiny),
          child,
        ],
      ),
    );
  }
}

/*
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

 */
