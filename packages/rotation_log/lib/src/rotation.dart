part of 'package:rotation_log/rotation_log.dart';

/// Convenience helpers for converting [Level] values to display labels.
extension LevelExtension on Level {
  /// Lowercase label derived from the enum name.
  String get label => toString().split('.').last;
}

/// Common interface implemented by each rotation strategy.
abstract class RotationOutput {
  /// Absolute path of the active log file.
  String get logFileName;

  /// Prepares output for writing into [logfilePath].
  Future<void> init(Directory logfilePath);

  /// Appends a rendered log line.
  void append(String log);

  /// Creates an archive of managed log files.
  Future<String> archive(Directory logfilePath);

  /// Closes any underlying resources.
  Future<void> close(Directory logfilePath);

  /// Deletes managed logs and related archives.
  Future<void> clear(Directory logfilePath);

  /// Returns active and archived log files.
  Future<List<File>> logFiles(Directory logfilePath);

  /// Applies retention rules.
  Future<void> prune(Directory logfilePath);

  /// Creates the appropriate output implementation for [term].
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
