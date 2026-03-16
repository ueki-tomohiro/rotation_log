part of rotation_log;

enum RotationStructuredLogFormat { json, prettyJson }

class RotationStructuredLogSchema {
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

  final String levelKey;
  final String timestampKey;
  final String messageKey;
  final String errorKey;
  final String stackTraceKey;
  final String tagsKey;
  final String contextKey;
}

class RotationLogOptions {
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
  }) : assert(directoryName != ''),
       assert(fileNamePrefix != ''),
       assert(archiveFileName != ''),
       assert(maxArchivedFiles == null || maxArchivedFiles >= 0),
       assert(sessionContextKey != '');

  final String directoryName;
  final String fileNamePrefix;
  final String archiveFileName;
  final int? maxArchivedFiles;
  final Level minimumLevel;
  final RotationStructuredLogFormat structuredLogFormat;
  final List<String> defaultTags;
  final Map<String, Object?> defaultContext;
  final bool includeSessionId;
  final String sessionContextKey;
  final RotationStructuredLogSchema structuredLogSchema;

  String get activeLogFileName => '$fileNamePrefix.log';
}
