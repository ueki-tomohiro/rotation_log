part of rotation_log;

class Logger {
  RotationLogTerm term;
  late RotationOutput output;

  String get logFileName => output.logFileName;

  Logger(this.term) {
    output = RotationOutput.fromTerm(term);
  }

  Future<void> init() async {
    final logfilePath = await _logFilePath();
    await output.init(logfilePath);
  }

  void error(Error err) {
    final errorMessage =
        _resolveError(errorMessage: err.toString(), stackTrace: err.stackTrace);
    log(RotationLogLevelEnum.error, errorMessage);
  }

  void exception(dynamic exception, StackTrace stackTrace) {
    final errorMessage = _resolveError(
        errorMessage: exception.toString(), stackTrace: stackTrace);
    log(RotationLogLevelEnum.error, errorMessage);
  }

  void log(RotationLogLevelEnum level, String message) {
    append("[${level.label}][${clock.now().toIso8601String()}]: $message");
  }

  void append(String log) => output.append(log);

  Future<String> archiveLog() async {
    final logfilePath = await _logFilePath();
    return await output.archive(logfilePath);
  }

  Future<void> close() async {
    final logfilePath = await _logFilePath();
    output.close(logfilePath);
  }

  Future<Directory> _logFilePath() async {
    final documents = await getApplicationSupportDirectory();
    final logFilePath = Directory(documents.path + "/logs");
    if (logFilePath.existsSync()) {
      return logFilePath;
    } else {
      return await logFilePath.create();
    }
  }

  String _resolveError({String? errorMessage, StackTrace? stackTrace}) {
    return '$errorMessage\n' +
        (stackTrace != null
            ? Trace.from(stackTrace).frames.map((f) {
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
              }).join('')
            : "");
  }
}
