/// A type-erased key suitable for dependency lineage and cache bookkeeping.
abstract interface class InsightBlockKeyBase {
  Type get blockType;
  String get namespace;
  int get schemaVersion;
  Type get valueType;
}

/// Immutable semantic identity for one prepared block request.
///
/// [blockType] prevents unrelated implementations from sharing a cache entry.
/// Increment [schemaVersion] when a block's computation changes meaning while
/// its parameters stay the same. Parameters should be immutable value types;
/// mutable collections are rejected because they can corrupt map keys.
final class InsightBlockKey<T> implements InsightBlockKeyBase {
  @override
  final Type blockType;
  @override
  final String namespace;
  @override
  final int schemaVersion;
  final List<Object?> parameters;
  @override
  final Type valueType;

  InsightBlockKey(
    this.blockType,
    this.namespace, [
    Iterable<Object?> parameters = const [],
    this.schemaVersion = 1,
  ]) : parameters = List.unmodifiable(parameters),
       valueType = T {
    if (namespace.trim().isEmpty) {
      throw ArgumentError.value(namespace, 'namespace', 'must not be empty');
    }
    if (schemaVersion < 1) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        'must be positive',
      );
    }
    for (final parameter in this.parameters) {
      if (parameter is Iterable || parameter is Map) {
        throw ArgumentError.value(
          parameter,
          'parameters',
          'must contain immutable scalar or value-equal objects',
        );
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is InsightBlockKey &&
      blockType == other.blockType &&
      namespace == other.namespace &&
      schemaVersion == other.schemaVersion &&
      valueType == other.valueType &&
      _orderedEquals(parameters, other.parameters);

  @override
  int get hashCode => Object.hash(
    blockType,
    namespace,
    schemaVersion,
    valueType,
    Object.hashAll(parameters),
  );

  @override
  String toString() =>
      '${blockType.toString()}.$namespace.v$schemaVersion'
      '<${valueType.toString()}>(${parameters.join(', ')})';
}

bool _orderedEquals(List<Object?> left, List<Object?> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
