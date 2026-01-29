import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_ui/Util/helpers/repo_result_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Navigation/navigation_provider.dart';
import 'package:stripes_ui/Providers/questions/questions_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Record/Screens/question_screen.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/layout_helper.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/record_layout_shell.dart';
import 'package:stripes_ui/UI/Record/Screens/submit_screen.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:uuid/uuid.dart';

class RecordSplitter extends ConsumerStatefulWidget {
  final String type;

  late final QuestionsListener questionListener;
  RecordSplitter({super.key, required this.type, QuestionsListener? data}) {
    questionListener = data ?? QuestionsListener();
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return RecordSplitterState();
  }
}

class RecordSplitterState extends ConsumerState<RecordSplitter> {
  late final QuestionsListener original;

  late final PageController pageController;

  int currentIndex = 0;

  bool hasChanged = false;

  bool isLoading = false;

  bool submitSuccess = false;

  bool _allowPop = false;

  final Map<int, ScrollController> _scrollControllers = {};
  final Map<int, int> _previousQuestionCounts = {};
  bool _isScrolled = false;
  String? _errorMessage;

  @override
  void initState() {
    original = widget.questionListener.copy();
    pageController = PageController();
    widget.questionListener.addListener(_changedUpdate);

    super.initState();
  }

  _changedUpdate() {
    final bool change = !_areListenersEqual(original, widget.questionListener);

    if (mounted && change != hasChanged) {
      setState(() {
        hasChanged = change;
      });
    }
  }

  bool _areListenersEqual(QuestionsListener a, QuestionsListener b) {
    if (a.submitTime != b.submitTime) return false;
    if (a.description != b.description) return false;
    if (a.questions.length != b.questions.length) return false;

    for (final key in a.questions.keys) {
      if (!b.questions.containsKey(key)) return false;
      if (a.questions[key] != b.questions[key]) return false;
    }
    return true;
  }

