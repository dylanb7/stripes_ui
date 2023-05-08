import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/Record/RecordPaths/question_splitter.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
import 'package:stripes_ui/UI/Record/submit_screen.dart';
import 'package:stripes_ui/UI/Record/symptom_record_data.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

final continueTried = StateProvider.autoDispose((_) => false);

class RecordSplitter extends ConsumerStatefulWidget {
  final String type;

  final SymptomRecordData data;

  late final QuestionsListener questionListener;
  RecordSplitter({super.key, required this.type, required this.data}) {
    questionListener = data.listener ?? QuestionsListener();
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return RecordSplitterState();
  }
}

class RecordSplitterState extends ConsumerState<RecordSplitter> {
  late final Map<Question, Response<Question>> original;

  late final PageController pageController;
  @override
  void initState() {
    original = Map.from(widget.questionListener.questions);
    pageController = PageController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<List<Question>> pages = ref.watch(pageProvider(widget.type));
    final OverlayQuery query = ref.watch(overlayProvider);
    final bool tried = ref.watch(continueTried);
    final Size screenSize = MediaQuery.of(context).size;
    return SafeArea(
        child: Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [backgroundStrong, backgroundLight])),
          child: Stack(children: [
            Center(
              child: SizedBox(
                width: min(SMALL_LAYOUT, screenSize.width),
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
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Recording ${widget.type}\nfor ${_name()}',
                                style: darkBackgroundHeaderStyle,
                              ),
                            ),
                            IconButton(
                                onPressed: () {
                                  _showErrorPrevention(context);
                                },
                                icon: const Icon(
                                  Icons.close,
                                  size: 35,
                                  color: buttonDarkBackground,
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
                        elevation: 8.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 8.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PageView.builder(
                                  itemBuilder: (context, index) {
                                    if (index == pages.length) {
                                      return SubmitScreen(
                                        questionsListener:
                                            widget.questionListener,
                                        type: widget.type,
                                        desc: widget.data.initialDesc,
                                        isEdit: widget.data.isEditing ?? false,
                                        submitTime: widget.data.submitTime,
                                      );
                                    }
                                    return QuestionScreen(
                                        header: "",
                                        questions: pages[index],
                                        questionsListener:
                                            widget.questionListener);
                                  },
                                  itemCount: pages.length + 1,
                                  controller: pageController,
                                ),
                                SmoothPageIndicator(
                                    controller: pageController,
                                    count: pages.length + 1),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        /*widget.screen.hasPrev()
                                        ? IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: _prev,
                                            highlightColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            splashColor: Colors.transparent,
                                            tooltip: 'Previous',
                                            iconSize: 45,
                                            icon: Icon(
                                              Icons.arrow_back_rounded,
                                              color: widget
                                                      .questionListener.pending.isEmpty
                                                  ? buttonLightBackground
                                                  : disabled,
                                            ),
                                          )
                                        : const SizedBox(
                                            width: 45,
                                          ),*/
                                        if (tried)
                                          Text(
                                            'Select slider ${widget.questionListener.pending.length > 1 ? 'values' : 'value'}',
                                            style: errorStyleTitle,
                                          ),
                                        /*pageController.
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
                                              color: widget
                                                      .questionListener.pending.isEmpty
                                                  ? buttonLightBackground
                                                  : disabled,
                                            ),
                                          )
                                        : const SizedBox(
                                            width: 45,
                                          ),*/
                                      ]),
                                ),
                              ]),
                        ),
                      )),
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
      ),
    ));
  }

  _name() {
    SubUser current = ref.read(subHolderProvider).current;
    return SubUser.isEmpty(current) ? 'N/A' : current.name;
  }

  _next() {
    if (widget.questionListener.pending.isEmpty) {
      ref.read(continueTried.notifier).state = false;
      pageController.nextPage(
          duration: const Duration(milliseconds: 250), curve: Curves.bounceIn);
    } else {
      ref.read(continueTried.notifier).state = true;
    }
  }

  _prev() {
    if (widget.questionListener.pending.isEmpty) {
      ref.read(continueTried.notifier).state = false;
      pageController.previousPage(
          duration: const Duration(milliseconds: 250), curve: Curves.bounceIn);
    } else {
      ref.read(continueTried.notifier).state = true;
    }
  }

  _showErrorPrevention(BuildContext context) {
    if (mapEquals(original, widget.questionListener.questions)) {
      ref.read(continueTried.notifier).state = false;
      context.pop();
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
    return Stack(
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
                          'Wait!',
                          style: darkBackgroundHeaderStyle.copyWith(
                              color: buttonDarkBackground),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        const Text(
                          'Are you sure you want to leave this screen?',
                          style: lightBackgroundStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        Text(
                          'You will lose all information you\nentered for this ${type.toLowerCase()} entry',
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
                        text: 'Leave'),
                    BasicButton(
                        onClick: (context) {
                          _closeOverlay(context, ref);
                        },
                        text: 'Stay'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
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

  const BasicButton({required this.onClick, required this.text, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        onClick(context);
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(buttonDarkBackground),
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
