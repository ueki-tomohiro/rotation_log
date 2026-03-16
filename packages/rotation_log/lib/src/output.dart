part of rotation_log;

class RotationLogOutputOptions {
  const RotationLogOutputOptions({
    this.structured = false,
    this.includeRenderedLines = true,
    this.renderedLinesContextKey = 'renderedLines',
    this.tags = const <String>[],
    this.context = const <String, Object?>{},
  }) : assert(renderedLinesContextKey != '');

  final bool structured;
  final bool includeRenderedLines;
  final String renderedLinesContextKey;
  final List<String> tags;
  final Map<String, Object?> context;
}

class RotationLogOutput extends LogOutput {
  final RotationLogger rotationLogger;
  final RotationLogOutputOptions options;

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
