part of rotation_log;

class RotationLogEvent {
  const RotationLogEvent({
    required this.level,
    required this.message,
    this.timestamp,
    this.error,
    this.stackTrace,
    this.tags = const <String>[],
    this.context = const <String, Object?>{},
  });

  final Level level;
  final String message;
  final DateTime? timestamp;
  final Object? error;
  final StackTrace? stackTrace;
  final List<String> tags;
  final Map<String, Object?> context;

  Map<String, Object?> toJson([
    RotationStructuredLogSchema schema = const RotationStructuredLogSchema(),
  ]) {
    return <String, Object?>{
      schema.levelKey: level.label,
      schema.timestampKey: (timestamp ?? clock.now()).toIso8601String(),
      schema.messageKey: message,
      if (error != null) schema.errorKey: error.toString(),
      if (stackTrace != null) schema.stackTraceKey: stackTrace.toString(),
      if (tags.isNotEmpty) schema.tagsKey: tags,
      if (context.isNotEmpty) schema.contextKey: context,
    };
  }

  RotationLogEvent copyWith({
    Level? level,
    String? message,
    DateTime? timestamp,
    Object? error = _rotationLogUnsetValue,
    Object? stackTrace = _rotationLogUnsetValue,
    List<String>? tags,
    Map<String, Object?>? context,
  }) {
    return RotationLogEvent(
      level: level ?? this.level,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      error: identical(error, _rotationLogUnsetValue) ? this.error : error,
      stackTrace: identical(stackTrace, _rotationLogUnsetValue)
          ? this.stackTrace
          : stackTrace as StackTrace?,
      tags: tags ?? this.tags,
      context: context ?? this.context,
    );
  }
}

const Object _rotationLogUnsetValue = Object();
