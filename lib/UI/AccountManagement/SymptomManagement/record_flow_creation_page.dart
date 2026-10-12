import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_header.dart';
import 'package:stripes_ui/UI/CommonWidgets/Conditions/rule_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/question_graph_builder.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/dependency_editor.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation/record_flow_build_step.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation/record_flow_creation_chrome.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation/record_flow_details_step.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation/record_flow_draft.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation/record_flow_review_step.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_persistence.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/symptom_type_management.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';

class RecordFlowCreationPage extends ConsumerStatefulWidget {
  const RecordFlowCreationPage({super.key});

  @override
  ConsumerState<RecordFlowCreationPage> createState() =>
      _RecordFlowCreationPageState();
}

class _RecordFlowCreationPageState
    extends ConsumerState<RecordFlowCreationPage> {
  final detailsKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final Set<int> errorSteps = {};
  late final PageController pageController;
  late final RecordFlowDraft draft;

  Period? period;
  int currentStep = 0;
  bool saving = false;

  List<DraftRecordFlowSection> get sections => draft.sections;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    draft = RecordFlowDraft();
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      context.translate.recordFlowDetailsTitle,
      context.translate.buildFlowTitle,
      context.translate.reviewQuestionSet,
    ];
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            RecordFlowHeader(
              title: titles[currentStep],
              subtitle: currentStep == 0 ? null : nameController.text.trim(),
              onBack: currentStep == 0
                  ? () => Navigator.pop(context)
                  : () => _goToStep(currentStep - 1),
            ),
            RecordFlowCreationProgress(
              currentStep: currentStep,
              errorSteps: errorSteps,
              pageController: pageController,
            ),
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => currentStep = index),
                children: [
                  RecordFlowDetailsStep(
                    formKey: detailsKey,
                    nameController: nameController,
                    period: period,
                    onNameChanged: () => _clearStepError(0),
                    onPeriodChanged: (value) => setState(() => period = value),
                  ),
                  RecordFlowBuildStep(
                    flowName: nameController.text.trim(),
                    onPreview: draft.questions.isEmpty ? null : _preview,
                    sections: sections,
                    sectionLabel: _sectionLabel,
                    sectionRuleSummary: _sectionRuleSummary,
                    onAddSection: _addSection,
                    onAddQuestion: _addQuestion,
                    onRenameSection: _renameSection,
                    onEditSectionDependency: _editSectionDependency,
                    onMoveSection: _moveSection,
                    onRemoveSection: _removeSection,
                    onReorderQuestion: _reorderQuestion,
                    onMoveQuestion: _moveQuestion,
                    onDeleteQuestion: _deleteQuestion,
                    onEditQuestion: _editQuestion,
                  ),
                  RecordFlowReviewStep(
                    period: period,
                    flowName: nameController.text.trim(),
                    sections: sections,
                    sectionLabel: _sectionLabel,
                    onPreview: _preview,
                    onEditQuestions: () => _goToStep(1),
                    sectionRuleSummary: _sectionRuleSummary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            RecordFlowCreationFooter(
              currentStep: currentStep,
              saving: saving,
              onPressed: _primaryAction,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _primaryAction() async {
    if (currentStep == 0) {
      if (!(detailsKey.currentState?.validate() ?? false)) {
        setState(() => errorSteps.add(0));
        return;
      }
      _clearStepError(0);
      await _goToStep(1);
      return;
    }
    if (currentStep == 1) {
      if (sections.any((section) => section.questions.isEmpty)) {
        setState(() => errorSteps.add(1));
        showSnack(context, context.translate.emptySectionSaveError);
        return;
      }
      if (!draft.rulesFollowFlowOrder) {
        setState(() => errorSteps.add(1));
        showSnack(context, context.translate.ruleOrderingError);
        return;
      }
      _clearStepError(1);
      await _goToStep(2);
      return;
    }
    await _save();
  }

  Future<void> _goToStep(int step) async {
    await pageController.animateToPage(
      step,
      duration: Durations.medium1,
      curve: Curves.easeInOut,
    );
  }

  void _clearStepError(int step) {
    if (!errorSteps.contains(step)) return;
    setState(() => errorSteps.remove(step));
  }

  String _sectionLabel(DraftRecordFlowSection section, int index) {
    final header = section.header?.trim();
    return header == null || header.isEmpty
        ? context.translate.sectionNumber(index + 1)
        : header;
  }

  List<QuestionSectionOption> get _sectionOptions => sections.indexed
      .map(
        (entry) => QuestionSectionOption(
          id: entry.$2.id,
          label: _sectionLabel(entry.$2, entry.$1),
        ),
      )
      .toList();

  Future<void> _addQuestion(String sectionId) async {
    final result = await Navigator.of(context).push<QuestionDraftResult>(
      MaterialPageRoute<QuestionDraftResult>(
        builder: (context) => AddQuestionPage(
          type: nameController.text.trim(),
          saveToRepository: false,
          sections: _sectionOptions,
          initialSectionId: sectionId,
          availableDependenciesBySection: draft.availableDependenciesBySection,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => draft.addQuestion(result.sectionId, result.question));
    _clearStepError(1);
  }

  Future<void> _editQuestion(Question question) async {
    final source = sections.firstWhere(
      (section) => section.questions.contains(question),
    );
    final index = source.questions.indexOf(question);
    final available = draft.availableDependenciesBySection;
    // An edited question may only depend on answers preceding its position.
    available[source.id] = [
      ...draft.questionsBeforeSection(sections.indexOf(source)),
      ...source.questions.take(index),
    ];
    for (final entry in available.entries) {
      available[entry.key] = entry.value
          .where((q) => q.id != question.id)
          .toList();
    }
    final result = await Navigator.of(context).push<QuestionDraftResult>(
      MaterialPageRoute(
        builder: (context) => AddQuestionPage(
          type: nameController.text.trim(),
          saveToRepository: false,
          initialQuestion: question,
          sections: _sectionOptions,
          initialSectionId: source.id,
          availableDependenciesBySection: available,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.sectionId == source.id) {
        source.questions[index] = result.question;
      } else {
        source.questions.removeAt(index);
        draft.addQuestion(result.sectionId, result.question);
      }
      errorSteps.remove(1);
    });
  }

  void _addSection() {
    setState(() {
      draft.addSection();
      errorSteps.remove(1);
    });
  }

  void _removeSection(DraftRecordFlowSection section) {
    setState(() => draft.removeSection(section));
  }

  void _deleteQuestion(DraftRecordFlowSection section, int questionIndex) {
    setState(() => draft.deleteQuestion(section, questionIndex));
  }

  Future<void> _renameSection(
    DraftRecordFlowSection section,
    int sectionIndex,
  ) async {
    final result = await showSectionNameEditor(
      context,
      currentName: section.header ?? '',
      fallbackName: context.translate.sectionNumber(sectionIndex + 1),
    );
    if (result != null && mounted) setState(() => section.header = result);
  }

  void _moveSection(int from, int to) {
    setState(() => draft.moveSection(from, to));
  }

  void _moveQuestion(
    Question question,
    DraftRecordFlowSection source,
    String targetId,
  ) {
    setState(() => draft.moveQuestion(question, source, targetId));
  }

  void _reorderQuestion(DraftRecordFlowSection section, int from, int to) {
    setState(() => draft.reorderQuestion(section, from, to));
  }

  Future<void> _editSectionDependency(
    DraftRecordFlowSection section,
    int sectionIndex,
  ) async {
    final available = draft.questionsBeforeSection(sectionIndex);
    if (available.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => DependencyEditor(
        initialDependency: section.dependsOn,
        availableQuestions: available,
        onSave: (dependency) {
          setState(() => section.dependsOn = dependency);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  String _sectionRuleSummary(DraftRecordFlowSection section) {
    if (section.dependsOn.groups.isEmpty) {
      return context.translate.alwaysShown;
    }
    Question? questionFor(String id) {
      for (final question in draft.questions) {
        if (question.id == id) return question;
      }
      return null;
    }

    return localizedRuleSummary(context, section.dependsOn, questionFor);
  }

  Future<void> _preview() async {
    final questions = draft.questionsForType(nameController.text.trim());
    final path = RecordPath(
      name: nameController.text.trim(),
      pages: draft.toPageLayouts(),
      period: period,
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
    setState(() => saving = true);
    final repo = await ref.read(questionsProvider.future);
    if (repo == null) {
      if (mounted) setState(() => saving = false);
      return;
    }
    final path = RecordPath(
      name: nameController.text.trim(),
      pages: draft.toPageLayouts(),
      period: period,
      userCreated: true,
    );
    final succeeded = await persistNewRecordFlow(
      repo: repo,
      path: path,
      questions: draft.questionsForType(nameController.text.trim()),
    );
    if (!mounted) return;
    setState(() {
      saving = false;
      if (!succeeded) errorSteps.add(2);
    });
    if (succeeded) {
      Navigator.pop(context);
    } else {
      showSnack(context, context.translate.questionSetCreationFailed);
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    nameController.dispose();
    super.dispose();
  }
}
