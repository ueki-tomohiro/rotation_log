part of rotation_log;

enum RotationLogTermEnum { daily, week, month, line, size, custom }

class RotationLogTerm {
  final RotationLogTermEnum option;
  late int day;
  late int line;
  late int size;

  RotationLogTerm(this.option, {int? day, int? line, int? size}) {
    this.line = 0;
    this.day = 0;
    this.size = 0;

    switch (option) {
      case RotationLogTermEnum.daily:
        this.day = 1;
        break;
      case RotationLogTermEnum.week:
        this.day = 7;
        break;
      case RotationLogTermEnum.month:
        this.day = 30;
        break;
      case RotationLogTermEnum.line:
        if (line != null) {
          this.line = line;
        } else {
          throw ArgumentError('option needs line');
        }
        break;
      case RotationLogTermEnum.size:
        if (size != null) {
          this.size = size;
        } else {
          throw ArgumentError('option needs size');
        }
        break;
      case RotationLogTermEnum.custom:
        if (day != null) {
          this.day = day;
        } else {
          throw ArgumentError('option needs day');
        }
        break;
    }
  }

  factory RotationLogTerm.term(RotationLogTermEnum option) =>
      RotationLogTerm(option);

  factory RotationLogTerm.day(int day) =>
      RotationLogTerm(RotationLogTermEnum.custom, day: day);

  factory RotationLogTerm.line(int line) =>
      RotationLogTerm(RotationLogTermEnum.line, line: line);

  factory RotationLogTerm.size(int size) =>
      RotationLogTerm(RotationLogTermEnum.size, size: size);
}
