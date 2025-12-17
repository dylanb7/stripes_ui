import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/base.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_entry_scope.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Widgets/mouse_hover.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class VerticalPainFaces extends ConsumerStatefulWidget {
  final QuestionsListener questionsListener;
  final Numeric question;

  const VerticalPainFaces({
    required this.question,
    required this.questionsListener,
    super.key,
  });

  @override
  ConsumerState<VerticalPainFaces> createState() => _VerticalPainFacesState();
}

class _VerticalPainFacesState extends ConsumerState<VerticalPainFaces> {
  num? _getResponse() {
    final Response? res =
        widget.questionsListener.fromQuestion(widget.question);
    if (res == null) return null;
    return (res as NumericResponse).response;
  }

  void _saveValue(int newValue) {
    widget.questionsListener.addResponse(NumericResponse(
      question: widget.question,
      stamp: dateToStamp(DateTime.now()),
      response: newValue,
    ));
  }

  void _onTap(int index) {
    if (index == _getResponse()?.toInt()) {
      widget.questionsListener.removeResponse(widget.question);
      widget.questionsListener.addPending(widget.question);
    } else {
      widget.questionsListener.removePending(widget.question);
      _saveValue(index);
    }
    setState(() {});
  }

  void _setUnableToDetermine() {
    if (_getResponse() == -1) {
      widget.questionsListener.removeResponse(widget.question);
      widget.questionsListener.addPending(widget.question);
    } else {
      widget.questionsListener.removePending(widget.question);
      _saveValue(-1);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final num? selected = _getResponse();

    return QuestionEntryScope(
      question: widget.question,
      listener: widget.questionsListener,
      child: QuestionEntryCard(
        styled: false,
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.tiny),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppPadding.tiny),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(11, (index) {
                          return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _onTap(index),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppPadding.small),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Radio<int>.adaptive(
                                    value: index,
                                    groupValue: (selected ?? -1).toInt(),
                                    toggleable: true,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.padded,
                                    onChanged: (value) => _onTap(index),
                                  ),
                                  const SizedBox(width: AppPadding.tiny),
                                  Text(
                                    "$index",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            ),
                          ).showCursorOnHover;
                        }),
                      ),
                    ),
                    const SizedBox(width: AppPadding.small),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppPadding.tiny),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: List.generate(5, (index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppPadding.small),
                              child: Text(
                                context.translate.painLevelZero,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          if (index == 4) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppPadding.small),
                              child: Text(
                                context.translate.painLevelFive,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppPadding.small),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface),
                                      right: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface),
                                      bottom: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: AppPadding.small),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppPadding.tiny),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(5, (value) {
                          final Widget base = Container(
                            alignment: Alignment.center,
                            width: 45,
                            height: 45,
                            child: Image.asset(
                              "packages/stripes_ui/assets/images/pain_faces_$value.png",
                              width: 45,
                              height: 45,
                              fit: BoxFit.cover,
                            ),
                          );
                          if (value == 0 || value == 4) return base;
                          return Expanded(child: base);
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              Selection(
                text: "Unable to determine pain level",
                onClick: _setUnableToDetermine,
                selected: selected == -1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
