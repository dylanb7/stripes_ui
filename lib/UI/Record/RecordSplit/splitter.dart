import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_screen.dart';
import 'package:stripes_ui/UI/Record/submit_screen.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
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

  @override
  void initState() {
    original = widget.questionListener.copy();
    pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.questionListener.addListener(_changedUpdate);
    });

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

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PagesData> pagesData = ref.watch(
      pagesByPath(
        PagesByPathProps(pathName: widget.type, filterEnabled: true),
      ),
    );

    final bool isSmall = getBreakpoint(context).isLessThan(Breakpoint.medium);

    final bool isEdit = widget.questionListener.editId != null;

    final bool edited = !isEdit || isEdit && hasChanged;

    return PageWrap(
      actions: [
        if (!isSmall)
          ...TabOption.values.map((tab) => LargeNavButton(
                tab: tab,
                customSelect: (String route) {
                  _close(ref, context, route);
                },
              )),
      ],
      bottomNav: isSmall
          ? SmallLayout(
              customSelect: (String route) {
                _close(ref, context, route);
              },
            )
          : null,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Breakpoint.small.value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: AsyncValueDefaults(
              value: pagesData,
              onData: (loadedPages) {
                final List<LoadedPageLayout> evaluatedPages = loadedPages
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
                            AppLocalizations.of(context)!.nLevelError(
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
                                  ? AppLocalizations.of(context)!
                                      .editSubmitButtonText
                                  : AppLocalizations.of(context)!
                                      .submitButtonText),
                    ),
                  );
                }

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RecordHeader(
                        type: widget.type,
                        hasChanged: hasChanged,
                        questionListener: widget.questionListener,
                        pageController: pageController,
                        currentIndex: currentIndex,
                        length: evaluatedPages.length,
                        close: () {
                          _close(ref, context, null);
                        },
                      ),
                      Expanded(
                        child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
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
                                itemBuilder: (context, index) => _buildContent(
                                    context, index, evaluatedPages),
                                itemCount: evaluatedPages.length + 1,
                                controller: pageController,
                              ),
                            )),
                      ),
                      const SizedBox(
                        height: 8.0,
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
                        height: 8.0,
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
    if (index == layouts.length) {
      content = SubmitScreen(
        questionsListener: widget.questionListener,
        type: widget.type,
      );
    } else {
      content = QuestionScreen(
          header: layouts[index].header ??
              AppLocalizations.of(context)!.selectInstruction,
          questions: layouts[index].questions,
          questionsListener: widget.questionListener);
    }
    final ScrollController scrollController = ScrollController();
    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      interactive: false,
      controller: scrollController,
      radius: const Radius.circular(20.0),
      scrollbarOrientation: ScrollbarOrientation.right,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
            child: content),
      ),
    );
  }

  void _close(WidgetRef ref, BuildContext context, String? route) {
    if (!hasChanged) {
      widget.questionListener.tried = false;
      if (route == null) {
        context.pop();
      } else {
        context.go(route);
      }
      return;
    }

    ref.read(overlayProvider.notifier).state = CurrentOverlay(
        widget: ErrorPrevention(
      type: widget.type,
      route: route,
    ));
  }

  void _submitEntry(BuildContext context, WidgetRef ref, bool isEdit) async {
    if (widget.questionListener.pending.isNotEmpty) {
      widget.questionListener.tried = true;
      showSnack(
          context,
          AppLocalizations.of(context)!
              .nLevelError(widget.questionListener.pending.length));
      return;
    }
    if (isLoading) return;
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
      await ref
          .read(testProvider)
          .valueOrNull
          ?.onResponseEdit(detailResponse, widget.type);
    } else {
      await repo?.addStamp(detailResponse);
      (await ref.read(testProvider.future))
          ?.onResponseSubmit(detailResponse, widget.type);
    }
    setState(() {
      submitSuccess = true;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      isLoading = false;
    });
    if (context.mounted) {
      if (!isEdit) {
        showSnack(
            context,
            AppLocalizations.of(context)!
                .undoEntry(widget.type, submissionEntry, submissionEntry),
            action: () async {
          await repo?.removeStamp(detailResponse);
          (await ref.read(testProvider.future))
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListenableBuilder(
        listenable: questionListener,
        builder: (context, child) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (questionListener.tried && pendingCount != 0) ...[
                  Text(
                    AppLocalizations.of(context)!.nLevelError(pendingCount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 8.0,
                  )
                ],
                if (submitButton != null) ...[
                  submitButton!,
                  const SizedBox(
                    height: 8.0,
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
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.linear);
                              }
                            : null,
                        child: Text(AppLocalizations.of(context)!.nextButton)),
                  ),
              ]);
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
      padding: const EdgeInsets.symmetric(vertical: 20.0),
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
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.linear);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_sharp),
                )
              : SizedBox(
                  width: Theme.of(context).iconTheme.size ?? 20,
                ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.recordHeader(type),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary),
                  textAlign: TextAlign.center,
                ),
                if (name != null && name.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context)!.recordUsername(type, name),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
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

  final String? route;

  const ErrorPrevention({required this.type, required this.route, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConfirmationPopup(
        title: Text(
          AppLocalizations.of(context)!.errorPreventionTitle,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.errorPreventionLineOne,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 8.0,
            ),
            Text(
              AppLocalizations.of(context)!
                  .errorPreventionLineTwo(type.toLowerCase()),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        onConfirm: () {
          if (route == null) {
            context.pop();
          } else {
            context.go(route!);
          }
        },
        cancel: AppLocalizations.of(context)!.errorPreventionStay,
        confirm: AppLocalizations.of(context)!.errorPreventionLeave);
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
