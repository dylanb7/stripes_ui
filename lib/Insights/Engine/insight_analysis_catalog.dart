/// Declarative semantics used by the insight engine.
///
/// This catalog intentionally has no dependency on `Question`. Applications
/// may keep it in a separate asset or under a top-level `analysis` key in a
/// larger document. In either case, only the catalog entries are parsed.
library;

enum InsightMeasurement {
  continuous,
  ordinal,
  ordinalNonMonotonic,
  count,
  binary,
  nominal,
  text,
}

enum InsightAggregation {
  latest,
  mean,
  maximum,
  minimum,
  sum,
  observationCount,
  any,
  distribution,
  perEvent,
}

enum InsightPolarity { higherBetter, higherWorse, neutral, nonMonotonic }

enum InsightRole { outcome, exposure, context, event, coverage }

enum InsightTimeSemantics { occurredAt, recordedAt, period }

enum InsightCadence { eventDriven, daily, weekly, scheduled }

enum InsightAnalysisMode { event, baseline, scheduledReview, landmark }

enum InsightAbsenceSemantics { unobserved, unselectedMeansFalse }

class QuestionAnalysisSpec {
  final String questionId;
  final bool enabled;
  final InsightMeasurement measurement;
  final InsightAggregation aggregation;
  final InsightPolarity? polarity;
  final InsightRole? role;
  final InsightTimeSemantics? timeSemantics;
  final InsightCadence? cadence;
  final InsightAbsenceSemantics absenceSemantics;
  final num? validMin;
  final num? validMax;
  final Set<num> missingValues;
  final num? meaningfulChange;

  QuestionAnalysisSpec({
    required this.questionId,
    this.enabled = true,
    required this.measurement,
    required this.aggregation,
    this.polarity,
    this.role,
    this.timeSemantics,
    this.cadence,
    this.absenceSemantics = InsightAbsenceSemantics.unobserved,
    this.validMin,
    this.validMax,
    Set<num> missingValues = const {},
    this.meaningfulChange,
  }) : missingValues = Set.unmodifiable(missingValues);

  bool get supportsNumericAnalysis => switch (measurement) {
    InsightMeasurement.continuous ||
    InsightMeasurement.ordinal ||
    InsightMeasurement.count => true,
    InsightMeasurement.ordinalNonMonotonic ||
    InsightMeasurement.binary ||
    InsightMeasurement.nominal ||
    InsightMeasurement.text => false,
  };

  bool isMissing(num value) => missingValues.contains(value);

  bool isInValidRange(num value) {
    if (validMin != null && value < validMin!) return false;
    if (validMax != null && value > validMax!) return false;
    return true;
  }
}

class CategoryAnalysisSpec {
  final String categoryId;
  final bool enabled;
  final InsightRole? role;
  final InsightTimeSemantics? timeSemantics;
  final InsightCadence? cadence;
  final InsightAnalysisMode mode;
  final bool includeInGenericPatterns;

  const CategoryAnalysisSpec({
    required this.categoryId,
    this.enabled = true,
    this.role,
    this.timeSemantics,
    this.cadence,
    this.mode = InsightAnalysisMode.event,
    this.includeInGenericPatterns = true,
  });
}

class ResolvedInsightSemantics {
  final QuestionAnalysisSpec question;
  final CategoryAnalysisSpec? category;

  const ResolvedInsightSemantics({required this.question, this.category});

  bool get enabled => question.enabled && (category?.enabled ?? true);

  bool get eligibleForGenericPatterns =>
      enabled &&
      (category?.includeInGenericPatterns ?? true) &&
      (category?.mode ?? InsightAnalysisMode.event) ==
          InsightAnalysisMode.event;

  InsightRole? get role => question.role ?? category?.role;

  InsightTimeSemantics? get timeSemantics =>
      question.timeSemantics ?? category?.timeSemantics;

  InsightCadence? get cadence => question.cadence ?? category?.cadence;
}

class InsightAnalysisCatalog {
  static const int supportedSchemaVersion = 1;

