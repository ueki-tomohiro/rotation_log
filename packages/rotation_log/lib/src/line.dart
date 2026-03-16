part of rotation_log;

abstract class _RollingOutput implements RotationOutput {
  _RollingOutput(this.options);

  final RotationLogOptions options;

  late Directory _logDirectory;
  String _logFileName = '';

  @override
  String get logFileName => _logFileName;

  @override
  Future<void> init(Directory logfilePath) async {
    _logDirectory = logfilePath;
    _logFileName = path.join(_logDirectory.path, options.activeLogFileName);
    _activeFile.createSync(recursive: true);
    _pruneOverflowLogs();
  }

  @override
  void append(String log) {
    _ensureInitialized();

    if (shouldRotate(_activeFile, log)) {
      _rotate();
    }

    _activeFile.writeAsStringSync('$log\n', mode: FileMode.writeOnlyAppend);
  }

  @override
  Future<String> archive(Directory logfilePath) async {
    _logDirectory = logfilePath;
    _logFileName = path.join(_logDirectory.path, options.activeLogFileName);

    final archivePath = path.join(_logDirectory.path, options.archiveFileName);
    final archiveFile = File(archivePath);
    if (archiveFile.existsSync()) {
      archiveFile.deleteSync();
    }

    final encoder = ZipFileEncoder()..create(archivePath);
    for (final logfile in _orderedLogFiles()) {
      if (logfile.existsSync()) {
        await encoder.addFile(logfile);
      }
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
    for (final logfile in _orderedLogFiles()) {
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
    _logFileName = path.join(_logDirectory.path, options.activeLogFileName);
    return _orderedLogFiles();
  }

  @override
  Future<void> prune(Directory logfilePath) async {
    _logDirectory = logfilePath;
    _logFileName = path.join(_logDirectory.path, options.activeLogFileName);
    _pruneOverflowLogs();
  }

  bool shouldRotate(File activeFile, String nextLog);

  File get _activeFile => File(path.join(_logDirectory.path, options.activeLogFileName));

  List<File> _archivedFiles() {
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
      final timestampA = _timestampFromArchivedFile(a);
      final timestampB = _timestampFromArchivedFile(b);
      return timestampB.compareTo(timestampA);
    });

    return files;
  }

  List<File> _orderedLogFiles() {
    final files = <File>[];
    if (_activeFile.existsSync()) {
      files.add(_activeFile);
    }
    files.addAll(_archivedFiles());
    return files;
  }

  int _timestampFromArchivedFile(File file) {
    final filename = path.basenameWithoutExtension(file.path);
    final prefix = '${options.fileNamePrefix}-';
    return int.parse(filename.substring(prefix.length));
  }

  void _rotate() {
    if (_activeFile.existsSync() && _activeFile.lengthSync() > 0) {
      final archived = File(
        path.join(
          _logDirectory.path,
          '${options.fileNamePrefix}-${clock.now().microsecondsSinceEpoch}.log',
        ),
      );
      _activeFile.renameSync(archived.path);
    }

    _activeFile.createSync(recursive: true);
    _pruneOverflowLogs();
  }

  void _pruneOverflowLogs() {
    final maxArchivedFiles = options.maxArchivedFiles;
    if (maxArchivedFiles == null) {
      return;
    }

    final archivedFiles = _archivedFiles();
    if (archivedFiles.length <= maxArchivedFiles) {
      return;
    }

    for (final logfile in archivedFiles.skip(maxArchivedFiles)) {
      logfile.deleteSync();
    }
  }

  void _ensureInitialized() {
    if (_logDirectory.path.isEmpty) {
      throw StateError('Call init() before writing logs.');
    }
  }
}

class LineOutput extends _RollingOutput {
  final int line;

  LineOutput(this.line, RotationLogOptions options) : super(options);

  @visibleForTesting
  bool isNeedRotation(File file) {
    if (!file.existsSync()) {
      return false;
    }

    return file.readAsLinesSync().length >= line;
  }

  @override
  bool shouldRotate(File activeFile, String nextLog) {
    return isNeedRotation(activeFile);
  }
}
