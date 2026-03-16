part of rotation_log;

enum RotationStructuredLogFormat { json, prettyJson }

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

  String get activeLogFileName => '$fileNamePrefix.log';
}
