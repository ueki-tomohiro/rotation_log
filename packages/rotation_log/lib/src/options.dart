part of 'package:rotation_log/rotation_log.dart';

/// Output format used for structured log events.
enum RotationStructuredLogFormat { json, prettyJson }

/// Field names used when serializing [RotationLogEvent] to JSON.
class RotationStructuredLogSchema {
  /// Creates a schema with configurable JSON keys.
  const RotationStructuredLogSchema({
    this.levelKey = 'level',
    this.timestampKey = 'timestamp',
    this.messageKey = 'message',
    this.errorKey = 'error',
    this.stackTraceKey = 'stackTrace',
    this.tagsKey = 'tags',
    this.contextKey = 'context',
  }) : assert(levelKey != ''),
       assert(timestampKey != ''),
       assert(messageKey != ''),
       assert(errorKey != ''),
       assert(stackTraceKey != ''),
       assert(tagsKey != ''),
       assert(contextKey != '');

  /// JSON key used for the log level.
  final String levelKey;

  /// JSON key used for the timestamp.
  final String timestampKey;

  /// JSON key used for the message.
  final String messageKey;

  /// JSON key used for the error payload.
  final String errorKey;

  /// JSON key used for the stack trace.
  final String stackTraceKey;

  /// JSON key used for tags.
  final String tagsKey;

  /// JSON key used for structured context.
  final String contextKey;
}

/// Configuration for file naming, retention, and log rendering.
class RotationLogOptions {
  /// Creates logger options.
  const RotationLogOptions({
    this.directoryName = 'logs',
    this.fileNamePrefix = 'rotation',
    this.archiveFileName = 'log.zip',
    this.maxArchivedFiles,
    this.minimumLevel = Level.trace,
    this.structuredLogFormat = RotationStructuredLogFormat.json,
    this.defaultTags = const <String>[],
    this.defaultContext = const <String, Object?>{},
    this.includeSessionId = false,
    this.sessionContextKey = 'sessionId',
    this.structuredLogSchema = const RotationStructuredLogSchema(),
    this.plainTextOptions = const RotationPlainTextOptions(),
  }) : assert(directoryName != ''),
       assert(fileNamePrefix != ''),
       assert(archiveFileName != ''),
       assert(maxArchivedFiles == null || maxArchivedFiles >= 0),
       assert(sessionContextKey != '');

  /// Directory name created under the app support directory.
  final String directoryName;

  /// Prefix used for log file names.
  final String fileNamePrefix;

  /// File name used for ZIP archives.
  final String archiveFileName;

  /// Maximum number of archived log files to keep.
  final int? maxArchivedFiles;

  /// Lowest accepted log level.
  final Level minimumLevel;

  /// Structured output format.
  final RotationStructuredLogFormat structuredLogFormat;

  /// Tags added to every written log event.
  final List<String> defaultTags;

  /// Structured context added to every written log event.
  final Map<String, Object?> defaultContext;

  /// Whether a session identifier should be attached to structured logs.
  final bool includeSessionId;

  /// Context key used for the session identifier.
  final String sessionContextKey;

  /// Schema used for structured JSON logs.
  final RotationStructuredLogSchema structuredLogSchema;

  /// Plain-text rendering options.
  final RotationPlainTextOptions plainTextOptions;

  /// File name used for the active log file.
  String get activeLogFileName => '$fileNamePrefix.log';
}
