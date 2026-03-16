part of 'package:rotation_log/rotation_log.dart';

/// Resolves the directory where log files should be stored.
typedef RotationLogDirectoryProvider = Future<Directory> Function();

/// Main entry point for writing and managing rotating log files.
class RotationLogger {
  /// Rotation policy used by this logger.
  final RotationLogTerm term;

  /// Package options that control naming, formatting, and retention.
  final RotationLogOptions options;

  /// Optional custom directory resolver for log storage.
  final RotationLogDirectoryProvider? directoryProvider;

  /// Unique identifier for the current logger session.
  final String sessionId;

  /// Timestamp captured when this logger instance was created.
  final DateTime sessionStartedAt;

  /// Concrete output implementation selected from [term].
  late final RotationOutput output;
  Directory? _resolvedLogDirectory;
  bool _isInitialized = false;

  /// Absolute path of the currently active log file.
  String get logFileName => output.logFileName;

  /// Whether [init] has completed successfully.
  bool get isInitialized => _isInitialized;

  /// Creates a logger using the given rotation [term].
  RotationLogger(
    this.term, {
    this.options = const RotationLogOptions(),
    this.directoryProvider,
  }) : sessionStartedAt = clock.now(),
       sessionId = _createSessionId() {
    output = RotationOutput.fromTerm(term, options);
  }

  /// Initializes the logger and prepares the current log file.
  Future<void> init() async {
    final logfilePath = await _logFilePath(useCache: false);
    await output.init(logfilePath);
    _isInitialized = true;
  }

  /// Logs a Dart [Error] with its stack trace.
  void error(Error err) {
    final errorMessage = _resolveError(
      errorMessage: err.toString(),
      stackTrace: err.stackTrace,
    );
    log(Level.error, errorMessage);
  }

  /// Logs an arbitrary exception with the provided [stackTrace].
  void exception(dynamic exception, StackTrace stackTrace) {
    final errorMessage = _resolveError(
      errorMessage: exception.toString(),
      stackTrace: stackTrace,
    );
    log(Level.error, errorMessage);
  }

  /// Writes a plain-text log line.
  void log(Level level, String message) {
    logWithContext(level, message);
  }

  /// Writes a plain-text log line with optional tags and structured context.
  void logWithContext(
    Level level,
    String message, {
    DateTime? timestamp,
    List<String> tags = const <String>[],
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    if (!_shouldLog(level)) {
      return;
    }

    final eventTime = timestamp ?? clock.now();
    final rendered = options.plainTextOptions.format(
      level: level,
      message: message,
      timestamp: eventTime,
      tags: _mergeTags(tags),
      context: _mergeContext(context, includeStructuredSessionId: false),
      sessionId: sessionId,
    );
    append(rendered);
  }

  /// Writes a structured event.
  void logEvent(RotationLogEvent event) {
    final decoratedEvent = _decorateEvent(event);
    if (!_shouldLog(decoratedEvent.level)) {
      return;
    }

    append(_encodeStructuredEvent(decoratedEvent));
  }

  /// Writes a structured JSON event from primitive inputs.
  void logJson(
    Level level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    List<String> tags = const <String>[],
    Map<String, Object?> context = const <String, Object?>{},
    DateTime? timestamp,
  }) {
    logEvent(
      RotationLogEvent(
        level: level,
        message: message,
        timestamp: timestamp,
        error: error,
        stackTrace: stackTrace,
        tags: tags,
        context: context,
      ),
    );
  }

  /// Appends a pre-rendered log line directly to the output.
  void append(String log) => output.append(log);

  /// Archives all managed log files into the default ZIP file.
  Future<String> archiveLog() async {
    return archiveLogs();
  }

  /// Archives the selected log files into a ZIP file.
  Future<String> archiveLogs({
    String? archiveFileName,
    List<String>? filePaths,
  }) async {
    final logfilePath = await _logFilePath();
    final files = await _resolveArchiveFiles(logfilePath, filePaths);
    return _archiveFiles(
      logfilePath,
      files,
      archiveFileName: archiveFileName ?? options.archiveFileName,
    );
  }

  /// Archives only files created in the current logger session.
  Future<String> archiveCurrentSessionLogs({String? archiveFileName}) async {
    return archiveLogs(
      archiveFileName: archiveFileName,
      filePaths: await listCurrentSessionLogFiles(),
    );
  }

  /// Closes the underlying output if the logger has been initialized.
  Future<void> close() async {
    if (!_isInitialized || _resolvedLogDirectory == null) {
      return;
    }

    await output.close(_resolvedLogDirectory!);
  }

  /// Deletes all managed logs and resets the initialization state.
  Future<void> clearLogs() async {
    final logfilePath = await _logFilePath();
    await output.clear(logfilePath);
    _isInitialized = false;
  }

  /// Lists absolute paths for active and archived log files.
  Future<List<String>> listLogFiles() async {
    final logfilePath = await _logFilePath();
    final files = await output.logFiles(logfilePath);
    return files.map((file) => file.absolute.path).toList(growable: false);
  }

