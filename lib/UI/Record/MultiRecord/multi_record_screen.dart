import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'record_selection_step.dart';
import 'record_details_step.dart';
import 'record_review_step.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Navigation/navigation_provider.dart';
import 'package:stripes_ui/Providers/Record/multi_record_draft.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';
import 'package:stripes_ui/Providers/Record/record_study_processor.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/discard_changes_sheet.dart';
import 'package:stripes_ui/UI/Record/MultiRecord/record_timing_step.dart';
import 'package:stripes_ui/UI/Record/MultiRecord/record_flow_header.dart';
import 'package:stripes_ui/UI/Record/record_form_layout.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class MultiRecordScreen extends ConsumerWidget {
  final String? initialCategory;
  const MultiRecordScreen({this.initialCategory, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final data = ref.watch(multiRecordContextProvider);
    return data.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.recordLoadError),
            TextButton(
              onPressed: () => ref.invalidate(multiRecordContextProvider),
              child: Text(strings.recordRetry),
            ),
          ],
        ),
      ),
      data: (loaded) =>
          MultiRecordFlow(data: loaded, initialCategory: initialCategory),
    );
  }
}

/// Keeps the first loaded profile and question graphs for the life of this
/// draft. A profile change blocks save instead of silently retargeting answers.
class MultiRecordFlow extends ConsumerStatefulWidget {
  final MultiRecordContext data;
  final String? initialCategory;
  const MultiRecordFlow({required this.data, this.initialCategory, super.key});

  @override
  ConsumerState<MultiRecordFlow> createState() => _MultiRecordFlowState();
}

class _MultiRecordFlowState extends ConsumerState<MultiRecordFlow> {
  late final MultiRecordDraft _draft;
  late final NavigationGuard _guard;
  late final String _studySignature;
  final _scroll = ScrollController();
  final _studyProcessor = RecordStudyProcessor();
  final _headerMeasureKey = GlobalKey();
  final Map<String, TextEditingController> _notes = {};
  final Map<String, GlobalKey> _questionKeys = {};
  final Map<String, Set<String>> _previousQuestionIds = {};
  final Set<String> _addedQuestionIds = {};
  int _step = 0;
  int _categoryIndex = 0;
  bool _returnToReview = false;
  bool _saving = false;
  bool _saved = false;
  bool _hasPartialSave = false;
  bool _allowPop = false;
  String? _error;
  List<Entry>? _pendingEntries;
  List<Entry>? _savedEntries;

  @override
  void initState() {
    super.initState();
    _draft = MultiRecordDraft(context: widget.data);
    _studySignature = _currentStudySignature;
    for (final item in widget.data.categories) {
      if (item.path.name == widget.initialCategory) _draft.toggle(item);
    }
    _draft.addListener(_draftChanged);
    _guard = (_) => _confirmExit();
  }

  String
  get _currentStudySignature => (_draft.context.tests?.currentProtocols ?? [])
      .map(
        (protocol) =>
            '${protocol.id}:${protocol.currentStageId}:${protocol.isCompleted}:${blueDyeActiveRunSessionId(protocol)}',
      )
      .join('|');

  void _draftChanged() {
    if (!mounted) return;
    if (_step == 2 && _draft.selected.isNotEmpty) {
      final previousAdded = Set<String>.of(_addedQuestionIds);
      final previousError = _error;
      final category = _draft.selected[_categoryIndex];
      final ids = _visibleQuestions(category).map((q) => q.id).toSet();
      final previous = _previousQuestionIds[category.type];
      if (previous != null) _addedQuestionIds.addAll(ids.difference(previous));
      _addedQuestionIds.removeWhere(
        (id) =>
            !ids.contains(id) ||
            category.graph.questionStateOf(id)?.value.answered == true,
      );
      _previousQuestionIds[category.type] = ids;
      if (_error != null && category.canSubmit) _error = null;
      if (!setEquals(previousAdded, _addedQuestionIds) ||
          previousError != _error) {
        setState(() {});
      }
      return;
    }
    setState(() {});
  }

  List<Question> _visibleQuestions(MultiRecordCategory category) => [
    for (var index = 0; index < category.graph.visiblePages.length; index++)
      ..._pageQuestions(category, index),
    ...category.session.submitQuestions,
  ];

  List<Question> _pageQuestions(MultiRecordCategory category, int index) {
    final graph = category.graph;
    if (index >= graph.visiblePages.length) {
      return category.session.submitQuestions;
    }
    return graph
        .visibleQuestionsForPage(index)
        .map((id) => graph.questionStateOf(id)?.value.resolvedQuestion)
        .whereType<Question>()
        .toList();
  }

