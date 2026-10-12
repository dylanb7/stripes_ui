import 'dart:collection';

import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Insights/Engine/insight_analysis_catalog.dart';

class InsightTimeWindow {
  final DateTime start;
  final DateTime endExclusive;

  InsightTimeWindow({required this.start, required this.endExclusive}) {
    if (!start.isBefore(endExclusive)) {
      throw ArgumentError.value(
        endExclusive,
        'endExclusive',
        'must be after start',
      );
    }
  }

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(endExclusive);

  int get calendarDays {
    final startDay = DateTime.utc(start.year, start.month, start.day);
    final endDay = DateTime.utc(
      endExclusive.year,
      endExclusive.month,
      endExclusive.day,
    );
    final wholeDays = endDay.difference(startDay).inDays;
    final endsAtMidnight =
        endExclusive.hour == 0 &&
        endExclusive.minute == 0 &&
        endExclusive.second == 0 &&
        endExclusive.millisecond == 0 &&
        endExclusive.microsecond == 0;
    return endsAtMidnight ? wholeDays : wholeDays + 1;
  }
}

enum InsightDatasetScope { focus, reference, all }

sealed class InsightObservationValue {
  const InsightObservationValue();
}

final class NumericInsightValue extends InsightObservationValue {
  final double value;
  const NumericInsightValue(this.value);

  @override
  String toString() => value.toString();
}

final class PresenceInsightValue extends InsightObservationValue {
  final bool present;
  const PresenceInsightValue(this.present);

  @override
  String toString() => present.toString();
}

final class ChoiceInsightValue extends InsightObservationValue {
  final List<String> choices;
  final bool allowsMultiple;

  ChoiceInsightValue({
    required Iterable<String> choices,
    required this.allowsMultiple,
  }) : choices = List.unmodifiable(choices);

  @override
  String toString() => choices.join('|');
}

final class TextInsightValue extends InsightObservationValue {
  final String value;
  const TextInsightValue(this.value);

  @override
  String toString() => value;
}

class InsightObservation {
  final String entryId;
  final String questionId;
  final String promptKey;
  final String categoryId;
  final DateTime occurredAt;
  final InsightObservationValue value;
  final ResolvedInsightSemantics? semantics;
  final InsightObservationProvenance provenance;

  InsightObservation({
    required this.entryId,
    required this.questionId,
    required this.promptKey,
    required this.categoryId,
    required this.occurredAt,
    required this.value,
    this.semantics,
    this.provenance = InsightObservationProvenance.explicit,
  }) {
    if (provenance == InsightObservationProvenance.inferredUnselectedCheck &&
        (value is! PresenceInsightValue ||
            (value as PresenceInsightValue).present)) {
      throw ArgumentError.value(
        value,
        'value',
        'An inferred unselected check must be PresenceInsightValue(false).',
      );
    }
  }

  DateTime get localDay {
    final local = occurredAt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

enum InsightObservationProvenance {
  explicit,
  inferredUnselectedCheck,
  landmarkField,
}

enum InsightEntryKind {
  event,
  form,
  baseline,
  scheduledReview,
  landmark,
  test,
  legacy,
}

enum InsightTimePrecision { exact, day, week, unknown }

/// Timing supplied by an application adapter without coupling the engine to UI
/// record models. A known date with an uncertain clock time uses [day].
class InsightResponseTiming {
  final DateTime occurredAt;
  final InsightTimePrecision precision;

  const InsightResponseTiming({
    required this.occurredAt,
    required this.precision,
  });
}

class InsightCompletionSnapshot {
  static const int supportedSchemaVersion = 1;

  final int schemaVersion;
  final String? questionSetRevision;
  final Set<String> consideredQuestionIds;
  final Set<String> applicableQuestionIds;
  final Set<String> answeredQuestionIds;

  InsightCompletionSnapshot({
    this.schemaVersion = 1,
    this.questionSetRevision,
    required Iterable<String> consideredQuestionIds,
    required Iterable<String> applicableQuestionIds,
    required Iterable<String> answeredQuestionIds,
  }) : consideredQuestionIds = Set.unmodifiable(consideredQuestionIds),
       applicableQuestionIds = Set.unmodifiable(applicableQuestionIds),
       answeredQuestionIds = Set.unmodifiable(answeredQuestionIds) {
    if (schemaVersion != supportedSchemaVersion) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        'Unsupported completion snapshot schema.',
      );
    }
    if (!this.consideredQuestionIds.containsAll(this.applicableQuestionIds)) {
      throw ArgumentError(
        'Applicable questions must be a subset of considered questions.',
      );
    }
    if (!this.applicableQuestionIds.containsAll(this.answeredQuestionIds)) {
      throw ArgumentError(
        'Answered questions must be a subset of applicable questions.',
      );
    }
  }
}

