/// Pure data and analysis primitives for metadata-driven insights.
///
/// This library is intentionally separate from the legacy insight UI. Host
/// applications supply a decoded analysis catalog and recorded responses; the
/// engine has no dependency on question-set parsing or localization.
library;

export 'Engine/Blocks/numeric_blocks.dart';
export 'Engine/Blocks/presence_rate_blocks.dart';
export 'Engine/Rules/aggregate_summary_rules.dart';
export 'Engine/Rules/numeric_relationship_rule.dart';
export 'Engine/Rules/recent_vs_usual_presence_rate_rule.dart';
export 'Engine/finding.dart';
export 'Engine/finding_engine.dart';
export 'Engine/insight_analysis_catalog.dart';
export 'Engine/insight_block.dart';
export 'Engine/insight_block_key.dart';
export 'Engine/insight_dataset.dart';
export 'Engine/insight_engine.dart';
export 'Engine/prepared_feature.dart';
