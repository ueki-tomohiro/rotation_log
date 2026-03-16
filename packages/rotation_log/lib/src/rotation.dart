part of rotation_log;

extension LevelExtension on Level {
  String get label => toString().split('.').last;
}

abstract class RotationOutput {
  String get logFileName;
  Future<void> init(Directory logfilePath);
  void append(String log);
  Future<String> archive(Directory logfilePath);
  Future<void> close(Directory logfilePath);
  Future<void> clear(Directory logfilePath);
  Future<List<File>> logFiles(Directory logfilePath);
  Future<void> prune(Directory logfilePath);

  factory RotationOutput.fromTerm(
    RotationLogTerm term,
    RotationLogOptions options,
  ) {
    switch (term.option) {
      case RotationLogTermEnum.line:
        return LineOutput(term.line, options);
      case RotationLogTermEnum.size:
        return SizeOutput(term.size, options);
      case RotationLogTermEnum.daily:
      case RotationLogTermEnum.week:
      case RotationLogTermEnum.month:
      case RotationLogTermEnum.custom:
        return DailyOutput(term.day, options);
    }
  }
}
