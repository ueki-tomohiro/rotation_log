part of rotation_log;

enum RotationLogLevelEnum { info, debug, warning, error }

extension RotationLogLevelEnumExtension on RotationLogLevelEnum {
  String get label => toString().split('.').last;
}

abstract class RotationOutput {
  String get logFileName;
  Future<void> init(Directory logfilePath);
  void append(String log);
  Future<String> archive(Directory logfilePath);
  Future<void> close(Directory logfilePath);

  factory RotationOutput.fromTerm(RotationLogTerm term) {
    if (term.option == RotationLogTermEnum.line) {
      return LineOutput(term.line);
    } else {
      return DailyOutput(term.day);
    }
  }
}
