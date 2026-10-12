import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

class BlueDyeContextKeys {
  static const startTime = 'startTime';
  static const finishedEating = 'finished_eating';
  static const finishedEatingTime = 'finished_eating_time';
  static const timerStart = 'timer_start';
  static const pauseTime = 'pause_time';
  static const amountConsumed = 'amount_consumed';
  static const logs = 'logs';

  static const values = <String>[
    startTime,
    finishedEating,
    finishedEatingTime,
    timerStart,
    pauseTime,
    amountConsumed,
    logs,
  ];
}

@immutable
class BlueDyeMealState with Equatable {
  final DateTime? startTime;
  final Duration? finishedEating;
  final DateTime? finishedEatingTime;
  final DateTime? timerStart;
  final DateTime? pauseTime;
  final AmountConsumed? amountConsumed;
  final List<BlueDyeBmLog> logs;

  const BlueDyeMealState({
    this.startTime,
    this.finishedEating,
    this.finishedEatingTime,
    this.timerStart,
    this.pauseTime,
    this.amountConsumed,
    this.logs = const [],
  });

  const BlueDyeMealState.empty() : this();

  factory BlueDyeMealState.fromContext(Map<String, dynamic> ctx) {
    return BlueDyeMealState(
      startTime: _parseDateTime(ctx[BlueDyeContextKeys.startTime]),
      finishedEating: _parseDuration(ctx[BlueDyeContextKeys.finishedEating]),
      finishedEatingTime: _parseDateTime(
        ctx[BlueDyeContextKeys.finishedEatingTime],
      ),
      timerStart: _parseDateTime(ctx[BlueDyeContextKeys.timerStart]),
      pauseTime: _parseDateTime(ctx[BlueDyeContextKeys.pauseTime]),
      amountConsumed: _parseAmountConsumed(
        ctx[BlueDyeContextKeys.amountConsumed],
      ),
      logs: _parseLogs(ctx[BlueDyeContextKeys.logs]),
    );
  }

  Map<String, dynamic> toContext() {
    return {
      if (startTime != null)
        BlueDyeContextKeys.startTime: startTime!.toUtc().toIso8601String(),
      if (finishedEating != null)
        BlueDyeContextKeys.finishedEating: finishedEating!.inMilliseconds,
      if (finishedEatingTime != null)
        BlueDyeContextKeys.finishedEatingTime: finishedEatingTime!
            .toUtc()
            .toIso8601String(),
      if (timerStart != null)
        BlueDyeContextKeys.timerStart: timerStart!.toUtc().toIso8601String(),
      if (pauseTime != null)
        BlueDyeContextKeys.pauseTime: pauseTime!.toUtc().toIso8601String(),
      if (amountConsumed != null)
        BlueDyeContextKeys.amountConsumed: amountConsumed.toString(),
      BlueDyeContextKeys.logs: logs.map((l) => l.toJson()).toList(),
    };
  }

  /// Replaces only the Blue Dye portion of a protocol context.
  ///
  /// Removing the old keys first is important because [toContext] omits null
  /// values. A simple map spread would otherwise retain fields that were
  /// intentionally cleared, such as a timer's pause time.
  Map<String, dynamic> replaceInContext(Map<String, dynamic> context) {
    final updatedContext = Map<String, dynamic>.from(context);
    for (final key in BlueDyeContextKeys.values) {
      updatedContext.remove(key);
    }
    updatedContext.addAll(toContext());
    return updatedContext;
  }

  BlueDyeMealState copyWith({
    DateTime? startTime,
    Duration? finishedEating,
    DateTime? finishedEatingTime,
    DateTime? timerStart,
    DateTime? pauseTime,
    AmountConsumed? amountConsumed,
    List<BlueDyeBmLog>? logs,
    bool clearTimerStart = false,
    bool clearPauseTime = false,
  }) {
    return BlueDyeMealState(
      startTime: startTime ?? this.startTime,
      finishedEating: finishedEating ?? this.finishedEating,
      finishedEatingTime: finishedEatingTime ?? this.finishedEatingTime,
      timerStart: clearTimerStart ? null : timerStart ?? this.timerStart,
      pauseTime: clearPauseTime ? null : pauseTime ?? this.pauseTime,
      amountConsumed: amountConsumed ?? this.amountConsumed,
      logs: logs ?? this.logs,
    );
  }

  BlueDyeTestStage get stage {
    if (startTime == null) return BlueDyeTestStage.initial;
    if (finishedEating == null) return BlueDyeTestStage.started;
    if (amountConsumed == null) return BlueDyeTestStage.amountConsumed;
    bool startsBlue = false;
    bool endsNormal = false;
    for (final log in logs) {
      if (log.isBlue) {
        startsBlue = true;
      } else if (startsBlue) {
        endsNormal = true;
      }
    }
    if (endsNormal) return BlueDyeTestStage.logsSubmit;
    return BlueDyeTestStage.logs;
  }

  @override
  List<Object?> get props => [
    startTime,
    finishedEating,
    finishedEatingTime,
    timerStart,
    pauseTime,
    amountConsumed,
    logs,
  ];

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    if (value is int) return dateFromStamp(value).toUtc();
    return null;
  }

  static Duration? _parseDuration(dynamic value) {
    if (value == null) return null;
    if (value is Duration) return value;
    if (value is int) return Duration(milliseconds: value);
    return null;
  }

  static AmountConsumed? _parseAmountConsumed(dynamic value) {
    if (value == null) return null;
    if (value is AmountConsumed) return value;
    return parseAmountConsumed(value.toString());
  }

  static List<BlueDyeBmLog> _parseLogs(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((m) => BlueDyeBmLog.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }
}

@immutable
class BlueDyeBmLog with Equatable {
  final int stamp;
  final bool isBlue;
  final String? description;

  const BlueDyeBmLog({
    required this.stamp,
    required this.isBlue,
    this.description,
  });

  factory BlueDyeBmLog.fromJson(Map<String, dynamic> json) {
    return BlueDyeBmLog(
      stamp: json['stamp'] as int,
      isBlue: json['isBlue'] as bool,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'stamp': stamp,
    'isBlue': isBlue,
    if (description != null) 'description': description,
  };

  @override
  List<Object?> get props => [stamp, isBlue, description];
}