/// One completed parent entry, retained even when it has no leaf responses.
class InsightEntry {
  final String entryId;
  final String categoryId;
  final DateTime occurredAt;
  final DateTime? recordedAt;
  final InsightEntryKind kind;
  final InsightTimePrecision timePrecision;
  final String? sessionId;
  final List<InsightObservation> observations;
  final InsightCompletionSnapshot? completion;

  InsightEntry({
    required this.entryId,
    required this.categoryId,
    required this.occurredAt,
    this.recordedAt,
    this.kind = InsightEntryKind.event,
    this.timePrecision = InsightTimePrecision.unknown,
    this.sessionId,
    Iterable<InsightObservation> observations = const [],
    this.completion,
  }) : observations = List.unmodifiable(observations) {
    for (final observation in this.observations) {
      if (observation.entryId != entryId ||
          observation.categoryId != categoryId ||
          observation.occurredAt != occurredAt) {
        throw ArgumentError(
          'Every observation must belong to its parent InsightEntry.',
        );
      }
      final completion = this.completion;
      if (completion != null &&
          observation.provenance !=
              InsightObservationProvenance.landmarkField) {
        if (!completion.applicableQuestionIds.contains(
          observation.questionId,
        )) {
          throw ArgumentError(
            'An observation cannot belong to an inapplicable question.',
          );
        }
        final isInferredAbsence =
            observation.provenance ==
            InsightObservationProvenance.inferredUnselectedCheck;
        if (isInferredAbsence &&
            completion.answeredQuestionIds.contains(observation.questionId)) {
          throw ArgumentError(
            'An inferred absence cannot also be marked answered.',
          );
        }
        if (!isInferredAbsence &&
            !completion.answeredQuestionIds.contains(observation.questionId)) {
          throw ArgumentError(
            'An explicit observation must be marked answered.',
          );
        }
      }
    }
  }

  Set<String> get answeredQuestionIds =>
      completion?.answeredQuestionIds ??
      Set.unmodifiable(
        observations.map((observation) => observation.questionId),
      );

  Set<String>? get applicableQuestionIds => completion?.applicableQuestionIds;

  bool get hasKnownOpportunities => completion != null;

  bool isQuestionApplicable(String questionId) =>
      applicableQuestionIds?.contains(questionId) ?? false;

