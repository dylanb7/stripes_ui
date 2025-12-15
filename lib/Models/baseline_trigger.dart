import 'package:stripes_backend_helper/stripes_backend_helper.dart';

/// Represents a baseline that needs to be completed.
class BaselineTrigger {
  final String baselineType;
  final String recordPath;
  final String title;
  final String description;

  const BaselineTrigger({
    required this.baselineType,
    required this.recordPath,
    required this.title,
    required this.description,
  });

  /// Returns true if this baseline has been completed.
  bool isComplete(List<Stamp> baselines) {
    return baselines.any((s) {
      // Check direct type match
      if (s.type == baselineType) return true;
      // Check if the ID indicates this baseline type (for versioned baselines)
      final id = s.id;
      if (id != null && id.startsWith(baselineType)) return true;
      return false;
    });
  }
}
