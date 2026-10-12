import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/question_graph_builder.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation_page.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/symptom_type_management.dart';

import '../../../Util/Design/paddings.dart';

class SymptomManagementScreen extends ConsumerWidget {
  const SymptomManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RecordPath>> asyncRecordPaths = ref.watch(
      questionLayoutProvider,
    );
    return AsyncValueDefaults(
      value: asyncRecordPaths,
      onData: (recordPaths) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RecordFlowHeader(
              title: context.translate.questionSetsTitle,
              subtitle: context.translate.flowListHelp,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed(RouteName.ACCOUNT);
                }
              },
              action: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const RecordFlowCreationPage(),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(context.translate.newQuestionSet),
              ),
            ),
            Expanded(
              child: RefreshWidget(
                depth: RefreshDepth.subuser,
                scrollable: ListView(
                  children: [
                    const SizedBox(height: AppPadding.small),
                    ...recordPaths.map(
                      (path) => CategoryDisplay(recordPath: path),
                    ),
                    const SizedBox(height: AppPadding.xxl),
                  ],
                ),
              ),
            ),

            /*
            ...checkin.keys.map((items) {
              items.map((item) => {
                item.
              });
              return Container();
            })*/
          ],
        );
      },
    );
  }
}

class QuestionSetCreationPage extends ConsumerStatefulWidget {
  const QuestionSetCreationPage({super.key});

  @override
  ConsumerState<QuestionSetCreationPage> createState() =>
      _QuestionSetCreationPageState();
}