  bool _pageValid(MultiRecordCategory category, int index) {
    if (index < category.graph.visiblePages.length) {
      return category.graph.validatePage(index)?.canProceed ?? false;
    }
    return category.session.submitQuestions.every(
      (question) =>
          category.graph.questionStateOf(question.id)?.value.valid ??
          category.graph.isQuestionValid(question),
    );
  }

  TextEditingController _notesFor(MultiRecordCategory category) =>
      _notes.putIfAbsent(category.type, () {
        final controller = TextEditingController(
          text: category.graph.description,
        );
        controller.addListener(() {
          if (category.graph.description != controller.text) {
            category.graph.description = controller.text;
          }
        });
        return controller;
      });

  void _showMissingAnswer(MultiRecordCategory category, int index) {
    category.graph.tried = true;
    setState(
      () => _error = AppLocalizations.of(context)!.recordRequiredAnswers,
    );
    final questions = _pageQuestions(category, index);
    Question? target;
    for (final question in questions) {
      if (!(category.graph.questionStateOf(question.id)?.value.valid ??
          category.graph.isQuestionValid(question))) {
        target = question;
        break;
      }
    }
    // Page-level requirements can require an answer to an otherwise optional question.
    target ??= questions
        .where((question) => category.graph.fromQuestion(question) == null)
        .firstOrNull;
    final key = target == null
        ? null
        : _questionKeys.putIfAbsent(
            '${category.type}/${target.id}',
            () => GlobalKey(),
          );
    _scrollToQuestion(key);
  }

  void _scrollToQuestion(GlobalKey? key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final box = key?.currentContext?.findRenderObject();
      final header = _headerMeasureKey.currentContext?.findRenderObject();
      if (box is RenderBox && header is RenderBox) {
        final offset =
            _scroll.offset +
            box.localToGlobal(Offset.zero).dy -
            header.localToGlobal(Offset(0, header.size.height)).dy -
            16;
        _scroll.animateTo(
          offset.clamp(0, _scroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _draft.removeListener(_draftChanged);
    for (final controller in _notes.values) {
      controller.dispose();
    }
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _profileMatches =>
      ref.read(subHolderProvider).value?.selected?.uid ==
          _draft.context.profile.uid &&
      ref.read(authStream).value?.uid == _draft.context.authUserId;

  Future<bool> _confirmExit() async {
    if (_saving) return false;
    if (_saved || !_draft.hasChanges) return true;
    if (_savedEntries != null) {
      // The record save completed; the remaining retry only updates study state.
      return true;
    }
    if (_pendingEntries != null) {
      final strings = AppLocalizations.of(context)!;
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              content: Text(strings.recordPartialSaveError),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(strings.discardEntryKeep),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(strings.recordLeave),
                ),
              ],
            ),
          ) ??
          false;
    }
    return showDiscardChangesSheet(context, ref);
  }

