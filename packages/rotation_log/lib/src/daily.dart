part of rotation_log;

class DailyOutput implements RotationOutput {
  final int day;
  final RotationLogOptions options;

  DailyOutput(this.day, this.options);

  late Directory _logDirectory;
  String _logFileName = '';

  @override
  String get logFileName => _logFileName;

  @override
  Future<void> init(Directory logfilePath) async {
    _logDirectory = logfilePath;
    _pruneExpiredLogs();
    _pruneOverflowLogs();
    _createCurrentFile();
  }

  @visibleForTesting
  bool isNeedRotation(File file) {
    return isNeedRotationFromDateTime(_createdAtFromFile(file), clock.now());
  }

  @visibleForTesting
  bool isNeedRotationFromDateTime(DateTime created, [DateTime? now]) {
    return _elapsedCalendarDays(created, now ?? clock.now()) >= day;
  }

  @visibleForTesting
  String createFileName() =>
      '${options.fileNamePrefix}-${clock.now().microsecondsSinceEpoch}.log';

  @override
  void append(String log) {
    _ensureInitialized();
    if (_logFileName.isEmpty || isNeedRotation(File(_logFileName))) {
      _pruneExpiredLogs();
      _pruneOverflowLogs();
      _createCurrentFile();
    }

    File(_logFileName).writeAsStringSync('$log\n', mode: FileMode.writeOnlyAppend);
  }

  @override
  Future<String> archive(Directory logfilePath) async {
    _logDirectory = logfilePath;
    final archivePath = path.join(_logDirectory.path, options.archiveFileName);
    final archiveFile = File(archivePath);
    if (archiveFile.existsSync()) {
      archiveFile.deleteSync();
    }

    final encoder = ZipFileEncoder()..create(archivePath);
    for (final logfile in _logFilesInDirectory()) {
      await encoder.addFile(logfile);
    }
    await encoder.close();

    return archivePath;
  }

  @override
  Future<void> close(Directory logfilePath) async {
    _logDirectory = logfilePath;
  }

  @override
  Future<void> clear(Directory logfilePath) async {
    _logDirectory = logfilePath;
    for (final logfile in _logFilesInDirectory()) {
      if (logfile.existsSync()) {
        logfile.deleteSync();
      }
    }

    final archiveFile = File(path.join(_logDirectory.path, options.archiveFileName));
    if (archiveFile.existsSync()) {
      archiveFile.deleteSync();
    }

    _logFileName = '';
  }

  @override
  Future<List<File>> logFiles(Directory logfilePath) async {
    _logDirectory = logfilePath;
    return _logFilesInDirectory();
  }

  @override
  Future<void> prune(Directory logfilePath) async {
    _logDirectory = logfilePath;
    _pruneExpiredLogs();
    _pruneOverflowLogs();
  }

  void _createCurrentFile() {
    final file = File(path.join(_logDirectory.path, createFileName()));
    file.createSync(recursive: true);
    _logFileName = file.absolute.path;
  }

  DateTime _createdAtFromFile(File file) {
    final filename = path.basenameWithoutExtension(file.path);
    final prefix = '${options.fileNamePrefix}-';
    final timestamp = filename.substring(prefix.length);
    return DateTime.fromMicrosecondsSinceEpoch(int.parse(timestamp));
  }

  int _elapsedCalendarDays(DateTime created, DateTime current) {
    final start = DateTime(created.year, created.month, created.day);
    final end = DateTime(current.year, current.month, current.day);
    return end.difference(start).inDays;
  }

  bool _isExpired(File file) {
    final created = _createdAtFromFile(file);
    return _elapsedCalendarDays(created, clock.now()) > day;
  }

  List<File> _logFilesInDirectory() {
    if (!_logDirectory.existsSync()) {
      return <File>[];
    }

    final pattern = RegExp(
      '^${RegExp.escape(options.fileNamePrefix)}-(\\d+)\\.log\$',
    );

    final files = _logDirectory
        .listSync(followLinks: false)
        .whereType<File>()
        .where((file) => pattern.hasMatch(path.basename(file.path)))
        .toList(growable: false);

    files.sort((a, b) {
      final createdA = _createdAtFromFile(a).microsecondsSinceEpoch;
      final createdB = _createdAtFromFile(b).microsecondsSinceEpoch;
      return createdB.compareTo(createdA);
    });

    return files;
  }

  void _pruneExpiredLogs() {
    for (final logfile in _logFilesInDirectory()) {
      if (_isExpired(logfile)) {
        logfile.deleteSync();
      }
    }
  }

  void _pruneOverflowLogs() {
    final maxArchivedFiles = options.maxArchivedFiles;
    if (maxArchivedFiles == null) {
      return;
    }

    final files = _logFilesInDirectory();
    if (files.length <= maxArchivedFiles) {
      return;
    }

    for (final logfile in files.skip(maxArchivedFiles)) {
      logfile.deleteSync();
    }
  }

  void _ensureInitialized() {
    if (_logDirectory.path.isEmpty) {
      throw StateError('Call init() before writing logs.');
    }
  }
}
