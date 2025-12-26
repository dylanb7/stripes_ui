import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/base.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_entry_scope.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class PainAreaWidget extends ConsumerStatefulWidget {
  final QuestionsListener questionsListener;

  final AllThatApply question;

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

  static Area fromValue(int value) {
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
  // We can remove the listener in initState because we use QuestionEntryScope
  // which rebuilds/notifies. Or we can use the scope controller.

  List<Area>? _getResponse([QuestionEntryController? controller]) {
    if (controller != null) {
      final res = controller.response;
      if (res is AllResponse) {
        return res.responses.map((value) => Area.fromValue(value)).toList();
      }
      return null;
    }
    final Response? res =
        widget.questionsListener.fromQuestion(widget.question);
    if (res == null) return null;
    List<int> index = (res as AllResponse).responses;
    return index.map((value) => Area.fromValue(value)).toList();
  }

  void _setResponse(QuestionEntryController controller, Area newValue) {
    final List<Area>? current = _getResponse(controller);

    if (newValue == Area.none) {
      if (current?.contains(newValue) ?? false) {
        controller.removeResponse();
      } else {
        controller.addResponse(
          AllResponse(
            question: widget.question,
            stamp: controller.stamp,
            responses: [newValue.toIndex()],
          ),
        );
      }
      return;
    }

    if (current == null) {
      controller.addResponse(AllResponse(
          question: widget.question,
          stamp: controller.stamp,
          responses: [newValue.toIndex()]));
    } else if (current.contains(newValue)) {
      if (current.length == 1) {
        controller.removeResponse();
      } else {
        current.remove(newValue);
        controller.addResponse(
          AllResponse(
            question: widget.question,
            stamp: controller.stamp,
            responses: current.map((val) => val.toIndex()).toList(),
          ),
        );
      }
    } else {
      current.add(newValue);
      if (current.contains(Area.none)) current.remove(Area.none);
      controller.addResponse(
        AllResponse(
          question: widget.question,
          stamp: controller.stamp,
          responses: current.map((val) => val.toIndex()).toList(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return QuestionEntryScope(
      question: widget.question,
      listener: widget.questionsListener,
      child: Builder(builder: (context) {
        final controller = QuestionEntryScope.of(context);
        final List<Area>? selected = _getResponse(controller);

        return QuestionEntryCard(
          styled: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: AppPadding.medium),
                IntrinsicHeight(
                  child: Stack(children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface),
                        borderRadius: BorderRadius.circular(AppRounding.medium),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRounding.medium),
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
                                      ...List.generate(3, (rowIndex) {
                                        final int index =
                                            (colIndex * 3) + rowIndex;
                                        final Area area =
                                            Area.fromValue(index + 1);
                                        return Expanded(
                                          child: SelectableTile(
                                              row: rowIndex,
                                              col: colIndex,
                                              index: index,
                                              selected:
                                                  (selected?.contains(area) ??
                                                          false)
                                                      ? area
                                                      : null,
                                              onSelect: (newValue) {
                                                _setResponse(
                                                    controller, newValue);
                                              }),
                                        );
                                      })
                                    ],
                                  ),
                                ),
                              )
                            ],
                          )),
                    ),
                  ]),
                ),
                const SizedBox(height: AppPadding.medium),
                Selection(
                    text: "Unable to determine pain location",
                    onClick: () {
                      _setResponse(controller, Area.none);
                    },
                    selected: selected?.contains(Area.none) ?? false),
                const SizedBox(height: AppPadding.medium)
              ],
            ),
          ),
        );
      }),
    );
  }
}

class SelectableTile extends StatelessWidget {
  final int row, col, index;

  final Area? selected;

  final void Function(Area) onSelect;

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
    final Area value = Area.fromValue(index + 1);
    final bool isSelected = value == selected;
    return GestureDetector(
      onTap: () {
        onSelect(value);
      },
      child: Container(
        padding: const EdgeInsets.all(AppPadding.tiny),
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
