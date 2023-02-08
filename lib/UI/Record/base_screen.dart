import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
import 'package:stripes_ui/UI/Record/screen_manager.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class BaseScreen extends ConsumerStatefulWidget {
  final String type;

  final ScreenController screen;

  final QuestionsListener listener;

  const BaseScreen(
      {required this.type,
      required this.screen,
      required this.listener,
      super.key});

  @override
  ConsumerState<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends ConsumerState<BaseScreen> {
  late final Map<Question, Response<Question>> original;

  @override
  void initState() {
    original = widget.listener.questions;
    widget.screen.addListener(() {
      setState(() {});
    });
    widget.listener.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final OverlayQuery query = ref.watch(overlayProvider);
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
            SingleChildScrollView(
              child: Center(
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
                        Card(
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
                                ScreenManager(
                                  controller: widget.screen,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      widget.screen.hasPrev()
                                          ? IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: _prev,
                                              highlightColor:
                                                  Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              splashColor: Colors.transparent,
                                              tooltip: 'Previous',
                                              iconSize: 45,
                                              icon: Icon(
                                                Icons.arrow_back_rounded,
                                                color: widget.listener.pending
                                                        .isEmpty
                                                    ? buttonLightBackground
                                                    : disabled,
                                              ),
                                            )
                                          : const SizedBox(
                                              width: 45,
                                            ),
                                      widget.screen.hasNext()
                                          ? IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: _next,
                                              highlightColor:
                                                  Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              splashColor: Colors.transparent,
                                              tooltip: 'Next',
                                              iconSize: 45,
                                              icon: Icon(
                                                Icons.arrow_forward_rounded,
                                                color: widget.listener.pending
                                                        .isEmpty
                                                    ? buttonLightBackground
                                                    : disabled,
                                              ),
                                            )
                                          : const SizedBox(
                                              width: 45,
                                            ),
                                    ],
                                  ),
                                ),
                              ],
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
    if (widget.listener.pending.isEmpty) {
      widget.screen.next();
    } else {
      showSnack("Must enter value on slider", context);
    }
  }

  _prev() {
    if (widget.listener.pending.isEmpty) {
      widget.screen.previous();
    } else {
      showSnack("Must enter value on slider", context);
    }
  }

  _showErrorPrevention(BuildContext context) {
    if (mapEquals(original, widget.listener.questions)) {
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
