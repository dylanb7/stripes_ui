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

    if (mounted && change) {
      setState(() {
        hasChanged = change;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<PageLayout> pages =
        ref.watch(pagePaths)[widget.type]?.pages ?? [];

    final AsyncValue<QuestionRepo> questionRepo = ref.watch(questionsProvider);

    if (questionRepo.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final QuestionHome home = questionRepo.value!.questions;

    final bool isEdit = widget.questionListener.editId != null;

    final bool edited = !isEdit || isEdit && hasChanged;

    final bool hasPending = widget.questionListener.pending.isNotEmpty;

    return PageWrap(
      leading: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          _close(ref, context);
        },
        icon: Icon(Icons.adaptive.arrow_back),
      ),
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
                  listener: widget.questionListener),
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
                                    thickness: 10,
                                    controller: scrollController,
                                    radius: const Radius.circular(20),
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
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Divider(
                              height: 2,
                              indent: 15,
                              endIndent: 15,
                              thickness: 2,
                            ),
                          ),
                          RecordFooter(
                            submitButton: isEdit || currentIndex == pages.length
                                ? GestureDetector(
                                    onTap: () {
                                      if (hasPending && !isLoading) {
                                        showSnack(
                                            context,
                                            AppLocalizations.of(context)!
                                                .nLevelError(widget
                                                    .questionListener
                                                    .pending
                                                    .length));
                                      }
                                    },
                                    child: FilledButton(
                                      onPressed:
                                          !hasPending && !isLoading && edited
                                              ? () {
                                                  _submitEntry(
                                                      context, ref, isEdit);
                                                }
                                              : null,
                                      child: isLoading
                                          ? const ButtonLoadingIndicator()
                                          : Text(isEdit
                                              ? AppLocalizations.of(context)!
                                                  .editSubmitButtonText
                                              : AppLocalizations.of(context)!
                                                  .submitButtonText),
                                    ),
                                  )
                                : null,
                            questionListener: widget.questionListener,
                            pageController: pageController,
                            length: pages.length,
                          )
                        ]),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              )
            ],
          ),
        ),
      ),
    );
  }

  void _close(WidgetRef ref, BuildContext context) {
    if (!hasChanged) {
      widget.questionListener.tried = false;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.HOME);
      }
      return;
    }

    ref.read(overlayProvider.notifier).state =
        CurrentOverlay(widget: ErrorPrevention(type: widget.type));
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

class SubmitFAB extends StatelessWidget {
  final int pendingLength;

  final bool isLoading, edited, isEdit;

  final Function submit;

  const SubmitFAB(
      {required this.submit,
      required this.pendingLength,
      required this.isLoading,
      required this.edited,
      required this.isEdit,
      super.key});

  @override
  Widget build(BuildContext context) {
    //if (isEdit || currentIndex == pages.length)
    return FloatingActionButton.extended(
      heroTag: "Submit-Button",
      label: Text(isEdit
          ? AppLocalizations.of(context)!.editSubmitButtonText
          : AppLocalizations.of(context)!.submitButtonText),
      icon: Icon(isEdit ? Icons.edit : Icons.add),
      onPressed: pendingLength == 0 && !isLoading && edited
          ? () {
              if (pendingLength > 0 && !isLoading) {
                showSnack(context,
                    AppLocalizations.of(context)!.nLevelError(pendingLength));
                return;
              }
              submit();
            }
          : null,
    );
  }
}

class RecordFooter extends StatelessWidget {
  final QuestionsListener questionListener;
  final PageController pageController;
  final int length;
  final Widget? submitButton;

  const RecordFooter(
      {required this.questionListener,
      required this.pageController,
      required this.submitButton,
      required this.length,
      super.key});

  @override
  Widget build(BuildContext context) {
    final int currentIndex = pageController.page?.round() ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListenableBuilder(
        listenable: questionListener,
        builder: (context, child) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (questionListener.tried &&
                    questionListener.pending.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context)!
                        .nLevelError(questionListener.pending.length),
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
                if (length != 0)
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        currentIndex > 0
                            ? IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: _prev,
                                highlightColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                tooltip: 'Previous',
                                iconSize: 45,
                                icon: Icon(Icons.arrow_back_rounded,
                                    color: Theme.of(context).primaryColor),
                              )
                            : const SizedBox(
                                width: 45,
                              ),
                        SmoothPageIndicator(
                          controller: pageController,
                          count: length + 1,
                          onDotClicked: (index) {
                            _goToPage(index);
                          },
                          effect: ScrollingDotsEffect(
                              activeDotColor: Theme.of(context).primaryColor,
                              activeDotScale: 1),
                        ),
                        currentIndex < length
                            ? IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: _next,
                                highlightColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                tooltip: 'Next',
                                iconSize: 45,
                                icon: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: questionListener.pending.isEmpty
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).disabledColor,
                                ),
                              )
                            : const SizedBox(
                                width: 45,
                              )
                      ])
              ]);
        },
      ),
    );
  }

  _goToPage(int index) {
    if (questionListener.pending.isEmpty) {
      questionListener.tried = false;
      pageController.animateToPage(index,
          duration: const Duration(milliseconds: 200), curve: Curves.linear);
    } else {
      questionListener.tried = true;
    }
  }

  _next() {
    if (questionListener.pending.isEmpty) {
      questionListener.tried = false;
      pageController.nextPage(
          duration: const Duration(milliseconds: 200), curve: Curves.linear);
    } else {
      questionListener.tried = true;
    }
  }

  _prev() {
    questionListener.tried = false;
    pageController.previousPage(
        duration: const Duration(milliseconds: 250), curve: Curves.linear);
  }
}

class RecordHeader extends ConsumerWidget {
  final String type;
  final bool hasChanged;
  final QuestionsListener listener;
  const RecordHeader(
      {required this.type,
      required this.hasChanged,
      required this.listener,
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SubUser? current = ref.read(subHolderProvider).valueOrNull?.selected;
    final String? name =
        current == null || SubUser.isEmpty(current) ? null : current.name;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
      child: Center(
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
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(Routes.HOME);
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
        backgroundColor: MaterialStateProperty.all(color),
        shape: MaterialStateProperty.all(const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)))),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
