part of rotation_log;

class SizeOutput extends _RollingOutput {
  final int size;

  SizeOutput(this.size, RotationLogOptions options) : super(options);

  @visibleForTesting
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
