part of 'package:rotation_log/rotation_log.dart';

/// Formatting options for plain-text log lines.
class RotationPlainTextOptions {
  /// Creates plain-text formatting options.
  const RotationPlainTextOptions({
    this.prefix,
    this.includeLevel = true,
    this.includeTimestamp = true,
    this.timestampPattern,
    this.fieldSeparator = ' ',
    this.contextSeparator = ' ',
    this.tagSeparator = ',',
    this.includeSessionId = false,
  }) : assert(fieldSeparator != ''),
       assert(contextSeparator != ''),
       assert(tagSeparator != '');

  /// Optional prefix inserted before each rendered line.
  final String? prefix;

  /// Whether the log level should be rendered.
  final bool includeLevel;

  /// Whether the timestamp should be rendered.
  final bool includeTimestamp;

  /// Optional `intl` pattern used to render timestamps.
  final String? timestampPattern;

  /// Separator used between top-level fields.
  final String fieldSeparator;

  /// Separator used between structured context entries.
  final String contextSeparator;

  /// Separator used between tags.
  final String tagSeparator;

  /// Whether the session identifier should be included in plain-text context.
  final bool includeSessionId;

  /// Renders a plain-text log line from the provided values.
  String format({
    required Level level,
    required String message,
    required DateTime timestamp,
    required List<String> tags,
    required Map<String, Object?> context,
    String? sessionId,
  }) {
    final segments = <String>[
      if (prefix != null && prefix!.isNotEmpty) prefix!,
      if (includeLevel) '[${level.label}]',
      if (includeTimestamp) '[${_formatTimestamp(timestamp)}]',
      if (tags.isNotEmpty) '[${tags.join(tagSeparator)}]',
      message,
    ];

    final mergedContext = <String, Object?>{
      ...context,
      if (includeSessionId && sessionId != null) 'sessionId': sessionId,
    };
    if (mergedContext.isNotEmpty) {
      segments.add(_renderContext(mergedContext));
    }

    return segments.join(fieldSeparator);
  }

  String _formatTimestamp(DateTime timestamp) {
    if (timestampPattern == null || timestampPattern!.isEmpty) {
      return timestamp.toIso8601String();
    }

    return DateFormat(timestampPattern!).format(timestamp);
  }

  String _renderContext(Map<String, Object?> context) {
    final keys = context.keys.toList(growable: false)..sort();
    return keys
        .map((key) => '$key=${_stringifyContextValue(context[key])}')
        .join(contextSeparator);
  }

  String _stringifyContextValue(Object? value) {
    if (value == null) {
      return 'null';
    }

    if (value is num || value is bool) {
      return value.toString();
    }

    final text = value.toString();
    if (text.contains(' ') || text.contains('"')) {
      return jsonEncode(text);
    }
    return text;
  }
}
