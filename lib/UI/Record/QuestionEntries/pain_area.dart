import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';

import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/base.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_screen.dart';

class PainAreaWidget extends ConsumerStatefulWidget {
  final QuestionsListener questionsListener;

  final MultipleChoice question;

  const PainAreaWidget(
      {required this.questionsListener, required this.question, super.key});

  @override
  ConsumerState<PainAreaWidget> createState() => _PainAreaWidgetState();
}

enum Area {
  none,
  center,
  left,
  right,
  bottom,
  top,
  topleft,
  topright,
  bottomleft,
  bottomright;

  Area fromValue(int value) {
    switch (value) {
      case 0:
        return Area.none;
      case 1:
        return Area.topleft;
      case 2:
        return Area.top;
      case 3:
        return Area.topright;
      case 4:
        return Area.left;
      case 5:
        return Area.center;
      case 6:
        return Area.right;
      case 7:
        return Area.bottomleft;
      case 8:
        return Area.bottom;
      case 9:
        return Area.bottomright;
      default:
        return Area.none;
    }
  }
}

extension ToValue on Area {
  int toIndex() {
    switch (this) {
      case Area.none:
        return 0;
      case Area.topleft:
        return 1;
      case Area.top:
        return 2;
      case Area.topright:
        return 3;
      case Area.left:
        return 4;
      case Area.center:
        return 5;
      case Area.right:
        return 6;
      case Area.bottomleft:
        return 7;
      case Area.bottom:
        return 8;
      case Area.bottomright:
        return 9;
    }
  }

  static Area fromIndex(int value) {
    switch (value) {
      case 0:
        return Area.none;
      case 1:
        return Area.topleft;
      case 2:
        return Area.top;
      case 3:
        return Area.topright;
      case 4:
        return Area.left;
      case 5:
        return Area.center;
      case 6:
        return Area.right;
      case 7:
        return Area.bottomleft;
      case 8:
        return Area.bottom;
      case 9:
        return Area.bottomright;
      default:
        return Area.none;
    }
  }
}

class _PainAreaWidgetState extends ConsumerState<PainAreaWidget> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.questionsListener.addListener(_state);
    });
    super.initState();
  }

  _state() {
    setState(() {});
  }

  Area? response() {
    Response? res = widget.questionsListener.fromQuestion(widget.question);
    if (res == null) return null;
    int index = (res as MultiResponse).index;
    return Area.none.fromValue(index);
  }

  @override
  Widget build(BuildContext context) {
    final Area? selected = response();

    return QuestionWrap(
      question: widget.question,
      listener: widget.questionsListener,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 12.0,
            ),
            IntrinsicHeight(
              child: Stack(children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.onBackground),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    clipBehavior: Clip.hardEdge,
                    child: Image.asset(
                      'packages/stripes_ui/assets/images/abdomin.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: FractionallySizedBox(
                      widthFactor: 0.55,
                      heightFactor: 0.7,
                      child: Column(
                        children: [
                          ...List.generate(
                            3,
                            (colIndex) => Expanded(
                              child: Row(
                                children: [
                                  ...List.generate(
                                    3,
                                    (rowIndex) => Expanded(
                                      child: SelectableTile(
                                          row: rowIndex,
                                          col: colIndex,
                                          index: (colIndex * 3) + rowIndex,
                                          selected: selected,
                                          onSelect: (newValue) {
                                            setResponse(newValue);
                                          }),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      )),
                ),
              ]),
            ),
            const SizedBox(
              height: 12.0,
            ),
            Selection(
                text: "Unable to determine pain location",
                onClick: () {
                  setResponse(Area.none);
                },
                selected: selected == Area.none),
            const SizedBox(
              height: 12.0,
            )
          ],
        ),
      ),
    );
  }

  setResponse(Area newValue) {
    final Area? current = response();
    print(current == newValue);
    if (current == newValue) {
      widget.questionsListener.removeResponse(widget.question);
      widget.questionsListener.addPending(widget.question);
    } else {
      widget.questionsListener.addResponse(MultiResponse(
          question: widget.question,
          stamp: dateToStamp(DateTime.now()),
          index: newValue.toIndex()));
      widget.questionsListener.removePending(widget.question);
    }
  }

  @override
  void dispose() {
    widget.questionsListener.removeListener(_state);
    super.dispose();
  }
}

class SelectableTile extends StatelessWidget {
  final int row, col, index;

  final Area? selected;

  final Function(Area) onSelect;

  const SelectableTile(
      {required this.row,
      required this.col,
      required this.index,
      required this.selected,
      required this.onSelect,
      super.key});

  @override
  Widget build(BuildContext context) {
    final filledBorder =
        BorderSide(color: Theme.of(context).colorScheme.onSurface);
    const blankBorder = BorderSide(color: Colors.transparent);
    final Area value = Area.none.fromValue(index + 1);
    final bool isSelected = value == selected;
    return GestureDetector(
      onTap: () {
        onSelect(value);
      },
      child: Container(
        padding: const EdgeInsets.all(4.0),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border(
              top: col == 0 ? blankBorder : filledBorder,
              left: row == 0 ? blankBorder : filledBorder,
              right: row == 2 ? blankBorder : filledBorder,
              bottom: col == 2 ? blankBorder : filledBorder),
        ),
        child: Stack(children: [
          Positioned.fill(
            child: FractionallySizedBox(
              widthFactor: 0.8,
              heightFactor: 0.8,
              child: AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.5,
                      colors: [
                        Theme.of(context).colorScheme.error,
                        Colors.transparent
                      ],
                      stops: const [0.1, 1.0],
                    ),
                  ),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
