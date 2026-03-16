part of 'package:rotation_log/rotation_log.dart';

/// A structured log event that can be encoded as JSON.
class RotationLogEvent {
  /// Creates a structured log event.
  const RotationLogEvent({
    required this.level,
    required this.message,
    this.timestamp,
    this.error,
    this.stackTrace,
    this.tags = const <String>[],
    this.context = const <String, Object?>{},
  });

  /// Severity of this event.
  final Level level;

  /// Human-readable log message.
  final String message;

  /// Event timestamp. When omitted, the current time is used during encoding.
  final DateTime? timestamp;

  /// Optional error payload attached to the event.
  final Object? error;

  /// Optional stack trace attached to the event.
  final StackTrace? stackTrace;

  /// Tags that classify the event.
  final List<String> tags;

  /// Arbitrary structured metadata for the event.
  final Map<String, Object?> context;

  /// Converts the event into a JSON-ready map using [schema] field names.
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

  /// Returns a copy with the provided fields replaced.
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
