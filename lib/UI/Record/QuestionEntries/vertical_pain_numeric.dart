import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/base.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_screen.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class VerticalPainFaces extends StatefulWidget {
  final QuestionsListener questionsListener;

  final Numeric question;

  const VerticalPainFaces(
      {required this.question, required this.questionsListener, super.key});

  @override
  State<StatefulWidget> createState() {
    return _VerticalPainFacesState();
  }
}

class _VerticalPainFacesState extends State<VerticalPainFaces> {
  @override
  Widget build(BuildContext context) {
    final num? selected = response();

    return QuestionWrap(
      question: widget.question,
      listener: widget.questionsListener,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(children: [
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(11, (index) {
                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if (index == selected?.toInt()) {
                            setState(() {
                              widget.questionsListener
                                  .removeResponse(widget.question);
                              widget.questionsListener
                                  .addPending(widget.question);
                            });
                            return;
                          }
                          setState(() {
                            widget.questionsListener
                                .removePending(widget.question);
                            _saveValue(index);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                                onChanged: (value) {
                                  if (value == null || index == selected) {
                                    setState(() {
                                      widget.questionsListener
                                          .removeResponse(widget.question);
                                      widget.questionsListener
                                          .addPending(widget.question);
                                    });
                                    return;
                                  }
                                  setState(() {
                                    widget.questionsListener
                                        .removePending(widget.question);
                                    _saveValue(value);
                                  });
                                },
                              ),
                              const SizedBox(
                                width: 6.0,
                              ),
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
                const SizedBox(
                  width: 8.0,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: List.generate(5, (index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(
                            AppLocalizations.of(context)!.painLevelZero,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      if (index == 4) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(
                            AppLocalizations.of(context)!.painLevelFive,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                const SizedBox(
                  width: 8.0,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
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
              onClick: () {
                setState(() {
                  if (response() == -1) {
                    widget.questionsListener.removeResponse(widget.question);
                    widget.questionsListener.addPending(widget.question);
                  } else {
                    widget.questionsListener.removePending(widget.question);
                    _saveValue(-1);
                  }
                });
              },
              selected: response() == -1)
        ]),
      ),
    );
  }

  num? response() {
    Response? res = widget.questionsListener.fromQuestion(widget.question);
    if (res == null) return null;
    return (res as NumericResponse).response;
  }

  _saveValue(int newValue) {
    widget.questionsListener.addResponse(NumericResponse(
        question: widget.question,
        stamp: dateToStamp(DateTime.now()),
        response: newValue));
  }
}