  DateTime get localDay {
    final local = occurredAt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

enum InsightDataIssueCode {
  missingValue,
  outOfRange,
  invalidChoiceIndex,
  unsupportedResponse,
}

class InsightDataIssue {
  final InsightDataIssueCode code;
  final String entryId;
  final String questionId;
  final String categoryId;
  final DateTime occurredAt;
  final Object? value;

  const InsightDataIssue({
    required this.code,
    required this.entryId,
    required this.questionId,
    required this.categoryId,
    required this.occurredAt,
    this.value,
  });
}

class InsightNumericObservation {
  final InsightObservation observation;
  final double value;

  const InsightNumericObservation({
    required this.observation,
    required this.value,
  });
}

class InsightDailyNumericValue {
  final DateTime day;
  final double value;
  final int observationCount;
  final Set<String> sourceEntryIds;

  InsightDailyNumericValue({
    required this.day,
    required this.value,
    required this.observationCount,
    Iterable<String> sourceEntryIds = const [],
  }) : sourceEntryIds = Set.unmodifiable(sourceEntryIds);
}

class InsightDailyNumericPair {
  final DateTime day;
  final InsightDailyNumericValue left;
  final InsightDailyNumericValue right;

  const InsightDailyNumericPair({
    required this.day,
    required this.left,
    required this.right,
  });
}

class InsightDataset {
  final InsightAnalysisCatalog catalog;
  final InsightTimeWindow focusWindow;
  final InsightTimeWindow? referenceWindow;
  final List<InsightEntry> _entries;
  final List<InsightObservation> _observations;
  final List<InsightDataIssue> issues;

  InsightDataset._({
    required this.catalog,
    required this.focusWindow,
    required this.referenceWindow,
    required List<InsightEntry> entries,
    required List<InsightObservation> observations,
    required List<InsightDataIssue> issues,
  }) : _entries = List.unmodifiable(entries),
       _observations = List.unmodifiable(observations),
       issues = List.unmodifiable(issues);

  factory InsightDataset.fromResponses(
    Iterable<Response> responses, {
    required InsightTimeWindow focusWindow,
    InsightTimeWindow? referenceWindow,
    InsightAnalysisCatalog catalog = const InsightAnalysisCatalog.empty(),
    InsightResponseTiming Function(Response response)? timingResolver,
  }) {
    final entryDrafts = <_InsightEntryDraft>[];
    final observations = <InsightObservation>[];
    final issues = <InsightDataIssue>[];

    for (final response in responses) {
      _collectResponse(
        response,
        inheritedEntry: null,
        timingResolver: timingResolver,
        entryDrafts: entryDrafts,
        catalog: catalog,
        observations: observations,
        issues: issues,
      );
    }

    observations.sort(_compareObservations);
    issues.sort(_compareIssues);
    final deduplicatedObservations = _deduplicateObservations(observations);
    final entries = _buildEntries(entryDrafts, deduplicatedObservations)
      ..sort(_compareEntries);

    return InsightDataset._(
      catalog: catalog,
      focusWindow: focusWindow,
      referenceWindow: referenceWindow,
      entries: entries,
      observations: deduplicatedObservations,
      issues: _deduplicateIssues(issues),
    );
  }

  factory InsightDataset.fromEntries(
    Iterable<InsightEntry> entries, {
    required InsightTimeWindow focusWindow,
    InsightTimeWindow? referenceWindow,
    InsightAnalysisCatalog catalog = const InsightAnalysisCatalog.empty(),
    Iterable<InsightDataIssue> issues = const [],
  }) {
    final entryList = entries.toList()..sort(_compareEntries);
    final identities = <String>{};
    for (final entry in entryList) {
      if (!identities.add(entry.entryId)) {
        throw ArgumentError('Duplicate InsightEntry ${entry.entryId}.');
      }
    }
    final observations = _deduplicateObservations(
      entryList.expand((entry) => entry.observations).toList()
        ..sort(_compareObservations),
    );
    final observationsByEntry = <String, List<InsightObservation>>{};
    for (final observation in observations) {
      observationsByEntry
          .putIfAbsent(observation.entryId, () => [])
          .add(observation);
    }
    final canonicalEntries = [
      for (final entry in entryList)
        InsightEntry(
          entryId: entry.entryId,
          categoryId: entry.categoryId,
          occurredAt: entry.occurredAt,
          recordedAt: entry.recordedAt,
          kind: entry.kind,
          timePrecision: entry.timePrecision,
          sessionId: entry.sessionId,
          observations: observationsByEntry[entry.entryId] ?? const [],
          completion: entry.completion,
        ),
    ];
    final issueList = issues.toList()..sort(_compareIssues);
    return InsightDataset._(
      catalog: catalog,
      focusWindow: focusWindow,
      referenceWindow: referenceWindow,
      entries: canonicalEntries,
      observations: observations,
      issues: _deduplicateIssues(issueList),
    );
  }

  List<InsightEntry> entries({
    InsightDatasetScope scope = InsightDatasetScope.focus,
  }) {
    final window = _windowFor(scope);
    if (scope == InsightDatasetScope.reference && window == null) {
      return const [];
    }
    if (window == null) return _entries;
    return List.unmodifiable(
      _entries.where((entry) => window.contains(entry.occurredAt)),
    );
  }

  List<InsightEntry> entriesForCategory(
    String categoryId, {
    InsightDatasetScope scope = InsightDatasetScope.focus,
  }) => List.unmodifiable(
    entries(scope: scope).where((entry) => entry.categoryId == categoryId),
  );

  List<InsightObservation> observations({
    InsightDatasetScope scope = InsightDatasetScope.focus,
  }) {
    final window = _windowFor(scope);
    if (scope == InsightDatasetScope.reference && window == null) {
      return const [];
    }
    if (window == null) return _observations;
    return List.unmodifiable(
      _observations.where(
        (observation) => window.contains(observation.occurredAt),
      ),
    );
  }

  List<InsightObservation> observationsFor(
    String questionId, {
    InsightDatasetScope scope = InsightDatasetScope.focus,
  }) => List.unmodifiable(
    observations(scope: scope)
        .where((observation) => observation.questionId == questionId),
  );

  List<InsightNumericObservation> numericObservationsFor(
    String questionId, {
    InsightDatasetScope scope = InsightDatasetScope.focus,
    bool eligibleForGenericAnalysis = false,
  }) {
    final result = <InsightNumericObservation>[];
    for (final observation in observationsFor(questionId, scope: scope)) {
      final semantics =
          catalog.resolve(
            questionId: observation.questionId,
            categoryId: observation.categoryId,
          ) ??
          observation.semantics;
      if (eligibleForGenericAnalysis &&
          !(semantics?.eligibleForGenericPatterns ?? false)) {
        continue;
      }
      if (observation.value case NumericInsightValue(:final value)) {
        result.add(
          InsightNumericObservation(observation: observation, value: value),
        );
      }
    }
    return List.unmodifiable(result);
  }

  List<InsightDataIssue> issuesFor(
    String questionId, {
    InsightDatasetScope scope = InsightDatasetScope.focus,
  }) {
    final window = _windowFor(scope);
    if (scope == InsightDatasetScope.reference && window == null) {
      return const [];
    }
    return List.unmodifiable(
      issues.where(
        (issue) =>
            issue.questionId == questionId &&
            (window == null || window.contains(issue.occurredAt)),
      ),
    );
  }

  List<InsightDailyNumericValue> dailyNumericSeries(
    String questionId, {
    required InsightAggregation aggregation,
    InsightDatasetScope scope = InsightDatasetScope.focus,
    bool eligibleForGenericAnalysis = false,
  }) {
    final grouped = SplayTreeMap<DateTime, List<InsightNumericObservation>>();
    for (final observation in numericObservationsFor(
      questionId,
      scope: scope,
      eligibleForGenericAnalysis: eligibleForGenericAnalysis,
    )) {
      grouped
          .putIfAbsent(observation.observation.localDay, () => [])
          .add(observation);
    }

    return List.unmodifiable([
      for (final entry in grouped.entries)
        InsightDailyNumericValue(
          day: entry.key,
          value: aggregateNumericObservations(entry.value, aggregation),
          observationCount: entry.value.length,
          sourceEntryIds: entry.value.map(
            (observation) => observation.observation.entryId,
          ),
        ),
    ]);
  }

  List<InsightDailyNumericPair> pairedDailyNumeric(
    String leftQuestionId,
    String rightQuestionId, {
    required InsightAggregation leftAggregation,
    required InsightAggregation rightAggregation,
    InsightDatasetScope scope = InsightDatasetScope.focus,
    bool eligibleForGenericAnalysis = false,
  }) {
    final left = {
      for (final value in dailyNumericSeries(
        leftQuestionId,
        aggregation: leftAggregation,
        scope: scope,
        eligibleForGenericAnalysis: eligibleForGenericAnalysis,
      ))
        value.day: value,
    };
    final right = {
      for (final value in dailyNumericSeries(
        rightQuestionId,
        aggregation: rightAggregation,
        scope: scope,
        eligibleForGenericAnalysis: eligibleForGenericAnalysis,
      ))
        value.day: value,
    };

    final sharedDays = left.keys.where(right.containsKey).toList()..sort();
    return List.unmodifiable([
      for (final day in sharedDays)
        InsightDailyNumericPair(day: day, left: left[day]!, right: right[day]!),
    ]);
  }

  InsightTimeWindow? _windowFor(InsightDatasetScope scope) => switch (scope) {
    InsightDatasetScope.focus => focusWindow,
    InsightDatasetScope.reference => referenceWindow,
    InsightDatasetScope.all => null,
  };

  static void _collectResponse(
    Response response, {
    required _InsightEntryContext? inheritedEntry,
    InsightResponseTiming Function(Response response)? timingResolver,
    required List<_InsightEntryDraft> entryDrafts,
    required InsightAnalysisCatalog catalog,
    required List<InsightObservation> observations,
    required List<InsightDataIssue> issues,
  }) {
    switch (response) {
      case DetailResponse(:final responses):
        final entry = _entryContextFor(
          response,
          timingResolver?.call(response),
        );
        entryDrafts.add(_InsightEntryDraft(context: entry));
        for (final child in responses) {
          _collectResponse(
            child,
            inheritedEntry: entry,
            timingResolver: timingResolver,
            entryDrafts: entryDrafts,
            catalog: catalog,
            observations: observations,
            issues: issues,
          );
        }
      case ResponseWrap(:final responses):
        for (final child in responses) {
          _collectResponse(
            child,
            inheritedEntry: inheritedEntry,
            timingResolver: timingResolver,
            entryDrafts: entryDrafts,
            catalog: catalog,
            observations: observations,
            issues: issues,
          );
        }
      case SingleResponseWrap(:final response):
        _collectResponse(
          response,
          inheritedEntry: inheritedEntry,
          timingResolver: timingResolver,
          entryDrafts: entryDrafts,
          catalog: catalog,
          observations: observations,
          issues: issues,
        );
      default:
        final entry =
            inheritedEntry ??
            _entryContextFor(response, timingResolver?.call(response));
        if (inheritedEntry == null) {
          entryDrafts.add(_InsightEntryDraft(context: entry));
        }
        _collectLeaf(
          response,
          entryId: entry.entryId,
          occurredAt: entry.occurredAt,
          categoryId: entry.categoryId,
          catalog: catalog,
          observations: observations,
          issues: issues,
        );
    }
  }

  static void _collectLeaf(
    Response response, {
    required String entryId,
    required DateTime occurredAt,
    required String categoryId,
    required InsightAnalysisCatalog catalog,
    required List<InsightObservation> observations,
    required List<InsightDataIssue> issues,
  }) {
    final question = response.question;
    final semantics = catalog.resolve(
      questionId: question.id,
      categoryId: categoryId,
    );

    InsightObservationValue? value;
    switch (response) {
      case NumericResponse(:final response):
        if (semantics?.question.isMissing(response) ?? false) {
          issues.add(
            InsightDataIssue(
              code: InsightDataIssueCode.missingValue,
              entryId: entryId,
              questionId: question.id,
              categoryId: categoryId,
              occurredAt: occurredAt,
              value: response,
            ),
          );
          return;
        }
        if (!_isNumericValueInRange(response, question, semantics)) {
          issues.add(
            InsightDataIssue(
              code: InsightDataIssueCode.outOfRange,
              entryId: entryId,
              questionId: question.id,
              categoryId: categoryId,
              occurredAt: occurredAt,
              value: response,
            ),
          );
          return;
        }
        value = NumericInsightValue(response.toDouble());
      case Selected():
        value = const PresenceInsightValue(true);
      case MultiResponse(:final index, :final question):
        if (index < 0 || index >= question.choices.length) {
          issues.add(
            InsightDataIssue(
              code: InsightDataIssueCode.invalidChoiceIndex,
              entryId: entryId,
              questionId: question.id,
              categoryId: categoryId,
              occurredAt: occurredAt,
              value: index,
            ),
          );
          return;
        }
        value = ChoiceInsightValue(
          choices: [question.choices[index]],
          allowsMultiple: false,
        );
      case AllResponse(:final responses, :final question):
        final choices = <String>[];
        for (final index in responses) {
          if (index < 0 || index >= question.choices.length) {
            issues.add(
              InsightDataIssue(
                code: InsightDataIssueCode.invalidChoiceIndex,
                entryId: entryId,
                questionId: question.id,
                categoryId: categoryId,
                occurredAt: occurredAt,
                value: index,
              ),
            );
            return;
          }
          choices.add(question.choices[index]);
        }
        value = ChoiceInsightValue(choices: choices, allowsMultiple: true);
      case OpenResponse(:final response):
        value = TextInsightValue(response);
      default:
        issues.add(
          InsightDataIssue(
            code: InsightDataIssueCode.unsupportedResponse,
            entryId: entryId,
            questionId: question.id,
            categoryId: categoryId,
            occurredAt: occurredAt,
          ),
        );
        return;
    }

    observations.add(
      InsightObservation(
        entryId: entryId,
        questionId: question.id,
        promptKey: question.prompt,
        categoryId: categoryId,
        occurredAt: occurredAt,
        value: value,
        semantics: semantics,
      ),
    );
  }

  static bool _isNumericValueInRange(
    num value,
    Question question,
    ResolvedInsightSemantics? semantics,
  ) {
    if (!value.isFinite) return false;
    if (!(semantics?.question.isInValidRange(value) ?? true)) return false;
    if (question case Numeric(:final min, :final max)) {
      if (min != null && value < min) return false;
      if (max != null && value > max) return false;
    }
    return true;
  }

  static double aggregateNumericObservations(
    List<InsightNumericObservation> observations,
    InsightAggregation aggregation,
  ) {
    if (observations.isEmpty) {
      throw StateError('Cannot aggregate an empty numeric observation list.');
    }
    final values = observations
        .map((observation) => observation.value)
        .toList();
    return switch (aggregation) {
      InsightAggregation.latest =>
        (observations.toList()..sort((a, b) {
              var result = a.observation.occurredAt.compareTo(
                b.observation.occurredAt,
              );
              if (result != 0) return result;
              result = a.observation.entryId.compareTo(b.observation.entryId);
              if (result != 0) return result;
              return a.value.compareTo(b.value);
            }))
            .last
            .value,
      InsightAggregation.mean =>
        values.reduce((left, right) => left + right) / values.length,
      InsightAggregation.maximum => values.reduce(
        (left, right) => left > right ? left : right,
      ),
      InsightAggregation.minimum => values.reduce(
        (left, right) => left < right ? left : right,
      ),
      InsightAggregation.sum => values.reduce((left, right) => left + right),
      InsightAggregation.observationCount => values.length.toDouble(),
      InsightAggregation.any => values.any((value) => value != 0) ? 1.0 : 0.0,
      InsightAggregation.distribution ||
      InsightAggregation.perEvent => throw ArgumentError.value(
        aggregation,
        'aggregation',
        'does not produce one numeric value per day',
      ),
    };
  }
}

class _InsightEntryContext {
  final String entryId;
  final DateTime occurredAt;
  final String categoryId;
  final InsightTimePrecision timePrecision;

  const _InsightEntryContext({
    required this.entryId,
    required this.occurredAt,
    required this.categoryId,
    required this.timePrecision,
  });
}

class _InsightEntryDraft {
  final _InsightEntryContext context;

  const _InsightEntryDraft({required this.context});
}

_InsightEntryContext _entryContextFor(
  Response response,
  InsightResponseTiming? timing,
) => _InsightEntryContext(
  entryId:
      response.id ??
      '${response.stamp}:${response.type}:${response.group ?? ''}',
  occurredAt: timing?.occurredAt ?? dateFromStamp(response.stamp),
  categoryId: response.type,
  timePrecision: timing?.precision ?? InsightTimePrecision.exact,
);

List<InsightObservation> _deduplicateObservations(
  Iterable<InsightObservation> observations,
) {
  final seen = <String>{};
  return [
    for (final observation in observations)
      if (seen.add(_observationIdentity(observation))) observation,
  ];
}

List<InsightEntry> _buildEntries(
  Iterable<_InsightEntryDraft> drafts,
  Iterable<InsightObservation> observations,
) {
  final observationsByEntry = <String, List<InsightObservation>>{};
  for (final observation in observations) {
    observationsByEntry
        .putIfAbsent(observation.entryId, () => [])
        .add(observation);
  }

  final mergedDrafts = <String, _InsightEntryDraft>{};
  for (final draft in drafts) {
    final existing = mergedDrafts[draft.context.entryId];
    if (existing != null &&
        (existing.context.categoryId != draft.context.categoryId ||
            existing.context.occurredAt != draft.context.occurredAt)) {
      throw FormatException(
        'Conflicting legacy entry identity ${draft.context.entryId}.',
      );
    }
    mergedDrafts.putIfAbsent(draft.context.entryId, () => draft);
  }

  return [
    for (final entry in mergedDrafts.entries)
      InsightEntry(
        entryId: entry.value.context.entryId,
        categoryId: entry.value.context.categoryId,
        occurredAt: entry.value.context.occurredAt,
        kind: InsightEntryKind.legacy,
        timePrecision: entry.value.context.timePrecision,
        observations:
            observationsByEntry[entry.value.context.entryId] ?? const [],
      ),
  ];
}

String _observationIdentity(InsightObservation observation) => [
  observation.entryId,
  observation.occurredAt.microsecondsSinceEpoch,
  observation.categoryId,
  observation.questionId,
  observation.provenance.name,
  _valueIdentity(observation.value),
].join(r'\u{1f}');

String _valueIdentity(InsightObservationValue value) => switch (value) {
  NumericInsightValue(:final value) => 'numeric:$value',
  PresenceInsightValue(:final present) => 'presence:$present',
  ChoiceInsightValue(:final choices, :final allowsMultiple) =>
    'choice:$allowsMultiple:${(choices.toList()..sort()).join(',')}',
  TextInsightValue(:final value) => 'text:$value',
};

List<InsightDataIssue> _deduplicateIssues(Iterable<InsightDataIssue> issues) {
  final seen = <String>{};
  return [
    for (final issue in issues)
      if (seen.add(
        '${issue.entryId}:${issue.categoryId}:${issue.questionId}:${issue.occurredAt.microsecondsSinceEpoch}:${issue.code.name}:${issue.value}',
      ))
        issue,
  ];
}

int _compareObservations(InsightObservation left, InsightObservation right) {
  var result = left.occurredAt.compareTo(right.occurredAt);
  if (result != 0) return result;
  result = left.entryId.compareTo(right.entryId);
  if (result != 0) return result;
  result = left.questionId.compareTo(right.questionId);
  if (result != 0) return result;
  result = left.provenance.index.compareTo(right.provenance.index);
  if (result != 0) return result;
  return _valueIdentity(left.value).compareTo(_valueIdentity(right.value));
}

int _compareIssues(InsightDataIssue left, InsightDataIssue right) {
  var result = left.occurredAt.compareTo(right.occurredAt);
  if (result != 0) return result;
  result = left.entryId.compareTo(right.entryId);
  if (result != 0) return result;
  result = left.categoryId.compareTo(right.categoryId);
  if (result != 0) return result;
  result = left.questionId.compareTo(right.questionId);
  if (result != 0) return result;
  result = left.code.index.compareTo(right.code.index);
  if (result != 0) return result;
  return '${left.value}'.compareTo('${right.value}');
}

int _compareEntries(InsightEntry left, InsightEntry right) {
  var result = left.occurredAt.compareTo(right.occurredAt);
  if (result != 0) return result;
  result = left.entryId.compareTo(right.entryId);
  if (result != 0) return result;
  return left.categoryId.compareTo(right.categoryId);
}
