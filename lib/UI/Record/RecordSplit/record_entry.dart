import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_ui/Util/Helpers/repo_result_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Navigation/navigation_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Questions/record_session_provider.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/discard_changes_sheet.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Record/Screens/question_screen.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/compact_record_questions.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/record_layout_shell.dart';
import 'package:stripes_ui/UI/Record/record_form_layout.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/session_entry_scaffold.dart';
import 'package:stripes_ui/UI/Record/Screens/submit_screen.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:uuid/uuid.dart';
import 'package:stripes_ui/Models/record_time.dart';

class RecordSplitter extends ConsumerStatefulWidget {
  final String type;
  final SessionData initialData;

  const RecordSplitter({super.key, required this.type, SessionData? data})
    : initialData = data ?? const SessionData();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return RecordSplitterState();
  }
}

class RecordSplitterState extends ConsumerState<RecordSplitter> {
  late final PageController pageController;

  int currentIndex = 0;
  String? _currentPageId;

  bool isLoading = false;

  bool submitSuccess = false;

  bool _allowPop = false;

  final Map<int, ScrollController> _scrollControllers = {};
  final Map<int, int> _previousQuestionCounts = {};
  String? _errorMessage;

  @override
  void initState() {
    pageController = PageController();
    super.initState();
  }

  Future<bool> _handleNavigation(
    BuildContext context,
    RecordSessionState session,
  ) async {
    if (!session.hasChanged) return true;
    final result = await showDiscardChangesSheet(context, ref);
    if (result) {
      ref.read(recordSessionProvider(_sessionArgs).notifier).acceptChanges();
    }
    return result;
  }

  RecordSessionArgs get _sessionArgs => RecordSessionArgs(
    recordPathName: widget.type,
    initialData: widget.initialData,
  );

