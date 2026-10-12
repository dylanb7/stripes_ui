import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/baseline_id.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Helpers/repo_result_handler.dart';
import 'package:stripes_ui/Providers/Questions/baseline_version_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Questions/record_session_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/record_layout_shell.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/session_entry_scaffold.dart';
import 'package:stripes_ui/UI/Record/Screens/question_screen.dart';

import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_ui/UI/CommonWidgets/discard_changes_sheet.dart';
import 'package:stripes_ui/Providers/Navigation/navigation_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';

class BaselineEntry extends ConsumerStatefulWidget {
  final String recordPath;
  final List<Question>? questions;
  final bool isEmbedded;
  final SessionData initialData;

  const BaselineEntry({
    super.key,
    required this.recordPath,
    this.questions,
    this.isEmbedded = false,
    SessionData? data,
  }) : initialData = data ?? const SessionData();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _BaselineEntryState();
  }
}

class _BaselineEntryState extends ConsumerState<BaselineEntry> {
  bool isLoading = false;
  bool submitSuccess = false;
  String? _errorMessage;

  late final PageController _pageController;
  int _currentIndex = 0;
  final Map<int, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    _pageController = PageController();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
    recordPathName: widget.recordPath,
    initialData: widget.initialData,
    whiteList: widget.questions?.map((q) => q.id).toSet(),
  );

  @override
  Widget build(BuildContext context) {
    return SessionEntryScaffold(
      args: _sessionArgs,
      errorLabel: 'Unable to load baseline',
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

        final AsyncValue<PagesData> pagesData = ref.watch(
          pagesByPath(
            PagesByPathProps(pathName: widget.recordPath, filterEnabled: true),
          ),
        );

        final bool isEdit = sessionGraphNonNull.editId != null;
        final bool edited = !isEdit || isEdit && session.hasChanged;

        return PopScope(
          canPop: !session.hasChanged,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (await _handleNavigation(context, session)) {
              if (context.mounted) {
                await Future.delayed(Duration.zero);
                if (context.mounted) {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(Routes.HOME);
                  }
                }
              }
            }
          },
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: AsyncValueDefaults(
                  value: pagesData,
                  onData: (loadedPages) {
                    final List<PageLayout> evaluatedPages =
                        sessionGraphNonNull.visiblePages;

                    if (evaluatedPages.isEmpty) return const SizedBox();

                    final PageSessionState? pageValidation = sessionGraphNonNull
                        .validatePage(_currentIndex);

                    final bool isLastPage =
                        _currentIndex == evaluatedPages.length - 1;

                    final int totalQuestions = pageValidation?.totalCount ?? 0;
                    final int answeredQuestions =
                        pageValidation?.answeredCount ?? 0;
                    final int pendingRequiredCount =
                        pageValidation?.pendingCount ?? 0;

                    final bool canProceed = pageValidation?.canProceed ?? false;

                    final VoidCallback? onPressed = isLastPage
                        ? (canProceed && edited && !isLoading
                              ? () async {
                                  setState(() => isLoading = true);
                                  try {
                                    await _submit(
                                      context,
                                      ref,
                                      true,
                                      sessionGraphNonNull,
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() => isLoading = false);
                                    }
                                  }
                                }
                              : null)
                        : (canProceed
                              ? () {
                                  sessionGraphNonNull.tried = false;
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null);

                    final VoidCallback effectiveOnPressed =
                        onPressed == null && !canProceed && !isLoading
                        ? () {
                            sessionGraphNonNull.tried = true;
                            setState(() {
                              final pendingCount =
                                  pageValidation?.pendingCount ?? 0;
                              if (pendingCount > 0) {
                                _errorMessage = context.translate.nLevelError(
                                  pendingCount,
                                );
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

                    final controller = RecordEntryController(
                      title:
                          localizations?.value(widget.recordPath) ??
                          widget.recordPath,
                      currentIndex: _currentIndex,
                      totalPages: evaluatedPages.length,
                      pageIds: [
                        for (
                          var index = 0;
                          index < evaluatedPages.length;
                          index++
                        )
                          evaluatedPages[index].id ?? 'baseline-page-$index',
                      ],
                      pageController: _pageController,
                      onClose: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(Routes.HOME);
                        }
                      },
                      isLoading: isLoading,
                      onControl: effectiveOnPressed,
                      controlLabel: isLastPage ? 'Submit' : 'Next',
                      isReady: canProceed && !isLoading,
                      isSubmit: isLastPage,
                      errorMessage: canProceed ? null : _errorMessage,
                      onDismissError: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                      totalQuestions: totalQuestions,
                      answeredQuestions: answeredQuestions,
                      pendingRequiredCount: pendingRequiredCount,
                      validationFailed:
                          sessionGraphNonNull.tried && !canProceed,
                    );

                    return RecordEntryProvider(
                      controller: controller,
                      child: RecordEntryShell(
                        divider: const RecordEntryPageProgressDivider(),
                        controlStyle: RecordControlStyle.bottomBar,
                        content: PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: evaluatedPages.length,
                          onPageChanged: (idx) {
                            setState(() {
                              _currentIndex = idx;
                              _errorMessage = null;
                            });
                          },
                          itemBuilder: (context, index) {
                            final pageLayout = evaluatedPages[index];
                            final String? header = pageLayout.header;
                            final visibleQids = sessionGraphNonNull
                                .visibleQuestionsForPage(index);
                            final List<Question> visibleQuestions = visibleQids
                                .map(
                                  (qid) => sessionGraphNonNull
                                      .questionStateOf(qid)
                                      ?.value
                                      .resolvedQuestion,
                                )
                                .whereType<Question>()
                                .toList();

                            _scrollControllers.putIfAbsent(
                              index,
                              () => ScrollController(),
                            );
                            final scrollController = _scrollControllers[index]!;

                            return Scrollbar(
                              controller: scrollController,
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppPadding.small,
                                    left: AppPadding.small,
                                    right: AppPadding.small,
                                    bottom: 72,
                                  ),
                                  child: QuestionScreen(
                                    header: header == null
                                        ? ''
                                        : localizations?.value(header) ??
                                              header,
                                    questions: visibleQuestions,
                                    questionsListener: sessionGraphNonNull,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    bool showConfirmation,
    SessionGraph sessionGraph,
  ) async {
    if (!sessionGraph.canSubmit) {
      sessionGraph.tried = true;
      return;
    }
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );

    final StampRepo? repo = await ref.read(stampProvider.future);
    if (repo == null || SubUser.isEmpty(repo.currentUser)) {
      if (context.mounted) {
        const Failure(message: 'No profile selected').handle(context);
      }
      return;
    }
    final DateTime submissionEntry = sessionGraph.submitTime ?? DateTime.now();

    final versions =
        ref.read(baselineVersionsProvider(widget.recordPath)).value ?? [];
    final int nextVersion = versions.isEmpty ? 1 : versions.first.version + 1;
    final String entryId = BaselineId.create(
      widget.recordPath,
      nextVersion,
      subUserId: repo.currentUser.uid,
    );

    final DetailResponse detailResponse = sessionGraph.createDetailResponse(
      detailType: widget.recordPath,
      id: entryId,
    );

    final RepoResult result = await repo.addStamp(detailResponse);
    if (context.mounted) {
      result.handle(context);
    }
    if (result is! Success) return;

    final modularRepo = await ref.read(testProvider.future);
    final subUser = (await ref.read(subHolderProvider.future)).selected;
    if (modularRepo != null && subUser != null && !SubUser.isEmpty(subUser)) {
      final entry = detailResponseToEntry(
        detailResponse,
        subUser.uid,
        category: InputCategory.baseline,
      );
      await modularRepo.processEntry(entry);
    }

    if (mounted) {
      setState(() {
        submitSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 600));

      if (context.mounted) {
        final String baselineName =
            localizations?.value(widget.recordPath) ?? widget.recordPath;
        showSnack(
          context,
          context.translate.undoEntry(
            baselineName,
            submissionEntry,
            submissionEntry,
          ),
          action: () async {
            final RepoResult result = await repo.removeStamp(detailResponse);
            if (context.mounted) {
              result.handle(context);
            }
          },
        );

        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.HOME);
        }
      }
    }
  }
}
