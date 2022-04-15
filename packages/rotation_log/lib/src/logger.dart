part of rotation_log;

class Logger {
  RotationLogTerm term;
  late RotationOutput output;

  String get logFileName => output.logFileName;

  Logger(this.term) {
    output = RotationOutput.fromTerm(term);
  }

  Future init() async {
    final logfilePath = await _logFilePath();
    await output.init(logfilePath);
  }

  void err(Error error) {
    final errorMessage = _resolveError(
        errorMessage: error.toString(), stackTrace: error.stackTrace);
    log(RotationLogLevelEnum.error, errorMessage);
  }

  void log(RotationLogLevelEnum level, String message) {
    append("[$level][${clock.now().toIso8601String()}]: $message");
  }

  void append(String log) => output.append(log);

  Future<String> archiveLog() async {
    final logfilePath = await _logFilePath();
    return await output.archive(logfilePath);
  }

  Future close() async {
    final logfilePath = await _logFilePath();
    output.close(logfilePath);
  }

  Future<Directory> _logFilePath() async {
    final documents = await getApplicationDocumentsDirectory();
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