  @override
  Widget build(BuildContext context) {
    return SessionEntryScaffold(
      args: _sessionArgs,
      errorLabel: 'Unable to load record',
      builder: (context, ref, session) {
        ref.watch(
          registerGuardProvider(
            (context) => _handleNavigation(context, session),
          ),
        );

        final SessionGraph sessionGraphNonNull = session.sessionGraph;

        final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
          context,
        );

        final String localizedType =
            localizations?.value(widget.type) ?? widget.type;

        final StripesConfig config = ref.watch(configProvider);
        final CategoryAppearance appearance = CategoryTheme.resolve(
          widget.type,
        );
        final bool themed = config.betaUi.useCategoryTheme;
        final bool colored = config.betaUi.categoryColorsEnabled;
        final bool betaLayout = config.betaUi.multiSessionFlow;

        final bool isEdit = sessionGraphNonNull.editId != null;
        final bool edited = !isEdit || session.hasChanged;

        final List<PageLayout> evaluatedPages =
            sessionGraphNonNull.visiblePages;

        final pageIds = [
          for (var index = 0; index < evaluatedPages.length; index++)
            evaluatedPages[index].id ?? 'record-page-$index',
          'record-submit',
        ];
        _synchronizeCurrentPage(pageIds);

        final PageSessionState? pageValidation = sessionGraphNonNull
            .validatePage(currentIndex);

        final bool isSubmit = currentIndex == evaluatedPages.length;
        // At large reading sizes, keep the complete category/profile context
        // in the page's scroll view so it cannot crowd out the question.
        final scrollHeader =
            MediaQuery.sizeOf(context).height <
            MediaQuery.textScalerOf(context).scale(300);

        final int totalQuestions = isSubmit
            ? 0
            : (pageValidation?.totalCount ?? 0);
        final int answeredQuestions = isSubmit
            ? 0
            : (pageValidation?.answeredCount ?? 0);
        final int pendingRequiredCount = isSubmit
            ? 0
            : (pageValidation?.pendingCount ?? 0);

        final VoidCallback? onPressed;
        if (isSubmit) {
          List<Question> testAdditions = session.submitQuestions;

          if (isEdit) {
            testAdditions = testAdditions
                .where((q) => sessionGraphNonNull.fromQuestion(q) != null)
                .toList();
          }

          int submitPending = 0;
          for (final question in testAdditions) {
            final qState = sessionGraphNonNull
                .questionStateOf(question.id)
                ?.value;
            final isValid =
                qState?.valid ?? sessionGraphNonNull.isQuestionValid(question);
            if (!isValid) {
              submitPending++;
            }
          }

          final bool canSubmit =
              sessionGraphNonNull.canSubmit &&
              submitPending == 0 &&
              !isLoading &&
              edited;

          onPressed = submitSuccess
              ? () {}
              : canSubmit
              ? () => _submitEntry(context, ref, isEdit, sessionGraphNonNull)
              : null;
        } else {
          final bool canProceed = pageValidation?.canProceed ?? false;
          onPressed = canProceed
              ? () {
                  sessionGraphNonNull.tried = false;
                  pageController.nextPage(
                    duration: Durations.medium1,
                    curve: Curves.linear,
                  );
                }
              : null;
        }

        final bool canProceed = isSubmit
            ? (onPressed != null)
            : (pageValidation?.canProceed ?? false);

        final VoidCallback effectiveOnPressed =
            onPressed == null && !canProceed && !isLoading
            ? () {
                sessionGraphNonNull.tried = true;
                setState(() {
                  final pendingCount = pageValidation?.pendingCount ?? 0;
                  if (pendingCount > 0) {
                    _errorMessage = context.translate.nLevelError(pendingCount);
                  }
                });
              }
            : () {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
                onPressed?.call();
              };

        final SubUser? currentUser = ref
            .read(subHolderProvider)
            .value
            ?.selected;
        final String? subtitle =
            currentUser == null || SubUser.isEmpty(currentUser)
            ? null
            : context.translate.recordUsername(localizedType, currentUser.name);

        final controller = RecordEntryController(
          title: context.translate.recordHeader(localizedType),
          subtitle: subtitle,
          icon: themed ? appearance.icon : null,
          categoryAppearance: themed ? appearance : null,
          color: colored ? appearance.color : null,
          categoryTitle: localizedType,
          currentIndex: currentIndex,
          totalPages: evaluatedPages.length + 1,
          pageIds: pageIds,
          pageController: pageController,
          onClose: () => close(ref, context, session.hasChanged),
          isLoading: isLoading,
          onControl: effectiveOnPressed,
          controlLabel: isSubmit
              ? context.translate.submitButtonText
              : betaLayout
              ? context.translate.continueButton
              : context.translate.nextButton,
          isReady: canProceed && !isLoading,
          isSubmit: isSubmit,
          errorMessage: !isSubmit && canProceed ? null : _errorMessage,
          onDismissError: () {
            setState(() {
              _errorMessage = null;
            });
          },
          totalQuestions: totalQuestions,
          answeredQuestions: answeredQuestions,
          pendingRequiredCount: pendingRequiredCount,
          validationFailed:
              !isSubmit && sessionGraphNonNull.tried && !canProceed,
        );

        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (await _handleNavigation(context, session)) {
              if (context.mounted) {
                setState(() {
                  _allowPop = true;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(Routes.HOME);
                    }
                  }
                });
              }
            }
          },
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: betaLayout
                    ? double.infinity
                    : Breakpoint.medium.value,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: betaLayout
                      ? null
                      : Border.symmetric(
                          vertical: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                ),
                child: RecordEntryProvider(
                  controller: controller,
                  child: RecordEntryShell(
                    alignContent: betaLayout,
                    header: scrollHeader
                        ? const RecordEntryNavigationHeader()
                        : null,
                    divider: const RecordEntryPageProgressDivider(),
                    controlStyle: RecordControlStyle.bottomBar,
                    content: PageView.builder(
                      onPageChanged: (value) {
                        setState(() {
                          currentIndex = value;
                          _currentPageId = pageIds[value];
                          _errorMessage = null;
                        });
                      },
                      physics: const NeverScrollableScrollPhysics(),
                      findChildIndexCallback: (key) {
                        if (key is! ValueKey<String>) return null;
                        final index = pageIds.indexOf(key.value);
                        return index < 0 ? null : index;
                      },
                      itemBuilder: (context, index) => KeyedSubtree(
                        key: ValueKey(pageIds[index]),
                        child: _buildContent(
                          context,
                          index,
                          evaluatedPages,
                          betaLayout,
                          scrollHeader: scrollHeader,
                          sessionGraph: sessionGraphNonNull,
                          submitQuestions: session.submitQuestions,
                        ),
                      ),
                      itemCount: evaluatedPages.length + 1,
                      controller: pageController,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _synchronizeCurrentPage(List<String> pageIds) {
    if (pageIds.isEmpty) return;

    final trackedId = _currentPageId;
    if (trackedId == null || !pageIds.contains(trackedId)) {
      currentIndex = currentIndex.clamp(0, pageIds.length - 1);
      _currentPageId = pageIds[currentIndex];
      return;
    }

    final resolvedIndex = pageIds.indexOf(trackedId);
    if (resolvedIndex == currentIndex) return;

    currentIndex = resolvedIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !pageController.hasClients) return;
      pageController.jumpToPage(resolvedIndex);
    });
  }

  Widget _buildContent(
    BuildContext context,
    int index,
    List<PageLayout> layouts,
    bool betaLayout, {
    bool scrollHeader = false,
    required SessionGraph sessionGraph,
    List<Question> submitQuestions = const [],
  }) {
    Widget content;
    int filteredCount = 0;
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );

    if (index == layouts.length) {
      content = SubmitScreen(
        questionsListener: sessionGraph,
        type: widget.type,
        submitQuestions: submitQuestions,
      );
    } else {
      final String? header = layouts[index].header;
      final visibleQids = sessionGraph.visibleQuestionsForPage(index);
      final List<Question> visibleQuestions = visibleQids
          .map(
            (qid) => sessionGraph.questionStateOf(qid)?.value.resolvedQuestion,
          )
          .whereType<Question>()
          .toList();

      filteredCount = visibleQuestions.length;

      content = QuestionScreen(
        header: header == null
            ? (betaLayout ? '' : context.translate.selectInstruction)
            : localizations?.value(header) ?? header,
        questions: visibleQuestions,
        questionsListener: sessionGraph,
        compact: betaLayout,
      );
    }

    if (betaLayout) {
      content = CompactRecordQuestions(
        requiredLabel: context.translate.recordQuestionRequired,
        invalidLabel: context.translate.recordQuestionInvalid,
        child: content,
      );
    }

    _scrollControllers.putIfAbsent(index, () {
      return ScrollController();
    });
    final scrollController = _scrollControllers[index]!;

    final previousCount = _previousQuestionCounts[index] ?? 0;
    if (filteredCount > previousCount && previousCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          final currentPosition = scrollController.position.pixels;
          final maxPosition = scrollController.position.maxScrollExtent;

          final targetPosition = (currentPosition + 150).clamp(
            0.0,
            maxPosition,
          );
          if (targetPosition > currentPosition) {
            scrollController.animateTo(
              targetPosition,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      });
    }
    _previousQuestionCounts[index] = filteredCount;

    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      interactive: false,
      controller: scrollController,
      radius: const Radius.circular(AppRounding.large),
      scrollbarOrientation: ScrollbarOrientation.right,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: EdgeInsets.only(
            top: betaLayout ? AppPadding.large : AppPadding.small,
            left: betaLayout
                ? RecordFormLayout.horizontalPadding
                : AppPadding.small,
            right: betaLayout
                ? RecordFormLayout.horizontalPadding
                : AppPadding.small,
            bottom: betaLayout ? AppPadding.large : 72,
          ),
          child: scrollHeader
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const RecordEntryHeader(showNavigation: false),
                    const SizedBox(height: AppPadding.medium),
                    content,
                  ],
                )
              : content,
        ),
      ),
    );
  }

  void close(WidgetRef ref, BuildContext context, bool hasChanged) async {
    if (!hasChanged || submitSuccess) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.HOME);
      }
    } else {
      if (context.canPop()) {
        ref.read(navigationControllerProvider).pop(context);
      } else {
        ref.read(navigationControllerProvider).navigate(context, Routes.HOME);
      }
    }
  }

  void _submitEntry(
    BuildContext context,
    WidgetRef ref,
    bool isEdit,
    SessionGraph sessionGraph,
  ) async {
    if (isLoading || !sessionGraph.canSubmit) {
      sessionGraph.tried = true;
      return;
    }
    QuestionsLocalizations? localizations = QuestionsLocalizations.of(context);

    final String detailType = localizations?.value(widget.type) ?? widget.type;

    setState(() {
      isLoading = true;
    });
    final StampRepo? stampRepo = await ref.read(stampProvider.future);
    final DetailResponse draftResponse = sessionGraph.createDetailResponse(
      detailType: widget.type,
    );

    final modularRepo = await ref.read(testProvider.future);
    final bool isNewStudyBm =
        !isEdit &&
        draftResponse.responses.any(
          (response) => response.question.id == 'BlueDyeQuestion',
        );
    final protocol = isNewStudyBm
        ? await ref.read(activeProtocolProvider.future)
        : null;
    final DetailResponse detailResponse = protocol == null
        ? draftResponse
        : DetailResponse(
            id: draftResponse.id,
            group: draftResponse.group,
            linkingId: blueDyeActiveRunSessionId(protocol),
            description: draftResponse.description,
            responses: draftResponse.responses,
            stamp: draftResponse.stamp,
            detailType: draftResponse.type,
          );
    final persistedResult = await _persistRecord(
      ref: ref,
      isEdit: isEdit,
      detailResponse: detailResponse,
      stampRepo: stampRepo,
    );
    final _PersistedRecord persisted;
    switch (persistedResult) {
      case Success(data: final saved):
        persisted = saved;
      case Failure():
        if (context.mounted) persistedResult.handle(context);
        if (mounted) setState(() => isLoading = false);
        return;
    }

    if (modularRepo != null &&
        (persisted.entry.timeOfDay == null ||
            persisted.entry.timeOfDay == TimeOfDayEntry.exact)) {
      final stamps = await stampRepo?.stamps.first ?? const <Stamp>[];
      final historicalEntries =
          blueDyeBmTestLogs(stamps, persisted.response.linkingId ?? '')
              .where(
                (log) => persisted.response.id != null
                    ? log.id != persisted.response.id
                    : log.stamp != persisted.response.stamp,
              )
              .map(
                (log) => detailResponseToEntry(
                  log.response,
                  persisted.entry.subUserId,
                ),
              )
              .toList(growable: false);
      await modularRepo.processEntry(
        persisted.entry,
        historicalResponses: historicalEntries,
      );
    }

    if (!mounted) return;
    setState(() => submitSuccess = true);

    navBarHeaderKey.currentState?.trigger();
    if (context.mounted) {
      if (!isEdit) {
        final StripesConfig config = ref.read(configProvider);
        final bool colored = config.betaUi.categoryColorsEnabled;
        final CategoryAppearance appearance = CategoryTheme.resolve(
          widget.type,
        );
        final DateTime submissionEntry =
            sessionGraph.submitTime ?? DateTime.now();
        showSnack(
          context,
          context.translate.undoEntry(
            detailType,
            submissionEntry,
            submissionEntry,
          ),
          accentColor: colored ? appearance.color : null,
          action: () async {
            final RepoResult result = await persisted.undo();
            if (context.mounted) {
              result.handle(context);
            }
          },
        );
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.HOME);
      }
    }
  }

  Future<RepoResult<_PersistedRecord>> _persistRecord({
    required WidgetRef ref,
    required bool isEdit,
    required DetailResponse detailResponse,
    required StampRepo? stampRepo,
  }) async {
    final config = ref.read(configProvider);
    final subUser = (await ref.read(subHolderProvider.future)).selected;
    if (subUser == null || SubUser.isEmpty(subUser)) {
      return const Failure(message: 'No profile selected');
    }

    Entry? originalEntry;
    if (isEdit && detailResponse.id != null) {
      final entryRepository = await ref.read(entryRepoProvider.future);
      if (entryRepository != null) {
        await entryRepository.refresh();
        final existing = await entryRepository.entries.first;
        for (final entry in existing) {
          if (entry.id == detailResponse.id) {
            originalEntry = entry;
            break;
          }
        }
      }
    }
    final needsEntryWriter =
        config.betaUi.multiSessionFlow ||
        originalEntry?.data.containsKey(recordTimeField) == true ||
        originalEntry?.data.containsKey(recordBatchIdField) == true;
    if (!needsEntryWriter) {
      final RepoResult<Stamp?> result = isEdit
          ? await stampRepo?.updateStamp(detailResponse) ??
                const Failure(message: 'Stamp repo not found')
          : await stampRepo?.addStamp(detailResponse) ??
                const Failure(message: 'Stamp repo not found');
      switch (result) {
        case Success(data: final savedStamp):
          final response = savedStamp is DetailResponse
              ? savedStamp
              : detailResponse;
          return Success(
            _PersistedRecord(
              response: response,
              entry: detailResponseToEntry(response, subUser.uid),
              undo: () =>
                  stampRepo?.removeStamp(response) ??
                  Future.value(const Failure(message: 'Stamp repo not found')),
            ),
          );
        case Failure():
          return _recordFailure(result);
      }
    }

    final writer = await ref.read(recordSessionWriterProvider.future);
    if (writer == null) {
      return const Failure(
        message: 'Entry persistence is not available for this repository',
      );
    }

    final requestedSessionId = isEdit
        ? null
        : detailResponse.linkingId ?? const Uuid().v4();
    final questionGraph = await ref.read(questionGraphProvider.future);
    final recordPath = questionGraph.recordPath(detailResponse.type);
    if (recordPath == null) {
      return const Failure(
        message: 'The record path for this entry is unavailable',
        type: FailureType.validation,
      );
    }
    final candidate = detailResponseToEntry(
      detailResponse,
      subUser.uid,
      category: recordPath.inputCategory,
      sessionId: requestedSessionId,
    ).copyWith(timeOfDay: isEdit ? null : TimeOfDayEntry.exact);
    final RepoResult<List<Entry>> result = isEdit
        ? await writer.updateSession(entries: [candidate])
        : await writer.createSession(
            sessionId: requestedSessionId!,
            entries: [candidate],
          );

    switch (result) {
      case Success(data: final entries):
        final entry = entries.single;
        final home = await ref.read(questionHomeProvider.future);
        final response = entry.toDetailResponse(home);
        await stampRepo?.refresh();
        return Success(
          _PersistedRecord(
            response: response,
            entry: entry,
            undo: () async {
              final removeResult = await writer.removeEntries(entries: [entry]);
              await stampRepo?.refresh();
              return removeResult;
            },
          ),
        );
      case Failure():
        return _recordFailure(result);
    }
  }

  Failure<_PersistedRecord> _recordFailure(Failure<dynamic> failure) => Failure(
    message: failure.message,
    type: failure.type,
    error: failure.error,
    stackTrace: failure.stackTrace,
  );

  @override
  void dispose() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    pageController.dispose();
    super.dispose();
  }
}

class _PersistedRecord {
  final DetailResponse response;
  final Entry entry;
  final Future<RepoResult<void>> Function() undo;

  const _PersistedRecord({
    required this.response,
    required this.entry,
    required this.undo,
  });
}
