import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/question_splitter.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_screen.dart';
import 'package:stripes_ui/UI/Record/submit_screen.dart';
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
    final PageProps props =
        PageProps(context: context, questionListener: widget.questionListener);
    final List<PageLayout> pages =
        ref.watch(pagePaths(props))[widget.type]?.pages ?? [];
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;

    final AsyncValue<QuestionRepo> questionRepo = ref.watch(questionsProvider);

    if (questionRepo.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final QuestionHome home = questionRepo.value!.questions;

    final bool isEdit = widget.questionListener.editId != null;

    final bool edited = !isEdit || isEdit && hasChanged;

    int pending() {
      if (currentIndex > pages.length - 1) return 0;
      final List<String> pageQuestions = pages[currentIndex].questionIds;
      return widget.questionListener.pending
          .where((pending) => pageQuestions.contains(pending.id))
          .length;
    }

    final int pendingCount = pending();

    Widget? submitButton() {
      if (currentIndex != pages.length) return null;
      return GestureDetector(
        onTap: () {
          if (pendingCount != 0 && !isLoading) {
            showSnack(
                context,
                AppLocalizations.of(context)!
                    .nLevelError(widget.questionListener.pending.length));
          }
        },
        child: FilledButton(
          onPressed: pendingCount == 0 && !isLoading && edited
              ? () {
                  _submitEntry(context, ref, isEdit);
                }
              : null,
          child: isLoading
              ? const ButtonLoadingIndicator()
              : Text(isEdit
                  ? AppLocalizations.of(context)!.editSubmitButtonText
                  : AppLocalizations.of(context)!.submitButtonText),
        ),
      );
    }

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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SMALL_LAYOUT),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecordHeader(
                type: widget.type,
                hasChanged: hasChanged,
                questionListener: widget.questionListener,
                pageController: pageController,
                currentIndex: currentIndex,
                length: pages.length,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: ElevationOverlay.applySurfaceTint(
                          Theme.of(context).cardColor,
                          Theme.of(context).colorScheme.surfaceTint,
                          3)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 5.0, horizontal: 8.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: IgnorePointer(
                              ignoring: isLoading,
                              child: PageView.builder(
                                onPageChanged: (value) {
                                  setState(() {
                                    currentIndex = value;
                                  });
                                },
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  Widget content;
                                  if (index == pages.length) {
                                    content = SubmitScreen(
                                      questionsListener:
                                          widget.questionListener,
                                      type: widget.type,
                                    );
                                  } else {
                                    content = QuestionScreen(
                                        header: pages[index].header ??
                                            AppLocalizations.of(context)!
                                                .selectInstruction,
                                        questions: pages[index]
                                            .questionIds
                                            .map((id) => home.fromBank(id))
                                            .toList(),
                                        questionsListener:
                                            widget.questionListener);
                                  }
                                  final ScrollController scrollController =
                                      ScrollController();
                                  return Scrollbar(
                                    thumbVisibility: true,
                                    thickness: 8.0,
                                    interactive: false,
                                    controller: scrollController,
                                    radius:
                                        const Radius.circular(double.infinity),
                                    scrollbarOrientation:
                                        ScrollbarOrientation.right,
                                    child: SingleChildScrollView(
                                        controller: scrollController,
                                        scrollDirection: Axis.vertical,
                                        child: content),
                                  );
                                },
                                itemCount: pages.length + 1,
                                controller: pageController,
                              ),
                            ),
                          ),
                        ]),
                  ),
                ),
              ),
              const SizedBox(
                height: 8.0,
              ),
              IgnorePointer(
                ignoring: isLoading,
                child: Center(
                  child: RecordFooter(
                    submitButton: submitButton(),
                    questionListener: widget.questionListener,
                    pageController: pageController,
                    length: pages.length,
                    pendingCount: pendingCount,
                    currentIndex: currentIndex,
                  ),
                ),
              ),
              const SizedBox(
                height: 8.0,
              )
            ],
          ),
        ),
      ),
    );
  }

  void _close(WidgetRef ref, BuildContext context, String route) {
    if (!hasChanged) {
      widget.questionListener.tried = false;
      context.go(route);
      return;
    }

    ref.read(overlayProvider.notifier).state = CurrentOverlay(
        widget: ErrorPrevention(
      type: widget.type,
      route: route,
    ));
  }

  void _submitEntry(BuildContext context, WidgetRef ref, bool isEdit) async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    final StampRepo? repo = ref.read(stampProvider).map(
        data: (data) => data.value,
        error: (error) => null,
        loading: (loading) => null);
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
      await ref
          .read(testProvider)
          .valueOrNull
          ?.onResponseSubmit(detailResponse, widget.type);
    }
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
          await ref
              .read(testProvider)
              .valueOrNull
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

  const RecordHeader(
      {required this.type,
      required this.hasChanged,
      required this.questionListener,
      required this.pageController,
      required this.currentIndex,
      required this.length,
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
                  onPressed: currentIndex == 0
                      ? null
                      : () {
                          questionListener.tried = false;
                          pageController.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.linear);
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

  final String route;

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
          context.go(route);
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
