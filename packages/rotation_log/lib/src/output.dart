part of 'package:rotation_log/rotation_log.dart';

/// Options used when bridging the `logger` package into [RotationLogger].
class RotationLogOutputOptions {
  /// Creates output bridge options.
  const RotationLogOutputOptions({
    this.structured = false,
    this.includeRenderedLines = true,
    this.renderedLinesContextKey = 'renderedLines',
    this.tags = const <String>[],
    this.context = const <String, Object?>{},
  }) : assert(renderedLinesContextKey != '');

  /// Whether `logger` events should be forwarded as structured events.
  final bool structured;

  /// Whether rendered logger lines should be copied into structured context.
  final bool includeRenderedLines;

  /// Context key used when [includeRenderedLines] is enabled.
  final String renderedLinesContextKey;

  /// Tags attached to forwarded events.
  final List<String> tags;

  /// Context attached to forwarded events.
  final Map<String, Object?> context;
}

/// `logger` package output that forwards events into [RotationLogger].
class RotationLogOutput extends LogOutput {
  /// Logger receiving converted output events.
  final RotationLogger rotationLogger;

  /// Bridge behavior for forwarded events.
  final RotationLogOutputOptions options;

  /// Creates a `logger` output bridge.
  RotationLogOutput(
    this.rotationLogger, {
    this.options = const RotationLogOutputOptions(),
  });

  @override
  void output(OutputEvent event) {
    if (!options.structured) {
      rotationLogger.log(event.level, event.lines.join('\n'));
      return;
    }

    final context = <String, Object?>{
      ...options.context,
      if (options.includeRenderedLines && event.lines.isNotEmpty)
        options.renderedLinesContextKey: event.lines,
    };

    rotationLogger.logEvent(
      RotationLogEvent(
        level: event.level,
        message: event.origin.message.toString(),
        timestamp: event.origin.time,
        error: event.origin.error,
        stackTrace: event.origin.stackTrace,
        tags: options.tags,
        context: context,
      ),
    );
  }
}
