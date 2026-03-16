part of rotation_log;

class RotationLogFileInfo {
  const RotationLogFileInfo({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.isActiveLog,
    required this.isArchive,
    required this.isCurrentSessionFile,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;
  final bool isActiveLog;
  final bool isArchive;
  final bool isCurrentSessionFile;
}