  final int schemaVersion;
  final Map<String, QuestionAnalysisSpec> questions;
  final Map<String, CategoryAnalysisSpec> categories;

  const InsightAnalysisCatalog.empty()
    : schemaVersion = supportedSchemaVersion,
      questions = const {},
      categories = const {};

  InsightAnalysisCatalog({
    this.schemaVersion = supportedSchemaVersion,
    Map<String, QuestionAnalysisSpec> questions = const {},
    Map<String, CategoryAnalysisSpec> categories = const {},
  }) : questions = Map.unmodifiable(questions),
       categories = Map.unmodifiable(categories);

  QuestionAnalysisSpec? question(String questionId) => questions[questionId];

  CategoryAnalysisSpec? category(String categoryId) => categories[categoryId];

  ResolvedInsightSemantics? resolve({
    required String questionId,
    required String categoryId,
  }) {
    final questionSpec = questions[questionId];
    if (questionSpec == null) return null;
    return ResolvedInsightSemantics(
      question: questionSpec,
      category: categories[categoryId],
    );
  }

  /// Reads only [analysisKey] from a larger decoded document.
  ///
  /// The document's `questions` collection is never traversed. This permits a
  /// question set and its analysis catalog to share one physical asset without
  /// coupling their parsers or runtime models.
  factory InsightAnalysisCatalog.fromDocument(
    Map<Object?, Object?> document, {
    String analysisKey = 'analysis',
    bool strict = true,
  }) {
    final analysis = document[analysisKey];
    if (analysis == null) return const InsightAnalysisCatalog.empty();
    return InsightAnalysisCatalog.fromMap(analysis, strict: strict);
  }

  /// Parses a standalone decoded analysis catalog.
  ///
  /// `YamlMap` implements [Map], so host applications can call this method
  /// after `loadYaml` without adding a YAML dependency to `stripes_ui`.
  factory InsightAnalysisCatalog.fromMap(Object? source, {bool strict = true}) {
    final root = _stringMap(source, r'$');
    if (strict) {
      _checkKnownKeys(root, const {
        'schemaVersion',
        'questions',
        'categories',
      }, r'$');
    }

    final schemaVersion = _schemaVersion(root['schemaVersion']);
    if (schemaVersion != supportedSchemaVersion) {
      throw FormatException(
        'Unsupported analysis schema version $schemaVersion; '
        'expected $supportedSchemaVersion.',
      );
    }

    final questionNodes = root['questions'] == null
        ? const <String, Object?>{}
        : _stringMap(root['questions'], r'$.questions');
    final categoryNodes = root['categories'] == null
        ? const <String, Object?>{}
        : _stringMap(root['categories'], r'$.categories');

    final questions = <String, QuestionAnalysisSpec>{};
    for (final entry in questionNodes.entries) {
      questions[entry.key] = _parseQuestion(
        entry.key,
        entry.value,
        strict: strict,
      );
    }

    final categories = <String, CategoryAnalysisSpec>{};
    for (final entry in categoryNodes.entries) {
      categories[entry.key] = _parseCategory(
        entry.key,
        entry.value,
        strict: strict,
      );
    }

    return InsightAnalysisCatalog(
      schemaVersion: schemaVersion,
      questions: questions,
      categories: categories,
    );
  }

