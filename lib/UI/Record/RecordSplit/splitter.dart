import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/navigation_provider.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_screen.dart';
import 'package:stripes_ui/UI/Record/submit_screen.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';
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

  @override
  void initState() {
    original = widget.questionListener.copy();
    pageController = PageController();
    widget.questionListener.addListener(_changedUpdate);

    super.initState();
  }

  _changedUpdate() {
    final bool change = original != widget.questionListener;

    if (mounted) {
      setState(() {
        hasChanged = change;
      });
    }
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
      // User confirmed they want to leave, reset hasChanged so guard doesn't trigger again
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

    final bool edited = !isEdit || isEdit && hasChanged;

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Breakpoint.small.value),
            child: AsyncValueDefaults(
              value: pagesData,
              onData: (loadedPages) {
                final PagesData translatedPage =
                    localizations?.translatePage(loadedPages) ?? loadedPages;

                final List<LoadedPageLayout> evaluatedPages = translatedPage
                        .loadedLayouts
                        ?.where((page) =>
                            page.dependsOn.eval(widget.questionListener))
                        .toList() ??
                    [];
                int pending() {
                  if (currentIndex > evaluatedPages.length - 1) return 0;
                  final List<Question> pageQuestions =
                      evaluatedPages[currentIndex].questions;
                  return widget.questionListener.pending
                      .where((pending) => pageQuestions.contains(pending))
                      .length;
                }

                final int pendingCount = pending();

                Widget? submitButton() {
                  if (currentIndex != evaluatedPages.length) return null;
                  final bool canSubmit =
                      pendingCount == 0 && !isLoading && edited;
                  return GestureDetector(
                    onTap: () {
                      if (pendingCount != 0 && !isLoading) {
                        showSnack(
                            context,
                            context.translate.nLevelError(
                                widget.questionListener.pending.length));
                      }
                    },
                    child: FilledButton(
                      onPressed: submitSuccess
                          ? () {}
                          : canSubmit
                              ? () {
                                  _submitEntry(context, ref, isEdit);
                                }
                              : null,
                      child: submitSuccess
                          ? const Icon(Icons.check)
                          : isLoading
                              ? const ButtonLoadingIndicator()
                              : Text(isEdit
                                  ? context.translate.editSubmitButtonText
                                  : context.translate.submitButtonText),
                    ),
                  );
                }

                return Column(children: [
                  RecordHeader(
                    type: localizedType,
                    hasChanged: hasChanged,
                    questionListener: widget.questionListener,
                    pageController: pageController,
                    currentIndex: currentIndex,
                    length: evaluatedPages.length,
                    close: () {
                      close(ref, context);
                    },
                  ),
                  Expanded(
                    child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppPadding.medium),
                          color: ElevationOverlay.applySurfaceTint(
                              Theme.of(context).cardColor,
                              Theme.of(context).colorScheme.surfaceTint,
                              3),
                        ),
                        child: IgnorePointer(
                          ignoring: isLoading,
                          child: PageView.builder(
                            onPageChanged: (value) {
                              setState(() {
                                currentIndex = value;
                              });
                            },
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) =>
                                _buildContent(context, index, evaluatedPages),
                            itemCount: evaluatedPages.length + 1,
                            controller: pageController,
                          ),
                        )),
                  ),
                  const SizedBox(
                    height: AppPadding.tiny,
                  ),
                  IgnorePointer(
                    ignoring: isLoading || pagesData.isLoading,
                    child: Center(
                      child: RecordFooter(
                        submitButton: submitButton(),
                        questionListener: widget.questionListener,
                        pageController: pageController,
                        length: evaluatedPages.length,
                        pendingCount: pendingCount,
                        currentIndex: currentIndex,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: AppPadding.tiny,
                  )
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, int index, List<LoadedPageLayout> layouts) {
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
          widget.questionListener.removeResponse(question);
          widget.questionListener.removePending(question);
        }
      }

      filteredCount = visible.length;

      content = QuestionScreen(
          header: layouts[index].header ?? context.translate.selectInstruction,
          questions: visible,
          questionsListener: widget.questionListener);
    }

    _scrollControllers.putIfAbsent(index, () => ScrollController());
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
            padding: const EdgeInsets.symmetric(
                vertical: AppPadding.tiny, horizontal: AppPadding.small),
            child: content),
      ),
    );
  }

  void close(WidgetRef ref, BuildContext context) async {
    if (!hasChanged) {
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
      showSnack(
          context,
          context.translate
              .nLevelError(widget.questionListener.pending.length));
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
      responses:
          widget.questionListener.questions.values.toList(growable: false),
      stamp: isEdit
          ? dateToStamp(widget.questionListener.submitTime!)
          : entryStamp,
      detailType: widget.type,
    );

    if (isEdit) {
      await repo?.updateStamp(detailResponse);
      await ((await ref.read(testProvider.future))
          ?.onResponseEdit(detailResponse, widget.type));
    } else {
      await repo?.addStamp(detailResponse);
      await (await ref.read(testProvider.future))
          ?.onResponseSubmit(detailResponse, widget.type);
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
          await repo?.removeStamp(detailResponse);
          await (await ref.read(testProvider.future))
              ?.onResponseDelete(detailResponse, widget.type);
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

class RecordFooter extends StatelessWidget {
  final QuestionsListener questionListener;
  final PageController pageController;
  final int length, pendingCount, currentIndex;

  final Widget? submitButton;

  const RecordFooter(
      {required this.questionListener,
      required this.pageController,
      required this.submitButton,
      required this.pendingCount,
      required this.currentIndex,
      required this.length,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.xl, vertical: AppPadding.tiny),
      child: ListenableBuilder(
        listenable: questionListener,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (questionListener.tried && pendingCount != 0) ...[
                Text(
                  context.translate.nLevelError(pendingCount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: AppPadding.tiny,
                )
              ],
              if (submitButton != null) ...[
                submitButton!,
                const SizedBox(
                  height: AppPadding.tiny,
                )
              ],
              if (length != 0 && currentIndex != length)
                GestureDetector(
                  onTap: () {
                    if (pendingCount != 0) {
                      questionListener.tried = true;
                    }
                  },
                  child: FilledButton(
                      onPressed: pendingCount == 0
                          ? () {
                              questionListener.tried = false;
                              pageController.nextPage(
                                  duration: Durations.medium1,
                                  curve: Curves.linear);
                            }
                          : null,
                      child: Text(context.translate.nextButton)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class RecordHeader extends ConsumerWidget {
  final String type;
  final bool hasChanged;
  final QuestionsListener questionListener;
  final PageController pageController;
  final int currentIndex, length;
  final Function close;

  const RecordHeader(
      {required this.type,
      required this.hasChanged,
      required this.questionListener,
      required this.pageController,
      required this.currentIndex,
      required this.length,
      required this.close,
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SubUser? current = ref.read(subHolderProvider).valueOrNull?.selected;
    final String? name =
        current == null || SubUser.isEmpty(current) ? null : current.name;
    return Padding(
      padding:
          const EdgeInsets.only(bottom: AppPadding.tiny, top: AppPadding.small),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          length != 0
              ? IconButton(
                  onPressed: () {
                    if (currentIndex == 0) {
                      close();
                    } else {
                      questionListener.tried = false;
                      pageController.previousPage(
                          duration: Durations.medium1, curve: Curves.linear);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_sharp),
                )
              : SizedBox(
                  width: Theme.of(context).iconTheme.size ?? 24.0,
                ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  context.translate.recordHeader(type),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary),
                  textAlign: TextAlign.center,
                ),
                if (name != null && name.isNotEmpty) ...[
                  Text(
                    context.translate.recordUsername(type, name),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ]
              ],
            ),
          ),
          SizedBox(
            width: Theme.of(context).iconTheme.size ?? 24.0,
          ),
        ],
      ),
    );
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
