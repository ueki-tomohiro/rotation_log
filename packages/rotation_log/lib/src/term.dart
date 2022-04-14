part of rotation_log;

enum RotationLogTermEnum { daily, week, month, line, custom }

class RotationLogTerm {
  RotationLogTermEnum option;
  late int day;
  late int line;

  RotationLogTerm(this.option, {int? day, int? line}) {
    this.line = 0;
    this.day = 0;

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
          throw ArgumentError("option needs line");
        }
        break;
      case RotationLogTermEnum.custom:
        if (day != null) {
          this.day = day;
        } else {
          throw ArgumentError("option needs day");
        }
        break;
    }
  }

  bool isNeedRotation(File file) {
    if (option == RotationLogTermEnum.line) {
      final lines = file.readAsBytesSync();
      return lines.length > line;
    } else {
      final filename = path.basenameWithoutExtension(file.path);
      final created = DateTime.fromMicrosecondsSinceEpoch(int.parse(filename));
      return isNeedRotationFromDateTime(created);
    }
  }

  bool isNeedRotationFromDateTime(DateTime created) {
    final diff = clock.now().difference(created);
    return diff.inDays > day;
  }

  String createFileName() =>
      clock.now().microsecondsSinceEpoch.toString() + ".log";

  factory RotationLogTerm.term(RotationLogTermEnum option) =>
      RotationLogTerm(option);

  factory RotationLogTerm.day(int day) =>
      RotationLogTerm(RotationLogTermEnum.custom, day: day);

  factory RotationLogTerm.line(int line) =>
      RotationLogTerm(RotationLogTermEnum.line, line: line);
}