  static QuestionAnalysisSpec _parseQuestion(
    String id,
    Object? source, {
    required bool strict,
  }) {
    final path = r'$.questions.' + id;
    final node = _stringMap(source, path);
    if (strict) {
      _checkKnownKeys(node, const {
        'enabled',
        'measurement',
        'aggregation',
        'polarity',
        'role',
        'timeSemantics',
        'cadence',
        'absenceSemantics',
        'validRange',
        'missingValues',
        'meaningfulChange',
      }, path);
    }

    final measurement = _requiredEnum(
      node,
      'measurement',
      path,
      _measurementValues,
    );
    final aggregation = _requiredEnum(
      node,
      'aggregation',
      path,
      _aggregationValues,
    );
    final validRange = _optionalRange(node['validRange'], '$path.validRange');
    final missingValues = _numberSet(
      node['missingValues'],
      '$path.missingValues',
    );
    final meaningfulChange = _optionalNumber(
      node['meaningfulChange'],
      '$path.meaningfulChange',
    );
    if (meaningfulChange != null && meaningfulChange < 0) {
      throw FormatException('$path.meaningfulChange must not be negative.');
    }

    return QuestionAnalysisSpec(
      questionId: id,
      enabled: _optionalBool(node['enabled'], '$path.enabled') ?? true,
      measurement: measurement,
      aggregation: aggregation,
      polarity: _optionalEnum(
        node['polarity'],
        '$path.polarity',
        _polarityValues,
      ),
      role: _optionalEnum(node['role'], '$path.role', _roleValues),
      timeSemantics: _optionalEnum(
        node['timeSemantics'],
        '$path.timeSemantics',
        _timeSemanticsValues,
      ),
      cadence: _optionalEnum(node['cadence'], '$path.cadence', _cadenceValues),
      absenceSemantics:
          _optionalEnum(
            node['absenceSemantics'],
            '$path.absenceSemantics',
            _absenceSemanticsValues,
          ) ??
          InsightAbsenceSemantics.unobserved,
      validMin: validRange?.$1,
      validMax: validRange?.$2,
      missingValues: missingValues,
      meaningfulChange: meaningfulChange,
    );
  }

  static CategoryAnalysisSpec _parseCategory(
    String id,
    Object? source, {
    required bool strict,
  }) {
    final path = r'$.categories.' + id;
    final node = _stringMap(source, path);
    if (strict) {
      _checkKnownKeys(node, const {
        'enabled',
        'role',
        'timeSemantics',
        'cadence',
        'mode',
        'includeInGenericPatterns',
      }, path);
    }

    return CategoryAnalysisSpec(
      categoryId: id,
      enabled: _optionalBool(node['enabled'], '$path.enabled') ?? true,
      role: _optionalEnum(node['role'], '$path.role', _roleValues),
      timeSemantics: _optionalEnum(
        node['timeSemantics'],
        '$path.timeSemantics',
        _timeSemanticsValues,
      ),
      cadence: _optionalEnum(node['cadence'], '$path.cadence', _cadenceValues),
      mode:
          _optionalEnum(node['mode'], '$path.mode', _modeValues) ??
          InsightAnalysisMode.event,
      includeInGenericPatterns:
          _optionalBool(
            node['includeInGenericPatterns'],
            '$path.includeInGenericPatterns',
          ) ??
          true,
    );
  }
}

const _measurementValues = <String, InsightMeasurement>{
  'continuous': InsightMeasurement.continuous,
  'ordinal': InsightMeasurement.ordinal,
  'ordinalnonmonotonic': InsightMeasurement.ordinalNonMonotonic,
  'count': InsightMeasurement.count,
  'binary': InsightMeasurement.binary,
  'nominal': InsightMeasurement.nominal,
  'text': InsightMeasurement.text,
};

const _aggregationValues = <String, InsightAggregation>{
  'latest': InsightAggregation.latest,
  'mean': InsightAggregation.mean,
  'maximum': InsightAggregation.maximum,
  'max': InsightAggregation.maximum,
  'minimum': InsightAggregation.minimum,
  'min': InsightAggregation.minimum,
  'sum': InsightAggregation.sum,
  'observationcount': InsightAggregation.observationCount,
  'any': InsightAggregation.any,
  'distribution': InsightAggregation.distribution,
  'perevent': InsightAggregation.perEvent,
};

const _polarityValues = <String, InsightPolarity>{
  'higherbetter': InsightPolarity.higherBetter,
  'higherworse': InsightPolarity.higherWorse,
  'neutral': InsightPolarity.neutral,
  'nonmonotonic': InsightPolarity.nonMonotonic,
};