  Future<bool> _handleNavigation(BuildContext context) async {
    if (!hasChanged) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ErrorPrevention(
        type: widget.type,
      ),
    );
    if (result == true) {
      setState(() {
        hasChanged = false;
      });
    }
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(registerGuardProvider(_handleNavigation));
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);

    final String localizedType =
        localizations?.value(widget.type) ?? widget.type;

    final AsyncValue<PagesData> pagesData = ref.watch(
      pagesByPath(
        PagesByPathProps(
          pathName: widget.type,
          filterEnabled: true,
        ),
      ),
    );

    final bool isEdit = widget.questionListener.editId != null;

    final bool edited = !isEdit || hasChanged;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _handleNavigation(context)) {
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
          constraints: BoxConstraints(maxWidth: Breakpoint.large.value),
          child: AsyncValueDefaults(
            value: pagesData,
            onData: (loadedPages) {
              final PagesData translatedPage =
                  localizations?.translatePage(loadedPages) ?? loadedPages;

              final List<LoadedPageLayout> evaluatedPages =
                  LayoutHelper.processLayouts(
                loadedLayouts: translatedPage.loadedLayouts,
                listener: widget.questionListener,
                deferCleanup: true,
              );

              final validation = LayoutHelper.validatePage(
                pages: evaluatedPages,
                currentIndex: currentIndex,
                listener: widget.questionListener,
              );

              final progress = LayoutHelper.calculateProgress(
                pages: evaluatedPages,
                currentIndex: currentIndex,
                listener: widget.questionListener,
              );

              final bool isSubmit = currentIndex == evaluatedPages.length;
              final VoidCallback? onPressed;
              if (isSubmit) {
                final testProviderValue = ref.watch(testProvider);
                List<Question> testAdditions = testProviderValue.valueOrNull
                        ?.getRecordAdditions(context, widget.type) ??
                    [];

                if (isEdit) {
                  testAdditions = testAdditions
                      .where((q) =>
                          widget.questionListener.fromQuestion(q) != null)
                      .toList();
                }

                final submitValidation = LayoutHelper.validateSubmitScreen(
                  submitQuestions: testAdditions,
                  listener: widget.questionListener,
                );

                final bool canSubmit = !testProviderValue.isLoading &&
                    submitValidation.requirementMet &&
                    !isLoading &&
                    edited;

                onPressed = submitSuccess
                    ? () {}
                    : canSubmit
                        ? () => _submitEntry(context, ref, isEdit)
                        : null;
              } else {
                onPressed = validation.canProceed
                    ? () {
                        widget.questionListener.tried = false;
                        pageController.nextPage(
                            duration: Durations.medium1, curve: Curves.linear);
                      }
                    : null;
              }

              List<Question> submitQuestions = ref
                      .read(testProvider)
                      .valueOrNull
                      ?.getRecordAdditions(context, widget.type) ??
                  [];
              if (isEdit) {
                submitQuestions = submitQuestions
                    .where(
                        (q) => widget.questionListener.fromQuestion(q) != null)
                    .toList();
              }

              final effectiveValidation = isSubmit
                  ? LayoutHelper.validateSubmitScreen(
                      submitQuestions: submitQuestions,
                      listener: widget.questionListener,
                    )
                  : validation;

              final VoidCallback effectiveOnPressed = onPressed == null &&
                      !effectiveValidation.canProceed &&
                      !isLoading
                  ? () {
                      widget.questionListener.tried = true;
                      setState(() {
                        if (effectiveValidation.pendingCount > 0) {
                          _errorMessage = context.translate
                              .nLevelError(effectiveValidation.pendingCount);
                        } else if (effectiveValidation.pendingRequirement !=
                            null) {
                          _errorMessage = effectiveValidation
                              .pendingRequirement!
                              .toReadableString(
                            (qid) => LayoutHelper.resolveQuestionPrompt(
                                qid, evaluatedPages),
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

              final SubUser? currentUser =
                  ref.read(subHolderProvider).valueOrNull?.selected;
              final String? subtitle =
                  currentUser == null || SubUser.isEmpty(currentUser)
                      ? null
                      : context.translate
                          .recordUsername(localizedType, currentUser.name);

              final controller = RecordEntryController(
                title: context.translate.recordHeader(localizedType),
                subtitle: subtitle,
                currentIndex: currentIndex,
                totalPages: evaluatedPages.length + 1,
                pageController: pageController,
                onClose: () => close(ref, context),
                isCollapsed: _isScrolled,
                isLoading: isLoading,
                onControl: effectiveOnPressed,
                controlLabel: isSubmit
                    ? context.translate.submitButtonText
                    : context.translate.nextButton,
                isReady: validation.canProceed && !isLoading,
                isSubmit: isSubmit,
                errorMessage: _errorMessage,
                onDismissError: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                totalQuestions: progress.total,
                answeredQuestions: progress.answered,
                pendingRequiredCount: progress.pendingRequired,
              );

              return RecordEntryProvider(
                controller: controller,
                child: RecordEntryShell(
                  divider: const ComboDivider(),
                  controlStyle: RecordControlStyle.bottomBar,
                  content: PageView.builder(
                    onPageChanged: (value) {
                      setState(() {
                        currentIndex = value;
                        _errorMessage = null;
                      });
                    },
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) =>
                        _buildContent(context, index, evaluatedPages, false),
                    itemCount: evaluatedPages.length + 1,
                    controller: pageController,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, int index,
      List<LoadedPageLayout> layouts, bool compactHeader) {
    Widget content;
    int filteredCount = 0;

    if (index == layouts.length) {
      content = SubmitScreen(
        questionsListener: widget.questionListener,
        type: widget.type,
      );
    } else {
      final List<Question> questions = layouts[index].questions;
      final List<Question> visible = [];
      final List<Question> hidden = [];

      for (final question in questions) {
        final bool shouldShow = question.dependsOn == null ||
            question.dependsOn!.eval(widget.questionListener);
        if (shouldShow) {
          visible.add(question);
        } else {
          hidden.add(question);
        }
      }

      for (final question in hidden) {
        if (widget.questionListener.fromQuestion(question) != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.questionListener.removeResponse(question);
            widget.questionListener.removePending(question);
          });
        }
      }

      filteredCount = visible.length;

      final Object? extra = GoRouterState.of(context).extra;
      final DetailResponse? baseline = extra is DetailResponse ? extra : null;

      content = QuestionScreen(
          header: compactHeader
              ? ""
              : (layouts[index].header ?? context.translate.selectInstruction),
          questions: visible,
          questionsListener: widget.questionListener,
          baseline: baseline);
    }

    _scrollControllers.putIfAbsent(index, () {
      final controller = ScrollController();
      controller.addListener(() {
        final bool scrolled = controller.hasClients && controller.offset > 10;
        if (scrolled != _isScrolled) {
          setState(() {
            _isScrolled = scrolled;
          });
        }
      });
      return controller;
    });
    final scrollController = _scrollControllers[index]!;

    final previousCount = _previousQuestionCounts[index] ?? 0;
    if (filteredCount > previousCount && previousCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          final currentPosition = scrollController.position.pixels;
          final maxPosition = scrollController.position.maxScrollExtent;

          final targetPosition =
              (currentPosition + 150).clamp(0.0, maxPosition);
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
            padding: const EdgeInsets.only(
                top: AppPadding.small,
                left: AppPadding.small,
                right: AppPadding.small,
                bottom: 72),
            child: content),
      ),
    );
  }

  void close(WidgetRef ref, BuildContext context) async {
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

  void _submitEntry(BuildContext context, WidgetRef ref, bool isEdit) async {
    if (widget.questionListener.pending.isNotEmpty) {
      widget.questionListener.tried = true;
      setState(() {
        _errorMessage = context.translate
            .nLevelError(widget.questionListener.pending.length);
      });
      return;
    }
    if (isLoading) return;
    QuestionsLocalizations? localizations = QuestionsLocalizations.of(context);

    final String detailType = localizations?.value(widget.type) ?? widget.type;

    setState(() {
      isLoading = true;
    });
    final StampRepo? repo = await ref.read(stampProvider.future);
    final DateTime submissionEntry =
        widget.questionListener.submitTime ?? DateTime.now();
    final int entryStamp = dateToStamp(submissionEntry);
    final DetailResponse detailResponse = DetailResponse(
      id: widget.questionListener.editId ?? const Uuid().v4(),
      description: widget.questionListener.description,
      responses: widget.questionListener.questions.values
          .map((res) => res.encodeGeneratedQuestion())
          .toList(growable: false),
      stamp: isEdit
          ? dateToStamp(widget.questionListener.submitTime!)
          : entryStamp,
      detailType: widget.type,
    );

    if (isEdit) {
      RepoResult<Stamp?>? result = await repo?.updateStamp(detailResponse) ??
          const Failure(message: 'Stamp repo not found');
      if (result case Success()) {
        await ((await ref.read(testProvider.future))
            ?.onResponseEdit(detailResponse, widget.type));
      }
      if (context.mounted) {
        result.handle(context);
      }
    } else {
      RepoResult<Stamp?>? result = await repo?.addStamp(detailResponse) ??
          const Failure(message: 'Stamp repo not found');
      if (result case Success()) {
        await (await ref.read(testProvider.future))
            ?.onResponseSubmit(detailResponse, widget.type);
      }
      if (context.mounted) {
        result.handle(context);
      }
    }
    setState(() {
      submitSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      isLoading = false;
    });

    navBarHeaderKey.currentState?.trigger();
    if (context.mounted) {
      if (!isEdit) {
        showSnack(
            context,
            context.translate
                .undoEntry(detailType, submissionEntry, submissionEntry),
            action: () async {
          final RepoResult result = await repo?.removeStamp(detailResponse) ??
              const Failure(message: 'Repo not found');
          await (await ref.read(testProvider.future))
              ?.onResponseDelete(detailResponse, widget.type);
          if (context.mounted) {
            result.handle(context);
          }
        });
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.HOME);
      }
    }
  }

  @override
  void dispose() {
    widget.questionListener.removeListener(_changedUpdate);
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

class ErrorPrevention extends ConsumerWidget {
  final String type;

  const ErrorPrevention({required this.type, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConfirmationPopup(
        title: Text(
          context.translate.errorPreventionTitle,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              context.translate.errorPreventionLineOne,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: AppPadding.small,
            ),
            Text(
              context.translate.errorPreventionLineTwo(type.toLowerCase()),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        cancel: context.translate.errorPreventionStay,
        confirm: context.translate.errorPreventionLeave);
  }
}

class BasicButton extends StatelessWidget {
  final Function(BuildContext) onClick;

  final String text;

  final Color color;

  const BasicButton(
      {required this.onClick,
      required this.color,
      required this.text,
      super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        onClick(context);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        shape: WidgetStateProperty.all(const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)))),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