  Future<void> _close() async {
    if (!await _confirmExit() || !mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.HOME);
      }
    });
  }

  void _goTo(int step, {int? category, bool fromReview = false}) {
    setState(() {
      _step = step;
      if (category != null) _categoryIndex = category;
      _returnToReview = fromReview;
      _error = null;
      _addedQuestionIds.clear();
      if (step == 2) {
        final current = _draft.selected[_categoryIndex];
        _previousQuestionIds[current.type] = _visibleQuestions(current)
            .map((q) => q.id)
            .toSet();
        current.graph.tried = false;
      }
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _back() {
    if (_saving || _pendingEntries != null) return;
    if (_returnToReview) {
      _goTo(3);
    } else if (_step == 2 && _categoryIndex > 0) {
      _goTo(2, category: _categoryIndex - 1);
    } else if (_step == 3) {
      _goTo(2, category: _draft.selected.length - 1);
    } else if (_step > 0) {
      _goTo(_step - 1);
    } else {
      _close();
    }
  }

  void _continue() {
    final strings = AppLocalizations.of(context)!;
    if (_step == 0) {
      if (_draft.selected.isNotEmpty) _goTo(1);
    } else if (_step == 1) {
      if (!_draft.timesValid(DateTime.now())) {
        setState(() => _error = strings.recordInvalidTime);
        return;
      }
      _goTo(_returnToReview ? 3 : 2, category: 0);
    } else if (_step == 2) {
      final category = _draft.selected[_categoryIndex];
      if (!category.canSubmit) {
        final invalid = List.generate(
          category.graph.visiblePages.length + 1,
          (i) => i,
        ).firstWhere((i) => !_pageValid(category, i), orElse: () => 0);
        _showMissingAnswer(category, invalid);
      } else if (_returnToReview ||
          _categoryIndex == _draft.selected.length - 1) {
        _goTo(3);
      } else {
        _goTo(2, category: _categoryIndex + 1);
      }
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    if (_saving || !_profileMatches) return;
    final strings = AppLocalizations.of(context)!;
    if (_pendingEntries == null &&
        (!_draft.questionsValid || !_draft.timesValid(DateTime.now()))) {
      setState(() => _error = strings.recordRequiredAnswers);
      return;
    }
    if (_pendingEntries == null && _currentStudySignature != _studySignature) {
      setState(() => _error = strings.recordStudyChanged);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Resolve repositories once for this attempt, then recheck identity after
      // awaiting them. No data can be written to a newly selected profile.
      final writer = await ref.read(recordSessionWriterProvider.future);
      final stampRepo = await ref.read(stampProvider.future);
      final entryRepository = await ref.read(entryRepoProvider.future);
      if (!mounted) return;
      if (!_profileMatches || writer == null) {
        setState(
          () => _error = !_profileMatches
              ? strings.recordProfileChanged
              : strings.recordSaveError,
        );
        return;
      }
      if (_pendingEntries == null) {
        if (_currentStudySignature != _studySignature) {
          setState(() => _error = strings.recordStudyChanged);
          return;
        }
        final tests = _draft.context.tests;
        ActiveTestProtocol? protocol;
        if (_draft.selected.any(
          (category) => category.requiresBlueDyeSession,
        )) {
          // Identify the protocol that actually injects this question rather
          // than assuming the first active protocol is a blue dye study.
          for (final candidate
              in tests?.currentProtocols ?? <ActiveTestProtocol>[]) {
            if (candidate.isCompleted) continue;
            final injectsBlueDye = _draft.selected.any((category) {
              final reviewIds = tests!.engine.getInjectedQuestionIds(
                activeTest: candidate,
                flowType: category.type,
                placement: TestQuestionPlacement.review,
                pageIndex: 0,
              );
              return reviewIds.contains('BlueDyeQuestion') ||
                  List.generate(
                    category.graph.allPages.length,
                    (index) => index,
                  ).any(
                    (index) => tests.engine
                        .getInjectedQuestionIds(
                          activeTest: candidate,
                          flowType: category.type,
                          placement: TestQuestionPlacement.page,
                          pageIndex: index,
                        )
                        .contains('BlueDyeQuestion'),
                  );
            });
            if (injectsBlueDye) {
              protocol = candidate;
              break;
            }
          }
          if (protocol == null) {
            setState(() => _error = strings.recordStudyChanged);
            return;
          }
        }
        _pendingEntries = _draft.entries(
          blueDyeSessionId: protocol == null
              ? null
              : blueDyeActiveRunSessionId(protocol),
        );
      }
      if (_savedEntries == null) {
        final result = await writer.createSession(
          sessionId: _draft.batchId,
          entries: _pendingEntries!,
          preserveEntrySessionIds: true,
        );
        if (!mounted) return;
        switch (result) {
          case Success(data: final entries):
            _savedEntries = entries;
            _hasPartialSave = false;
          case Failure():
            setState(() {
              if (result.error is RecordSessionWriteRecovery) {
                _hasPartialSave = true;
              }
              if (_hasPartialSave) {
                _error = strings.recordPartialSaveError;
              } else {
                _pendingEntries = null;
                _error = strings.recordSaveError;
              }
            });
            return;
        }
      }
      final tests = _draft.context.tests;
      if (tests != null) {
        final history = await entryRepository?.entries.first ?? const <Entry>[];
        await _studyProcessor.process(
          tests: tests,
          entries: _savedEntries!,
          history: history,
        );
      }
      await stampRepo?.refresh();
      if (!mounted) return;
      ref.invalidate(stampsStreamProvider);
      setState(() {
        _saved = true;
        _saving = false;
      });
      showSnack(context, strings.recordSaved);
      await _close();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _savedEntries == null
              ? strings.recordSaveError
              : strings.recordStudyUpdateError,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _primaryLabel(AppLocalizations strings) {
    if (_saving) return strings.recordSaving;
    if (_pendingEntries != null) return strings.recordRetry;
    if (_step == 3) return strings.recordSaveAll;
    if (_returnToReview) return strings.recordReturnToReview;
    return strings.continueButton;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(registerGuardProvider(_guard));
    ref.watch(subHolderProvider);
    ref.watch(authStream);
    final strings = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final themed = ref.watch(configProvider).betaUi.useCategoryTheme;
    final titles = [
      strings.recordSelectCategories,
      strings.recordDateAndTime,
      strings.recordDetails,
      strings.recordReviewAndSave,
    ];
    final locked = _saving || _pendingEntries != null;
    final primaryLabel = _primaryLabel(strings);
    final primaryEnabled =
        !_saving &&
        _profileMatches &&
        (_step != 0 || _draft.selected.isNotEmpty) &&
        (_step != 1 || _draft.timesValid(DateTime.now()));

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_pendingEntries != null) {
            _close();
          } else {
            _back();
          }
        }
      },
      child: Scaffold(
        backgroundColor: colors.surfaceContainerLowest,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => CustomScrollView(
                    key: const ValueKey('multi-record-scroll'),
                    controller: _scroll,
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: RecordFlowHeader(
                          collapsible: _step != 0,
                          label: titles[_step],
                          profileLabel: strings.recordUsername(
                            '',
                            _draft.context.profile.name,
                          ),
                          step: _step,
                          width: constraints.maxWidth.clamp(
                            0,
                            RecordFormLayout.maxWidth,
                          ),
                          textScaler: MediaQuery.textScalerOf(context),
                          textDirection: Directionality.of(context),
                          titleStyle: Theme.of(context).textTheme.titleMedium!,
                          subtitleStyle: Theme.of(context).textTheme.bodySmall!,
                          backTooltip: strings.recordBack,
                          closeTooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          onBack: locked ? null : _back,
                          onClose: _saving ? null : _close,
                          measureKey: _headerMeasureKey,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: AbsorbPointer(
                          key: const ValueKey('multi-record-content'),
                          absorbing: locked || !_profileMatches,
                          child: RecordFormLayout(
                            padding: const EdgeInsets.all(
                              RecordFormLayout.horizontalPadding,
                            ),
                            child: switch (_step) {
                              0 => RecordSelectionStep(
                                draft: _draft,
                                themed: themed,
                              ),
                              1 => RecordTimingStep(draft: _draft),
                              2 => RecordDetailsStep(
                                category: _draft.selected[_categoryIndex],
                                categoryIndex: _categoryIndex,
                                categoryCount: _draft.selected.length,
                                time: _draft.timeFor(
                                  _draft.selected[_categoryIndex].type,
                                ),
                                nextCategoryType:
                                    _categoryIndex + 1 < _draft.selected.length
                                    ? _draft.selected[_categoryIndex + 1].type
                                    : null,
                                themed: themed,
                                returnToReview: _returnToReview,
                                notesController: _notesFor(
                                  _draft.selected[_categoryIndex],
                                ),
                                addedQuestionIds: Set.unmodifiable(
                                  _addedQuestionIds,
                                ),
                                pageQuestions: (index) => _pageQuestions(
                                  _draft.selected[_categoryIndex],
                                  index,
                                ),
                                questionKeyFor: (question) =>
                                    _questionKeys.putIfAbsent(
                                      '${_draft.selected[_categoryIndex].type}/${question.id}',
                                      () => GlobalKey(),
                                    ),
                              ),
                              _ => RecordReviewStep(
                                draft: _draft,
                                themed: themed,
                                colored: ref
                                    .watch(configProvider)
                                    .betaUi
                                    .categoryColorsEnabled,
                                onEditTime: () => _goTo(1, fromReview: true),
                                onEditCategory: (index) =>
                                    _goTo(2, category: index, fromReview: true),
                              ),
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_step == 2 && _addedQuestionIds.isNotEmpty)
                Semantics(
                  liveRegion: true,
                  child: TextButton.icon(
                    key: const ValueKey('view-added-questions'),
                    onPressed: locked || !_profileMatches
                        ? null
                        : () {
                            final category = _draft.selected[_categoryIndex];
                            final first = _visibleQuestions(category)
                                .firstWhere(
                                  (q) => _addedQuestionIds.contains(q.id),
                                );
                            _scrollToQuestion(
                              _questionKeys['${category.type}/${first.id}'],
                            );
                            setState(() => _addedQuestionIds.clear());
                          },
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    label: Text(strings.recordViewFollowUps),
                  ),
                ),
              if (!_profileMatches) _Message(strings.recordProfileChanged),
              if (_error != null) _Message(_error!),
              const Divider(height: 1),
              RecordFormLayout(
                padding: const EdgeInsets.symmetric(
                  horizontal: RecordFormLayout.horizontalPadding,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('multi-record-continue'),
                        onPressed: primaryEnabled ? _continue : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        child: Text(primaryLabel, textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);
  @override
  Widget build(BuildContext context) => RecordFormLayout(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
    child: Semantics(
      liveRegion: true,
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );
}
