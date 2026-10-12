import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Util/extensions.dart';

String localizedRuleSummary(
  BuildContext context,
  DependsOn dependency,
  Question? Function(String qid) questionProvider,
) {
  String valueFor(Condition condition, Question? question) {
    if (condition case EqualsExact(expected: final expected)) {
      if (expected is int && question is MultipleChoice) {
        return expected >= 0 && expected < question.choices.length
            ? question.choices[expected]
            : expected.toString();
      }
      if (expected is List && question is AllThatApply) {
        return expected
            .map(
              (index) =>
                  index is int && index >= 0 && index < question.choices.length
                  ? question.choices[index]
                  : index.toString(),
            )
            .join(', ');
      }
      return expected.toString();
    }
    if (condition case ContainsIndex(index: final index)) {
      if (question is AllThatApply &&
          index >= 0 &&
          index < question.choices.length) {
        return question.choices[index];
      }
      return index.toString();
    }
    if (condition case ContainsText(text: final text)) return text;
    if (condition case MatchesRegex(pattern: final pattern)) return pattern;
    return '';
  }

  String describe(Condition condition) {
    if (condition is ConditionGroup) {
      final joiner = condition.op == GroupOp.all
          ? ' ${context.translate.conditionAnd} '
          : ' ${context.translate.conditionOr} ';
      final summary = condition.conditions.map(describe).join(joiner);
      return condition.conditions.length > 1 ? '($summary)' : summary;
    }
    final question = condition.questionId == null
        ? null
        : questionProvider(condition.questionId!);
    final prompt = question?.prompt ?? condition.questionId ?? '';
    return switch (condition) {
      ExistsCondition() =>
        '$prompt — ${context.translate.conditionHasResponse}',
      EqualsExact() =>
        '$prompt — ${context.translate.conditionEquals} ${valueFor(condition, question)}',
      ContainsIndex() =>
        '$prompt — ${context.translate.conditionContainsSelection}: ${valueFor(condition, question)}',
      ContainsText() =>
        '$prompt — ${context.translate.conditionContainsText}: ${valueFor(condition, question)}',
      MatchesRegex() =>
        '$prompt — ${context.translate.conditionExactMatch}: ${valueFor(condition, question)}',
      ConditionGroup() => '',
    };
  }

  return dependency.groups
      .map(describe)
      .join(' ${context.translate.conditionAnd} ');
}
