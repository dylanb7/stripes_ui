# Insight engine

The engine treats question configuration and analysis semantics as two separate
inputs:

```text
questions.yaml  -> question loader -> Question objects
insights.yaml   -> YAML/JSON loader -> InsightAnalysisCatalog
persisted data  -> entry adapter    -> InsightDataset
                                      -> shared InsightBlock graph
                                      -> FindingRule(s) -> Finding(s)
```

`Question` and the question loader do not contain or parse insight metadata.
The catalog parser accepts an already-decoded map and iterates only the sparse
catalog entries. The host app remains responsible for loading YAML, so this
package is not coupled to YAML, localization, or a particular asset layout.

## Recommended standalone catalog

```yaml
schemaVersion: 1

categories:
  category.PAIN:
    role: outcome
    timeSemantics: occurredAt
    cadence: eventDriven
    mode: event

  category.BASELINE:
    mode: baseline
    includeInGenericPatterns: false

  category.LANDMARK:
    role: exposure
    mode: landmark
    includeInGenericPatterns: false

questions:
  q6:
    measurement: ordinal
    aggregation: maximum
    polarity: higherWorse
    validRange: [0, 10]
    missingValues: [-1]
    meaningfulChange: 2

  bowelMovementCount:
    measurement: count
    aggregation: sum
    polarity: higherWorse

  q8:
    measurement: binary
    aggregation: any
    absenceSemantics: unselectedMeansFalse
```

Question IDs are exact stable identifiers. Prompts and localization keys do not
belong in the catalog. An unlisted or generated question is retained as a
descriptive observation but is ineligible for metadata-driven rules. If a
question's meaning or choice ordering changes, give the new question a new ID
rather than silently applying old semantics to historical responses.

`aggregation` describes how multiple valid answers on one calendar day become
one value. `observationCount` explicitly counts recorded answers; use `sum` for
a numeric response whose value is itself a count.

`absenceSemantics` is deliberately conservative. Its default is `unobserved`.
Set `unselectedMeansFalse` only when an unselected check really means that the
symptom was absent on a completed, applicable entry. The metadata declaration
alone is not enough to infer a negative value; the entry must also carry an
authoritative completion snapshot.

## Loading

```dart
final decoded = loadYaml(assetText);
final catalog = InsightAnalysisCatalog.fromMap(decoded);
```

The same parser also accepts decoded JSON. `fromDocument` is available when a
host chooses a shared physical document, but it performs one lookup of the
configured analysis key and never traverses the document's question list.

## Findings and presentation thresholds

Every accepted result is a typed `Finding`:

- `AggregateFinding` is an exact summary such as a distribution or typical
  time. It can still require enough coverage to be useful.
- `ObservationFinding` is an exact comparison or recurring pattern, such as a
  recent symptom rate versus that user's usual rate.
- `AnomalyFinding` identifies a value or cluster that differs from a robust
  personal baseline.
- `InferentialFinding` makes the strongest statistical claim, such as an
  association with uncertainty and multiplicity controls.

The type fixes the maximum strength of the claim; visualization and localized
copy remain downstream concerns. Preparation never hides a small sample. It
returns the exact value and its evidence, and the rule records a structured
rejection when the result is not yet worth presenting. This applies to
aggregates as well as inferential analyses.

## Shared preparation graph

An `InsightBlock<T>` declares a value-keyed request and produces a
`PreparedFeature<T>`. Prepared features carry:

- the typed computed value;
- evidence expressed in an explicit independent unit;
- distinct sets of entries considered and entries that contributed;
- dependency keys for derived features; and
- structured exclusion counts with explicit units.

`InsightBlockContext` memoizes blocks for one engine run. Fresh block instances
with the same semantic key share one result, so a daily symptom series can be
prepared once and reused by many relationship, trend, and anomaly rules. The
context detects dependency cycles and does not cache failed computations.

## Entries, absence, and landmarks

`InsightDataset.fromResponses` is a compatibility adapter for historical
`Response` data. It now retains completed parent entries even when they contain
no leaf response, but their question opportunities remain unknown.

New data should enter through `InsightDataset.fromEntries`. Each `InsightEntry`
can preserve its category, occurrence and recording times, time precision,
session ID, entry kind, observations, and an `InsightCompletionSnapshot`. The
snapshot records the question-set revision and the considered, applicable, and
answered question IDs from the final session graph. It must be captured when
the entry is completed; replaying today's conditional question graph against
old data is not safe.

Landmarks are first-class entries (`InsightEntryKind.landmark`) rather than
synthetic questions. That leaves room for future before/after and cluster rules
to align symptoms with moves, medication or diet changes, doctor changes, and
other environmental shifts without including those annotations in generic
same-day correlations.

## Implemented analysis slices

The numeric relationship rule now consumes shared numeric, daily-series, and
paired-series blocks. Its current effect-threshold-only result is deliberately
an `ObservationFinding`, not an inferential claim. The rate comparison blocks
prepare exact recent/reference binary rates from authoritative entry
opportunities, and `RecentVsUsualPresenceRateRule` emits an
`ObservationFinding` only after configurable denominator and effect-size gates.

Typed downstream presenters now exist for these findings. Before user-facing
numeric relationship analysis is enabled by default, add uncertainty
estimation, stability checks, multiple-comparison control, and protection
against shared time trends. Before automatically discovering binary-rate
subjects, encode an explicit opportunity policy for each question/category
pair; conditionally shown questions must never assume that every category entry
was an opportunity.

## Runtime integration

`historyFindingsProvider` and `dashboardFindingsProvider` run this engine for
the active History and Home periods. They keep the complete loaded response
stream available to the dataset, then apply explicit focus and reference
windows. History filters are applied before analysis. The legacy `Insight`
providers remain available for report compatibility, but these two screens now
render typed engine findings through the downstream presentation registry.

The default rule set contains only exact aggregate summaries:

- recording consistency and longest streak within the selected period;
- busiest local hour, weekday, and calendar date;
- category-entry and recorded-choice distributions; and
- category co-logging on the same calendar days.

The default analysis catalog is empty and host-owned. Override
`insightAnalysisCatalogProvider` and `insightFindingRulesProvider` to add a
versioned catalog and approved observational rules. Presenters already exist
for numeric relationship and recent-versus-usual findings, but those rules are
deliberately not enabled by default under the safeguards described above.
