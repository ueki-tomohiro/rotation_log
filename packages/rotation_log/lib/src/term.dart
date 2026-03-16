part of 'package:rotation_log/rotation_log.dart';

/// Built-in rotation strategies supported by [RotationLogTerm].
enum RotationLogTermEnum { daily, week, month, line, size, custom }

/// Describes when log files should rotate.
class RotationLogTerm {
  /// Selected rotation strategy.
  final RotationLogTermEnum option;

  /// Rotation interval in days for day-based strategies.
  late int day;

  /// Rotation threshold in lines for line-based strategies.
  late int line;

  /// Rotation threshold in bytes for size-based strategies.
  late int size;

  /// Creates a term for the selected [option].
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

  /// Creates one of the predefined terms from [option].
  factory RotationLogTerm.term(RotationLogTermEnum option) =>
      RotationLogTerm(option);

  /// Creates a custom day-based rotation term.
  factory RotationLogTerm.day(int day) =>
      RotationLogTerm(RotationLogTermEnum.custom, day: day);

  /// Creates a line-count-based rotation term.
  factory RotationLogTerm.line(int line) =>
      RotationLogTerm(RotationLogTermEnum.line, line: line);

  /// Creates a file-size-based rotation term.
  factory RotationLogTerm.size(int size) =>
      RotationLogTerm(RotationLogTermEnum.size, size: size);
}