  /// Returns metadata for active, archived, and ZIP files.
  Future<List<RotationLogFileInfo>> listLogFileInfos() async {
    final logfilePath = await _logFilePath();
    final logFiles = await output.logFiles(logfilePath);
    final archiveFile = File(
      path.join(logfilePath.path, options.archiveFileName),
    );
    final files = <File>[
      ...logFiles,
      if (archiveFile.existsSync()) archiveFile,
    ];
    return _buildFileInfos(files);
  }

  /// Returns metadata for the currently active log file, if any.
  Future<RotationLogFileInfo?> currentLogFileInfo() async {
    final currentPath = logFileName;
    if (currentPath.isEmpty || !File(currentPath).existsSync()) {
      return null;
    }

    final infos = await _buildFileInfos(<File>[File(currentPath)]);
    return infos.isEmpty ? null : infos.single;
  }

  /// Lists log files produced during the current logger session.
  Future<List<String>> listCurrentSessionLogFiles() async {
    final allFiles = await listLogFiles();
    return allFiles.where(_belongsToCurrentSession).toList(growable: false);
  }

  /// Returns metadata for log files produced during the current session.
  Future<List<RotationLogFileInfo>> listCurrentSessionLogFileInfos() async {
    final currentSessionFiles = await listCurrentSessionLogFiles();
    return _buildFileInfos(
      currentSessionFiles.map(File.new).toList(growable: false),
    );
  }

  /// Applies retention rules and removes overflow files.
  Future<void> pruneLogs() async {
    final logfilePath = await _logFilePath();
    await output.prune(logfilePath);
  }

  /// Flushes buffered output.
  ///
  /// Current implementations write synchronously, so this is a no-op.
  Future<void> flush() async {}

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

  bool _shouldLog(Level level) {
    return level.value >= options.minimumLevel.value;
  }

  String _encodeStructuredEvent(RotationLogEvent event) {
    final json = event.toJson(options.structuredLogSchema);
    switch (options.structuredLogFormat) {
      case RotationStructuredLogFormat.json:
        return jsonEncode(json);
      case RotationStructuredLogFormat.prettyJson:
        return const JsonEncoder.withIndent('  ').convert(json);
    }
  }

  RotationLogEvent _decorateEvent(RotationLogEvent event) {
    final mergedContext = _mergeContext(
      event.context,
      includeStructuredSessionId: true,
    );
    final mergedTags = _mergeTags(event.tags);

    return event.copyWith(tags: mergedTags, context: mergedContext);
  }

  List<String> _mergeTags(List<String> tags) {
    return <String>{...options.defaultTags, ...tags}.toList(growable: false);
  }

  Map<String, Object?> _mergeContext(
    Map<String, Object?> context, {
    required bool includeStructuredSessionId,
  }) {
    return <String, Object?>{
      ...options.defaultContext,
      if (includeStructuredSessionId && options.includeSessionId)
        options.sessionContextKey: sessionId,
      ...context,
    };
  }

  Future<List<File>> _resolveArchiveFiles(
    Directory logfilePath,
    List<String>? filePaths,
  ) async {
    if (filePaths == null) {
      return await output.logFiles(logfilePath);
    }

    return filePaths
        .map(File.new)
        .where((file) => file.existsSync())
        .toList(growable: false);
  }

  Future<String> _archiveFiles(
    Directory logfilePath,
    List<File> files, {
    required String archiveFileName,
  }) async {
    final archivePath = path.join(logfilePath.path, archiveFileName);
    final archiveFile = File(archivePath);
    if (archiveFile.existsSync()) {
      archiveFile.deleteSync();
    }

    final encoder = ZipFileEncoder()..create(archivePath);
    for (final file in files) {
      await encoder.addFile(file);
    }
    await encoder.close();
    return archivePath;
  }

  Future<List<RotationLogFileInfo>> _buildFileInfos(List<File> files) async {
    final infos = <RotationLogFileInfo>[];
    for (final file in files) {
      if (!file.existsSync()) {
        continue;
      }
      final stat = file.statSync();
      infos.add(
        RotationLogFileInfo(
          path: file.absolute.path,
          name: path.basename(file.path),
          sizeBytes: stat.size,
          modifiedAt: stat.modified,
          isActiveLog: file.absolute.path == logFileName,
          isArchive: path.basename(file.path) == options.archiveFileName,
          isCurrentSessionFile: _belongsToCurrentSession(file.absolute.path),
        ),
      );
    }

    infos.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return infos;
  }

  bool _belongsToCurrentSession(String filePath) {
    final basename = path.basename(filePath);
    if (basename == options.activeLogFileName) {
      return true;
    }

    final match = RegExp(
      '^${RegExp.escape(options.fileNamePrefix)}-(\\d+)\\.log\$',
    ).firstMatch(basename);
    if (match == null) {
      return false;
    }

    final createdAt = int.parse(match.group(1)!);
    return createdAt >= sessionStartedAt.microsecondsSinceEpoch;
  }

  static String _createSessionId() {
    return '${clock.now().microsecondsSinceEpoch}-$pid';
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
