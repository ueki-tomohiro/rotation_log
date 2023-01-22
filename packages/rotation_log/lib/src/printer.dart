part of rotation_log;

class RotationLogPrinter extends LogPrinter {
  final RotationLogger rotationLogger;
  final prettyPrinter = PrettyPrinter(printEmojis: false, colors: false);

  RotationLogPrinter(this.rotationLogger);

  @override
  List<String> log(LogEvent event) {
    final formatLog = prettyPrinter.log(event);
    rotationLogger.log(event.level, formatLog.join());
    return formatLog;
  }
}
