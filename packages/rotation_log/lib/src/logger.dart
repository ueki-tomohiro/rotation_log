part of rotation_log;

typedef RotationLogDirectoryProvider = Future<Directory> Function();

class RotationLogger {
  final RotationLogTerm term;
  final RotationLogOptions options;
  final RotationLogDirectoryProvider? directoryProvider;
  late final RotationOutput output;
  Directory? _resolvedLogDirectory;
  bool _isInitialized = false;

  String get logFileName => output.logFileName;

  RotationLogger(
    this.term, {
    this.options = const RotationLogOptions(),
    this.directoryProvider,
  }) {
    output = RotationOutput.fromTerm(term, options);
  }

  Future<void> init() async {
    final logfilePath = await _logFilePath(useCache: false);
    await output.init(logfilePath);
    _isInitialized = true;
  }

  void error(Error err) {
    final errorMessage = _resolveError(
      errorMessage: err.toString(),
      stackTrace: err.stackTrace,
    );
    log(Level.error, errorMessage);
  }

  void exception(dynamic exception, StackTrace stackTrace) {
    final errorMessage = _resolveError(
      errorMessage: exception.toString(),
      stackTrace: stackTrace,
    );
    log(Level.error, errorMessage);
  }

  void log(Level level, String message) {
    append('[${level.label}][${clock.now().toIso8601String()}]: $message');
  }

  void append(String log) => output.append(log);

  Future<String> archiveLog() async {
    final logfilePath = await _logFilePath();
    return await output.archive(logfilePath);
  }

  Future<void> close() async {
    if (!_isInitialized || _resolvedLogDirectory == null) {
      return;
    }

    await output.close(_resolvedLogDirectory!);
  }

  Future<void> clearLogs() async {
    final logfilePath = await _logFilePath();
    await output.clear(logfilePath);
    _isInitialized = false;
  }

  Future<List<String>> listLogFiles() async {
    final logfilePath = await _logFilePath();
    final files = await output.logFiles(logfilePath);
    return files.map((file) => file.absolute.path).toList(growable: false);
  }

  Future<void> pruneLogs() async {
    final logfilePath = await _logFilePath();
    await output.prune(logfilePath);
  }

  Future<Directory> _logFilePath({bool useCache = true}) async {
    if (useCache && _resolvedLogDirectory != null) {
      return _resolvedLogDirectory!;
    }

    if (directoryProvider != null) {
      final providedDirectory = await directoryProvider!.call();
      if (!providedDirectory.existsSync()) {
        _resolvedLogDirectory = await providedDirectory.create(recursive: true);
        return _resolvedLogDirectory!;
      }
      _resolvedLogDirectory = providedDirectory;
      return providedDirectory;
    }

    final documents = await getApplicationSupportDirectory();
    final logFilePath = Directory(
      path.join(documents.path, options.directoryName),
    );
    if (logFilePath.existsSync()) {
      _resolvedLogDirectory = logFilePath;
      return logFilePath;
    } else {
      _resolvedLogDirectory = await logFilePath.create(recursive: true);
      return _resolvedLogDirectory!;
    }
  }

  String _resolveError({String? errorMessage, StackTrace? stackTrace}) {
    return '$errorMessage\n${stackTrace != null ? Trace.from(stackTrace).frames.map((f) {
        String member = f.member ?? "<anonymous>";
        if (member == '<fn>') {
          member = '<anonymous>';
        }

        String loc = 'unknown location';
        if (f.isCore) {
          loc = 'native';
        } else if (f.line != null) {
          loc = '${f.uri}:${f.line}:${f.column ?? 0}';
        }

        return '    at $member ($loc)\n';
      }).join('') : ""}';
  }
}
