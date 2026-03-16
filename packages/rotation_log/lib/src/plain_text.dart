part of rotation_log;

class RotationPlainTextOptions {
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

  final String? prefix;
  final bool includeLevel;
  final bool includeTimestamp;
  final String? timestampPattern;
  final String fieldSeparator;
  final String contextSeparator;
  final String tagSeparator;
  final bool includeSessionId;

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
