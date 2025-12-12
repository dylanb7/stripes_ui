import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/baseline_id.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';

const String _baselineVersionPrefKey = 'baseline_version_preference';

/// Provider for managing baseline version preferences.
///
/// Stores the user's preferred baseline version per baseline type in SharedPreferences.
/// Falls back to the latest version if no preference is set.
final baselineVersionPreferenceProvider =
    AsyncNotifierProvider<BaselineVersionNotifier, Map<String, int>>(
  BaselineVersionNotifier.new,
);

class BaselineVersionNotifier extends AsyncNotifier<Map<String, int>> {
  @override
  Future<Map<String, int>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_baselineVersionPrefKey);
    if (stored == null || stored.isEmpty) {
      return {};
    }

    // Parse stored preferences: "type1:version1,type2:version2"
    final Map<String, int> result = {};
    for (final pair in stored.split(',')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final version = int.tryParse(parts[1]);
        if (version != null) {
          result[parts[0]] = version;
        }
      }
    }
    return result;
  }

  /// Sets the preferred baseline version for a specific baseline type.
  Future<void> setVersion(String baselineType, int version) async {
    final current = state.valueOrNull ?? {};
    final updated = {...current, baselineType: version};

    final prefs = await SharedPreferences.getInstance();
    final encoded = updated.entries.map((e) => '${e.key}:${e.value}').join(',');
    await prefs.setString(_baselineVersionPrefKey, encoded);

    state = AsyncData(updated);
  }

  /// Clears the preference for a specific baseline type (reverts to latest).
  Future<void> clearVersion(String baselineType) async {
    final current = state.valueOrNull ?? {};
    final updated = {...current}..remove(baselineType);

    final prefs = await SharedPreferences.getInstance();
    final encoded = updated.entries.map((e) => '${e.key}:${e.value}').join(',');
    await prefs.setString(_baselineVersionPrefKey, encoded);

    state = AsyncData(updated);
  }

  /// Gets the preferred version for a baseline type, or null if using latest.
  int? getVersion(String baselineType) {
    return state.valueOrNull?[baselineType];
  }
}

/// Provider that returns available baseline versions for a given type.
///
/// Returns a list of (version, stamp) tuples sorted by version descending.
final baselineVersionsProvider =
    FutureProvider.family<List<({int version, int stamp})>, String>(
        (ref, baselineType) async {
  final baselines = await ref.watch(baselinesStreamProvider.future);

  final List<({int version, int stamp})> versions = [];

  for (final stamp in baselines) {
    if (stamp is DetailResponse && stamp.type == baselineType) {
      // Try to parse version from the response ID if it's a versioned baseline
      final parsed = stamp.id != null ? BaselineId.parse(stamp.id!) : null;
      if (parsed != null) {
        versions.add((version: parsed.version, stamp: stamp.stamp));
      } else {
        // Legacy baseline without version - treat as version 1
        // Check if we already added a version 1
        if (!versions.any((v) => v.version == 1)) {
          versions.add((version: 1, stamp: stamp.stamp));
        }
      }
    }
  }

  // Sort by version descending (latest first)
  versions.sort((a, b) => b.version.compareTo(a.version));
  return versions;
});

/// Provider that returns the effective baseline version to use for a type.
///
/// Uses the user's preference if set, otherwise returns the latest version.
final effectiveBaselineVersionProvider =
    FutureProvider.family<int, String>((ref, baselineType) async {
  final preference = await ref.watch(baselineVersionPreferenceProvider.future);
  final preferredVersion = preference[baselineType];

  if (preferredVersion != null) {
    return preferredVersion;
  }

  // No preference set, use latest version
  final versions =
      await ref.watch(baselineVersionsProvider(baselineType).future);
  if (versions.isEmpty) {
    return 1; // Default to version 1 if no baselines exist
  }
  return versions.first.version;
});

final baselineResponseProvider = FutureProvider.family<DetailResponse?,
    ({String baselineType, int? version})>((ref, params) async {
  final baselines = await ref.watch(baselinesStreamProvider.future);

  final effectiveVersion = params.version ??
      await ref
          .watch(effectiveBaselineVersionProvider(params.baselineType).future);

  for (final stamp in baselines) {
    if (stamp is DetailResponse && stamp.type == params.baselineType) {
      final parsed = stamp.id != null ? BaselineId.parse(stamp.id!) : null;
      if (parsed != null && parsed.version == effectiveVersion) {
        return stamp;
      } else if (parsed == null && effectiveVersion == 1) {
        // Legacy baseline without version ID
        return stamp;
      }
    }
  }

  final matching = baselines
      .whereType<DetailResponse>()
      .where((s) => s.type == params.baselineType)
      .toList();

  if (matching.isEmpty) return null;

  matching.sort((a, b) => b.stamp.compareTo(a.stamp));
  return matching.first;
});