class _QuestionSetCreationPageState
    extends ConsumerState<QuestionSetCreationPage> {
  final _detailsKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final List<Question> _questions = [];
  Period? _period;
  int _step = 0;
  int _draftCount = 0;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate.newQuestionSetTitle),
        leading: IconButton(
          onPressed: _step == 0
              ? () => Navigator.pop(context)
              : () => setState(() => _step -= 1),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _CreationProgress(currentStep: _step),
            const Divider(height: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: Durations.medium2,
                child: switch (_step) {
                  0 => _detailsStep(),
                  1 => _questionsStep(),
                  _ => _reviewStep(),
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _primaryAction,
                  icon: _saving
                      ? const ButtonLoadingIndicator()
                      : Icon(_step == 2 ? Icons.check : Icons.arrow_forward),
                  label: Text(
                    _step == 2
                        ? context.translate.createQuestionSet
                        : context.translate.continueButton,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsStep() {
    return SingleChildScrollView(
      key: const ValueKey('details'),
      padding: const EdgeInsets.all(AppPadding.large),
      child: Form(
        key: _detailsKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.translate.questionSetDetailsStep,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppPadding.tiny),
            Text(
              context.translate.newQuestionSetDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppPadding.large),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.translate.questionSetName,
                hintText: context.translate.questionSetNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.translate.questionSetNameRequired
                  : null,
            ),
            const SizedBox(height: AppPadding.large),
            Text(
              context.translate.recordTiming,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppPadding.tiny),
            Text(
              context.translate.recordTimingHelp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppPadding.small),
            DropdownMenuFormField<Period?>(
              initialSelection: _period,
              expandedInsets: EdgeInsets.zero,
              enableFilter: false,
              enableSearch: false,
              inputDecorationTheme: const InputDecorationThemeData(
                border: OutlineInputBorder(),
              ),
              dropdownMenuEntries: [
                DropdownMenuEntry(
                  value: null,
                  label: context.translate.eventBased,
                  leadingIcon: const Icon(Icons.touch_app_outlined),
                ),
                DropdownMenuEntry(
                  value: Period.day,
                  label: context.translate.dailyTiming,
                ),
                DropdownMenuEntry(
                  value: Period.week,
                  label: context.translate.weeklyTiming,
                ),
                DropdownMenuEntry(
                  value: Period.month,
                  label: context.translate.monthlyTiming,
                ),
                DropdownMenuEntry(
                  value: Period.year,
                  label: context.translate.yearlyTiming,
                ),
              ],
              onSelected: (value) => setState(() => _period = value),
            ),
            const SizedBox(height: AppPadding.tiny),
            Text(
              _period == null
                  ? context.translate.eventBasedDescription
                  : context.translate.scheduledDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionsStep() {
    return Padding(
      key: const ValueKey('questions'),
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.translate.questionsStep,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppPadding.tiny),
          Text(
            context.translate.questionsStepDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppPadding.medium),
          OutlinedButton.icon(
            onPressed: _addDraftQuestion,
            icon: const Icon(Icons.add),
            label: Text(context.translate.addQuestion),
          ),
          const SizedBox(height: AppPadding.medium),
          Expanded(
            child: _questions.isEmpty
                ? Center(
                    child: Text(
                      context.translate.addFirstQuestion,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: _questions.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        final question = _questions.removeAt(oldIndex);
                        _questions.insert(newIndex, question);
                      });
                    },
                    itemBuilder: (context, index) {
                      final question = _questions[index];
                      return Card(
                        key: ValueKey(question.id),
                        elevation: 0,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
                        child: ListTile(
                          leading: Icon(switch (QuestionType.from(question)) {
                            QuestionType.check => Icons.check_box_outlined,
                            QuestionType.slider => Icons.linear_scale,
                            QuestionType.multipleChoice =>
                              Icons.radio_button_checked,
                            QuestionType.allThatApply => Icons.checklist,
                            QuestionType.freeResponse => Icons.short_text,
                          }),
                          title: Text(question.prompt),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: MaterialLocalizations.of(context)
                                    .deleteButtonTooltip,
                                onPressed: () =>
                                    setState(() => _questions.removeAt(index)),
                                icon: const Icon(Icons.delete_outline),
                              ),
                              const Icon(Icons.drag_handle),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _reviewStep() {
    return ListView(
      key: const ValueKey('review'),
      padding: const EdgeInsets.all(AppPadding.large),
      children: [
        Text(
          context.translate.reviewQuestionSet,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppPadding.tiny),
        Text(
          context.translate.reviewQuestionSetDescription,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppPadding.large),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Column(
            children: [
              ListTile(
                title: Text(_name.text.trim()),
                subtitle: Text(
                  context.translate.questionsCount(_questions.length),
                ),
              ),
              const Divider(height: 1),
              ..._questions.map(
                (question) => ListTile(
                  title: Text(question.prompt),
                  leading: const Icon(Icons.help_outline),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppPadding.medium),
        OutlinedButton.icon(
          onPressed: _previewDraft,
          icon: const Icon(Icons.play_circle_outline),
          label: Text(context.translate.previewFlow),
        ),
      ],
    );
  }

  Future<void> _primaryAction() async {
    if (_step == 0) {
      if (!(_detailsKey.currentState?.validate() ?? false)) return;
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (_questions.isEmpty) {
        showSnack(context, context.translate.addFirstQuestion);
        return;
      }
      setState(() => _step = 2);
      return;
    }
    await _save();
  }

  Future<void> _addDraftQuestion() async {
    final id =
        'draft-${DateTime.now().microsecondsSinceEpoch}-${_draftCount++}';
    final question = await Navigator.of(context).push<Question>(
      MaterialPageRoute<Question>(
        builder: (context) => AddQuestionPage(
          type: _name.text.trim(),
          saveToRepository: false,
          draftId: id,
        ),
      ),
    );
    if (question != null && mounted) {
      setState(() => _questions.add(question));
    }
  }

  Future<void> _previewDraft() async {
    final questions = _questionsForCurrentName();
    final path = RecordPath(
      name: _name.text.trim(),
      pages: [PageLayout(questionIds: questions.map((q) => q.id).toList())],
      period: _period,
      userCreated: true,
    );
    final graph = QuestionGraphBuilder.build(
      home: PreviewQuestionHome(questions),
      recordPaths: [path],
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => RecordFlowPreviewSheet(graph: graph, path: path),
    );
    graph.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = await ref.read(questionsProvider.future);
    if (repo == null) {
      if (mounted) setState(() => _saving = false);
      return;
    }
    final path = RecordPath(
      name: _name.text.trim(),
      pages: const [],
      period: _period,
      userCreated: true,
    );
    final addedQuestions = <Question>[];
    final pathAdded = await repo.addRecordPath(path);
    bool succeeded = pathAdded;
    if (succeeded) {
      for (final question in _questionsForCurrentName()) {
        if (!await repo.addQuestion(question)) {
          succeeded = false;
          break;
        }
        addedQuestions.add(question);
      }
    }
    if (!succeeded) {
      for (final question in addedQuestions.reversed) {
        await repo.removeQuestion(question);
      }
      if (pathAdded) await repo.removeRecordPath(path);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (succeeded) {
      Navigator.pop(context);
    } else {
      showSnack(context, context.translate.questionSetCreationFailed);
    }
  }

  List<Question> _questionsForCurrentName() {
    final type = _name.text.trim();
    return _questions
        .map(
          (question) => switch (question) {
            Check() => question.copyWith(type: type),
            Numeric() => question.copyWith(type: type),
            MultipleChoice() => question.copyWith(type: type),
            AllThatApply() => question.copyWith(type: type),
            FreeResponse() => question.copyWith(type: type),
          },
        )
        .toList();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }
}

class _CreationProgress extends StatelessWidget {
  final int currentStep;

  const _CreationProgress({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.translate.questionSetDetailsStep,
      context.translate.questionsStep,
      context.translate.reviewStep,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.large,
        AppPadding.small,
        AppPadding.large,
        AppPadding.medium,
      ),
      child: Row(
        children: labels.indexed
            .map((entry) {
              final (index, label) = entry;
              final active = index <= currentStep;
              return Expanded(
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: active ? 1 : 0,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: AppPadding.tiny),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: active
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            })
            .separated(by: const SizedBox(width: AppPadding.small)),
      ),
    );
  }
}

class CategoryDisplay extends ConsumerWidget {
  final RecordPath recordPath;

  const CategoryDisplay({required this.recordPath, super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final int symptoms = recordPath.pages.fold<int>(
      0,
      (previousValue, page) => previousValue + page.questionIds.length,
    );
    final RecordPath translated =
        localizations?.translatePath(recordPath) ?? recordPath;
    final colorScheme = Theme.of(context).colorScheme;
    final String cadence = _timingLabel(context, recordPath.period);
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.fromLTRB(
        AppPadding.large,
        0,
        AppPadding.large,
        AppPadding.small,
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(
          AppPadding.large,
          AppPadding.small,
          AppPadding.small,
          AppPadding.small,
        ),
        onTap: () {
          context.pushNamed(
            RouteName.SYMPTOMTYPE,
            pathParameters: {'type': recordPath.name},
          );
        },
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: const Icon(Icons.fact_check_outlined),
        ),
        title: Text(
          translated.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: translated.enabled ? null : Theme.of(context).disabledColor,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppPadding.tiny),
          child: Wrap(
            spacing: AppPadding.small,
            runSpacing: AppPadding.tiny,
            children: [
              Text(context.translate.questionsCount(symptoms)),
              Semantics(
                label: recordPath.period == null
                    ? '${context.translate.eventBased}. '
                          '${context.translate.eventBasedDescription}'
                    : cadence,
                excludeSemantics: true,
                child: Text(cadence),
              ),
              if (!recordPath.enabled) Text(context.translate.hiddenFlowLabel),
              if (!recordPath.userCreated)
                Text(context.translate.builtInFlowLabel),
              if (recordPath.userCreated) ...[
                Text(context.translate.customRecordFlowLabel),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: context.translate.recordFlowSettings,
              onPressed: () {
                ref
                    .read(sheetControllerProvider)
                    .show(
                      context: context,
                      child: (context) =>
                          CategorySettingsSheet(path: recordPath),
                    );
              },
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
      ),
    );
  }

  String _timingLabel(BuildContext context, Period? period) {
    return switch (period) {
      null => context.translate.eventBased,
      Period.day => context.translate.dailyTiming,
      Period.week => context.translate.weeklyTiming,
      Period.month => context.translate.monthlyTiming,
      Period.year => context.translate.yearlyTiming,
    };
  }
}

class AddCategorySheet extends ConsumerStatefulWidget {
  const AddCategorySheet({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return AddCategorySheetState();
  }
}

class AddCategorySheetState extends ConsumerState<AddCategorySheet> {
  final ValueNotifier<AddCategoryFormState> _formState =
      ValueNotifier<AddCategoryFormState>(AddCategoryFormState.idle);
  final TextEditingController category = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Period? recordPeriod;

  @override
  Widget build(BuildContext context) {
    final bool loading = _formState.value == AddCategoryFormState.loading;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppPadding.large,
          AppPadding.small,
          AppPadding.large,
          AppPadding.large + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: formKey,
          child: Opacity(
            opacity: loading ? 0.6 : 1,
            child: IgnorePointer(
              ignoring: loading,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                          context.translate.newQuestionSetTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    context.translate.newQuestionSetDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppPadding.large),
                  TextFormField(
                    controller: category,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: context.translate.questionSetName,
                      hintText: context.translate.questionSetNameHint,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? context.translate.questionSetNameRequired
                        : null,
                  ),
                  const SizedBox(height: AppPadding.large),
                  Text(
                    context.translate.recordTiming,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppPadding.tiny),
                  Text(
                    context.translate.recordTimingHelp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppPadding.small),
                  DropdownMenuFormField<Period?>(
                    expandedInsets: EdgeInsets.zero,
                    enableSearch: false,
                    enableFilter: false,
                    inputDecorationTheme: const InputDecorationThemeData(
                      border: OutlineInputBorder(),
                    ),
                    initialSelection: recordPeriod,
                    onSelected: (value) => setState(() => recordPeriod = value),
                    dropdownMenuEntries: [
                      DropdownMenuEntry(
                        value: null,
                        label: context.translate.eventBased,
                        leadingIcon: const Icon(Icons.touch_app_outlined),
                      ),
                      DropdownMenuEntry(
                        value: Period.day,
                        label: context.translate.dailyTiming,
                      ),
                      DropdownMenuEntry(
                        value: Period.week,
                        label: context.translate.weeklyTiming,
                      ),
                      DropdownMenuEntry(
                        value: Period.month,
                        label: context.translate.monthlyTiming,
                      ),
                      DropdownMenuEntry(
                        value: Period.year,
                        label: context.translate.yearlyTiming,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.tiny),
                  Text(
                    recordPeriod == null
                        ? context.translate.eventBasedDescription
                        : context.translate.scheduledDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppPadding.xl),
                  FilledButton.icon(
                    onPressed: add,
                    icon: _formState.value == AddCategoryFormState.success
                        ? const Icon(Icons.check)
                        : const Icon(Icons.add),
                    label: loading
                        ? const ButtonLoadingIndicator()
                        : Text(context.translate.createQuestionSet),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> add() async {
    if (_formState.value == AddCategoryFormState.loading) return;

    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _formState.value = AddCategoryFormState.loading;
    });
    final QuestionRepo? repo = await ref.read(questionsProvider.future);

    if (repo == null) {
      if (mounted) showSnack(context, "Failed to add question");
      if (mounted) {
        setState(() => _formState.value = AddCategoryFormState.idle);
      }
      return;
    }
    final bool added = await repo.addRecordPath(
      RecordPath(
        pages: const [],
        period: recordPeriod,
        userCreated: true,
        name: category.text.trim(),
      ),
    );
    if (added && mounted) {
      setState(() {
        category.clear();
        _formState.value = AddCategoryFormState.success;
      });
      await Future.delayed(Durations.long4);
      recordPeriod = null;
      formKey.currentState?.reset();
    } else if (mounted) {
      showSnack(context, "Failed to add question");
    }
    if (mounted) {
      context.pop();
      setState(() {
        _formState.value = AddCategoryFormState.idle;
      });
    }
  }
}

class CategorySettingsSheet extends ConsumerStatefulWidget {
  final RecordPath path;

  const CategorySettingsSheet({required this.path, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return CategorySettingsSheetState();
  }
}

class CategorySettingsSheetState extends ConsumerState<CategorySettingsSheet> {
  late final int symptoms;

  @override
  void initState() {
    symptoms = widget.path.pages.fold<int>(
      0,
      (previousValue, page) => previousValue + page.questionIds.length,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final AsyncValue<RecordPath?> path = ref.watch(
      questionLayoutProvider.select(
        (value) => value.whenData(
          (path) => path.where((path) => path.id == widget.path.id).firstOrNull,
        ),
      ),
    );
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsetsGeometry.symmetric(
          horizontal: AppPadding.large,
        ),
        child: AsyncValueDefaults(
          value: path,
          onData: (path) {
            if (path == null) return Text("Failed to load ${widget.path.name}");
            final RecordPath translated =
                localizations?.translatePath(path) ?? path;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: AppPadding.large),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          text: translated.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: translated.enabled
                                    ? null
                                    : Theme.of(context).disabledColor,
                              ),
                          children: [
                            if (translated.userCreated) ...[
                              TextSpan(
                                text:
                                    " · ${context.translate.customRecordFlowLabel}",
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.75),
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppPadding.tiny),
                    IconButton(
                      onPressed: () {
                        context.pop();
                      },
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
                Text(
                  "${context.translate.questionsCount(symptoms)}${translated.period != null ? " / ${translated.period!.name}" : ""}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: AppPadding.small),
                /*Row(
                  children: [
                    Text(
                      "Frequency",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (widget.path.userCreated)
                      DropdownMenu<Period?>(
                        enableSearch: false,
                        enableFilter: false,
                        inputDecorationTheme: InputDecorationThemeData(
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppPadding.tiny),
                          ),
                        ),
                        initialSelection: path.period,
                        onSelected: (value) async {
                          if (!await (await ref.read(questionsProvider.future))!
                                  .setPathEnabled(path, !path.enabled) &&
                              context.mounted) {
                            showSnack(context,
                                "Failed to ${!widget.path.enabled ? "enable" : "disable"} ${widget.path.name}");
                          }
                        },
                        dropdownMenuEntries: [...Period.values, null]
                            .map<DropdownMenuEntry<Period?>>((option) =>
                                DropdownMenuEntry(
                                    value: option,
                                    label: frequencyMap[option] ?? "Event"))
                            .toList(),
                      )
                    else
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRounding.tiny),
                          border: Border.all(width: 0.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsetsGeometry.symmetric(
                              horizontal: AppPadding.xl,
                              vertical: AppPadding.large),
                          child: Text(frequencyMap[path.period] ?? "Event"),
                        ),
                      ),
                  ],
                ),*/
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.translate.showRecordFlow),
                  subtitle: Text(
                    translated.locked
                        ? context.translate.settingManagedByApp
                        : context.translate.hideRecordFlowDescription,
                  ),
                  trailing: Switch(
                    value: translated.enabled,
                    onChanged: translated.locked
                        ? null
                        : (_) async {
                            if (!await (await ref.read(
                                  questionsProvider.future,
                                ))!.setPathEnabled(path, !path.enabled) &&
                                context.mounted) {
                              showSnack(
                                context,
                                "Failed to ${!translated.enabled ? "enable" : "disable"} ${translated.name}",
                              );
                            }
                          },
                    thumbIcon: translated.locked
                        ? WidgetStateProperty.all(const Icon(Icons.lock))
                        : null,
                  ),
                ),
                const Divider(height: AppPadding.large),
                if (!translated.userCreated)
                  Container(
                    padding: const EdgeInsets.all(AppPadding.medium),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                                context.translate.builtInFlowStructure,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppPadding.tiny),
                              Text(
                                context
                                    .translate
                                    .builtInFlowStructureDescription,
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
                        if (!await (await ref.read(questionsProvider.future))!
                                .removeRecordPath(path) &&
                            context.mounted) {
                          showSnack(
                            context,
                            "Failed to delete ${widget.path.name}",
                          );
                        }
                      },
                      label: Text(context.translate.deleteAction),
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
              ],
            );
          },
        ),
      ),
    );
  }
}

enum AddCategoryFormState { idle, loading, success }
