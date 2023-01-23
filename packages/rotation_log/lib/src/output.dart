part of rotation_log;

class RotationLogOutput extends LogOutput {
  final RotationLogger rotationLogger;

  RotationLogOutput(this.rotationLogger);

  @override
  void output(OutputEvent event) {
    rotationLogger.log(event.level, event.lines.toString());
  }
}
