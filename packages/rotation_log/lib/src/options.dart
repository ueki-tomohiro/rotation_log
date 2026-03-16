part of rotation_log;

class RotationLogOptions {
  const RotationLogOptions({
    this.directoryName = 'logs',
    this.fileNamePrefix = 'rotation',
    this.archiveFileName = 'log.zip',
    this.maxArchivedFiles,
  }) : assert(directoryName != ''),
       assert(fileNamePrefix != ''),
       assert(archiveFileName != ''),
       assert(maxArchivedFiles == null || maxArchivedFiles >= 0);

  final String directoryName;
  final String fileNamePrefix;
  final String archiveFileName;
  final int? maxArchivedFiles;

  String get activeLogFileName => '$fileNamePrefix.log';
}
