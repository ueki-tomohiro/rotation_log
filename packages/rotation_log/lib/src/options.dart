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
  }) : assert(directoryName != ''),
       assert(fileNamePrefix != ''),
       assert(archiveFileName != ''),
       assert(maxArchivedFiles == null || maxArchivedFiles >= 0);

  final String directoryName;
  final String fileNamePrefix;
  final String archiveFileName;
  final int? maxArchivedFiles;
  final Level minimumLevel;
  final RotationStructuredLogFormat structuredLogFormat;

  String get activeLogFileName => '$fileNamePrefix.log';
}
