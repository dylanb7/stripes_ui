import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/question_splitter.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
import 'package:stripes_ui/UI/Record/submit_screen.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

final continueTried = StateProvider.autoDispose((_) => false);

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

  @override
  void initState() {
    original = QuestionsListener.copy(widget.questionListener);
    pageController = PageController();
    widget.questionListener.addListener(() {
      setState(() {
        hasChanged = original == widget.questionListener;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<PageLayout> pages =
        ref.watch(pagePaths)[widget.type]?.pages ?? [];
    final int length = pages.length;
    final OverlayQuery query = ref.watch(overlayProvider);
    final bool tried = ref.watch(continueTried);
    final hasPending = widget.questionListener.pending.isNotEmpty;
    final String? name = _name();
    final bool emptyName = name == null || name.isEmpty;
    final Color primary = Theme.of(context).primaryColor;
    final Color disabled = Theme.of(context).disabledColor;
    return SafeArea(
      child: Scaffold(
        body: Stack(children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: SMALL_LAYOUT),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              emptyName
                                  ? AppLocalizations.of(context)!
                                      .emptyRecordHeader(widget.type)
                                  : AppLocalizations.of(context)!
                                      .recordHeader(widget.type, name),
                              style: darkBackgroundHeaderStyle,
                            ),
                          ),
                          IconButton(
                              onPressed: () {
                                _showErrorPrevention(context);
                              },
                              alignment: Alignment.topRight,
                              icon: const Icon(
                                Icons.close,
                                size: 35,
                              ))
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                    Expanded(
                      child: Card(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 8.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: PageView.builder(
                                    onPageChanged: (value) {
                                      setState(() {
                                        currentIndex = value;
                                      });
                                    },
                                    physics:
                                        const NeverScrollableScrollPhysics(),
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
                                            questions: pages[index].questions,
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
                                const Padding(
                                  padding: EdgeInsets.only(top: 1),
                                  child: Divider(
                                    height: 2,
                                    indent: 15,
                                    endIndent: 15,
                                    thickness: 2,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        if (tried && hasPending)
                                          Text(
                                            AppLocalizations.of(context)!
                                                .nLevelError(widget
                                                    .questionListener
                                                    .pending
                                                    .length),
                                            style: errorStyleTitle.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error),
                                          ),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              currentIndex > 0
                                                  ? IconButton(
                                                      padding: EdgeInsets.zero,
                                                      onPressed: _prev,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      splashColor:
                                                          Colors.transparent,
                                                      tooltip: 'Previous',
                                                      iconSize: 45,
                                                      icon: Icon(
                                                        Icons
                                                            .arrow_back_rounded,
                                                        color: widget
                                                                .questionListener
                                                                .pending
                                                                .isEmpty
                                                            ? primary
                                                            : disabled,
                                                      ),
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
                                                    activeDotColor:
                                                        Theme.of(context)
                                                            .primaryColor,
                                                    activeDotScale: 1),
                                              ),
                                              currentIndex < length
                                                  ? IconButton(
                                                      padding: EdgeInsets.zero,
                                                      onPressed: _next,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      splashColor:
                                                          Colors.transparent,
                                                      tooltip: 'Next',
                                                      iconSize: 45,
                                                      icon: Icon(
                                                        Icons
                                                            .arrow_forward_rounded,
                                                        color: widget
                                                                .questionListener
                                                                .pending
                                                                .isEmpty
                                                            ? primary
                                                            : disabled,
                                                      ),
                                                    )
                                                  : const SizedBox(
                                                      width: 45,
                                                    )
                                            ])
                                      ]),
                                ),
                              ]),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (query.widget != null) query.widget!,
        ]),
      ),
    );
  }

  String? _name() {
    SubUser current = ref.read(subHolderProvider).current;
    return SubUser.isEmpty(current) ? null : current.name;
  }

  _goToPage(int index) {
    if (widget.questionListener.pending.isEmpty) {
      ref.read(continueTried.notifier).state = false;
      pageController.animateToPage(index,
          duration: const Duration(milliseconds: 250), curve: Curves.linear);
    } else {
      ref.read(continueTried.notifier).state = true;
    }
  }

  _next() {
    if (widget.questionListener.pending.isEmpty) {
      ref.read(continueTried.notifier).state = false;
      pageController.nextPage(
          duration: const Duration(milliseconds: 250), curve: Curves.linear);
    } else {
      ref.read(continueTried.notifier).state = true;
    }
  }

  _prev() {
    if (widget.questionListener.pending.isEmpty) {
      ref.read(continueTried.notifier).state = false;
      pageController.previousPage(
          duration: const Duration(milliseconds: 250), curve: Curves.linear);
    } else {
      ref.read(continueTried.notifier).state = true;
    }
  }

  _showErrorPrevention(BuildContext context) {
    if (!hasChanged) {
      ref.read(continueTried.notifier).state = false;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.HOME);
      }
      return;
    }

    ref.read(overlayProvider.notifier).state =
        OverlayQuery(widget: ErrorPrevention(type: widget.type));
  }
}

class ErrorPrevention extends ConsumerWidget {
  final String type;

  const ErrorPrevention({required this.type, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConfirmationPopup(
        title: Text(
          AppLocalizations.of(context)!.errorPreventionTitle,
          style: darkBackgroundHeaderStyle,
          textAlign: TextAlign.center,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.errorPreventionLineOne,
              style: lightBackgroundStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 8.0,
            ),
            Text(
              AppLocalizations.of(context)!
                  .errorPreventionLineTwo(type.toLowerCase()),
              style: lightBackgroundStyle,
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
    /*return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: lightBackgroundText.withOpacity(0.9),
          ),
        ),
        Center(
          child: SizedBox(
            width: SMALL_LAYOUT / 1.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.errorPreventionTitle,
                          style: darkBackgroundHeaderStyle.copyWith(
                              color: buttonDarkBackground),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        Text(
                          AppLocalizations.of(context)!.errorPreventionLineOne,
                          style: lightBackgroundStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        Text(
                          AppLocalizations.of(context)!
                              .errorPreventionLineTwo(type.toLowerCase()),
                          style: lightBackgroundStyle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    BasicButton(
                        onClick: (context) {
                          _dismiss(context, ref);
                        },
                        color: buttonDarkBackground,
                        text:
                            AppLocalizations.of(context)!.errorPreventionLeave),
                    BasicButton(
                        onClick: (context) {
                          _closeOverlay(context, ref);
                        },
                        color: buttonLightBackground,
                        text:
                            AppLocalizations.of(context)!.errorPreventionStay),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );*/
  }

  _dismiss(BuildContext context, WidgetRef ref) {
    _closeOverlay(context, ref);

    context.pop();
  }

  _closeOverlay(BuildContext context, WidgetRef ref) {
    ref.read(overlayProvider.notifier).state = closedQuery;
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
      Key? key})
      : super(key: key);

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
        style: darkBackgroundStyle,
      ),
    );
  }
}
