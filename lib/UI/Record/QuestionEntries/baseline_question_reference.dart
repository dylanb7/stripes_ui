import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

/// The saved snapshot and the source answers used by a comparison question.
/// Empty source answers mean no precise source is available; show the baseline
/// as a whole rather than guessing an association between unrelated answers.
@immutable
class BaselineQuestionContext {
  final DetailResponse baseline;
  final Question question;
  final List<Question> resolvedQuestions;
  final List<Response> sourceResponses;

  BaselineQuestionContext({
    required this.baseline,
    required this.question,
    required List<Question> resolvedQuestions,
    required List<Response> sourceResponses,
  }) : resolvedQuestions = List.unmodifiable(resolvedQuestions),
       sourceResponses = List.unmodifiable(sourceResponses);
}

/// Customize the reference and its relationship to the answer controls without
/// resolving questions or fetching a second baseline snapshot.
typedef BaselineReferenceBuilder = Widget Function(
  BuildContext context,
  BaselineQuestionContext reference,
  Widget child,
);

class BaselineQuestionReference extends StatelessWidget {
  final BaselineQuestionContext reference;
  final Widget child;

  const BaselineQuestionReference({
    required this.reference,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final baseline = reference.baseline;
    final localizations = QuestionsLocalizations.of(context);
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(DateTime.fromMillisecondsSinceEpoch(baseline.stamp));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.translate.baselineComparisonReference,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${localizations?.value(baseline.type) ?? baseline.type} · $date',
                ),
                if (reference.sourceResponses.isNotEmpty)
                  DetailDisplay(
                    detail: DetailResponse(
                      detailType: baseline.type,
                      stamp: baseline.stamp,
                      responses: reference.sourceResponses,
                    ),
                  ),
                ExpansionTile(
                  key: ValueKey(
                    'baseline-reference-${reference.question.id}-${baseline.id}',
                  ),
                  tilePadding: EdgeInsets.zero,
                  title: Text(context.translate.baselineViewAllAnswers),
                  children: [DetailDisplay(detail: baseline)],
                ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