const _roleValues = <String, InsightRole>{
  'outcome': InsightRole.outcome,
  'exposure': InsightRole.exposure,
  'context': InsightRole.context,
  'event': InsightRole.event,
  'coverage': InsightRole.coverage,
};

const _timeSemanticsValues = <String, InsightTimeSemantics>{
  'occurredat': InsightTimeSemantics.occurredAt,
  'recordedat': InsightTimeSemantics.recordedAt,
  'period': InsightTimeSemantics.period,
};

const _cadenceValues = <String, InsightCadence>{
  'eventdriven': InsightCadence.eventDriven,
  'daily': InsightCadence.daily,
  'weekly': InsightCadence.weekly,
  'scheduled': InsightCadence.scheduled,
};

const _modeValues = <String, InsightAnalysisMode>{
  'event': InsightAnalysisMode.event,
  'baseline': InsightAnalysisMode.baseline,
  'scheduledreview': InsightAnalysisMode.scheduledReview,
  'landmark': InsightAnalysisMode.landmark,
};

const _absenceSemanticsValues = <String, InsightAbsenceSemantics>{
  'unobserved': InsightAbsenceSemantics.unobserved,
  'unselectedmeansfalse': InsightAbsenceSemantics.unselectedMeansFalse,
};

int _schemaVersion(Object? value) {
  if (value == null) return InsightAnalysisCatalog.supportedSchemaVersion;
  if (value is num && value == value.roundToDouble()) return value.toInt();
  if (value is String) {
    final major = int.tryParse(value.split('.').first);
    if (major != null) return major;
  }
  throw const FormatException(r'$.schemaVersion must be an integer or semver.');
}

Map<String, Object?> _stringMap(Object? source, String path) {
  if (source is! Map) throw FormatException('$path must be a map.');
  final result = <String, Object?>{};
  for (final entry in source.entries) {
    if (entry.key is! String) {
      throw FormatException('$path contains a non-string key.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

void _checkKnownKeys(
  Map<String, Object?> source,
  Set<String> known,
  String path,
) {
  for (final key in source.keys) {
    if (!known.contains(key)) {
      throw FormatException('Unknown analysis field $path.$key.');
    }
  }
}

String _normalizedEnumName(Object? source, String path) {
  if (source is! String || source.trim().isEmpty) {
    throw FormatException('$path must be a non-empty string.');
  }
  return source.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
}

T _requiredEnum<T extends Enum>(
  Map<String, Object?> source,
  String key,
  String path,
  Map<String, T> values,
) {
  if (!source.containsKey(key)) {
    throw FormatException('$path.$key is required.');
  }
  return _optionalEnum(source[key], '$path.$key', values)!;
}

T? _optionalEnum<T extends Enum>(
  Object? source,
  String path,
  Map<String, T> values,
) {
  if (source == null) return null;
  final normalized = _normalizedEnumName(source, path);
  final result = values[normalized];
  if (result == null) {
    throw FormatException('$path has unsupported value "$source".');
  }
  return result;
}

bool? _optionalBool(Object? source, String path) {
  if (source == null) return null;
  if (source is bool) return source;
  throw FormatException('$path must be a boolean.');
}

num? _optionalNumber(Object? source, String path) {
  if (source == null) return null;
  if (source is num && source.isFinite) return source;
  throw FormatException('$path must be a finite number.');
}

(num, num)? _optionalRange(Object? source, String path) {
  if (source == null) return null;
  if (source is! List || source.length != 2) {
    throw FormatException('$path must contain exactly [minimum, maximum].');
  }
  final minimum = _optionalNumber(source[0], '$path[0]')!;
  final maximum = _optionalNumber(source[1], '$path[1]')!;
  if (minimum > maximum) {
    throw FormatException('$path minimum must not exceed its maximum.');
  }
  return (minimum, maximum);
}

Set<num> _numberSet(Object? source, String path) {
  if (source == null) return const {};
  if (source is! List) throw FormatException('$path must be a list.');
  return Set.unmodifiable([
    for (var i = 0; i < source.length; i++)
      _optionalNumber(source[i], '$path[$i]')!,
  ]);
}
