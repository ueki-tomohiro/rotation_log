part of 'package:rotation_log/rotation_log.dart';

/// Rotates logs when the active file exceeds a byte threshold.
class SizeOutput extends _RollingOutput {
  /// Maximum file size in bytes before rotation.
  final int size;

  /// Creates a size-based output.
  SizeOutput(this.size, RotationLogOptions options) : super(options);

  @visibleForTesting
  /// Returns whether [file] would exceed the size limit after [nextLog].
  bool isNeedRotation(File file, {String? nextLog}) {
    if (!file.existsSync()) {
      return false;
    }

    final nextBytes = utf8.encode(nextLog == null ? '' : '$nextLog\n').length;
    return file.lengthSync() + nextBytes > size;
  }

  @override
  bool shouldRotate(File activeFile, String nextLog) {
    return isNeedRotation(activeFile, nextLog: nextLog);
  }
}
