import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class BlueDyeEntry extends ConsumerStatefulWidget {
  final QuestionsListener listener;

  final MultipleChoice question;

  const BlueDyeEntry(
      {required this.listener, required this.question, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _BlueDyeEntryState();
  }
}

class _BlueDyeEntryState extends ConsumerState<BlueDyeEntry> {
  late int? index;

  List<bool> toggleState = [false, false];

  @override
  void initState() {
    Response? res = widget.listener.questions[widget.question];
    if (res != null) {
      final int index = (res as MultiResponse).index;
      toggleState[index] = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        widget.listener.addPending(widget.question);
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color surface =
        Theme.of(context).colorScheme.surface.withOpacity(0.12);
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final bool hasError = widget.listener.pending.contains(widget.question) &&
        widget.listener.tried;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Container(
        decoration: BoxDecoration(
            border: hasError
                ? Border.all(
                    color: Theme.of(context).colorScheme.error, width: 2.0)
                : null,
            borderRadius: const BorderRadius.all(Radius.circular(12.0))),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.submitBlueQuestion,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 8.0,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450.0),
              child: Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ChoiceChip(
                      label:
                          Text(AppLocalizations.of(context)!.blueQuestionYes),
                      selected: toggleState[0],
                      selectedColor: primary,
                      backgroundColor: surface,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      labelStyle: TextStyle(
                          color: toggleState[0] ? onPrimary : onSurface,
                          fontWeight: FontWeight.bold),
                      checkmarkColor: toggleState[0] ? onPrimary : onSurface,
                      onSelected: (value) {
                        if (toggleState[0]) return;
                        setState(() {
                          toggleState = [true, false];
                          widget.listener.addResponse(MultiResponse(
                              question: widget.question,
                              stamp: DateTime.now().millisecondsSinceEpoch,
                              index: 0));
                          widget.listener.removePending(widget.question);
                        });
                      },
                    ),
                    ChoiceChip(
                      label: Text(AppLocalizations.of(context)!.blueQuestionNo),
                      selected: toggleState[1],
                      selectedColor: primary,
                      backgroundColor: surface,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      labelStyle: TextStyle(
                          color: toggleState[1] ? onPrimary : onSurface,
                          fontWeight: FontWeight.bold),
                      checkmarkColor: toggleState[1] ? onPrimary : onSurface,
                      onSelected: (value) {
                        if (toggleState[1]) return;
                        setState(() {
                          toggleState = [false, true];
                          widget.listener.addResponse(MultiResponse(
                              question: widget.question,
                              stamp: DateTime.now().millisecondsSinceEpoch,
                              index: 1));
                          widget.listener.removePending(widget.question);
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(
                height: 8.0,
              ),
              Text(
                AppLocalizations.of(context)!.submitBlueQuestionError,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              )
            ],
          ],
        ),
      ),
    );
  }
}
